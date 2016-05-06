

local rs232 = require("luars232")
local e, p = rs232.open("COM9")
local font26,font12,font120
function love.load()
	if p then
		p:set_baud_rate(rs232.RS232_BAUD_115200)
		p:set_data_bits(rs232.RS232_DATA_8)
		p:set_parity(rs232.RS232_PARITY_NONE)
		p:set_stop_bits(rs232.RS232_STOP_1)
		p:set_flow_control(rs232.RS232_FLOW_OFF)
	end
	font26 = love.graphics.newFont( 26 )
	font12 = love.graphics.newFont( 12 )
	font120 = love.graphics.newFont( 120 )
end

function round(num, idp)
  if idp and idp>0 then
    local mult = 10^idp
    return math.floor(num * mult + 0.5) / mult
  end
  return math.floor(num + 0.5)
end

local tab={}
local dot_tab={}
function printTab( tab )
	local x,y=10,62
	local dy=26
	for k,v in ipairs(tab) do
		love.graphics.print(v, x, y+k*dy, 0)
	end
end

function drawDotTab( tab )
	local dy=26
	local x,y=0,0
	love.graphics.setColor( 55, 255, 55, 170 )
	for k,v in ipairs(tab) do
		local x1,y1=100+2*k,(1400-v)/2
		if x>0 then
			love.graphics.line( x,y,x1,y1 )
		end
		x,y=x1,y1
	end
end

local t=0
local data_read=""
local buffer=""
local HBR,HB=0,0

local low={}
local high={}
local lowest=1024
local highest=1024
local flag=false

function isHB()
	if 
		high[2]-low[2]>100 and high[2]-high[3]>100
		then
		return 1
	else
		return 0
	end
end

function hbr_calc(value)
	local ret=0
	if flag==false then
		if value<lowest-10 then
			lowest = value
		elseif value>lowest+10 then
			table.insert(low,1,lowest)
			highest = 0
			while #low>8 do
				table.remove(low)
			end
			flag=true
		end
	else
		if value>highest+10 then
			highest = value
		elseif value<highest-10 then
			table.insert(high,1,highest)
			lowest = 1024
			while #high>8 do
				table.remove(high)
				ret=ret+isHB()
			end
			flag=false
		end
	end
	return ret
end

local hbr_buf=""
function love.draw( dt )
	love.graphics.setColor( 255, 255, 255, 150 )
	love.graphics.setFont(font120)
	love.graphics.print("HBR:"..HBR, 500, 270, 0)
	love.graphics.setFont(font26)
	love.graphics.print("TEST", 10, 10, 0)
	love.graphics.print(t, 10, 36, 0)
	love.graphics.setFont(font12)
	love.graphics.print(hbr_buf, 500, 250, 0)
	printTab(tab)
	drawDotTab(dot_tab)
	-- love.graphics.print(low, 800, 6, 0)
	-- love.graphics.print(high, 800, 36, 0)
end

hbr_tab={}
function calc_weight(tab)
	local sum=0
	for i,v in ipairs(tab) do
		sum=sum+v.n
	end
	avr = sum/#tab
	for i=1,#tab do
		tab[i].p = math.pow(1-math.abs(tab[i].n-avr)/avr,3)
		if tab[i].p<0 or tab[i].p>1 then
			tab[i].p = 0
		end
	end
	return tab
end

function love.update( dt )
	t=t+dt
	if p then
		e, dataread, size = p:read(50,1)
	end
	if size and size>0 then
		buffer=buffer .. dataread
		for v in string.gmatch(buffer,"%w+:%d+,") do
			table.insert(tab, 1, v)
			n = tonumber(string.match(v,"%d+"))
			if hbr_calc(n)>0 then
				table.insert(hbr_tab, 1, {n=t,p=1})
				while #hbr_tab>8 do
					table.remove(hbr_tab)
				end
				hbr_tab = calc_weight(hbr_tab)

				hbr_buf = hbr_tab[1].n .. " x " .. hbr_tab[1].p
				HBR = round( (1-hbr_tab[1].p)*HBR+hbr_tab[1].p*60/hbr_tab[1].n ,1)
				t=0
			end
			table.insert(dot_tab,1,n)
			while #tab>22 do
				table.remove(tab)
			end
			while #dot_tab>650 do
				table.remove(dot_tab)
			end
		end
		a,b = string.find(buffer,",\n")
		while b and b>0 do
			buffer = string.sub(buffer, b)
			a,b = string.find(buffer,",\n")
		end
	end
end
