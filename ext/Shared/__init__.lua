--- Some Shared Class
---@class SomeSharedClass
---@overload fun():SomeSharedClass
SomeSharedClass = class "SomeSharedClass"

require "__shared/Enums"
require "__shared/Settings"

require "__shared/Utils/Logger"
--require "__shared/Utils/DC"
require "__shared/Utils/RealityModTimer"

---@type Logger
local m_Logger = Logger("SomeSharedClass", false)

function SomeSharedClass:__init()
	m_Logger:Write("SomeSharedClass init.")
	self:RegisterVars()
	self:RegisterEvents()
	self:RegisterHooks()
end

function SomeSharedClass:RegisterVars()
	-- add variables here
end

function SomeSharedClass:RegisterEvents()
	Events:Subscribe('Engine:Update', self, self.OnEngineUpdate)
end

function SomeSharedClass:RegisterHooks()
	-- register hooks here
end

function SomeSharedClass:OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)
	RealityModTimer:OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)
end

return SomeSharedClass()

