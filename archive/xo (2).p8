pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- tic-tac-toe
function _init()
	debug_flag=true
	debug={}
	game_over=false
	gwinner=nil
	translate_grid = {
		x = 35,
		y = 30
	}
	diag=21 -- board sqare diagonal
	x_sp = 0 -- sprite for x
	o_sp = 2 -- sprite for o
	player_sp = {x_sp,o_sp}
	player = 1+flr(rnd(2)) -- decide player 1 or 2 randomly
	if player == 1 then
		ai_player = 2
		player_turn = true
	else
		ai_player = 1
		player_turn = false
	end
	selected = { -- state of currently selected cell
		r=1,
		c=1,
		col=7,
		canim = {
			col={1,4,9,15,10,15,9,4},
			speed=2
		}
	}
	sel_anim=cocreate(anim_col)
	objs=new_objs() -- state of all pieces on the board
	
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
						self.c[i]*diag+diag/7 +
							translate_grid.x, 
						self.r[i]*diag+diag/7 +
							self.dy +
							translate_grid.y, 
						2, 
						2)
			end
		end,
		
		add_obj=function(self,sp,r,c)
			if self.state[r+1][c+1] != 0 then
				debug['off']='t r='..r..' c='..c
				return false
			else
				debug['off']='f'
			end
			add(self.sp,sp)
			add(self.r,r)
			add(self.c,c)
			self:update_state()
			return true
		end,
		
		update_state=function(self)
			for i,sp in pairs(self.sp) do
				r=self.r[i]
				c=self.c[i]
				if sp == x_sp then
					self.state[r+1][c+1] = 1
				elseif sp == o_sp then
					self.state[r+1][c+1] = 2
				end
			end
		end,
	}
	
	return o
end

function _update()
	objs:update_state()
	if btnp(⬆️) then
		sfx(0)
		selected.r = max(0, selected.r-1)
	elseif btnp(⬇️) then
		sfx(0)
		selected.r = min(2,selected.r+1)
	elseif btnp(➡️) then
		sfx(0)
		selected.c = min(2,selected.c+1)
	elseif btnp(⬅️) then
		sfx(0)
		selected.c = max(0, selected.c-1)
	elseif btnp(🅾️) then
		-- player turn
		local res = objs:add_obj(
				player_sp[player],
				selected.r,
				selected.c
		)
		
		if not res then return end
		sfx(1)
		
		-- ai turn
		local result = minmax(
			objs.state,
			ai_player
		)
		
		--if result == 'err' then
		--	run()
		--end
		
		if result.winner != 0 then
			game_over = true
			gwinner = result.winner
			return
		end
		debug['am']=result.move[1]..','..result.move[2]
		
		local err = objs:add_obj(
			player_sp[ai_player],
			max(0,result.move[1]-1),
			max(0,result.move[2]-1)
	 )		
	 --if err then
	 --	run()
	 --end
	elseif btnp(❎) then
		if game_over then
				run()
		end
	end
end

function _draw()
	cls()
	
	if game_over then
		if gwinner == player then
			print('you win!',50,64,10)
		else
			print('you loose',50,64,8)
		end
		print('press ❎ to play again',25,80,6)
		return
	end
	
	draw_grid(12)
	draw_hud()
	objs:draw()
	
	if debug_flag==true then
		draw_debug()
	end
end

function draw_debug()
	for i,c in pairs(ai_state) do
		for j,r in pairs(ai_state[i]) do
			print(ai_state[i][j], 70+10*j,70+10*i, 5)
			print(objs.state[i][j], 70+10*j,10+10*i, 5)		
		end
	end
	
	i=0
	for k,v in pairs(debug) do
		print(k.." - "..v,0,i*10,7)
		i+=1
	end
	
	print(eval_win(objs.state), 80, 10, 8)	
end

function draw_grid(col)
	for i=0,2 do
		for j=0,2 do
			rect(
				i*diag+translate_grid.x,
				j*diag+translate_grid.y,
				(i+1)*diag+translate_grid.x,
				(j+1)*diag+translate_grid.y,
				col)
		end
	end
	if sel_anim and costatus(sel_anim) != 'dead' then
		coresume(sel_anim)
	end
	rect(
		selected.c*diag+translate_grid.x,
		selected.r*diag+translate_grid.y,
		(selected.c+1)*diag+translate_grid.x,
		(selected.r+1)*diag+translate_grid.y,
		selected.col)
end

function draw_hud()
	local sp = nil
	if player == 1 then
		sp = 32
	else
		sp = 33
	end
	
	print('player',50,12)
	spr(
		sp,
		75,
		10,
		1,
		1
	)
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
ai_state = {}

function str_arr(arr)
	r = ''
	for i in all(arr) do
		r = r..','..i
	end
	return r
end

function minmax(
	state, 		 	 -- game state 
	player_id,		-- curr player id
	alpha,
	beta,
	depth
	)
	local alpha = alpha or -32768
	local beta = beta or 32767
	local depth = depth or 0
	
	local best_score = -32768
	local best_move = {-1, -1}
	local best_winner = -1
	
	local cur_winner = eval_win(
	state
	)
	
	if cur_winner != 0 
		or depth == 5 
		or is_board_full(state) then
		local cur_score = eval_score(
			state,depth
		)
		return {
			score=cur_score,
			winner=cur_winner,
	 	move={-10,-1}
		}
	end
	
	local m = get_moves(state)

	for move in all(m) do
		local i = move[1]
		local j = move[2]
		state[i][j] = player_id
		
		local move_score = minmax(
			state,
			3-player_id, --flip
			alpha,
			beta,
			depth+1
		)
		
		if move_score.score > best_score then
			best_score = move_score.score
			best_move = move
			best_winner = move_score.winner
		end
		
		state[i][j] = 0
		
		if player_id == ai_player then
			alpha = max(
				alpha, 
				move_score.score)
			if alpha >= beta then
				return {
					score=best_score,
					move=best_move,
					winner=best_winner
				}
			end
		else
			beta = min(
				beta, 
				move_score.score)
				if beta <= alpha then
					return {
						score=best_score,
						move=best_move,
						winner=best_winner
					}
				end
		end
	end
end

function get_moves(s)
	local moves = {}
	for i=1,3 do
		for j=1,3 do
			if s[i][j] == 0 then
				add(moves,{i,j})
			end
		end
	end
	moves=shuffle(moves)
	return moves
end

function eval_score(state, depth)
	local winner = eval_win(state)
	if winner == ai_player then
		return 10
	elseif winner == player then
		return -10
	--elseif is_board_full(state) then
	--	return 0
	else
		return 0
	end
	
	local score = 0
	for i=1,3 do
		for j=1,3 do
			if state[i][j] == ai_player then
				score += 1
			elseif state[i][j] == player then
				score -= 1
			end
		end
	end
	return score
end

function is_board_full(s)
	local full = true
	for i=1,#s do
		for j=1,#s[i] do
			if s[i][j] == 0 then
				full = false
			end
		end
	end
	
	return full
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
-->8
function shuffle(t)
    for n=1,#t*2 do -- #t*2 times seems enough
        local a,b=flr(1+rnd(#t)),flr(1+rnd(#t))
        t[a],t[b]=t[b],t[a]
    end
    return t
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
01222210000bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
127222210bbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222203bbbbb10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222033bbb110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
29999992033351110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99aaaa99033351110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19aaaa91003351100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01299210000351000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0801000004701067010a7010c7120e7121071210713107100f7101070010700017000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000100000065000650006400062000620006100060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
