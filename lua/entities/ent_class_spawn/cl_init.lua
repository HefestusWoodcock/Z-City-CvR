include("shared.lua")

function ENT:Draw()
    local wep = LocalPlayer():GetActiveWeapon()
    if IsValid(wep) and not wep:GetClass() == "weapon_physgun" then return end

    self:DrawModel()
end