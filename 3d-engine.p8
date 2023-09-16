pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
	cube = new_cube(7)
	cam = new_camera(0,0,0)
	cam:look_at(0,0,1)
	y=0
	x=0
	pitch,yaw=0,2.4
	speed=0.05
end

function _update()
	cam:look_at(x,y,1)
	
	local r = rmat(pitch,yaw)	
	local t = {0,0,3,0}
	tobj = transform_obj(
		cube,
		cam,
		r,
		t
	)
	
	pitch = (pitch + 0.01) % 3.1417
	--yaw = (yaw + 0.01) % 3.1417

	if btn(⬅️) then
		x+=speed
	elseif btn(➡️) then
		x-=speed
	elseif btn(⬆️) then
		y+=speed
	elseif btn(⬇️) then
		y-=speed
	end
end

function _draw()
	cls()
	--debug_obj(tsquare)
	draw_obj(tobj)
end
-->8
function dotp(v1,v2)
	return v1[1]*v2[1]+v1[2]*v2[2]+v1[3]+v2[3]
end

function matmul_v(m,v)
	if #m == 4 and #m[1]==4 then
		return {
			v[1]*m[1][1]+v[2]*m[1][2]+v[3]*m[1][3]+m[1][4],
			v[1]*m[2][1]+v[2]*m[2][2]+v[3]*m[2][3]+m[2][4],
			v[1]*m[3][1]+v[2]*m[3][2]+v[3]*m[3][3]+m[3][4],
			v[1]*m[4][1]+v[2]*m[4][2]+v[3]*m[4][3]+m[4][4],
		}
	elseif #m == 3 and #m[1]==3 then
		return {
			v[1]*m[1][1]+v[2]*m[1][2]+v[3]*m[1][3],
			v[1]*m[2][1]+v[2]*m[2][2]+v[3]*m[2][3],
			v[1]*m[3][1]+v[2]*m[3][2]+v[3]*m[3][3]	
		}
	end
end

function vlen(v)
	return sqrt(v[1]*v[1]+v[2]*v[2]+v[3]*v[3])
end

function vadd(v1,v2)
	local r={
			{v1[1]+v2[1]},
			{v1[2]+v2[2]},
			{v1[3]+v2[3]}
	}
	if #v1==4 or #v2==4 then
		add(r,{v1[4]+v2[4]})
	end
	return r
end

function norm(v)
	local l = vlen(v)
	return l == 0 and {0,0,0} or 
		{v[1]/l,v[2]/l,v[3]/l}
end

function cross(v1,v2)
	return {
		v1[2]*v2[3]-v1[3]*v2[2],
		v1[3]*v2[1]-v1[1]*v2[3],
		v1[1]*v2[2]-v1[2]*v2[1],
	}
end

function vsub(v1,v2)
	return {
		v1[1]-v2[1],
		v1[2]-v2[2],
		v1[3]-v2[3]
	}
end

function matmul(matrix1, matrix2)
    local result = {}

    local a11, a12, a13 = matrix1[1][1], matrix1[1][2], matrix1[1][3]
    local a21, a22, a23 = matrix1[2][1], matrix1[2][2], matrix1[2][3]
    local a31, a32, a33 = matrix1[3][1], matrix1[3][2], matrix1[3][3]

    local b11, b12, b13 = matrix2[1][1], matrix2[1][2], matrix2[1][3]
    local b21, b22, b23 = matrix2[2][1], matrix2[2][2], matrix2[2][3]
    local b31, b32, b33 = matrix2[3][1], matrix2[3][2], matrix2[3][3]

    result[1] = {
        a11 * b11 + a12 * b21 + a13 * b31,
        a11 * b12 + a12 * b22 + a13 * b32,
        a11 * b13 + a12 * b23 + a13 * b33
    }

    result[2] = {
        a21 * b11 + a22 * b21 + a23 * b31,
        a21 * b12 + a22 * b22 + a23 * b32,
        a21 * b13 + a22 * b23 + a23 * b33
    }

    result[3] = {
        a31 * b11 + a32 * b21 + a33 * b31,
        a31 * b12 + a32 * b22 + a33 * b32,
        a31 * b13 + a32 * b23 + a33 * b33
    }

    return result
end

-->8
function new_camera(x,y,z)
	return {
		target={-1,-1,-1},
		pitch=-1,
		yaw=-1,
		pos={x,y,z},
		forward=function(self)
			return norm(
				vsub(self.target,self.pos)
			)
		end,
		right=function(self,up,fwd)
			return norm(
				cross(up,fwd)
			)
		end,
		up=function(self,fwd,right)
			return cross(fwd,right)
		end,
		
		look_at=function(self,x,y,z)
			--if x == self.target[1] or y == self.target[2] or z == self.target[3] then
			--	return self.vm
			--end
			
			self.target={x,y,z}
			local f=self:forward()
			local r=self:right({0,1,0},f)
			local u=self:up(f,r)
			
			self.vm={
				{r[1],r[2],r[3],0},
				{u[1],u[2],u[3],0},
				{-f[1],-f[2],-f[3],0},
				{0,0,0,1}
			}
			return self.vm
		end
	}
end

-- euler rotation matrix with pitch and yaw
function rmat(p,y)
	local a,b=y,p
	
	return {
        {cos(a) * cos(b), -sin(a) * cos(b), sin(b)},
        {sin(a), cos(a), 0},
        {-cos(a) * sin(b), sin(a) * sin(b), cos(b)},
    }
end

-- project polygon to screen
function screen_proj(p)
	local m = 127/2
	return {
		abs(p[3])<=-0.1 and 0 or -m*(p[1]/p[3])+m,
		abs(p[3])<=-0.1 and 0 or -m*(p[2]/p[3])+m,
	}
end

function draw_poly(p,c)
	local p1=screen_proj(p.v[1])
	local p2=screen_proj(p.v[2])
	local p3=screen_proj(p.v[3])

	line(p1[1],p1[2],p2[1],p2[2],c)
	line(p2[1],p2[2],p3[1],p3[2],c)
	line(p3[1],p3[2],p1[1],p1[2],c)
end

function draw_obj(o)
	for poly in all(o) do
		draw_poly(poly,poly.c)
	end
end

function transform_obj(
	obj,cam,rot,trans
)
	local res = {}
	
	for poly in all(obj) do
		local tp = {v={},c=poly.c}
		for pv in all(poly.v) do
			local vtx = pv
			if rot ~= nil then
				vtx = matmul_v(rot,vtx)
			end
			
			if trans ~= nil then
				vtx = vsub(vtx,trans)
			end
			
			vtx = matmul_v(
				cam.vm,vtx
			)
			
			add(tp.v,
				vtx
			)
		end
		add(res,tp)
	end
	
	return res
end
-->8
-- https://github.com/morgan3d/misc/blob/master/p8sort/sort.p8
function ce_heap_sort(data)
 local n = #data

 -- form a max heap
 for i = flr(n / 2) + 1, 1, -1 do
  -- m is the index of the max child
  local parent, value, m = i, data[i], i + i
  local key = value.key 
  
  while m <= n do
   -- find the max child
   if ((m < n) and (data[m + 1].key > data[m].key)) m += 1
   local mval = data[m]
   if (key > mval.key) break
   data[parent] = mval
   parent = m
   m += m
  end
  data[parent] = value
 end 

 -- read out the values,
 -- restoring the heap property
 -- after each step
 for i = n, 2, -1 do
  -- swap root with last
  local value = data[i]
  data[i], data[1] = data[1], value

  -- restore the heap
  local parent, terminate, m = 1, i - 1, 2
  local key = value.key 
  
  while m <= terminate do
   local mval = data[m]
   local mkey = mval.key
   if (m < terminate) and (data[m + 1].key > mkey) then
    m += 1
    mval = data[m]
    mkey = mval.key
   end
   if (key > mkey) break
   data[parent] = mval
   parent = m
   m += m
  end  
  
  data[parent] = value
 end
end
-->8
function debug_mt(mt)
	for r in all(mt) do
		local s=''
		s=s..'|'
		for c in all(r) do
			s=s..c..','
		end
		print(s)
	end
end

function debug_obj(o)
	for p in all(o) do
		print('--')
		for v in all(p.v) do
			print(v[1]..','..v[2]..','..v[3])
		end
	end
end
-->8
function new_cube(c)
	local vtx = {
		{0,0,0},
		{-1,-1,0},
		{-1,0,0},
		{0,-1,0},
		
		{0,0,-1},
		{-1,-1,-1},
		{-1,0,-1},
		{0,-1,-1},
	}
	
	local pol = {
		{1,2,4}, --front
		{1,2,3},
		
		{5,6,8}, --back
		{5,6,7},
		
		{1,4,5}, --left
		{4,8,5},
		
		{2,3,7},	--right
		{2,6,7},
		
		{2,4,6}, --top
		{6,8,4},
		
		{3,1,7},
		{7,5,1}, -- bottom
	}
	
	local obj = {}
	for p in all(pol) do
		local opol = {c=c,v={}}
		for v in all(p) do
			add(opol.v,vtx[v])
		end
		add(obj,opol)
	end
	
	return obj
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
