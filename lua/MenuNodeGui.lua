local _setup_item_rows_original = MenuNodeMainGui._setup_item_rows
local _add_version_string_original = MenuNodeMainGui._add_version_string

function MenuNodeMainGui:_add_version_string()
    _add_version_string_original(self)
    self._version_string:set_text("PAYDAY2 v" .. Application:version() .. " with SydneyHUD v" .. SydneyHUD:GetVersion())
    if SydneyHUD:GetOption("remove_ads") then
        self._version_string:set_align("right")
    end
end

function MenuNodeMainGui:_setup_item_rows(node, ...)
    _setup_item_rows_original(self, node, ...)
    if SydneyHUD._poco_conf and not SydneyHUD._poco_warning then
        SydneyHUD._fixed_poco_conf = deep_clone(SydneyHUD._poco_conflicting_defaults)
        for k, v in pairs(SydneyHUD._poco_conf) do
            if not SydneyHUD._fixed_poco_conf[k] then
                SydneyHUD._fixed_poco_conf[k] = v
            else
                for k2, v2 in pairs(SydneyHUD._poco_conf[k]) do
                    SydneyHUD._fixed_poco_conf[k][k2] = v2
                end
            end
        end
        local conflicts = {}
        local buff = SydneyHUD._fixed_poco_conf.buff
        if buff then
            if buff.hideInteractionCircle ~= nil then
                SydneyHUD._fixed_poco_conf.buff.hideInteractionCircle = nil
                table.insert(conflicts, "buff.hideInteractionCircle")
            end
        end
        local game = SydneyHUD._fixed_poco_conf.game
        if game then
            if game.interactionClickStick ~= false then
                SydneyHUD._fixed_poco_conf.game.interactionClickStick = false
                table.insert(conflicts, "game.interactionClickStick")
            end
            if game.truncateNames ~= nil then
                SydneyHUD._fixed_poco_conf.game.truncateNames = nil
                table.insert(conflicts, "game.truncateNames")
            end
        end
        local playerBottom = SydneyHUD._fixed_poco_conf.playerBottom
        if playerBottom then
            if playerBottom.showRank ~= false then
                SydneyHUD._fixed_poco_conf.playerBottom.showRank = false
                table.insert(conflicts, "playerBottom.showRank")
            end
            if playerBottom.uppercaseNames ~= false then
                SydneyHUD._fixed_poco_conf.playerBottom.uppercaseNames = false
                table.insert(conflicts, "playerBottom.uppercaseNames")
            end
        end
        if #conflicts ~= 0 then -- Some conflicts were found better fix it
            local menu_title = managers.localization:text("sydneyhud_pocohud_conflicts_found")
            local menu_message = managers.localization:text("sydneyhud_pocohud_conflicts_found_desc_1") .. json.encode(conflicts) .. managers.localization:text("sydneyhud_pocohud_conflicts_found_desc_2")
            local menu_options = {
                [1] = {
                    text = managers.localization:text("sydneyhud_ok"),
                    is_cancel_button = true
                }
            }
            QuickMenu:new(menu_title, menu_message, menu_options, true)
            SydneyHUD:ApplyFixedPocoSettings()
        end
        local recommendations = {}
        if buff then
            if buff.showBoost ~= false then
                SydneyHUD._fixed_poco_conf.buff.showBoost = false
                table.insert(recommendations, "buff.showBoost")
            end
            if buff.showCharge ~= false then
                SydneyHUD._fixed_poco_conf.buff.showCharge = false
                table.insert(recommendations, "buff.showCharge")
            end
            if buff.showECM ~= false then
                SydneyHUD._fixed_poco_conf.buff.showECM = false
                table.insert(recommendations, "buff.showECM")
            end
            if buff.showInteraction ~= false then
                SydneyHUD._fixed_poco_conf.buff.showInteraction = false
                table.insert(recommendations, "buff.showInteraction")
            end
            if buff.showReload ~= false then
                SydneyHUD._fixed_poco_conf.buff.showReload = false
                table.insert(recommendations, "buff.showReload")
            end
            if buff.showShield ~= false then
                SydneyHUD._fixed_poco_conf.buff.showShield = false
                table.insert(recommendations, "buff.showShield")
            end
            if buff.showStamina ~= false then
                SydneyHUD._fixed_poco_conf.buff.showStamina = false
                table.insert(recommendations, "buff.showStamina")
            end
            if buff.showSwanSong ~= false then
                SydneyHUD._fixed_poco_conf.buff.showSwanSong = false
                table.insert(recommendations, "buff.showSwanSong")
            end
            if buff.showTapeLoop ~= false then
                SydneyHUD._fixed_poco_conf.buff.showTapeLoop = false
                table.insert(recommendations, "buff.showTapeLoop")
            end
            if buff.simpleBusyIndicator ~= false then
                SydneyHUD._fixed_poco_conf.buff.simpleBusyIndicator = false
                table.insert(recommendations, "buff.simpleBusyIndicator")
            end
        end
        playerBottom = SydneyHUD._fixed_poco_conf.playerBottom
        if playerBottom then
            if not playerBottom.showDetectionRisk or playerBottom.showDetectionRisk > 0 then
                SydneyHUD._fixed_poco_conf.playerBottom.showDetectionRisk = 0
                table.insert(recommendations, "playerBottom.showDetectionRisk")
            end
            if not playerBottom.showDowns or playerBottom.showDowns > 0 then
                SydneyHUD._fixed_poco_conf.playerBottom.showDowns = 0
                table.insert(recommendations, "playerBottom.showDowns")
            end
            if not playerBottom.showInteraction or playerBottom.showInteraction > 0 then
                SydneyHUD._fixed_poco_conf.playerBottom.showInteraction = 0
                table.insert(recommendations, "playerBottom.showInteraction")
            end
            if not playerBottom.showInteractionTime or playerBottom.showInteractionTime > 0 then
                SydneyHUD._fixed_poco_conf.playerBottom.showInteractionTime = 0
                table.insert(recommendations, "playerBottom.showInteractionTime")
            end
            if not playerBottom.showKill or playerBottom.showKill > 0 then
                SydneyHUD._fixed_poco_conf.playerBottom.showKill = 0
                table.insert(recommendations, "playerBottom.showKill")
            end
            if not playerBottom.showSpecial or playerBottom.showSpecial > 0 then
                SydneyHUD._fixed_poco_conf.playerBottom.showSpecial = 0
                table.insert(recommendations, "playerBottom.showSpecial")
            end
        end
        if #recommendations ~= 0 and SydneyHUD:GetOption("show_poco_recommendations") then
            local menu_title = managers.localization:text("sydneyhud_pocohud_recommendations_found")
            local menu_message = managers.localization:text("sydneyhud_pocohud_recommendations_found_desc_1") .. json.encode(recommendations) .. managers.localization:text("sydneyhud_pocohud_recommendations_found_desc_2")
            local menu_options = {
                [1] = {
                    text = managers.localization:text("sydneyhud_pocohud_recommendations_found_fix"),
                    callback = function()
                        SydneyHUD:ApplyFixedPocoSettings()
                    end
                },
                [2] = {
                    text = managers.localization:text("sydneyhud_pocohud_recommendations_found_keep"),
                    is_cancel_button = true
                },
                [3] = {
                    text = managers.localization:text("sydneyhud_pocohud_recommendations_found_keep_and_dont_remind"),
                    callback = function()
                        SydneyHUD._data.show_poco_recommendations = false
                        SydneyHUD:Save()
                    end
                }
            }
            QuickMenu:new(menu_title, menu_message, menu_options, true)
        end
        SydneyHUD._poco_warning = true
    end
end