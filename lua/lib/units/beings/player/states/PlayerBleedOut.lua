Hooks:PostHook(PlayerBleedOut, '_enter', "SydneyHUD:Down", function(self, enter_data)
    SydneyHUD:Down(LuaNetworking:LocalPeerID(), true)
end)