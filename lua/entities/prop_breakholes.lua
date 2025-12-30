AddCSLuaFile()
-- This tells GMod this entity exists
ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "procedural wall spawner"
ENT.Author = "Moot1n"
ENT.Spawnable = false
ENT.AdminSpawnable = false

-- VERY IMPORTANT: name used by Hammer
ENT.ClassName = "prop_breakholes"

ENT.leftcon = 1
ENT.righton = 1
ENT.topcon = 1
ENT.botcon = 1
ENT.texture = ""
ENT.width = 128
ENT.height = 128
ENT.thickness = 4



if SERVER then
    function ENT:KeyValue(key, value)
        //print("key", key, " value", value)
        if key == "leftcon" then
            self.leftcon = value
        elseif key == "rightcon" then
            self.rightcon = value
        elseif key == "topcon" then
            self.topcon = value
        elseif key == "botcon" then
            self.botcon = value
        elseif key == "texture" then
            self.texture = value
        elseif key == "width" then
            self.width = value
        elseif key == "height" then
            self.height = value
        elseif key == "thickness" then
            self.thickness = value
        end
    
    end
end
function ENT:Initialize()
    if SERVER then
        local newent = ents.Create("proceduralwall")
        if not IsValid(newent) then return false end
        if self.leftcon == "1" then newent:SetLeftCon(true) else newent:SetLeftCon(false) end
        if self.rightcon == "1" then newent:SetRightCon(true) else newent:SetRightCon(false) end
        if self.topcon == "1" then newent:SetTopCon(true) else newent:SetTopCon(false) end
        if self.botcon == "1" then newent:SetBotCon(true) else newent:SetBotCon(false) end
        --print(self.leftcon)

        --print()
        newent:SetSize_X(self.width)
        
        newent:SetSize_Y(self.height)
        newent:SetThickness(self.thickness)
        newent:SetPos(self:GetPos())
        newent:SetAngles(self:GetAngles())
        --self:SetModel( "models/props_c17/oildrum001.mdl" )
        
        //cleanup.Add(self:GetOwner, "props", ent)
        local texpath = "procedural/large/plaster1"
        if self.texture == "0" then
            texpath = "procedural/large/plaster1"
        elseif self.texture == "1" then
            texpath = "procedural/large/plaster2"
        elseif self.texture == "2" then
            texpath = "procedural/large/tilefloor"
        elseif self.texture == "3" then
            texpath = "procedural/small/woodcrate"
        elseif self.texture == "4" then
            texpath = "procedural/small/woodfloor"
        elseif self.texture == "5" then
            texpath = "procedural/small/woodfloor2"
        end
        newent:SetMaterial(texpath)
        newent:Spawn()
        self:Remove()
    end
end