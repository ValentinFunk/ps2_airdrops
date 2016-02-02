// Entity information.
ENT.Type = "anim"
ENT.Base = "base_anim"


ENT.PrintName = "Airdrop Crate"
ENT.Author = "Kamshak"
ENT.Information = "Crate for Airdrop"
ENT.Category = "Fun + Games"

ENT.Editable = false
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT


function ENT:Initialize( )
	self:SetModel( "models/care_package/care_package_new.mdl" )

	-- Physics stuff
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	-- Init physics only on server, so it doesn't mess up physgun beam
	if ( SERVER ) then
		self:PhysicsInit( SOLID_VPHYSICS )
		-- Wake up our physics object so we don't start asleep
		local phys = self:GetPhysicsObject()
		if ( IsValid( phys ) ) then
			phys:Wake()
		end

		self:SetUseType( SIMPLE_USE )
  end
end
