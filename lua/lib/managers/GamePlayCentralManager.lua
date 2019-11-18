local old_init = GamePlayCentralManager.init
function GamePlayCentralManager:init(...)
    old_init(self, ...)
    if SydneyHUD:GetOption("block_bullet_decals") then
        self._block_bullet_decals = true
    end
    if SydneyHUD:GetOption("block_blood_decals") then
        self._block_blood_decals = true
    end
end