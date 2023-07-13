package newton

USE_LINALG :: #config(NEWTON_USE_LINALG, false)
USE_GLSL :: #config(NEWTON_USE_USE_GLSL, true)

_NEWTON_USE_DOUBLE :: #config(_NEWTON_USE_DOUBLE, false)

import "core:math/linalg"
import glm "core:math/linalg/glsl"
import _c "core:c"

when _NEWTON_USE_DOUBLE {
	dFloat :: f64
} else {
	dFloat :: f32
}

when USE_LINALG {
	int2 :: distinct [2]i32
	int3 :: distinct [3]i32
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
} else when USE_GLSL {
	int2 :: glm.ivec2
	int3 :: glm.ivec3
	when _NEWTON_USE_DOUBLE {
		float2     :: glm.dvec2
		float3     :: glm.dvec3
		float4     :: glm.dvec4
		quaternion :: glm.dquat
		float4x4   :: glm.dmat4x4
	} else {
		float2     :: glm.vec2
		float3     :: glm.vec3
		float4     :: glm.vec4
		quaternion :: glm.quat
		float4x4   :: glm.mat4x4
	}
} else {
	int2 :: distinct [2]i32
	int3 :: distinct [3]i32
	float2 :: distinct [2]dFloat
	float3 :: distinct [3]dFloat
	float4 :: distinct [4]dFloat
	float4x4 :: distinct matrix[4, 4]dFloat
	when _NEWTON_USE_DOUBLE {
		quaternion :: distinct quaternion256
	} else {
		quaternion :: distinct quaternion128
	}
}
