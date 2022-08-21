--- Some Shared Class
---@class SomeSharedClass
---@overload fun():SomeSharedClass
SomeSharedClass = class "SomeSharedClass"

require "__shared/Enums"
require "__shared/Settings"

require "__shared/Utils/Logger"
require "__shared/Utils/DC"
require "__shared/Utils/RealityModTimer"

---@type DC
local m_FiringFunctionM249 = DC(Guid("F37DBC84-F61B-11DF-829C-95F94E7154E3"), Guid("7FCFC3D7-49C2-477E-8952-664FDA86B41E"))
---@type DC
local m_SMAWHEProjectileData = DC(Guid("168F529B-17F6-11E0-8CD8-85483A75A7C5"), Guid("168F529C-17F6-11E0-8CD8-85483A75A7C5"))
---@type DC
local m_SMAWHEProjectileBlueprint = DC(Guid("168F529B-17F6-11E0-8CD8-85483A75A7C5"), Guid("90BAEBC0-C9E6-CB0B-7531-110499218677"))

---@type Logger
local m_Logger = Logger("SomeSharedClass", true)

function SomeSharedClass:__init()
	m_Logger:Write("SomeSharedClass init.")
	self:RegisterVars()
	self:RegisterEvents()
	self:RegisterHooks()
	self:RegisterCallbacks()
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

function SomeSharedClass:RegisterCallbacks()
	m_FiringFunctionM249:RegisterLoadHandler(self, self.ModifyM249FiringFunctionData)
end

function SomeSharedClass:OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)
	RealityModTimer:OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)
end

---comment
---@param p_Instance FiringFunctionData
function SomeSharedClass:ModifyM249FiringFunctionData(p_FiringFunctionData)
	p_FiringFunctionData:MakeWritable()

	local s_ShotConfig = p_FiringFunctionData.shot

	if s_ShotConfig then
		s_ShotConfig.projectileData = m_SMAWHEProjectileData:GetInstance()
		s_ShotConfig.projectile = m_SMAWHEProjectileBlueprint:GetInstance()
		m_Logger:Write("Replaced M249 Projectile")
	end

	local s_FireLogic = p_FiringFunctionData.fireLogic

	if s_FireLogic then
		s_FireLogic.rateOfFire = 1200
		m_Logger:Write("Modified M249 FireLogic")
	end

	local s_AmmoConfig = p_FiringFunctionData.ammo

	if s_AmmoConfig then
		s_AmmoConfig.magazineCapacity = 249
		s_AmmoConfig.autoReplenishMagazine = true
		s_AmmoConfig.autoReplenishDelay = 5.0
		m_Logger:Write("Modified M249 AmmoConfig")
	end
end

return SomeSharedClass()

