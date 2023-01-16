local enabledDefaults = {
  TANK1 = true,
  TANK2 = true,
  focus = true,
  pet = true,
  mouseover = false,
  targettarget = false,
  target = false
}

-----------------------------
-- START PRIORITY HANDLING --
-----------------------------

LazyDirect.tempOrder = {"TANK1","TANK2","focus","pet"}

-- calculate sort order for priorities
function LazyDirect:PrioritySorting(info)
  local order = {"deselect"}
  local options = LazyDirect:PriorityValues(info)
  
  for _, target in ipairs(self.targets) do
    if options[target.key] ~= nil then
      table.insert(order, target.key)
    end
  end
  
  return order
end


-- calculate what values should be selectable in each priority
function LazyDirect:PriorityValues(info)
  local optionName = info[1]
  local currPriority = tonumber(string.sub(optionName,9,9))
  
  -- get all taken values so they can be excluded
  local takenValues = {}
  for priority, value in ipairs(self.tempOrder) do
    -- make sure to ignore current option so selected choice doesn't get hidden
    if currPriority ~= priority then
      takenValues[value] = value
    end
  end
  
  -- get all enabled values so they can be included
  local enabledValues = {}
  for option, value in pairs(self.enabled) do
    if value == true then
      enabledValues[option] = option
    end
  end
  
  -- calculate list of values
  local values = {deselect = "<DESELECT>"}
  for _, target in ipairs(self.targets) do
    local key = target.key
    if takenValues[key] == nil and enabledValues[key] then
      values[key] = target.name
    end    
  end

  return values
end


-- disables priority options that are greater than number of enabled targets
function LazyDirect:PriorityDisable(info)
  local optionName = info[1]
  local currPriority = tonumber(string.sub(optionName,9,9))
  
  local numEnabled = 0
  for key, value in pairs(self.enabled) do
    if value == true then
      numEnabled = numEnabled + 1
    end
  end
  
  return currPriority > numEnabled
end

---------------------------
-- END PRIORITY HANDLING --
---------------------------


-- run when confirm button is pressed
function LazyDirect:Confirm(info)
  -- copies tempOrder into priorityOrder to commit the changes
  self.priorityOrder = {}
  for index, value in ipairs(self.tempOrder) do
    self.priorityOrder[index] = value
  end
  
  self.db.profile.priorityOrder = LazyDirect:CopyTable(self.priorityOrder)
  self.db.profile.enabled = LazyDirect:CopyTable(self.enabled)
  
  -- update the macros
  LazyDirect:main()
  
  print("[LazyDirect] Successfully updated priorities.")
end


-- called when getting an option to display in the ui
function LazyDirect:GetOption(info)
  local optionName = info[1]
  local optionType = info.type
  
  local value = nil
  
  -- handle target enable options
  if optionType == "toggle" then
    value = self.enabled[optionName]
    if value == nil then
      value = enabledDefaults[optionName]
      self.enabled[optionName] = value
    end
  end
  
  -- handle priority select options
  if optionType == "select" then
    local priority = tonumber(string.sub(optionName,9,9))
    value = self.tempOrder[priority]
    if value == nil or value == "deselect" then
      value = ""
    end
  end
  
  return value
end


-- called when an option is updated
function LazyDirect:SetOption(info,value)
  local optionName = info[1]
  local optionType = info.type
  
  if optionType == "toggle" then
    self.enabled[optionName] = value
    -- if value is set to true, add newly selected value as bottom priority
    -- else, remove the value and adjust other priorities
    if value == true then
      table.insert(self.tempOrder, optionName)
    else
      -- find the index of disabled value
      local index = 0
      for i, key in ipairs(self.tempOrder) do
        if key == optionName then
          index = i
          break
        end
      end
      -- remove the found index
      table.remove(self.tempOrder, index)
      
      -- remove deselected indexes to prevent "deselect" getting stuck in list
      local deselectFound = true
      while deselectFound do
        local index = 0
        for i, key in ipairs(self.tempOrder) do
          if key == "deselect" then
            index = i
            break
          end
        end
        deselectFound = index ~= 0
        if deselectFound then
          table.remove(self.tempOrder, index)
        end
      end
      
    end
  end
  
  if optionType == "select" then
    local priority = tonumber(string.sub(optionName,9,9))
    self.tempOrder[priority] = value
  end
end


-- initialize the options menu and add it to blizard addon settings page
function LazyDirect:InitializeSettings()
  local options = {
    name = "LazyDirect",
    handler = LazyDirect,
    type = 'group',
    get = "GetOption",
    set = "SetOption",
    args = {
      description1 = {type = "description", name = "Select which targets you wish to include in the LazyDirect macro, " .. 
        "and then order the targets using the priority list below.", order = 10},
      description2 = {type = "description", name = "The LazyDirect macro will use the highest priority target that exists, is alive, and is friendly.", order = 20},
      targetDesc = {type = "header", name = "Targets", order = 50},
      priority = {type = "header", name = "Priority", order = 99},
      highest = {type = "description", name = "Highest Priority", order = 100},
      lowest = {type = "description", name = "Lowest Priority", order = 100 + (LazyDirect:CountTable(self.targets)*2) + 1},
      confirm = {type = "execute", name = "Confirm", func = "Confirm", order = 500}
    }
  }
  
  -- initialize checkboxes
  for _, target in ipairs(self.targets) do
    options.args[target.key] = 
      {type = "toggle", name = target.name, order = target.order + 50}
  end
  
  -- initialize priority selects
  for i, target in ipairs(self.targets) do
    options.args["spacer" .. i] = {type = "description", name = "", order = 100 + (i*2) - 1}
    options.args["priority" .. i] = 
      {type = "select", name = "", values = "PriorityValues", sorting = "PrioritySorting",
        disabled = "PriorityDisable", order = 100 + (i*2)}
  end
  
  LibStub("AceConfig-3.0"):RegisterOptionsTable("LazyDirect", options)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LazyDirect","LazyDirect")
  
  -- copy priority order into tempOrder so we can modify it without commiting any changes until ready
  self.tempOrder = {}
  for index, value in ipairs(self.priorityOrder) do
    self.tempOrder[index] = value
  end
end