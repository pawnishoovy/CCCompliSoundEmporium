-- Internal script for terrain detection.

require("MasterTerrainIDList")

function OnCollideWithTerrain(self, terrainID)
	local parent = self:GetParent();
	if IsAHuman(parent) then
		parent:SendMessage("CompliSound_HeadCollisionTerrainID", terrainID);
	end
end