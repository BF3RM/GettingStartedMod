--- Server Teleporter Class
---@class ServerTeleporter
---@overload fun():ServerTeleporter
ServerTeleporter = class "ServerTeleporter"

---@type Logger
local m_Logger = Logger("ServerTeleporter", true)

---@type RealityModTimer
local m_Timer = RealityModTimer

function ServerTeleporter:__init()
    m_Logger:Write("ServerTeleporter init.")
    self:RegisterVars()
    self:RegisterEvents()
    self:RegisterHooks()
end

function ServerTeleporter:RegisterVars()
    self.m_IgnoreSoldierDamageForPlayer = {}
end

function ServerTeleporter:RegisterEvents()
    NetEvents:Subscribe(NETEVENTS.TELEPORT_TO_POSITION, self, self.OnTeleportToPositionRequest)
end

function ServerTeleporter:RegisterHooks()
    Hooks:Install('Soldier:Damage', 1, self, self.OnSoldierDamage)
end

---@param p_HookCtx HookContext
---@param p_Soldier SoldierEntity
---@param p_Info DamageInfo
---@param p_GiverInfo DamageGiverInfo
function ServerTeleporter:OnSoldierDamage(p_HookCtx, p_Soldier, p_Info, p_GiverInfo)
    if self:_CheckIfSoldierIsProtected(p_Soldier) then
        -- disable damage
        p_HookCtx:Return(nil)
    else
        if self:_CheckIfSoldierIsProtected(p_Soldier) then
            m_Logger:Write("Removed player from ignore damage list because he didnt teleport")
        end
    end
end

---@param p_Player Player
---@param p_TeleportPosition Vec3
function ServerTeleporter:OnTeleportToPositionRequest(p_Player, p_TeleportPosition)
    if not p_TeleportPosition then
        m_Logger:Error("Teleport Position is invalid")
        return
    end

    -- get the player soldier to teleport
    local s_Soldier = p_Player.soldier

    if not s_Soldier then
        m_Logger:Warning("Soldier to teleport is nil")
        return
    end

    -- Set new position of the soldier
    s_Soldier:SetPosition(p_TeleportPosition)

    -- Add soldier to damage protection table
    table.insert(self.m_IgnoreSoldierDamageForPlayer, p_Player.name)

    -- remove protection after set time
    m_Timer:Simple(SETTINGS.TELEPORT_PROTECTION_IN_S, function()
        if self:_CheckIfSoldierIsProtected(p_Player.soldier) then
            m_Logger:Write("Soldier Protection Lifted")
        end
    end)

    -- log the teleported player and the position
    m_Logger:Write("Teleported Player: " .. p_Player.name .. " to Position: " .. tostring(p_TeleportPosition))
end

function ServerTeleporter:_CheckIfSoldierIsProtected(p_Soldier)
    for l_Index, l_SoldierName in ipairs(self.m_IgnoreSoldierDamageForPlayer) do
        if l_SoldierName == p_Soldier.player.name then
            table.remove(self.m_IgnoreSoldierDamageForPlayer, l_Index)
            return true
        end
    end
    return false
end

return ServerTeleporter()