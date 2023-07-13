package newton

USE_LINALG :: #config(NEWTON_USE_LINALG, true)
_NEWTON_USE_DOUBLE :: #config(_NEWTON_USE_DOUBLE, true)

import glm "core:math/linalg/glsl"
import "core:math/linalg"
import _c "core:c"

when _NEWTON_USE_DOUBLE {
	dFloat :: f64
} else {
	dFloat :: f32
}

//ff::float
//ll::long

int2 :: [2]i32
int3 :: [3]i32

when USE_LINALG {
	when _NEWTON_USE_DOUBLE {
		float2 :: linalg.Vector2f64
		float3 :: linalg.Vector3f64
		float4 :: linalg.Vector4f64
		quaternion :: linalg.Quaternionf64
		float4x4 :: linalg.Matrix4x4f64
	} else {
		float2 :: linalg.Vector2f32
		float3 :: linalg.Vector3f32
		float4 :: linalg.Vector4f32
		quaternion :: linalg.Quaternionf32
		float4x4 :: linalg.Matrix4x4f32
	}
} else {
	float2 :: [2]dFloat
	float3 :: [3]dFloat
	float4 :: [4]dFloat
	quaternion :: quaternion128
	float4x4 :: matrix[4, 4]dFloat

	ivec2 :: glm.ivec2
	ivec3 :: glm.ivec3
	when _NEWTON_USE_DOUBLE {
		vec2 :: glm.vec2
		vec3 :: glm.vec3
		vec4 :: glm.vec4
		quat :: glm.quat
		mat4x4 :: glm.dmat4x4

	} else {
		vec2 :: glm.dvec2
		vec3 :: glm.dvec3
		vec4 :: glm.dvec4
		quat :: glm.dquat
		mat4x4 :: glm.mat4x4
	}
}
