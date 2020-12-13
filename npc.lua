-- Andrew Pratt 2020
-- Npc class

-- IMPORTANT NOTE TO SELF: Methods like GetBodyTransform return copies of the tabels, not references to the original

#include "npc_util.lua"

Npc = {};
Npc.__index = Npc;

setmetatable(Npc, {
	__call = function(cls, ...) return cls.new(...); end
});

--	=CONSTRUCTOR=
function Npc.new(name)
	local self = setmetatable({}, Npc);
	
	-- Init name
	self.name = name;
	
	-- Init npc body
	self.body = FindBody("npc_" .. self.name, true);
	if (IsHandleValid(self.body) == false) then
		DebugPrint("WARNING: Could not find npc <body> named \"" .. name .. '\"' );
	end
	
	-- Init shapes
	--self.shapes = GetBodyShapes(self.body);
	
	-- Init head body
	self.headBody = FindBody("npc_head_" .. self.name, true);
	
	-- Init head shape
	--self.headShape = nil;
	--for _, shape in pairs(self.shapes) do
	--	if (HasTag(shape, "npc_head_" .. name )) then
	--		self.headShape = shape;
	--	end
	--end
	--
	--if (self.headShape == nil) then
	--	DebugPrint("WARNING: Could not find head shape for npc named \"" .. name .. '\"' );
	--end
	
	-- Init eye position
	self.eyepos = FindLocation("npc_eyepos_" .. name, true); -- Position of eyes relative to head
	if (IsHandleValid(self.eyepos) == false) then
		DebugPrint("WARNING: Could not find eyepos for npc named \"" .. name .. '\"' );
	end
	
	return self;
end


--	=GETS/SETS=
function Npc:GetName()
	return self.name;
end
--function Npc:SetName(name)
--	self.name = name;
--	return self;
--end


function Npc:GetPos()
	return GetBodyTransform(self.body).pos;
end
function Npc:SetPos(pos)
	self:SetTransform( Transform( pos, self:GetRot() ) );
end
function Npc:AddPos(pos)
	self:SetPos( VecAdd( self:GetPos(), pos ) );
end


function Npc:GetRot()
	return GetBodyTransform(self.body).rot;
end
function Npc:SetRot(rot)
	self:SetTransform( Transform( self:GetPos(), rot ) );
end
function Npc:AddRot(rot)
	self:SetRot( QuatRotateQuat( self:GetRot(), rot ) );
end


function Npc:GetBody()
	return self.body;
end


function Npc:GetTransform()
	return GetBodyTransform(self.body);
end
function Npc:SetTransform(t)
	-- Get body transform before mutation
	local preBodyT = GetBodyTransform(self.body);
	
	-- Get head body transform local to the npc body
	local headBodyLocalT = TransformToLocalTransform( preBodyT, GetBodyTransform(self.headBody) );
	
	-- Mutate npc body
	SetBodyTransform(self.body, t);
	-- Mutate head
	SetBodyTransform( self.headBody, TransformToParentTransform( GetBodyTransform(self.body), headBodyLocalT ) );
end


function Npc:GetEyeWorldPos()
	--return VecAdd( GetLocationTransform(self.eyepos).pos, GetShapeWorldTransform(self.headShape).pos );
	return VecAdd( GetLocationTransform(self.eyepos).pos, GetBodyTransform(self.body).pos );
end



--	=PREDICATES=
function Npc:IsValid()
	return IsHandleValid(self.body);
end



--	=METHODS=
function Npc:FacePos(target)
	-- Rotate the entire body's yaw to face target
	self:RotateYawToFacePos(target);
	-- Rotate head to face target
	self:FaceHeadTowardsPos(target);
end

function Npc:RotateYawToFacePos(target)
	--SetBodyTransform( self.body, Transform( GetBodyTransform(self.body).pos, NpcUtil.QuatLookAtOnYaw( GetBodyTransform(self.body).pos, target ) ) );
	self:SetRot( NpcUtil.QuatLookAtOnYaw( GetBodyTransform(self.body).pos, target ) );
end

function Npc:FaceHeadTowardsPos(target)
	local headPos = GetBodyTransform(self.headBody).pos;
	SetBodyTransform( self.headBody, Transform( headPos, QuatLookAt( headPos, target ) ) );
end


function Npc:update()
	-- Face the player
	self:FacePos(GetCameraTransform().pos);
end