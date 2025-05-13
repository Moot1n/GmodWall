// Maybe try https://github.com/Bigfoot71/2d-polygon-boolean-lua
// Didn;t work, now try https://github.com/EgoMoose/PolyBool-Lua

local new_poly = include("poly.lua") 
local PolyBool = include("PolyBool/pbinit.lua")

-- Defines the Entity's type, base, printable name, and author for shared access (both server and client)
ENT.Type = "anim" -- Sets the Entity type to 'anim', indicating it's an animated Entity.
ENT.Base = "base_gmodentity" -- Specifies that this Entity is based on the 'base_gmodentity', inheriting its functionality.
ENT.PrintName = "Test Entity" -- The name that will appear in the spawn menu.
ENT.Author = "YourName" -- The author's name for this Entity.
ENT.Category = "Test entities" -- The category for this Entity in the spawn menu.
ENT.Contact = "STEAM_0:1:12345678" -- The contact details for the author of this Entity.
ENT.Purpose = "To test the creation of entities." -- The purpose of this Entity.
ENT.Spawnable = true -- Specifies whether this Entity can be spawned by players in the spawn menu.
ENT.Mins = Vector( 0, 0, 0 )
ENT.Maxs = Vector(  100,  16,  100 )
ENT.mdlScale = 1
ENT.Material = Material( "hunter/myplastic" )
function ENT:GetVerts()
    local subject = { regions = {{{0,0}, {100,0}, {100,100}, {0,100}}}, inverted = false }
    local clip = { regions = {{{90,90}, {100,90}, {100,110}, {90,110}}},inverted = false }
    return self:trianglePoly(subject, clip);
end

function GetVerts2()
    local positions = {
        Vector( -0.5, 0, 0.5 ),
        Vector(  0.5, 0, 0.5 ),
        Vector( -0.5, 0,-0.5 ),

        Vector( -0.5, 0,-0.5 ),
        Vector(  0.5, 0, 0.5 ),
        Vector(  0.5, 0, -0.5 ),
    };
    return positions;
end

-- Bridge Holes
local function connectHoles(outer, holes)
    -- First copy outer to a new polygon
    local copy = {}
    for i=1, #outer do
        local curr_x = outer[i][1]
        local curr_y = outer[i][2]
        table.insert(copy, {curr_x,curr_y})
    end
    for _, hole in ipairs(holes) do
        -- Naive bridge: connect rightmost point of hole to closest outer vertex
        
        local rightmost = hole[1]
        for _, p in ipairs(hole) do
            
            if p[1] > rightmost[1] then rightmost = p end
        end

        local bridgeIndex = 1
        local minDist = math.huge
        for i, p in ipairs(copy) do
            local dx = p[1] - rightmost[1]
            local dy = p[2] - rightmost[2]
            local dist = dx*dx + dy*dy
            
            if dist < minDist and dx > 0 then
                minDist = dist
                bridgeIndex = i+1
                if bridgeIndex > #copy then
                    bridgeIndex = 1
                end
            end
        end
        
        -- Insert bridge and hole into outer polygon
        local bridgePoint = copy[bridgeIndex]
        table.insert(copy, bridgeIndex, rightmost)
        
        for _, p in ipairs(hole) do
            table.insert(copy, bridgeIndex + 1, p)
        end
        local bridgeIndexPrev = #copy 
        if bridgeIndex ~= 1 then 
            bridgeIndexPrev = bridgeIndex-1
        end
        table.insert(copy, bridgeIndex + #hole + 1, copy[bridgeIndexPrev])
        --table.insert(copy, bridgeIndex + #hole + 1, rightmost)
    end
    
    return copy
end

-- Bridge Holes
local function connectHoles2(outer, holes)
    
    -- First copy outer to a new polygon
    local copy = {}
    for i=1, #outer do
        local curr_x = outer[1+#outer-i][1]
        local curr_y = outer[1+#outer-i][2]
        table.insert(copy, {curr_x,curr_y})
    end
    if #holes < 1 then return copy end
    -- Copy holes to new holes
    local h_copy = {}
    for i=1, #holes do
        local hole_copy = {}
        for j=1, #holes[i] do
            local curr_x = holes[i][1+#holes[i]-j][1]
            local curr_y = holes[i][1+#holes[i]-j][2]
            table.insert(hole_copy, {curr_x,curr_y})
        end
        table.insert(h_copy, hole_copy)
    end

    -- Loop over each hole
    local hole_idx = 1
    while #h_copy > 0 do
        -- Find the rightmost hole
        local global_rightmost = h_copy[1][1] -- Global rightmost vertex
        local r_hole_i = 1 -- Rightmost hole index
        for i = 1, #h_copy do
            local hole = h_copy[i]
             -- Find rightmost point of hole
            local rightmost = hole[1]
            for _, p in ipairs(hole) do    
                if p[1] > rightmost[1] or ( p[1] == rightmost[1] and p[2] > rightmost[2]) then rightmost = p end
            end
            if rightmost[1] > global_rightmost[1] or ( rightmost[1] == global_rightmost[1] and rightmost[2] < global_rightmost[2]) then 
                global_rightmost = rightmost 
                r_hole_i = i
            end
        end
        
        -- Check the outer polygon for the leftmost seg to the right of the rightmost hole
        local leftmostseg = nil;
        local leftmostsegidx = 1
        for i = 1, #copy do
            local inext = i+1
            if inext > #copy then inext = 1 end
            p1 = copy[i]
            p2 = copy[inext]
            local seg = {p1,p2}
            -- Check if the hole global rightmost point is to the left of a segment from the 
            -- print("CHECK "..global_rightmost[1].." "..global_rightmost[2])
            -- print("AGAINST ("..seg[1][1]..", "..seg[1][2].."), ("..seg[2][1]..", "..seg[2][2]..")")
            
            if pointLeftOfSeg2(global_rightmost, seg) == true then
                -- print("OK")
                --print(i)
                if leftmostseg == nil  then 
                    leftmostseg = seg 
                    leftmostsegidx = i
                elseif segleftofseg(seg, leftmostseg)  then 
                    leftmostseg = seg 
                    leftmostsegidx = i
                end
            end
        end

        -- Get intersection point of left most line
        local ix, iy = findIntersect(0,global_rightmost[2], 1,global_rightmost[2], leftmostseg[1][1],leftmostseg[1][2],leftmostseg[2][1],leftmostseg[2][2])
        -- Check if any reflex points lie in the triangle
        local reflexpointidx = nil
        local minangle = nil
        for i = 1, #copy do
            -- Is not the vertex we found
            if i~= leftmostsegidx then
            local inext = i+1
            local iprev = i-1
            if inext > #copy then inext = 1 end
            if iprev < 1 then iprev = #copy end
            p0 = copy[iprev]
            p1 = copy[i]
            p2 = copy[inext]
            local cp = crossProduct({p0[1]-p1[1],p0[2]-p1[2]}, {p2[1]-p1[1],p2[2]-p1[2]})
            -- Is a reflex vertex
                if cp > 0 then
                    -- Check if in triangle
                    local tpoint = pointInTriangle(p1[1],p1[2], global_rightmost[1],global_rightmost[2],ix,iy,leftmostseg[1][1],leftmostseg[1][2])
                    if tpoint == true then
                        -- Check if the reflex point inside triangle is minimum angle
                        local cosang = dot(p1[1]-global_rightmost[1],p1[2]-global_rightmost[2],1,0)/normalized(p1[1]-global_rightmost[1],p1[2]-global_rightmost[2])
                        if minangle == nil or cosang > minangle then
                            minangle = cosang
                            reflexpointidx = i
                        end
                    end
                end
            end
        end
        -- Connect the hole to the polygon
        local bridgeIndex = leftmostsegidx
        if reflexpointidx ~= nil then
            bridgeIndex = reflexpointidx
            print("reflexpointidx "..reflexpointidx)
        end
        print("BRIDGEIDX "..bridgeIndex)
        
        local hole = h_copy[r_hole_i]
        local bridgePoint = copy[bridgeIndex]
        --table.insert(copy, bridgeIndex, global_rightmost)
        
        for _, p in ipairs(hole) do
            table.insert(copy, bridgeIndex + 1, p)
        end
        local bridgeIndexNext = 1
        if bridgeIndex ~= #copy  then 
            bridgeIndexNext = bridgeIndex+1
        end
        local bridgeIndexPrev = #copy
        if bridgeIndex ~= 1  then 
            bridgeIndexPrev = bridgeIndex-1
        end
        table.insert(copy, bridgeIndex + #hole + 1, bridgePoint)
        table.insert(copy, bridgeIndex + #hole + 1, copy[bridgeIndexNext])
        
        table.remove(h_copy,r_hole_i)
        --table.insert(copy, bridgeIndex + #hole + 1, rightmost)
        -- Exit the while loop if we're there for too long
        hole_idx = hole_idx +1
        if hole_idx > 1000 then
            print("ASASASAS WTFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF!!!!!")
            break
        end
    end
    return copy
end

function normalized(v1x,v1y)
    return math.sqrt(v1x*v1x+v1y*v1y)
end

function dot(v1x,v1y, v2x,v2y)
    return v1x*v2x+v1y*v2y
end

function pointInTriangle(px, py, x1, y1, x2, y2, x3, y3)
  local ax, ay = x1 - px, y1 - py
  local bx, by = x2 - px, y2 - py
  local cx, cy = x3 - px, y3 - py
  local sab = ax*by - ay*bx < 0
  if sab ~= (bx*cy - by*cx < 0) then
    return false
  end
  return sab == (cx*ay - cy*ax < 0)
end

function findIntersect(l1p1x,l1p1y, l1p2x,l1p2y, l2p1x,l2p1y, l2p2x,l2p2y)
  local a1,b1,a2,b2 = l1p2y-l1p1y, l1p1x-l1p2x, l2p2y-l2p1y, l2p1x-l2p2x
  local c1,c2 = a1*l1p1x+b1*l1p1y, a2*l2p1x+b2*l2p1y
  local det,x,y = a1*b2 - a2*b1
  if det==0 then return l2p1x, l2p1y end
  x,y = (b2*c1-b1*c2)/det, (a1*c2-a2*c1)/det
  return x,y
end


-- Checks if a point is left of segment
-- Returns -1 if seg is above or below point entirely
-- Returns 0 if point right of seg
-- Returns 1 if point left of seg 
function pointLeftOfSeg(pstart, segment)
    -- For interect
    local p1 = segment[1]
    local p2 = segment[2]
    local top = p1
    local bot = p2
    if p2[2] > p1[2] then
        top = p2
        bot = p1
    end

    -- Check if top above and bot below
    if bot[2] > pstart[2] then
        return -1 
    end
    if top[2] < pstart[2] then
        return -1
    end
    
    -- Check if line is to the right of point
    local cp = crossProduct({top[1]-pstart[1],top[2]-pstart[2]}, {bot[1]-pstart[1],bot[2]-pstart[2]})
    -- Point colinear with line
    if cp == 0 then
      if pstart[1] < p1[1] and pstart[1] < p2[1] then return true end
    end
    return cp < 0
    -- 
end

-- Checks if a point is left of segment
-- Returns -1 if seg is above or below point entirely
-- Returns 0 if point right of seg
-- Returns 1 if point left of seg 
-- The #2 version, checks vi below or on and vi+1 above or on
function pointLeftOfSeg2(pstart, segment)
    -- For interect
    local p1 = segment[1]
    local p2 = segment[2]
    -- Return -1 is p1 above line
    if p1[2] > pstart[2] then
        return -1 
    end
    if p2[2] < pstart[2] then
        return -1
    end
    -- Check if top above and bot below
    local top = p1
    local bot = p2
    if p2[2] > p1[2] then
        top = p2
        bot = p1
    end
    -- Check if line is to the right of point
    local cp = crossProduct({top[1]-pstart[1],top[2]-pstart[2]}, {bot[1]-pstart[1],bot[2]-pstart[2]})
    -- Point colinear with line
    if cp == 0 then
      if pstart[1] < p1[1] and pstart[1] < p2[1] then return true end
    end
    return cp < 0
    -- 
end

-- Checks if a seg a is left of seg b
function segleftofseg(sega, segb)
    -- Check if segments share a common point
    local pa = nil
    local pb = nil
    local pcommon = nil
    if pointEqual(sega[1],segb[1]) then
        pcommon = sega[1]
        pa = sega[2]
        pb = segb[2]
    elseif pointEqual(sega[2],segb[1]) then
        pcommon = sega[2]
        pa = sega[1]
        pb = segb[2]
    elseif pointEqual(sega[1],segb[2]) then
        pcommon = sega[1]
        pa = sega[2]
        pb = segb[1]
    elseif pointEqual(sega[2],segb[2]) then
        pcommon = sega[2]
        pa = sega[1]
        pb = segb[1]
    end
    -- If segments share a common point then segment with leftmost point is left
    if pcommon ~= nil then
        --return geom.crossProduct({pa[1]-pcommon[1],pa[2]-pcommon[2]},{pb[1]-pcommon[1],pb[2]-pcommon[2]}) < 0
        if pcommon[2] >= pa[2] then
            return crossProduct({-pa[1]+pcommon[1],-pa[2]+pcommon[2]},{pb[1]-pa[1],pb[2]-pa[2]}) < 0
        else
            return crossProduct({-pa[1]+pcommon[1],-pa[2]+pcommon[2]},{pb[1]-pa[1],pb[2]-pa[2]}) >= 0
        end

        --return pa[1] < pb[1]
    end

    -- If segments do not share a common point then test each point against eachother
    local check = pointLeftOfSeg(sega[1], segb)
    if check ~= -1 then return check end
    check = pointLeftOfSeg(sega[2], segb)
    if check ~= -1 then return check end
    check = pointLeftOfSeg(segb[1], sega)
    if check ~= -1 then return not check end
    check = pointLeftOfSeg(segb[2], sega)
    if check ~= -1 then return not check end

    -- Should never get here
    print("CASE WTF!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    return false
end

-- check if two points are equal
function pointEqual(p1, p2)
    return (p1[1] == p2[1]) and (p1[2] == p2[2])
end

function crossProduct(v1, v2)
    return v1[1] * v2[2] - v1[2]*v2[1]
end

function ENT:trianglePoly(subject, clip)
    
    local output = PolyBool.difference(subject,clip)
    
    local geoOutput = PolyBool.polygonToGeoJSON(output)
    --print("GEOOUTPUT")
    local polygons = geoOutput.coordinates
    

    --[[ print("GEOOUTPUT")
    for i = 1, #sub2 do
        print("Geo Polygon "..i)
        for j = 1, #sub2[i] do
            print("region "..j)
            local subb = sub2[i][j]
           
            for k = 1, #subb do
                local knext = k+1
                if knext > #subb then knext = 1 end
                local vector1 = Vector(subb[k][1], 0, subb[k][2])
                local vector2 = Vector(subb[knext][1], 0, subb[knext][2])
                if j==1 then
                    debugoverlay.Line(self:LocalToWorld(vector1), self:LocalToWorld(vector2),2, Color( 0, 255, 0 ))
                else 
                    debugoverlay.Line(self:LocalToWorld(vector1), self:LocalToWorld(vector2),2, Color( 255, 255, 0 ))
                end
            end
        end
    end ]]

    -- print(#sub2)
    -- Get triangle soup of all polygons
    -- Find all seperate polygons
    -- Connect holes for each part
    -- Triangulate part
    local outpol = {regions={}, reverse={}}
    local positions = {}
    for p_i = 1, #polygons do
        -- For each polygon
        local poly = new_poly{}
        -- Get hole regions
        local holes = {}
        if not is_outer_region_floating(polygons[p_i][1]) then 
            for j = 1, #polygons[p_i] do
                region = polygons[p_i][j]
                table.insert(outpol.regions, region)
                table.insert(outpol.reverse, j~=1)
                if j >= 2 then
                    table.insert(holes,region)
                end

                for k = 1, #region do
                    local knext = k+1
                    if knext > #region then knext = 1 end
                    local vector1 = Vector(region[k][1], 0, region[k][2])
                    local vector2 = Vector(region[knext][1], 0, region[knext][2])
                    debugoverlay.Line(self:LocalToWorld(vector1), self:LocalToWorld(vector2),2, Color( 0, 255, 0 ))
                end
            end

            

            local polyconnect = connectHoles2(polygons[p_i][1], holes)

            for i = 1, #polyconnect do
                local inext = i+1
                if inext > #polyconnect then inext = 1 end
                local vector1 = Vector(polyconnect[i][1], 0, polyconnect[i][2])
                local vector2 = Vector(polyconnect[inext][1], 0, polyconnect[inext][2])
                --debugoverlay.Line(self:LocalToWorld(vector1), self:LocalToWorld(vector2),2, Color( 255, 0, 0 ))
                poly:push_coord(polyconnect[i][1],polyconnect[i][2])
            end
            poly:close()
            local triangles = poly:get_triangles()
            for i = 1, #triangles do
                for j =1, 3 do
                    local i1 = triangles[i][j]
                    local x,y = poly:get_coord(i1)
                    table.insert(positions, Vector(x,0,y))
                end
            end
        end
    end
    return outpol, positions;
end

function is_outer_region_floating(region)
    local floating = true
    for i = 1, #region do
        if region[i][1] == 0 or region[i][1] == 100 or region[i][2] == 0 or region[i][2] == 100 then
            floating = false
        end
    end
    return floating
end

function ENT:GetVertsPhys()
    local out_polygon, positions = self:GetVerts()
    for i = 1, #positions do
        positions[i] = positions[i]*self.mdlScale
    end
    self.PhysicsPoly = out_polygon
    self.RenderPoly = out_polygon
    return positions
end

function ENT:OnTakeDamage(damage)
    local damagepos = damage:GetDamagePosition()
    if not CLIENT then
        print("DAMAGE")
        print(damagepos) 
        self:UpdateMeshHit(self:WorldToLocal(damagepos))
        --self:PhysicsFromMesh(self.physicsPoly)
    end
 end

function ENT:ImpactTrace(trace,dmgtype,customimpactname)
    local damagepos = trace.HitPos
	if CLIENT then
        print(self:WorldToLocal(damagepos))
        self:UpdateMeshHit(self:WorldToLocal(damagepos))
    end
end


function ENT:Initialize()
    --trianglePoly()
    local current_polygons = {}
    if CLIENT then
        self:CreateMesh()
        self:SetRenderBounds( self.Mins, self.Maxs )

        self:DrawShadow( false )
    end
    

	
    
    if not CLIENT then
        --self:PhysicsInitConvex(GetVerts())
        self:SetModel("models/props_c17/FurnitureCouch002a.mdl") -- Sets the model for the Entity.
        self:PhysicsDestroy()
        self:PhysicsFromMesh( self:GetVertsPhys() )
        self:SetSolid( SOLID_VPHYSICS ) -- Makes the Entity solid, allowing for collisions.
        self:SetMoveType( MOVETYPE_NONE ) -- Sets how the Entity moves, using physics.
        self:EnableCustomCollisions()
        self:GetPhysicsObject():EnableMotion(false)
        --self:PhysicsInit( SOLID_VPHYSICS ) -- Initializes physics for the Entity, making it solid and interactable.
       
        
        
        -- Enable custom collisions on the entity
        -- self:PhysicsInitConvex( self:GetVertsPhys())
    end
    if CLIENT then
        self:PhysicsFromMesh( self:GetVertsPhys() )
    end
	--self:GetPhysicsObject():EnableMotion( false )

	
    if not CLIENT then
        local phys = self:GetPhysicsObject() -- Retrieves the physics object of the Entity.
        if phys:IsValid() then -- Checks if the physics object is valid.
            --phys:SetMass(math.sqrt(phys:GetVolume()))
            
            phys:SetMaterial("glass")
            phys:Wake() -- Activates the physics object, making the Entity subject to physics (gravity, collisions, etc.).
        end
    end
end

function ENT:CreateMesh()
    local out_polygon, positions = self:GetVerts()
    self.RenderPoly = out_polygon
    points_outer = calculateOuterPositions(out_polygon)
    self:BuildMeshFromPositions(positions,points_outer)
end

function ENT:UpdateMeshHit(localhitpos)
    local subject = self.RenderPoly
    local clip = { regions = {{{-5,-5}, {2.5,-6}, {5,-5},{6,0}, {5,5}, {0,6}, {-5,5},{-7,2},{-7,0}}},inverted =false }
    --local clip = { regions = {{{-5,-5}, {5,-5}, {5,5}, {-5,5}}},inverted =false }
    for i = 1, #clip.regions do
        for j = 1, #clip.regions[i] do
            clip.regions[i][j][1] = localhitpos[1] + clip.regions[i][j][1]
            clip.regions[i][j][2] = localhitpos[3] + clip.regions[i][j][2]
        end
    end
    local out_polygon, positions = self:trianglePoly(subject, clip);
    self.RenderPoly = out_polygon
    points_outer = calculateOuterPositions(out_polygon)
    if CLIENT then
        self:BuildMeshFromPositions(positions, points_outer)
    end
    self:PhysicsFromMesh( positions )
end

function calculateOuterPositions(out_polygon)
    points_outer = {}
    regions = out_polygon.regions
    reverse = out_polygon.reverse
    for i=1, #regions do
        do_reverse = reverse[i]
        print(do_reverse)
        for j=1, #regions[i] do
            jnext = j+1
            if jnext > #regions[i] then jnext = 1 end
            local p1x = regions[i][j][1]
            local p1y = regions[i][j][2]
            local p2x = regions[i][jnext][1]
            local p2y = regions[i][jnext][2]
            local thick = 5
            
            if do_reverse then
                
                -- Build First Triangle
                table.insert(points_outer, Vector(p1x,0,p1y))
                table.insert(points_outer, Vector(p2x,0,p2y))
                table.insert(points_outer, Vector(p2x,thick,p2y))

                -- Build Second Triangle
                
                table.insert(points_outer, Vector(p1x,thick,p1y))
                table.insert(points_outer, Vector(p1x,0,p1y))
                table.insert(points_outer, Vector(p2x,thick,p2y))
            else
                -- Build First Triangle
                table.insert(points_outer, Vector(p2x,0,p2y))
                table.insert(points_outer, Vector(p1x,0,p1y))
                
                table.insert(points_outer, Vector(p2x,thick,p2y))

                -- Build Second Triangle
                table.insert(points_outer, Vector(p1x,0,p1y))
                table.insert(points_outer, Vector(p1x,thick,p1y))
                
                table.insert(points_outer, Vector(p2x,thick,p2y))
            end
        end
    end
    return points_outer
end

function ENT:BuildMeshFromPositions(positions,points_outer)
    
    --if not CLIENT then
    --self:PhysicsFromMesh(positions)
    --    return
    --end
    --self:PhysicsFromMesh(positions)
    local texcoord  = {
        Vector( 0, 0.2, 0.2 ),
        Vector(  0, 0, 0.2 ),
        Vector( 0, 0,0 ),
    }
    local mesh = mesh
    self.RenderMesh = Mesh(self.Material)
    
    print("SUBJECT")
    print(self.RenderPoly)
    mesh.Begin(self.RenderMesh, MATERIAL_TRIANGLES, math.floor(#positions/3)*2+math.floor(#points_outer/3))
    
    for i = 1, #positions do
        mesh.TexCoord( 0, positions[i].x/10, positions[i].z/10)
        mesh.Position( positions[i]*self.mdlScale)
        mesh.Normal(Vector(0,-1,0))
        mesh.AdvanceVertex()

    end


    for i = #positions, 1,-1 do
        local newPos = positions[i]
        newPos.y = 5
        mesh.TexCoord( 0, positions[i].x/10, positions[i].z/10)
        mesh.Position( newPos*self.mdlScale)
        mesh.Normal(Vector(0,-1,0))
        mesh.AdvanceVertex()
    end

    local j = 1
    for i = 1, #points_outer do
        mesh.TexCoord( 0, texcoord[j].x,texcoord[j].y)
        mesh.Position( points_outer[i]*self.mdlScale)
        --mesh.Normal(Vector(0,0,1))
        mesh.AdvanceVertex()
        j = j+1
        if j > 3 then
            j = 1
        end
    end

    mesh.End()
end
