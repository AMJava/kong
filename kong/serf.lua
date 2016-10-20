-- from the previous services.serf module, simply decoupled from
-- the Serf agent supervision logic.

local pl_stringx = require "pl.stringx"
local pl_utils = require "pl.utils"
local pl_file = require "pl.file"
local cjson = require "cjson.safe"
local log = require "kong.cmd.utils.log"
local socker = require "socket"
local pl_path = require "pl.path"
local conf_loader = require "kong.conf_loader"
local tostring = tostring

-- retrieve kong_config
local conf_path = pl_path.join(ngx.config.prefix(), "kong.conf")
local config = assert(conf_loader(conf_path))

function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end


local Serf = {}
Serf.__index = Serf

function sleep(sec)
    socket.select(nil, nil, sec)
end

Serf.args_mt = {
  __tostring = function(t)
    local buf = {}
    for k, v in pairs(t) do buf[#buf+1] = k.." '"..v.."'" end
    return table.concat(buf, " ")
  end
}

function Serf.new(kong_config, dao)
  return setmetatable({
    node_name = pl_file.read(kong_config.serf_node_id),
    config = kong_config,
    dao = dao
  }, Serf)
end

-- WARN: BAD, this is **blocking** IO. Legacy code from previous Serf
-- implementation that needs to be upgraded.
function Serf:invoke_signal(signal, args, no_rpc)
  ngx.log(ngx.ERR, "IN INVOKE SIGNAL 1 "..self.config.serf_sleep_time, "")
  sleep(5)
  args = args or {}
  if type(args) == "table" then
    setmetatable(args, Serf.args_mt)
  end
  local rpc = no_rpc and "" or "-rpc-addr="..self.config.cluster_listen_rpc
  local cmd = string.format("%s %s %s %s", self.config.serf_path, signal, rpc, tostring(args))
  local ok, code, stdout, stderr = pl_utils.executeex(cmd)
  if not ok or code ~= 0 then
    -- always print the first error line of serf
    local err = stdout ~= "" and pl_stringx.splitlines(stdout)[1] or stderr
    return nil, err
  end

  return stdout
end

function Serf:join_node(address)
  return select(2, self:invoke_signal("join", address)) == nil
end

function Serf:leave()
  -- See https://github.com/hashicorp/serf/issues/400
  -- Currently sometimes this returns an error, once that Serf issue has been
  -- fixed we can check again for any errors returned by the following command.
  self:invoke_signal("leave")

  local _, err = self.dao.nodes:delete {name = self.node_name}
  if err then return nil, tostring(err) end

  return true
end

function Serf:force_leave(node_name)
  local res, err = self:invoke_signal("force-leave", node_name)
  if not res then return nil, err end

  return true
end

function Serf:members()
  local res, err = self:invoke_signal("members", {["-format"] = "json"})
  if not res then return nil, err end

  local json, err = cjson.decode(res)
  if not json then return nil, err end

  return json.members
end

function Serf:keygen()
  return self:invoke_signal("keygen", nil, true)
end

function Serf:reachability()
  return self:invoke_signal("reachability")
end

function Serf:cleanup()
  -- Delete current node just in case it was there
  -- (due to an inconsistency caused by a crash)
  local _, err = self.dao.nodes:delete {name = self.node_name }
  if err then return nil, tostring(err) end

  return true
end

function Serf:autojoin()
  local nodes, err = self.dao.nodes:find_all()
  if err then return nil, tostring(err)
  elseif #nodes == 0 then
    log.verbose("no other nodes found in the cluster")
  else
    -- Sort by newest to oldest (although by TTL would be a better sort)
    table.sort(nodes, function(a, b) return a.created_at > b.created_at end)

    local joined
    for _, v in ipairs(nodes) do
      if self:join_node(v.cluster_listening_address) then
        log.verbose("successfully joined cluster at %s", v.cluster_listening_address)
        joined = true
        break
      else
        log.warn("could not join cluster at %s, if the node does not exist "..
                 "anymore it will be purged automatically", v.cluster_listening_address)
      end
    end
    if not joined then
      log.warn("could not join the existing cluster")
    end
  end

  return true
end

function Serf:add_node()
  local members, err = self:members()
  if not members then return nil, err end

  local addr
  for _, member in ipairs(members) do
    if member.name == self.node_name then
      addr = member.addr
      break
    end
  end

  if not addr then
    return nil, "can't find current member address"
  end

  local _, err = self.dao.nodes:insert({
    name = self.node_name,
    cluster_listening_address = pl_stringx.strip(addr)
  }, {ttl = self.config.cluster_ttl_on_failure})
  if err then return nil, tostring(err) end

  return true
end

function Serf:event(t_payload)
  local payload, err = cjson.encode(t_payload)
  if not payload then return nil, err end

  if #payload > 512 then
    -- Serf can't send a payload greater than 512 bytes
    return nil, "encoded payload is "..#payload.." and exceeds the limit of 512 bytes!"
  end

  return self:invoke_signal("event -coalesce=false", " kong '"..payload.."'")
end

return Serf
