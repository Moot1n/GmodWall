include("shared.lua")




-- Client-side draw function for the Entity
function ENT:Draw()
    self:DrawModel() -- Draws the model of the Entity. This function is called every frame.
    -- render.SetMaterial( mat ) -- Apply the material
    -- render.SetColorMaterialIgnoreZ()
    --obj:Draw()
   
end

function ENT:GetRenderMesh()
    return { Mesh = self.RenderMesh, Material = self.Material }
end

