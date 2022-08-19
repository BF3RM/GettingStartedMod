---@class DC
---@field WaitForInstances fun(self: DC, p_Instances : DC[], p_Userdata : any, p_Callback : function|nil)
---@overload fun(p_PartitionGuid: Guid, p_InstanceGuid: Guid):DC
DC = class "DC"

---@type Logger
local m_Logger = Logger("DC", false)

---Creates a new DC class
---@param p_PartitionGuid Guid
---@param p_InstanceGuid Guid
function DC:__init(p_PartitionGuid, p_InstanceGuid)
	if p_PartitionGuid == nil or p_InstanceGuid == nil then
		m_Logger:Error("Invalid guids specified")
		return
	end

	self.m_PartitionGuid = p_PartitionGuid
	self.m_InstanceGuid = p_InstanceGuid
	---@type ContainerCallback[]
	self.m_ContainerCallbacks = {}
end

---@return DataContainer|nil
function DC:GetInstance()
	local s_Instance = ResourceManager:FindInstanceByGuid(self.m_PartitionGuid, self.m_InstanceGuid)

	if s_Instance == nil then
		return nil
	end

	return _G[s_Instance.typeInfo.name](s_Instance)
end

---@param p_Userdata any
---@param p_Callback function|nil
function DC:CallOrRegisterLoadHandler(p_Userdata, p_Callback)
	local s_Instance = self:GetInstance()

	if s_Instance ~= nil then
		if p_Callback == nil then
			p_Userdata(self:_CastedAndWritable(s_Instance))
		else
			p_Callback(p_Userdata, self:_CastedAndWritable(s_Instance))
		end
	else
		self:RegisterLoadHandlerOnce(p_Userdata, p_Callback)
	end
end

---@param p_Userdata any
---@param p_Callback function|nil
function DC:RegisterLoadHandler(p_Userdata, p_Callback)
	self:_RegisterLoadHandlerInternal(false, p_Userdata, p_Callback)
end

---@param p_Userdata userdata|function
---@param p_Callback function|nil
function DC:RegisterLoadHandlerOnce(p_Userdata, p_Callback)
	self:_RegisterLoadHandlerInternal(true, p_Userdata, p_Callback)
end

---Deregister all ContainerCallbacks
function DC:Deregister()
	for _, l_ContainerCallback in ipairs(self.m_ContainerCallbacks) do
		l_ContainerCallback:Deregister()
	end

	self.m_ContainerCallbacks = {}
end

---@param p_Once boolean
---@param p_Userdata userdata|function
---@param p_Callback function|nil
function DC:_RegisterLoadHandlerInternal(p_Once, p_Userdata, p_Callback)
	local s_Args

	if p_Callback == nil then
		s_Args = { function(p_Instance) p_Userdata(self:_CastedAndWritable(p_Instance)) end }
	else
		s_Args = { p_Userdata, function(p_Userdata, p_Instance) p_Callback(p_Userdata, self:_CastedAndWritable(p_Instance)) end }
	end

	if p_Once then
		local s_ContainerCallback = ResourceManager:RegisterInstanceLoadHandlerOnce(self.m_PartitionGuid, self.m_InstanceGuid, table.unpack(s_Args))
		table.insert(self.m_ContainerCallbacks, s_ContainerCallback)
	else
		local s_ContainerCallback = ResourceManager:RegisterInstanceLoadHandler(self.m_PartitionGuid, self.m_InstanceGuid, table.unpack(s_Args))
		table.insert(self.m_ContainerCallbacks, s_ContainerCallback)
	end
end

---@param p_Instance DataContainer
---@return DataContainer
function DC:_CastedAndWritable(p_Instance)
	p_Instance = _G[p_Instance.typeInfo.name](p_Instance)
	p_Instance:MakeWritable()
	return p_Instance
end

---@param p_Instances DC[]
---@param p_Userdata userdata|function
---@param p_Callback function|nil
function DC.static:WaitForInstances(p_Instances, p_Userdata, p_Callback)
	---@type DataContainer[]
	local s_Instances = {}

	for l_Index, l_DC in ipairs(p_Instances) do
		---@param p_Instance DataContainer
		local function InstanceLoaded(p_Instance)
			s_Instances[l_Index] = p_Instance

			for i = 1, #p_Instances do
				if s_Instances[i] ~= nil then
					s_Instances[i] = ResourceManager:FindInstanceByGuid(p_Instances[i].m_PartitionGuid, p_Instances[i].m_InstanceGuid)

					if s_Instances[i] == nil then
						m_Logger:Warning("Something went wrong. The instance: Guid(\'" .. tostring(p_Instances[i].m_InstanceGuid) .. "\') got destroyed, register it again.")
						local s_ContainerCallback = ResourceManager:RegisterInstanceLoadHandlerOnce(p_Instances[i].m_PartitionGuid, p_Instances[i].m_InstanceGuid, InstanceLoaded)
						table.insert(p_Instances[i].m_ContainerCallbacks, s_ContainerCallback)
					end
				end

				if s_Instances[i] == nil then
					return
				end
			end

			if p_Callback == nil then
				p_Userdata(table.unpack(s_Instances))
			else
				p_Callback(p_Userdata, table.unpack(s_Instances))
			end

			self:WaitForInstances(p_Instances, p_Userdata, p_Callback)
		end

		local s_ContainerCallback = ResourceManager:RegisterInstanceLoadHandlerOnce(l_DC.m_PartitionGuid, l_DC.m_InstanceGuid, InstanceLoaded)
		table.insert(l_DC.m_ContainerCallbacks, s_ContainerCallback)
	end
end

return DC
