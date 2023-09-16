pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
	debug={}
	diag=21 -- board sqare diagonal
	x_sp = 0 -- sprite for x
	o_sp = 2 -- sprite for o
	player_turn = true
	player_sp = {x_sp,o_sp}
	player = 1+flr(rnd(2)) -- decide player 1 or 2 randomly
	if player == 1 then
		ai_player = 2
	else
		ai_player = 1
	end
	selected = { -- state of currently selected cell
		r=0,
		c=0,
		col=7,
		canim = {
			col={1,4,9,15,10,15,9,4},
			speed=2
		}
	}
	sel_anim=cocreate(anim_col)
	objs=new_objs() -- state of all pieces on the board
	--objs:add_obj(x_sp,0,0)
	--objs:add_obj(o_sp,1,1)
	--objs:add_obj(x_sp,2,0)
	
	objs_anim=cocreate(anim_y)
end

function new_objs()
	local o={
		state = {{0,0,0}, -- board state
											{0,0,0},
											{0,0,0}},
		sp = {},
		r = {},
		c = {},
		dy = 0,
		yanim = {
			dy=1,
			speed=15
		},
		
		draw=function(self)
			coresume(objs_anim, self)
			for i=1,#self.sp do
					spr(
						self.sp[i], 
						self.c[i]*diag+diag/7, 
						self.r[i]*diag+diag/7 + self.dy, 
						2, 
						2)
			end
		end,
		
		add_obj=function(self,sp,r,c)
			if self.state[c+1][r+1] != 0 then
				return
			end
			add(self.sp,sp)
			add(self.r,r)
			add(self.c,c)
		end,
		
		update_state=function(self)
			for i,sp in pairs(self.sp) do
				r=self.r[i]
				c=self.c[i]
				if sp == x_sp then
					self.state[c+1][r+1] = 1
				elseif sp == o_sp then
					self.state[c+1][r+1] = 2
				end
			end
		end,
	}
	
	return o
end

function _update()
	objs:update_state()
	if btnp(⬆️) then
		selected.r = max(0, selected.r-1)
	elseif btnp(⬇️) then
		selected.r = min(2,selected.r+1)
	elseif btnp(➡️) then
		selected.c = min(2,selected.c+1)
	elseif btnp(⬅️) then
		selected.c = max(0, selected.c-1)
	elseif btnp(🅾️) then
		if player_turn then
			debug['p']=player
			objs:add_obj(player_sp[player],selected.r,selected.c)
			player_turn = false
		end
	end
	
	if not player_turn then
		result = minmax(
			objs.state,
			ai_player,
			ai_player
		)
		debug['score']=result.score
	end
end

function _draw()
	cls()
	--print(stat(0), 40,90)
	for i,c in pairs(ai_state) do
		for j,r in pairs(ai_state[i]) do
			print(ai_state[i][j], 70+10*i,70+10*j, 5)
		end
	end

	i=0
	for k,v in pairs(debug) do
		print(k.." - "..v,10,70+i*10,7)
		i+=1
	end
	
	draw_grid(12)
	objs:draw()
	
	print(eval_win(objs.state), 80, 10, 8)
end

function draw_grid(col)
	for i=0,2 do
		for j=0,2 do
			rect(
				i*diag,
				j*diag,
				(i+1)*diag,
				(j+1)*diag,
				col)
				--spr(0, i*diag+diag/7, j*diag+diag/7, 2, 2)
		end
	end
	if sel_anim and costatus(sel_anim) != 'dead' then
		coresume(sel_anim)
	end
	rect(
		selected.c*diag,
		selected.r*diag,
		(selected.c+1)*diag,
		(selected.r+1)*diag,
		selected.col)
end

function anim_col()
	local t = 0
	local ai = 0
	while true do
		t = (t+1) % selected.canim.speed
		if t != 0 then
			yield()
		else
			ai = (ai + 1) % #selected.canim.col
			selected.col = selected.canim.col[ai+1]
			yield()
		end
	end
end

function anim_y(obj)
	local t = 0
	local up = true
	while true do
		t = (t + 1) % obj.yanim.speed 
		if t != 0 then
			yield()
		else
				obj.dy += obj.yanim.dy
				obj.yanim.dy = -obj.yanim.dy
		end
	end
end

function contains(arr,el)
	for v in all(arr) do
		if v == el then
			return true
		end
	end
	return false
end
-->8
calls = 0
ai_state = {}

function minmax(
	state, 		 	 -- game state 
	player_id,		-- curr player id
	ai_player,  -- ai player id
	alpha,
	beta
	)
	local alpha = alpha or 10
	local beta = beta or -10
	local scores = {}
	local moves = {}
	
	calls+=1
	debug['player_id']=player_id
	debug['calls']=calls
	
	local score = score_move(state)
	if score != 0 then
		return {
			score=score,
			move=nil
		}
	end
	
	
	m = get_moves(state)
	debug['nmoves']=#m
	for move in all(m) do
		local i = move[1]
		local j = move[2]
		
		new_state = make_move(state, i, j, player_id)
		debug['move']="by "..player_id.." "..i..", "..j
		local move_score = minmax(
			new_state,
			flip_player(player_id),
			ai_player,
			alpha,
			beta
		)
		add(scores,move_score.score)
		add(moves,{i,j})
		
		if player_id == ai_player then
			alpha = max(alpha, move_score.score)
		else
			beta = min(beta, move_score.score)
		end
		
		if beta <= alpha then
			break
		end
	end
	
	local i = nil
	if player_id == ai_player then
		i = imax(scores)
	else
		i = imin(scores)
	end
	
	return {
			score=scores[i],
			move=moves[i]
		}
end

function score_move(state,i, j,player)
	local winner = eval_win(state)
	
	if winner == player then
		return 10
	elseif winner == 0 then
		return 0
	else
		return -10
	end
end

function get_moves(state)
	local moves = {}
	
	for i=1,3 do
		for j=1,3 do
			if state[i][j] == 0 then
				add(moves,{i,j})
			end
		end
	end
	
	return moves
end

function make_move(state, mi, mj, player_id)
	local new_state = {}
	
	for i=1,3 do
		add(new_state, {0,0,0})
		for j=1,3 do
				new_state[i][j] = state[i][j]
		end
	end
	
	new_state[mi][mj]=player_id
	ai_state = new_state
	return new_state
end

function imax(arr)
	local m = -32000 
	for i,v in pairs(arr) do
		if v > m then
			m = m
		end
	end
	return m
end

function imin(arr)
	local m = 32000 
	for i,v in pairs(arr) do
		if v < m then
			m = m
		end
	end
	return m
end

function flip_player(player_id)
	if player_id == 1 then
		return 2
	else
		return 1
	end
end

function eval_win(s)
		-- rows and cols
		for i=1,3 do
			if     s[i][1]~=0
				and			s[i][1]==s[i][2]
				and   s[i][2]==s[i][3] then
				return s[i][1]
			elseif s[1][i]~=0
			 and   s[1][i]==s[2][i]
				and   s[2][i]==s[3][i] then
				return s[1][i]
			end
		end
		-- diags
		if     s[1][1]==s[2][2]
			and   s[2][2]==s[3][3] then
			return s[1][1]
		elseif s[1][3]==s[2][2]
			and			s[2][2]==s[3][1] then
			return s[1][3]
		end 
		
		-- no winner
		return 0
	end
__gfx__
0000000000000000000000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000222221000000000bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000027722221000000bbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000277722222100003bbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0022722222222100033bbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02222222222222100333bbbbbbbb3100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0222222222222210033333bbbb331100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
022222222222221003333333b5111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02221111111122100333333351111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02219999999712100333333351111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0219aaaaaa7791100333333351111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0299aaaaaaaa99100033333351111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0029aaaaaaaa91000003333351111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00012999999210000000553351111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001222222100000000005351100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
