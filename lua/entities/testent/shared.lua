// Maybe try https://github.com/Bigfoot71/2d-polygon-boolean-lua
// Didn;t work, now try https://github.com/EgoMoose/PolyBool-Lua
AddCSLuaFile()
local new_poly = include("poly.lua") 
local PolyBool = include("PolyBool/pbinit.lua")
local Epsilon = include("PolyBool/Epsilon.lua")
local epsilon = Epsilon()
-- Defines the Entity's type, base, printable name, and author for shared access (both server and client)
ENT.Type = "anim" -- Sets the Entity type to 'anim', indicating it's an animated Entity.
ENT.Base = "base_gmodentity" -- Specifies that this Entity is based on the 'base_gmodentity', inheriting its functionality.
ENT.PrintName = "Test Entity" -- The name that will appear in the spawn menu.
ENT.Author = "YourName" -- The author's name for this Entity.
ENT.Category = "Test entities" -- The category for this Entity in the spawn menu.
ENT.Contact = "STEAM_0:1:12345678" -- The contact details for the author of this Entity.
ENT.Purpose = "To test the creation of entities." -- The purpose of this Entity.
ENT.Spawnable = true -- Specifies whether this Entity can be spawned by players in the spawn menu.
local wall_size = Vector(128,128,0)
ENT.Mins = Vector( -1, -1, -1 )
ENT.Maxs = Vector(  wall_size.x,  16,  wall_size.y )
ENT.mdlScale = 1
ENT.Material = Material( "phoenix_storms/gear" )

function ENT:GetVerts()
    local subject = { regions = {{{0,0}, {wall_size.x,0}, {wall_size.x,wall_size.y}, {0,wall_size.y}}}, inverted = false }
    local clip = { regions = {{{590,590}, {600,590}, {600,610}, {50,610}}},inverted = false }
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

        end
        
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

function ENT:intersectPolygons(subject, clip)
    local startsdtime = os.clock()
    local output = PolyBool.difference(subject,clip)
    local endtisdme = os.clock()
    print("Taken to intersect no geo")
    print((endtisdme-startsdtime)*1000)
    local geoOutput = PolyBool.polygonToGeoJSON(output)
     
    --print("GEOOUTPUT")
    local polygons = geoOutput.coordinates
    
    
    return polygons
end

function ENT:connectPolygonHoles(polygons, p_i, outpol)
    local holes = {}
    for j = 1, #polygons[p_i] do
        region = polygons[p_i][j]
        table.insert(outpol.regions, region)
        table.insert(outpol.reverse, j~=1)
        if j >= 2 then
            table.insert(holes,region)
        end

        --[[ for k = 1, #region do
            local knext = k+1
            if knext > #region then knext = 1 end
            local vector1 = Vector(region[k][1], 0, region[k][2])
            local vector2 = Vector(region[knext][1], 0, region[knext][2])
            --debugoverlay.Line(self:LocalToWorld(vector1), self:LocalToWorld(vector2),2, Color( 0, 255, 0 ))
        end ]]
    end
    local polyconnect = connectHoles2(polygons[p_i][1], holes)
    return polyconnect, holes
end

function ENT:triangulatePolygon(polyconnect, positions)
    local poly = new_poly{}
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

function ENT:trianglePoly(subject, clip)
    
    local starttime = os.clock()
    polygons = self:intersectPolygons(subject, clip)
    local endtime = os.clock()
    print("TIme taken to intersect! (ms)")
    print((endtime-starttime)*1000)
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
    starttime = os.clock()
    local outpol = {regions={}, reverse={}}
    local positions = {}
    for p_i = 1, #polygons do
        -- For each polygon
        
        -- Get hole regions
        self.PolygonHoles = {}
        if not is_outer_region_floating(polygons[p_i][1]) then 
            
            local polyconnect,holes = self:connectPolygonHoles(polygons, p_i, outpol)
            table.insert(self.PolygonHoles, holes)
            self:triangulatePolygon(polyconnect,positions)
        end
    end
    endtime = os.clock()
    print("TIme taken to triangulate! (ms)")
    print((endtime-starttime)*1000)
    return outpol, positions;
end

-- This function helps spread the calculations out over a few frames
function ENT:trianglePolyState(InputState)
    
    local state = InputState.state
    
    if state == 0 then
        
        if #InputState.clips <= 1 then return end
        local subject = self.RenderPoly
        local clip = InputState.clips[1]
        print("STATE = ", state)
        --print("PI ",#clip)
        
        InputState.state = 1
        polygons = self:intersectPolygons(subject, clip)
        InputState.polygons = polygons
        InputState.p_i = 1
        InputState.outpol = {regions={}, reverse={}}
        InputState.positions = {}
        print("tabllelen = ", #InputState.clips)
        table.remove(InputState.clips,1)
        print("tabllelen = ", #InputState.clips)
        return
    end
    if state == 1 then
        print("STATE = ", state)
        InputState.state = 0
        local outpol = InputState.outpol
        local polygons = InputState.polygons
        local positions = InputState.positions
        for p_i = 1, #polygons do
            -- For each polygon
            
            -- Get hole regions
            self.PolygonHoles={}
            if not is_outer_region_floating(polygons[p_i][1]) then 
                
                local polyconnect,holes = self:connectPolygonHoles(polygons, p_i, outpol)
                table.insert(self.PolygonHoles, holes)
                self:triangulatePolygon(polyconnect,positions)
            end
        end
        //self:extrude_apply_mesh(InputState.outpol, InputState.positions)
        InputState.state = 2
        return
    end
    if state == 2 then
        print("STATE = ", state)
        InputState.state = 0
        if SERVER then
            if #InputState.clips > 1 then self.RenderPoly = InputState.outpol return end
        end
        self:extrude_apply_mesh(InputState.outpol, InputState.positions)
    end
end

function is_outer_region_floating(region)
    local floating = true
    for i = 1, #region do
        if region[i][1] == 0 or region[i][1] == wall_size.x or region[i][2] == 0 or region[i][2] == wall_size.y then
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
    local damageAmount = damage:GetBaseDamage()
    if not CLIENT then
        localDamagePos = self:WorldToLocal(damagepos)
        
        --self:PhysicsFromMesh(self.physicsPoly)
        local x = math.floor(localDamagePos.x*1000)
        local z = math.floor(localDamagePos.z*1000)
        local sentHitPos = Vector(x/1000,0,z/1000)
        local holetype = 0
        if localDamagePos.x < 0 || localDamagePos.z < 0 || localDamagePos.z > wall_size.y || localDamagePos.x > wall_size.x then
            return
        end
        local isInHole = false
        for i = 1, #self.PolygonHoles do
            for j=1, #self.PolygonHoles[i] do
                if epsilon.pointInsideRegion({localDamagePos.x,localDamagePos.z}, self.PolygonHoles[i][j]) then
                    isInHole = true 
                end
            end
        end

        if isInHole then return end
        if damage:IsDamageType(DMG_BLAST) then
            if damageAmount <=10 then return end
            if damageAmount > 10 then holetype = 5 end
            if damageAmount > 80 then holetype = 6 end
        elseif damage:IsDamageType(DMG_BUCKSHOT) then
            if damageAmount > 35 then holetype = 3 end
            if damageAmount > 60 then holetype = 4 end
            if damageAmount > 100 then holetype = 5 end
            if damageAmount > 120 then holetype = 6 end
        else
            if damageAmount > 35 then holetype = 1 end
            if damageAmount > 60 then holetype = 2 end
            if damageAmount > 80 then holetype = 3 end
            if damageAmount > 100 then holetype = 4 end
        end
        if holetype == 0 then
            if count_nearby_points(localDamagePos, self.RenderPoly,20,45) then
                holetype =3
            end
        end
        print("DAMAGEDAMAGE")
        print(sentHitPos)
        print(damageAmount)
        self:UpdateMeshHit(sentHitPos,holetype)
        net.Start( "WallHit"..self:EntIndex() )
            net.WriteUInt(holetype, 4)
            net.WriteInt( x,19 )
            net.WriteInt( z,19 )
		net.Broadcast() --Send all the data between now and the last net.Start() to the server.
    end
end

function ENT:PhysicsCollide( colData, collider )
    print("TAKEDAMAGE")
    
    --self.physicshitpos = colData.HitPos
    
end 

function ENT:Initialize()
    --trianglePoly()
    self.tri_calc_state = {state=0,clips={}, polygons={}, p_i=1,outpol = {}, positions={},polyconnect={}}
    self.PolygonHoles = {}
    if not CLIENT then
        util.AddNetworkString( "WallHit"..self:EntIndex() )
        self.physicshitpos = nil
    end
    if CLIENT then 
        
        local WallHitReceived = function( lengthOfMessageReceived, playerWhoSentTheMessageToUs )
		-- Note how we read them all in the same order as they are written:
        local holetype = net.ReadUInt(4)
		local x = net.ReadInt(19) --Read the first part of the message.
        local z = net.ReadInt(19)
        local localDamagePos = Vector(x/1000,0,z/1000)
		-- Now let's print them out with tabs between each one:
        --print("RECIEVED")
		--print(localDamagePos)
        self:UpdateMeshHit(localDamagePos,holetype)
        end
        net.Receive( "WallHit"..self:EntIndex(), WallHitReceived )
	end
    if not CLIENT then
        
        --self:PhysicsInitConvex(GetVerts())
        self:SetModel("models/props_c17/FurnitureCouch002a.mdl") -- Sets the model for the Entity.
        self:PhysicsDestroy()
        self:PhysicsFromMesh( self:GetVertsPhys() )
        self:SetSolid( SOLID_VPHYSICS ) -- Makes the Entity solid, allowing for collisions.
        self:SetMoveType( MOVETYPE_NONE ) -- Sets how the Entity moves, using physics.
        self:EnableCustomCollisions(true)
        self:GetPhysicsObject():EnableMotion(false)
        self:GetPhysicsObject():SetMass(50000)
        self:DrawShadow(false)
    end

    

    local current_polygons = {}
    if CLIENT then
        self:CreateMesh()
        self:EnableCustomCollisions(true)
        self:SetRenderBounds( self.Mins, self.Maxs )
        if self:GetPhysicsObject():IsValid() then
            self:GetPhysicsObject():EnableMotion(false)
            self:GetPhysicsObject():SetMass(50000)  // make sure to call these on client or else when you touch it, you will crash
            self:GetPhysicsObject():SetPos(self:GetPos())
        end
    end
    

	
    
   
	--self:GetPhysicsObject():EnableMotion( false )
end


function ENT:CreateMesh()
    local out_polygon, positions = self:GetVerts()
    self.RenderPoly = out_polygon
    points_outer = calculateOuterPositions(out_polygon)
    self:BuildMeshFromPositions(positions,points_outer)
end

function count_nearby_points(point,polygon,radius,max)
    local regions = polygon.regions
    local count = 0
    local px = point.x
    local py = point.z
    for i=1, #regions do
        for j=1, #regions[i] do
            local px2 = regions[i][j][1]
            local py2 = regions[i][j][2]
            if math.abs(px - px2) < radius && math.abs(py - py2) < radius then
                count=count+1
                if count >= max then return true end
            end
        end
    end
    return false
end

function ENT:UpdateMeshHit(localhitpos,holetype)
    local holesize = 0.8
    local holesizey = 1
    local subject = self.RenderPoly
    local clip = { regions = {{{-5,-5}, {2.5,-6}, {5,-5},{6,0}, {5,5}, {0,6}, {-5,5},{-7,2},{-7,0}}},inverted =false }
    if holetype == 0 then
        
        clip = { regions = {{{-5,-5}, {5,-5},{6,0}, {5,5}, {0,6}, {-5,5},{-7,2}}},inverted =false }
    elseif holetype == 1 then
        holesize = 1
    elseif holetype == 2 then
        holesize = 2
    elseif holetype == 3 then
        holesize = 3
    elseif holetype == 4 then
        holesize = 4
    elseif holetype == 5 then
        holesize = 5
        holesizey = 1.5
    elseif holetype == 6 then
        holesize = 6
        holesizey = 2
    end
    --local clip = { regions = {{{-5,-5}, {5,-5}, {5,5}, {-5,5}}},inverted =false }
    for i = 1, #clip.regions do
        for j = 1, #clip.regions[i] do
            clip.regions[i][j][1] = localhitpos[1] + clip.regions[i][j][1]*holesize
            clip.regions[i][j][2] = localhitpos[3] + clip.regions[i][j][2]*holesize*holesizey
        end
    end
    if SERVER then
        --local out_polygon, positions = self:trianglePoly(subject, clip);
        --self:extrude_apply_mesh(out_polygon, positions)
        table.insert(self.tri_calc_state.clips, clip)
        table.insert(self.tri_calc_state.clips, clip)
    else
        table.insert(self.tri_calc_state.clips, clip)
        table.insert(self.tri_calc_state.clips, clip)
        --local out_polygon, positions = self:trianglePoly(subject, clip);
        --local starttime = os.clock()
        --self:extrude_apply_mesh(out_polygon, positions)
        --print("Extruda Apply mesh time")
        --print((os.clock()-starttime)*1000)
    end
end

function ENT:extrude_apply_mesh(out_polygon, positions)
    self.RenderPoly = out_polygon
    points_outer = calculateOuterPositions(out_polygon)
    if CLIENT then
        self:BuildMeshFromPositions(positions, points_outer)
    end
    local positionsTriangles = {}
    for i = 1, #positions-3, 3 do
        local normVec = Vector(0,0,1)
        table.Add(positionsTriangles, {{pos =positions[i], normal = normVec},{pos=positions[i+1],normal = normVec},{pos=positions[i+2],normal = normVec}})
    end
    self:PhysicsDestroy()
    self:PhysicsFromMesh( positionsTriangles )
    self:SetSolid( SOLID_VPHYSICS ) -- Makes the Entity solid, allowing for collisions.
    self:SetMoveType( MOVETYPE_NONE ) -- Sets how the Entity moves, using physics.
    if #positionsTriangles == 0 then 
        if CLIENT then return end
        self:Remove() 
        return
    end
    self:EnableCustomCollisions(true)
    self:GetPhysicsObject():EnableMotion(false)
    self:GetPhysicsObject():SetMass(50000)
    self:DrawShadow(false)
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function ENT:Think()
    self:NextThink( CurTime())
    if SERVER then
        --print(self:GetPhysicsObject():GetPos())
        --print(self:GetPhysicsObject():IsMotionEnabled())
        if self.physicshitpos ~= nil then
            local damagepos = self.physicshitpos
            localDamagePos = self:WorldToLocal(damagepos)
            
            --self:PhysicsFromMesh(self.physicsPoly)
            local x = math.floor(localDamagePos.x*1000)
            local z = math.floor(localDamagePos.z*1000)
            local sentHitPos = Vector(x/1000,0,z/1000)
            local holetype = 3
            if localDamagePos.x < 0 || localDamagePos.z < 0 || localDamagePos.z > wall_size.y || localDamagePos.x > wall_size.x then
                return
            end
            print("DAMAGEDAMAGE")
            print(sentHitPos)
            print(damageAmount)
            self:UpdateMeshHit(sentHitPos,holetype)
            net.Start( "WallHit"..self:EntIndex() )
                net.WriteUInt(holetype, 4)
                net.WriteInt( x,19 )
                net.WriteInt( z,19 )
            net.Broadcast() --Send all the data between now and the last net.Start() to the server.
            self.physicshitpos = nil
        end
    end
    if CLIENT then
        --if #self.tri_calc_state.clip.regions >= 1 then
            
        --    local out_polygon, positions = self:trianglePoly(self.RenderPoly, self.tri_calc_state.clip);
        --    
        --    self:extrude_apply_mesh(out_polygon, positions)
        --    self.tri_calc_state.clip = {regions={}}
        --end
        self:trianglePolyState(self.tri_calc_state)
    else
        --while #self.tri_calc_state.clips ~=0 do
        --    local out_polygon, positions = self:trianglePoly(self.RenderPoly, self.tri_calc_state.clips[1]);
        --    self:extrude_apply_mesh(out_polygon, positions)
        --    table.remove(self.tri_calc_state.clips,1)
        --end  
        
        self:trianglePolyState(self.tri_calc_state)
        
    end
    
    return true
end


function calculateOuterPositions(out_polygon)
    points_outer = {}
    regions = out_polygon.regions
    reverse = out_polygon.reverse
    for i=1, #regions do
        do_reverse = reverse[i]
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
    print( math.floor(#positions/3)*2+math.floor(#points_outer/3))
    print(self.RenderPoly)
    mesh.Begin(self.RenderMesh, MATERIAL_TRIANGLES, math.floor(#positions/3)*2+math.floor(#points_outer/3))
    local faceNorm = Vector(0,-1,0)
    --faceNorm:Rotate(-self:GetAngles())
    for i = 1, #positions-2,3 do
        
        
        local v0 = positions[i]
        local v1 = positions[i+1]
        local v2 = positions[i+2]

        local tangentS, tangentT = CalculateTangents(v0, v1, v2)
        mesh.Position( v0*self.mdlScale)
        mesh.TexCoord( 0, v0.x/20, v0.z/20)
        --mesh.TexCoord( 0, 0, 0)
        mesh.Normal(Vector(0,-1,0))
        mesh.AdvanceVertex()

        mesh.Position( v1*self.mdlScale)
        mesh.TexCoord( 0, v1.x/20, v1.z/20)
        --mesh.TexCoord( 0, 0, 20)
        mesh.Normal(Vector(0,-1,0))
        mesh.AdvanceVertex()

        mesh.Position( v2*self.mdlScale)
        --mesh.TexCoord( 0, 20, 0)
        mesh.TexCoord( 0, v2.x/20, v2.z/20)
        mesh.Normal(Vector(0,-1,0))
        mesh.AdvanceVertex()

    end


    for i = #positions, 3,-3 do
        local v0 = positions[i]
        local v1 = positions[i-1]
        local v2 = positions[i-2]
        v0.y = 5
        v1.y = 5
        v2.y = 5

        local tangentS, tangentT = CalculateTangents(v0, v1, v2)
        mesh.Position( v0*self.mdlScale)
        mesh.TexCoord( 0, v0.x/20, v0.z/20)
        --mesh.TexCoord( 0, 0, 0)
        mesh.Normal(Vector(0,1,0))
        mesh.AdvanceVertex()

        mesh.Position( v1*self.mdlScale)
        mesh.TexCoord( 0, v1.x/20, v1.z/20)
        --mesh.TexCoord( 0, 0, 20)
        mesh.Normal(Vector(0,1,0))
        mesh.AdvanceVertex()

        mesh.Position( v2*self.mdlScale)
        --mesh.TexCoord( 0, 20, 0)
        mesh.TexCoord( 0, v2.x/20, v2.z/20)
        mesh.Normal(Vector(0,1,0))
        mesh.AdvanceVertex()
    end

    for i = 1, #points_outer-2,3 do
        local v0 = points_outer[i]
        local v1 = points_outer[i+1]
        local v2 = points_outer[i+2]

        mesh.TexCoord( 0, texcoord[1].x,texcoord[1].y)
        mesh.Position( v0*self.mdlScale)
        mesh.Normal(Vector(0,0,1))
        mesh.AdvanceVertex()

        mesh.TexCoord( 0, texcoord[2].x,texcoord[2].y)
        mesh.Position( v1*self.mdlScale)
        mesh.Normal(Vector(0,0,1))
        mesh.AdvanceVertex()

        mesh.TexCoord( 0, texcoord[3].x,texcoord[3].y)
        mesh.Position( v2*self.mdlScale)
        mesh.Normal(Vector(0,0,1))
        mesh.AdvanceVertex()

    end

    mesh.End()
end


function CalculateTangents(v0, v1, v2)
    local edge1 = v1 - v0
    local edge2 = v2 - v0

    local deltaUV1 = Vector(v1.x - v0.x, v1.z - v0.z,0)
    local deltaUV2 = Vector(v2.x - v0.x, v2.z - v0.z,0)

    local r = 1 / (deltaUV1.x * deltaUV2.y - deltaUV1.y * deltaUV2.x)

    local tangent = (edge1 * deltaUV2.y - edge2 * deltaUV1.y) * r
    local bitangent = (edge2 * deltaUV1.x - edge1 * deltaUV2.x) * r

    return tangent:GetNormalized(), bitangent:GetNormalized()
end
