---@class RealityModTimer
RealityModTimer = {}

---@type Logger
local m_Logger = Logger("RealityModTimer", false)

local m_CurrentTime = 0.0
local m_LastDelta = 0.0
local m_Timers = {}

local function _ResetVars()
	m_CurrentTime = 0.0
	m_LastDelta = 0.0
	m_Timers = {}
end

function RealityModTimer:OnResetData()
	_ResetVars()
end

function RealityModTimer:GetEngineTime()
	return m_CurrentTime
end

function RealityModTimer:GetTimers()
	return m_Timers
end

---@param p_TimerName string
---@return table|nil
function RealityModTimer:GetTimer(p_TimerName)
	if not p_TimerName then
		m_Logger:Error('RealityModTimer:GetTimer() - argument timerName was nil')
		return
	end

	return m_Timers[p_TimerName]
end

---@param p_DeltaTime number
---@param p_SimulationDeltaTime number
function RealityModTimer:OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)
	m_LastDelta = m_LastDelta + p_DeltaTime

	if m_LastDelta < 0.01 then -- add check: or round hasnt started yet
		return
	end

	m_CurrentTime = m_CurrentTime + m_LastDelta

	m_LastDelta = 0.0

	self:Check()
end

---@param p_TimerName string
---@return number|nil
function RealityModTimer:GetTimeLeft(p_TimerName)
	if not p_TimerName then
		m_Logger:Error('RealityModTimer:GetTimeLeft() - argument timerName was nil')
		return nil
	end

	local s_Timer = m_Timers[p_TimerName]
	m_Logger:Write("GetTimeLeft " .. p_TimerName)

	if s_Timer then
		local s_Result = s_Timer.lastExec + s_Timer.delay - m_CurrentTime
		m_Logger:Write("result " .. s_Result)

		return s_Result
	else
		return nil
	end
end

---@return string|nil
local function _GetNewRandomString()
	if m_CurrentTime == 0.0 then
		m_Logger:Warning('CurrentTime was 0, that means the OnEngineUpdate didn\'t start yet. No way you should be spawning stuff already. Canceling it.')
		return nil
	end

	---@type string|nil
	local s_Pseudorandom = nil

	while true do
		s_Pseudorandom = tostring(MathUtils:GetRandomInt(10000000, 99999999))

		if m_Timers[s_Pseudorandom] == nil then
			break
		end
	end

	m_Logger:Write("RealityModTimer:GetNewRandomString() - got a new random timer name: " .. s_Pseudorandom)
	return s_Pseudorandom
end

---@param p_TimerName string|nil
---@param p_Delay number
---@param p_Repetitions integer
---@param p_IsRepetitive boolean
---@param p_Context table
---@param p_Function function
---@overload fun(p_TimerName: string, p_Delay: number, p_Repetitions: integer, p_IsRepetitive: boolean, p_Function: function|nil)
local function _CreateInternal(p_TimerName, p_Delay, p_Repetitions, p_IsRepetitive, p_Context, p_Function) -- call one of the above not this one
	if p_Function == nil then
		---@diagnostic disable-next-line: cast-local-type
		p_Function = p_Context
		---@diagnostic disable-next-line: cast-local-type
		p_Context = nil
	end

	p_TimerName = p_TimerName or _GetNewRandomString()

	-- current time has to be 0 for this to occur, so we already got a warning/error
	if p_TimerName == nil then
		return
	end

	if m_Timers[p_TimerName] ~= nil then
		m_Logger:Error("Instead of creating a new timer you attempted to overwrite an existing one. TimerName: " .. p_TimerName)
	end

	if p_Context ~= nil and type(p_Context) ~= "table" then
		m_Logger:Error("Context has to be a table.")
	end

	m_Timers[p_TimerName] = {
		name = p_TimerName,
		delay = p_Delay,
		reps = p_Repetitions == 0 and -1 or p_Repetitions,
		context = p_Context,
		func = p_Function,
		on = true,
		lastExec = m_CurrentTime,
		isRepetitive = false or p_IsRepetitive,
	}

	m_Logger:Write("RealityModTimer:CreateInternal() - timer name: " .. p_TimerName .. ' delay: ' .. p_Delay)
end

---@param p_Delay number
---@param p_Context table
---@param p_Function function
---@overload fun(self, p_Delay: number, p_Function: function)
---@return string
function RealityModTimer:Simple(p_Delay, p_Context, p_Function)
	local s_TimerName = _GetNewRandomString()
	---@cast s_TimerName string
	_CreateInternal(s_TimerName, p_Delay, 1, false, p_Context, p_Function)

	return s_TimerName
end

---@param p_TimerName string?
---@param p_Delay number
---@param p_Repetitions integer
---@param p_Context table
---@param p_Function function
---@overload fun(self, p_TimerName: string?, p_Delay: number, p_Repetitions: integer, p_Function: function|nil)
function RealityModTimer:Create(p_TimerName, p_Delay, p_Repetitions, p_Context, p_Function)
	_CreateInternal(p_TimerName, p_Delay, p_Repetitions, false, p_Context, p_Function)
end

---@param p_TimerName string?
---@param p_Delay number
---@param p_Context table
---@param p_Function function
---@overload fun(self, p_TimerName: string?, p_Delay: number, p_Function: function)
function RealityModTimer:CreateRepetitive(p_TimerName, p_Delay, p_Context, p_Function)
	_CreateInternal(p_TimerName, p_Delay, 0, true, p_Context, p_Function)
end

function RealityModTimer:Check()
	local s_CurrentTime = m_CurrentTime

	for l_TimerName, l_Timer in pairs(m_Timers) do
		if l_Timer.lastExec + l_Timer.delay <= s_CurrentTime and l_Timer.on then
			if l_Timer.func ~= nil then
				if l_Timer.context ~= nil then
					l_Timer.func(table.unpack(l_Timer.context))
				else
					l_Timer.func()
				end
			end

			l_Timer.lastExec = s_CurrentTime

			if not l_Timer.isRepetitive then
				if l_Timer.reps > 0 then
					l_Timer.reps = l_Timer.reps - 1
					m_Logger:Write("RealityModTimer:Check() - Subtracted Rep. Reps left: " .. l_Timer.reps)
				end

				if l_Timer.reps <= 0 then
					m_Timers[l_TimerName] = nil
					m_Logger:Write("RealityModTimer:Check() - Deleted Timer: " .. l_TimerName)
				end
			end
		end
	end
end

---@param p_TimerName string
---@return boolean
function RealityModTimer:Start(p_TimerName)
	m_Logger:Write('RealityModTimer:Start() - Starting timer: ' .. p_TimerName)
	local s_Timer = m_Timers[p_TimerName]

	if not s_Timer then
		m_Logger:Error("Tried to start nonexistant timer: " .. tostring(p_TimerName))
		return false
	end

	s_Timer.on = true
	s_Timer.timeDiff = nil
	s_Timer.lastExec = m_CurrentTime

	return true
end

---@param p_TimerName string
---@return boolean
function RealityModTimer:Stop(p_TimerName)
	m_Logger:Write('RealityModTimer:Stop() - Stopping timer: ' .. p_TimerName)
	local s_Timer = m_Timers[p_TimerName]

	if not s_Timer then
		m_Logger:Error("Tried to stop nonexistant timer: " .. tostring(p_TimerName))
		return false
	end

	s_Timer.on = false
	s_Timer.timeDiff = nil
	--m_Timers[name] = nil

	return true
end

---@param p_TimerName string
---@return boolean
function RealityModTimer:Pause(p_TimerName)
	m_Logger:Write('RealityModTimer:Pause() - Pausing timer: ' .. p_TimerName)
	local s_Timer = m_Timers[p_TimerName]

	if not s_Timer then
		m_Logger:Error("Tried to pause nonexistant timer: " .. tostring(p_TimerName))
		return false
	end

	s_Timer.on = false
	s_Timer.timeDiff = m_CurrentTime - s_Timer.lastExec

	return true
end

---@param p_TimerName string
---@return boolean
function RealityModTimer:UnPause(p_TimerName)
	m_Logger:Write('RealityModTimer:UnPause() - Unpausing timer: ' .. p_TimerName)
	local s_Timer = m_Timers[p_TimerName]

	if not s_Timer or not s_Timer.timeDiff then
		m_Logger:Error("Tried to unpause nonexistant timer: " .. tostring(p_TimerName))
		return false
	end

	if not s_Timer.timeDiff then
		m_Logger:Error("Tried to unpause nonpaused timer: " .. tostring(p_TimerName))
		return false
	end

	s_Timer.on = true
	s_Timer.lastExec = m_CurrentTime - s_Timer.timeDiff
	s_Timer.timeDiff = nil

	return true
end

---@param p_TimerName string
---@param p_Delay number
---@param p_Repetitions integer
---@param p_IsRepetitive boolean
---@param p_Context table
---@param p_Function function|nil
---@return boolean
---@overload fun(self, p_TimerName: string, p_Delay: number, p_Repetitions: integer, p_IsRepetitive: boolean, p_Function: function|nil): boolean
function RealityModTimer:Adjust(p_TimerName, p_Delay, p_Repetitions, p_IsRepetitive, p_Context, p_Function)
	m_Logger:Write('RealityModTimer:Adjust() - Adjusting timer: ' .. p_TimerName .. ', new value: ' .. p_Delay)
	local s_Timer = m_Timers[p_TimerName]

	-- if not s_Timer or not s_Timer.timeDiff then
	if not s_Timer then
		m_Logger:Error("Tried to adjust nonexistant timer: " .. tostring(p_TimerName))
		return false
	end

	if type(p_Delay) ~= "number" or p_Delay < 0 then
		m_Logger:Error("Invalid timer delay: " .. tostring(p_Delay))
		return false
	end

	if type(p_Repetitions) ~= "number" or p_Repetitions < 0 or math.floor(p_Repetitions) ~= p_Repetitions then
		m_Logger:Error("Invalid timer reps: " .. tostring(p_Repetitions))
		return false
	end

	s_Timer.delay = p_Delay
	s_Timer.lastExec = m_CurrentTime
	s_Timer.reps = p_Repetitions
	s_Timer.isRepetitive = p_IsRepetitive

	if p_Function == nil then
		---@diagnostic disable-next-line: cast-local-type
		p_Function = p_Context
		---@diagnostic disable-next-line: cast-local-type
		p_Context = nil
	end

	if p_Function ~= nil and type(p_Function) ~= "function" and not (getmetatable(p_Function) and getmetatable(p_Function).__call) then
		m_Logger:Error("Invalid timer function: " .. tostring(p_Function))
		return false
	end

	if p_Context ~= nil then
		s_Timer.context = p_Context
	end

	if p_Function ~= nil then
		s_Timer.func = p_Function
	end

	return true
end

---@param p_TimerName string
function RealityModTimer:Delete(p_TimerName)
	if p_TimerName == nil or type(p_TimerName) ~= "string" then
		return
	end

	m_Logger:Write('RealityModTimer:Delete() - Delete timer: ' .. p_TimerName)

	if m_Timers[p_TimerName] ~= nil then
		m_Timers[p_TimerName] = nil
	end
end

return RealityModTimer
