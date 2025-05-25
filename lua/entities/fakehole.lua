AddCSLuaFile()
-- Defines the Entity's type, base, printable name, and author for shared access (both server and client)
ENT.Type = "anim" -- Sets the Entity type to 'anim', indicating it's an animated Entity.
ENT.Base = "base_gmodentity" -- Specifies that this Entity is based on the 'base_gmodentity', inheriting its functionality.
ENT.PrintName = "fakehole" -- The name that will appear in the spawn menu.
ENT.Author = "YourName" -- The author's name for this Entity.
ENT.Category = "Test entities" -- The category for this Entity in the spawn menu.
ENT.Contact = "STEAM_0:1:12345678" -- The contact details for the author of this Entity.
ENT.Purpose = "To test the creation of entities." -- The purpose of this Entity.
ENT.Spawnable = false -- Specifies whether this Entity can be spawned by players in the spawn menu.
ENT.Material = Material( "models/debug/debugwhite" )
ENT.RenderMesh = nil
-- This is a common technique for ensuring nothing below this line is executed on the Server
if not CLIENT then return end
function ENT:Initialize()
	self:SetModel("models/Combine_Helicopter/helicopter_bomb01.mdl")
    self:SetNoDraw(false)
    --self:SetMaterial("models/debug/debugwhite")
    self.Pos = self:GetPos()
    self.Vel = VectorRand() * 50 -- initial velocity
	self.spawntime = os.clock()
	--self:SetRenderBounds( Vector(0,0,0), Vector(100,5,100) )
	
end

-- Client-side draw function for the Entity
function ENT:Draw()
    self:DrawModel() -- Draws the model of the Entity. This function is called every frame.
end

function ENT:GetRenderMesh()
    return { Mesh = self.RenderMesh, Material = self.Material }
end

function ENT:Think()
    --self:Remove()
end
