-- template taking spell, tank unit id, spell
local template = "#showtooltip %s\n/cast [@%s,help,nodead][@pet,help,nodead] %s"
-- spells to create macros for
local spells = {"Misdirection","Tricks of the Trade"}

local function OnEvent(self, event, ...)
  local tankName = nil
  local tankId = ""
  
  -- determine if group is party or raid
  local groupType = (IsInRaid() and "raid") or (IsInGroup() and "party") or nil
  
  -- if in a group, search the group for someone with tank role
  if groupType ~= nil then
    for i=1,GetNumGroupMembers() do
      local role = UnitGroupRolesAssigned(groupType .. i)
      if role == "TANK" then
        tankName = UnitName(groupType .. i)
        tankId = groupType .. i
        break
      end
    end
  end
      
  for _, spell in ipairs(spells) do
    -- create the macro name and body
    local name = spell .. "-LazyDirect"
    local body = string.format(template, spell, tankId, spell)
    local spellName,_,icon = GetSpellInfo(spell)
    icon = icon or 134400 -- default to questionmark if spell was not found
  
    -- get the existing version of the macro if it exists
    local currMacro, _, currBody = GetMacroInfo(name)
    -- if the current macro exists, trim whitespace
    if currBody ~= nil then
      currBody = string.trim(currBody)
    end
  
    -- if the macro doesn't exist, create it, else update the macro if it needs to be modified
    local macroUpdated = false
    if currMacro == nil then
      CreateMacro(name, icon, body)
      macroUpdated = true
    elseif currBody ~= body then
      EditMacro(name, name, icon, body)
      macroUpdated = true
    end
    
    -- if the macro was updated, inform the user if they are speced in to the relevant spell
    if macroUpdated and spellName ~= nil then
      if tankName ~= nil then
        print("[LazyDirect] Updated " .. name .. " to use " .. spell .. " on " .. tankName .. ".")
      else
        print("[LazyDirect] No tank found. Updated " .. name .. " to only work on active pet or current target.")
      end
    end
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("GROUP_JOINED")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_ROLES_ASSIGNED")
f:SetScript("OnEvent", OnEvent)