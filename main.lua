-- Andrew Pratt 2020
-- NPC Mod

#include "npc.lua"


function mod_init()
	npc = Npc("bob");
end

function init()
	local status, err = pcall(mod_init);
	
	if (status == false) then
		DebugPrint("LUA ERROR IN MOD npc IN FUNCTION init: " .. err);
	end
end
	
	
function tick()
end


function mod_update(dt)
	if (npc:IsValid()) then npc:update(dt); end
end

function update(dt)
	local status, err = pcall(mod_update, dt);
	
	if (status == false) then
		--DebugPrint("LUA ERROR IN MOD npc IN FUNCTION update: " .. err);
	end
end


function draw()
end