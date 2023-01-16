-- macro templating
local targetTemplate = "[@%s,help,nodead]"
local macroStart = "#showtooltip %s\n/cast "
-- spells to create macros for
local spells = {"Misdirection","Tricks of the Trade"}

LazyDirect.tanks = {}

function LazyDirect:UpdateTanks()
  local tanks = {}
  
  -- determine if group is party or raid
  local groupType = (IsInRaid() and "raid") or (IsInGroup() and "party") or nil
  
  -- if in a group, search the group for someone with tank role
  if groupType ~= nil then
    for i=1,GetNumGroupMembers() do
      local role = UnitGroupRolesAssigned(groupType .. i)
      if role == "TANK" then
        table.insert(tanks, {
          name = UnitName(groupType .. i),
          id = groupType .. i
        })
        if #tanks == 2 then
          break
        end
      end
    end
  end
  
  local tankUpdate = {}
  local unknownTanks = {}
  -- update known tanks in the same position and get list of unkown tanks
  for i,newTank in ipairs(tanks) do
    local tankKnown = false
    for j,knownTank in ipairs(LazyDirect.tanks) do
      if newTank.name == knownTank.name then
        tankUpdate[j] = newTank
        tankKnown = true
      end
    end
    if tankKnown == false then
      table.insert(unknownTanks, newTank)
    end
  end
  
  -- fill in gaps with unknown tanks
  for _, newTank in ipairs(unknownTanks) do
    table.insert(tankUpdate, newTank)
  end
  
  -- set the tanks
  LazyDirect.tanks = tankUpdate
  LazyDirect.db.profile.tanks = tankUpdate
end

function LazyDirect:UpdateMacros()
  for _, spell in ipairs(spells) do
    local spellName,_,icon = GetSpellInfo(spell)
        
	-- if the user is not speced into the spell, skip and go to next spell
    if spellName ~= nil then
	  -- create the macro name
	  local name = spell .. "-LazyDirect"
      -- create the macro body    
      local body = string.format(macroStart, spell)
    
      -- loop throught the priority order and append each target to the body
      for _, target in ipairs(LazyDirect.priorityOrder) do
        -- if we come across a tank target, get the respective tank from the tank list
        if string.sub(target,1,4) == "TANK" then
          tank = LazyDirect.tanks[tonumber(string.sub(target,5,5))]
          if tank ~= nil then
            body = body .. string.format(targetTemplate, tank.id)
          end
		else 
		  body = body .. string.format(targetTemplate, target)
        end
      end
    
      -- end the body with the spell name
      body = body .. " " .. spell
      
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
    
      -- if the macro was updated, inform the user
      if macroUpdated then
        if #LazyDirect.tanks > 0 then
		  tankStrings = {}
		  for i, tank in ipairs(LazyDirect.tanks) do
		    table.insert(tankStrings, tank.name .. " (Tank " .. i .. ")")
		  end
          print("[LazyDirect] Updated " .. name .. " to use tank(s): " .. table.concat(tankStrings,", "))
        end
      end
	end
  end
end

function LazyDirect:main(event)
  LazyDirect:UpdateTanks()
  LazyDirect:UpdateMacros()
end

local f = CreateFrame("Frame")
f:RegisterEvent("GROUP_JOINED")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", LazyDirect.main)