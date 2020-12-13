-- Andrew Pratt 2020
-- Utility functions


NpcUtil = {}


function NpcUtil.VecToString(vec)
	return "Vec(" .. vec[1] .. ", " .. vec[2] .. ", " .. vec[3] .. ")";
end


function NpcUtil.VecDiff(vecA, vecB)
	return VecLength( VecSub(vecB, vecA) );
end

-- TODO: better/less confusing name for this function
function NpcUtil.VecSwizzleXZ(vec)
	return Vec( vec[1], 0, vec[3] );
end


-- Like QuatLookAt, but only affects yaw rotation
function NpcUtil.QuatLookAtOnYaw(eye, target)
	return QuatLookAt( eye, Vec(target[1], eye[2], target[3]) );
end


function NpcUtil.MakeBodyLookAt(body, target)
	local bodyPos = GetBodyTransform(body).pos;
	SetBodyTransform( body, Transform( bodyPos, QuatLookAt(bodyPos, target) ) );
end

function NpcUtil.MakeBodyLookAtOnYaw(body, target)
	local bodyPos = GetBodyTransform(body).pos;
	SetBodyTransform( body, Transform( bodyPos, QuatLookAtOnYaw(bodyPos, target) ) );
end

function NpcUtil.AddBodyVelocity(body, addVec)
	SetBodyVelocity( body, VecAdd( GetBodyVelocity(body), addVec ) );
end