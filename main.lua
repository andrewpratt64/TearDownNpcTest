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


function mod_update()
	if (npc:IsValid()) then npc:update(); end
end

function update()
	local status, err = pcall(mod_update);
	
	if (status == false) then
		--DebugPrint("LUA ERROR IN MOD npc IN FUNCTION update: " .. err);
	end
end


function draw()
end