local function SetTranshumanOrganism(org)

    org.CantCheckPulse = true
    org.bleedingmul = 0.75
    org.recoilmul = 0.6
    org.legstrength = 1.5
    org.stamina.range = 60 * 4
    org.stamina.max = 60 * 4
    org.stamina[1] = org.stamina.range

    org.shockMul = 0.4
    org.painMul = 0.6
    org.hurtMul = 0.8
    org.immobilizationMax = 10

    org.adrenalineStorage = 8

    self.organism.CantCheckPulse = nil
end