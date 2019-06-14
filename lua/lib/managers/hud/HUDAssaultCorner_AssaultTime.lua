-- Can't optimize it further because I can't use GroupAIStateBase functions on client
function HUDAssaultCorner:CalculateValueFromDiff()
    self:_calculate_difficulty_ratio()
    return math.lerp(self:_get_difficulty_dependent_value(tweak_data.group_ai.besiege.assault.sustain_duration_min), self:_get_difficulty_dependent_value(tweak_data.group_ai.besiege.assault.sustain_duration_max), math.random()) * self:_get_balancing_multiplier(tweak_data.group_ai.besiege.assault.sustain_duration_balance_mul)
end

function HUDAssaultCorner:_calculate_difficulty_ratio()
	local ramp = tweak_data.group_ai.difficulty_curve_points
	local diff = self.diff
	local i = 1

	while (ramp[i] or 1) < diff do
		i = i + 1
	end

	self._difficulty_point_index = i
	self._difficulty_ramp = (diff - (ramp[i - 1] or 0)) / ((ramp[i] or 1) - (ramp[i - 1] or 0))
end

function HUDAssaultCorner:_get_difficulty_dependent_value(tweak_values)
	return math.lerp(tweak_values[self._difficulty_point_index], tweak_values[self._difficulty_point_index + 1], self._difficulty_ramp)
end

function HUDAssaultCorner:_get_balancing_multiplier(balance_multipliers)
	local nr_players = 0

	for u_key, u_data in pairs(managers.groupai:state():all_player_criminals()) do
		if not u_data.status then
			nr_players = nr_players + 1
		end
	end

	local nr_ai = 0

	for u_key, u_data in pairs(managers.groupai:state():all_AI_criminals()) do
		if not u_data.status then
			nr_ai = nr_ai + 1
		end
	end

	nr_players = nr_players == 1 and nr_players + math.max(0, nr_ai - 1) or nr_players + nr_ai
	nr_players = math.clamp(nr_players, 1, 4)

	return balance_multipliers[nr_players]
end

function CrimeSpreeManager:DoesServerHasAssaultExtenderModifier()
    local server_modifiers = self._global.server_modifiers or {}
    for _, data in ipairs(server_modifiers) do
        if data.id == "assault_extender" then
            return true
        end
    end
    return false
end

core:import("CoreMissionScriptElement")
function ElementDifficulty:client_on_executed(...)
    if not self._values.enabled then
		return
    end
    managers.hud._hud_assault_corner.diff = self._values.difficulty
end