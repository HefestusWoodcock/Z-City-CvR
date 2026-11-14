local max, halfValue = math.max, util.halfValue
--local Organism = hg.organism
hg.organism.module.liver = {}
local module = hg.organism.module.liver
---@param org Organism
module[1] = function(org)
	org.liver = 0
end

module[2] = function(owner, org, mulTime)
	if not org.alive or org.hearstop then return end

	--fuckass
end