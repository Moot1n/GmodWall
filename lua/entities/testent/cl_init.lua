AddCSLuaFile()
include("shared.lua")


local render_SetModelLighting = render.SetModelLighting
local render_SetLocalModelLights = render.SetLocalModelLights

-- Client-side draw function for the Entity
function ENT:Draw()
    render.SetStencilEnable( true )
    render.ClearStencil()
    render.SetStencilTestMask( 255 )
    render.SetStencilWriteMask( 255 )
    render.SetStencilPassOperation( STENCILOPERATION_KEEP )
    render.SetStencilZFailOperation( STENCILOPERATION_KEEP )
    render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_NEVER )
    render.SetStencilReferenceValue( 9 )
    render.SetStencilFailOperation( STENCILOPERATION_REPLACE )
    for i=1, #self.holeents do
        self.holeents[i]:DrawModel()
    end
    
    render.SetStencilFailOperation( STENCILOPERATION_KEEP )
    render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_NOTEQUAL )
    
    self:DrawModel() -- Draws the model of the Entity. This function is called every frame.
    render.SetStencilEnable( false )
    --for i=1, #self.holeents do
    --    self.holeents_outer[i]:DrawModel()
    --end
    
    --self.holeents:DrawModel()
    --self.holeents:DrawModel()
    -- render.SetMaterial( mat ) -- Apply the material
    -- render.SetColorMaterialIgnoreZ()
    --obj:Draw()
    
end

function ENT:GetRenderMesh()
    render_SetLocalModelLights()
    render_SetModelLighting(1, 0.1, 0.1, 0.1)
    render_SetModelLighting(3, 0.1, 0.1, 0.1)
    render_SetModelLighting(5, 0.1, 0.1, 0.1)
    return { Mesh = self.RenderMesh, Material = self.Material }
end

