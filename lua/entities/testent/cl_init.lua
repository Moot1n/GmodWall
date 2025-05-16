AddCSLuaFile()
include("shared.lua")


local render_SetModelLighting = render.SetModelLighting
local render_SetLocalModelLights = render.SetLocalModelLights

-- Client-side draw function for the Entity
function ENT:Draw()
    self:DrawModel() -- Draws the model of the Entity. This function is called every frame.
    -- render.SetMaterial( mat ) -- Apply the material
    -- render.SetColorMaterialIgnoreZ()
    --obj:Draw()
    
end

function ENT:GetRenderMesh()
    --render_SetLocalModelLights()
    --render_SetModelLighting(1, 0.1, 0.1, 0.1)
    --render_SetModelLighting(3, 0.1, 0.1, 0.1)
    --render_SetModelLighting(5, 0.1, 0.1, 0.1)
    return { Mesh = self.RenderMesh, Material = self.Material }
end

