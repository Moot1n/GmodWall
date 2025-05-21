ENT.Base = "base_brush"
ENT.Type = "brush"
ENT.PointA = Vector(0,0,0)
ENT.PointB = Vector(16,16,16)
local luabsp = include("luabsp.lua") 
function ENT:Initialize()
    if SERVER then
        self:SetSolid(SOLID_BBOX)
        self:SetCollisionBoundsWS(self.PointA,self.PointB)
        print(self:GetBrushSurfaces())
        local surfaces = self:GetBrushSurfaces()
        for i = 1, #surfaces do
            local verts = surfaces[i]:GetVertices()
            for j=1, #verts do
                print(verts[j])
            end
        end
    end
    if CLIENT then
        print("HKJHKASKJ")
        map = luabsp.LoadMap("gm_proceduraldest")
        print(map)
    end
end

if (SERVER) then
    
    function ENT:StartTouch(entity)
        print("STARTTOUCH")
    end
    function ENT:EndTouch(entity)
        print("ENDTOUCH")
    end
    function ENT:Touch(entity)
        
    end
end

if SERVER then return end
function ENT:Draw()
    self:DrawModel() -- Draws the model of the Entity. This function is called every frame.
end