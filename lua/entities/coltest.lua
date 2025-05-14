AddCSLuaFile()

-- Defines the Entity's type, base, printable name, and author for shared access (both server and client)
ENT.Type = "anim" -- Sets the Entity type to 'anim', indicating it's an animated Entity.
ENT.Base = "base_gmodentity" -- Specifies that this Entity is based on the 'base_gmodentity', inheriting its functionality.
ENT.PrintName = "Coltest" -- The name that will appear in the spawn menu.
ENT.Author = "YourName" -- The author's name for this Entity.
ENT.Category = "Test entities" -- The category for this Entity in the spawn menu.
ENT.Contact = "STEAM_0:1:12345678" -- The contact details for the author of this Entity.
ENT.Purpose = "To test the creation of entities." -- The purpose of this Entity.
ENT.Spawnable = true -- Specifies whether this Entity can be spawned by players in the spawn menu.

-- This will be called on both the Client and Server realms
function ENT:Initialize()
	-- Ensure code for the Server realm does not accidentally run on the Client
	if SERVER then
	    self:SetModel("models/props_c17/FurnitureCouch002a.mdl")
		--self:BuildCollision()
		--self:PhysicsInit( SOLID_VPHYSICS )
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		
		self:EnableCustomCollisions(true)
		self:GetPhysicsObject():EnableMotion(false)
		self:GetPhysicsObject():SetMass(50000)  // max weight, should help a bit with the physics solver
		self:DrawShadow(false)
	    local phys = self:GetPhysicsObject() -- Retrieves the physics object of the Entity.
	    if phys:IsValid() then -- Checks if the physics object is valid.
	        phys:Wake() -- Activates the physics object, making the Entity subject to physics (gravity, collisions, etc.).
	    end
	end
	if CLIENT then
		if self:GetPhysicsObject():IsValid() then
        self:GetPhysicsObject():EnableMotion(false)
        self:GetPhysicsObject():SetMass(50000)  // make sure to call these on client or else when you touch it, you will crash
        self:GetPhysicsObject():SetPos(self:GetPos())
    end

	end
end

-- This is a common technique for ensuring nothing below this line is executed on the Server
if not CLIENT then return end

-- Client-side draw function for the Entity
function ENT:Draw()
    self:DrawModel() -- Draws the model of the Entity. This function is called every frame.
end