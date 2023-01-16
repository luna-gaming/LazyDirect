LazyDirect = LibStub("AceAddon-3.0"):NewAddon("LazyDirect")
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
  LazyDirect.db = LibStub("AceDB-3.0"):New("LazyDirectDB", dbDefaults)
  LazyDirect.enabled = LazyDirect:CopyTable(LazyDirect.db.profile.enabled)
  LazyDirect.priorityOrder = LazyDirect:CopyTable(LazyDirect.db.profile.priorityOrder)
  LazyDirect.tanks = LazyDirect:CopyTable(LazyDirect.db.profile.tanks)

  LazyDirect.InitializeSettings()
end

-- any stuff that needs to happen when the addon is enabled
function LazyDirect:OnEnable()
  LazyDirect.main()
end

function LazyDirect:CopyTable(src)
  local newTable = {}
  for k,v in pairs(src) do
    newTable[k] = v
  end
  return newTable
end