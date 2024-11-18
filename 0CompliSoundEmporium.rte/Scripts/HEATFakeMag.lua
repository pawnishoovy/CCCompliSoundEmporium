function OnDetach(self, exParent)
	exParent:SetNumberValue("HEAT_LostFakeMag", 1)
	self.ToDelete = true
end
