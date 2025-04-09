local function cross_product(a, b)
   return {
      a[2] * b[3] - a[3] * b[2],
      a[3] * b[1] - a[1] * b[3],
      a[1] * b[2] - a[2] * b[1]
   }
end

local function draw_3d_circle(center_x, center_y, center_z, radius, normal_vector, num_segments)
   -- Default number of segments if not provided
   num_segments = num_segments or 36
   
   -- Normalize the normal vector
   local length = math.sqrt(normal_vector[1]^2 + normal_vector[2]^2 + normal_vector[3]^2)
   local normal = {
       normal_vector[1]/length,
       normal_vector[2]/length,
       normal_vector[3]/length
   }
   
   -- Create two perpendicular vectors in the plane of the circle
   -- First, find a vector not parallel to the normal
   local v1
   if math.abs(normal[1]) < math.abs(normal[2]) and math.abs(normal[1]) < math.abs(normal[3]) then
       v1 = {1, 0, 0}
   elseif math.abs(normal[2]) < math.abs(normal[3]) then
       v1 = {0, 1, 0}
   else
       v1 = {0, 0, 1}
   end
   
   -- Create first basis vector using cross product
   local u = cross_product(normal, v1)
   local u_length = math.sqrt(u[1]^2 + u[2]^2 + u[3]^2)
   u = {
       u[1]/u_length,
       u[2]/u_length,
       u[3]/u_length
   }
   
   -- Create second basis vector using cross product
   local v = cross_product(normal, u)
   
   -- Generate points around the circle
   local angle_step = 2 * math.pi / num_segments
   
   -- Calculate the first point
   local angle = 0
   local x0 = center_x + radius * (u[1] * math.cos(angle) + v[1] * math.sin(angle))
   local y0 = center_y + radius * (u[2] * math.cos(angle) + v[2] * math.sin(angle))
   local z0 = center_z + radius * (u[3] * math.cos(angle) + v[3] * math.sin(angle))
   
   -- Project the 3D circle onto 2D space for drawing
   local x0_2d = client.WorldToScreen(Vector3(x0, y0, z0))
   if not x0_2d then return end
   
   -- Draw the circle segment by segment
   for i = 1, num_segments do
       angle = i * angle_step
       
       -- Calculate the next point on the circle
       local x1 = center_x + radius * (u[1] * math.cos(angle) + v[1] * math.sin(angle))
       local y1 = center_y + radius * (u[2] * math.cos(angle) + v[2] * math.sin(angle))
       local z1 = center_z + radius * (u[3] * math.cos(angle) + v[3] * math.sin(angle))
       
       -- Project to 2D
       local x1_2d = client.WorldToScreen(Vector3(x1, y1, z1))
       if not x1_2d then return end
       
       -- Draw the line segment
       draw.Line(x0_2d[1], x0_2d[2], x1_2d[1], x1_2d[2])
       
       -- Update the previous point
       x0_2d = x1_2d
   end
end

local function Draw()
   draw.Color(255, 255, 255, 255)

   local stickies = entities.FindByClass("CTFGrenadePipebombProjectile")
   for _, sticky in pairs(stickies) do
      local radius = sticky:GetPropFloat("m_DmgRadius")
      local pos = sticky:GetAbsOrigin()
      draw_3d_circle(pos.x, pos.y, pos.z, radius, {0, 0, 1}, 63)
   end
end

callbacks.Register("Draw", Draw)