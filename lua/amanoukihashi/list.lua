local M = {}

local NEW_LABEL = "+ new session"

function M.render_lines(sessions)
  local lines = {}
  for _, s in ipairs(sessions) do
    lines[#lines + 1] = (s.active and "● " or "○ ") .. s.name
  end
  lines[#lines + 1] = NEW_LABEL
  return lines
end

function M.action_for(line, sessions)
  local n = #sessions
  if line >= 1 and line <= n then
    local s = sessions[line]
    if s.active then return "refocus" end
    return "switch", s
  end
  return "new"
end

return M
