LazyDirect = LibStub("AceAddon-3.0"):NewAddon("LazyDirect", "AceConsole-3.0")
LazyDirect.options = {enabled = {}}

LazyDirect.targets = {
  {key = "TANK1", name = "Tank 1", order = 1},
  {key = "TANK2", name = "Tank 2", order = 4},
  {key = "focus", name = "Focus Target", order = 7},
  {key = "pet", name = "Pet", order = 2},
  {key = "mouseover", name = "Mouseover", order = 5},
  {key = "targettarget", name = "Target of Target", order = 3},
  {key = "target", name = "Current Target", order = 6}
}

-- any stuff that needs to happen to initialize the addon
function LazyDirect:OnInitialize()
  local dbDefaults = {
    profile = {
      enabled = {TANK1 = true},
      priorityOrder = {"TANK1","TANK2","focus","pet"},
      tanks = {}
    }
  }
  self.db = LibStub("AceDB-3.0"):New("LazyDirectDB", dbDefaults)
  self.enabled = self:CopyTable(self.db.profile.enabled)
  self.priorityOrder = self:CopyTable(self.db.profile.priorityOrder)
  self.tanks = self:CopyTable(self.db.profile.tanks)

  self:InitializeSettings()
  
  self:RegisterChatCommand("lazydirect","HandleCommand")
  self:RegisterChatCommand("LazyDirect","HandleCommand")
  self:RegisterChatCommand("Lazydirect","HandleCommand")
  self:RegisterChatCommand("lazyDirect","HandleCommand")
end

-- any stuff that needs to happen when the addon is enabled
function LazyDirect:OnEnable()
  self:main()
end

function LazyDirect:CopyTable(src)
  local newTable = {}
  for k,v in pairs(src) do
    newTable[k] = v
  end
  return newTable
end

function LazyDirect:CountTable(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end