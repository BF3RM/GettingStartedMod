--- Client Teleporter Class
---@class ClientTeleporter
---@overload fun():ClientTeleporter
ClientTeleporter = class "ClientTeleporter"

---@type Logger
local m_Logger = Logger("ClientTeleporter", true)

function ClientTeleporter:__init()
    m_Logger:Write("ClientTeleporter init.")
    self:RegisterVars()
    self:RegisterEvents()
    self:RegisterHooks()
end

function ClientTeleporter:RegisterVars()
    -- add variables here
end

function ClientTeleporter:RegisterEvents()
    Events:Subscribe('Player:UpdateInput', self, self.OnPlayerUpdateInput)
end

function ClientTeleporter:RegisterHooks()
    -- register hooks here
end

---Update Player Input Event
---@param p_Player Player
---@param p_DeltaTime number
function ClientTeleporter:OnPlayerUpdateInput(p_Player, p_DeltaTime)
    if InputManager:WentKeyDown(InputDeviceKeys.IDK_F) and p_Player.soldier ~= nil and not p_Player.inVehicle then
        self:TeleportRaycasted()
    end
end

function ClientTeleporter:TeleportRaycasted()
    -- get the client camera transform
    local s_Transform = ClientUtils:GetCameraTransform()

    -- add security checks
	if s_Transform == nil then return end

	if s_Transform.trans == Vec3.zero then -- Camera is below the ground. Creating an entity here would be useless.
		return
	end

	-- The freecam transform is inverted. Invert it back
	local s_CameraForward = Vec3(s_Transform.forward.x * -1, s_Transform.forward.y * -1, s_Transform.forward.z * -1)

    -- get the position in the world to raycast to
	local s_CastPosition = Vec3(
        s_Transform.trans.x + (s_CameraForward.x * SETTINGS.RAYCAST_DISTANCE),
		s_Transform.trans.y + (s_CameraForward.y * SETTINGS.RAYCAST_DISTANCE),
		s_Transform.trans.z + (s_CameraForward.z * SETTINGS.RAYCAST_DISTANCE)
    )

    -- Raycast
	local s_Raycast = RaycastManager:Raycast(s_Transform.trans, s_CastPosition, RayCastFlags.IsAsyncRaycast)

	if s_Raycast == nil then
		return
	end

    -- lets add a meter to the position height to prevent spawning in the ground
    local s_TeleportPosition = s_Raycast.position
    s_TeleportPosition.y = s_TeleportPosition.y + 1

    -- send our event to the server so it can handle the teleporting
    NetEvents:SendLocal(NETEVENTS.TELEPORT_TO_POSITION, s_TeleportPosition)
    m_Logger:Write("Teleport Request Sent")
end

return ClientTeleporter()
