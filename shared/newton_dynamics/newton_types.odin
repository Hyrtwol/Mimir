package newton

USE_LINALG :: #config(NEWTON_USE_LINALG, true)
_NEWTON_USE_DOUBLE :: #config(_NEWTON_USE_DOUBLE, true)

import "core:math/linalg"
import _c "core:c"

_short   :: _c.short    // i16
_ushort  :: _c.ushort    // u16
_int     :: _c.int      // i32
_uint    :: _c.uint     // u32
dLong    :: _c.longlong // i64
dFloat32 :: _c.float    // f32
dFloat64 :: _c.double   // f64

when _NEWTON_USE_DOUBLE {
	dFloat :: dFloat64
} else {
	dFloat :: dFloat32
}

int2 :: [2]_int
int3 :: [3]_int

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
}
