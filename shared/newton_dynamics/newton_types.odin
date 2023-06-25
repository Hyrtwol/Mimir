package newton

USE_LINALG :: #config(RAYLIB_USE_LINALG, true)

import "core:math/linalg"
import _c "core:c"

int :: _c.int
uint :: _c.uint
float :: _c.float

dFloat32 :: f32
dFloat64 :: f64
dFloat   :: dFloat32
dLong    :: i64 // aka _c.longlong

when USE_LINALG {
	// Vector2 type
	Vector2 :: linalg.Vector2f32
	// Vector3 type
	Vector3 :: linalg.Vector3f32
	// Vector4 type
	Vector4 :: linalg.Vector4f32

	// Quaternion type
	Quaternion :: linalg.Quaternionf32

	// Matrix type (OpenGL style 4x4 - right handed, column major)
	Matrix :: linalg.Matrix4x4f32
} else {
	// Vector2 type
	Vector2 :: distinct [2]f32
	// Vector3 type
	Vector3 :: distinct [3]f32
	// Vector4 type
	Vector4 :: distinct [4]f32

	// Quaternion type
	Quaternion :: distinct quaternion128

	// Matrix, 4x4 components, column major, OpenGL style, right handed
	Matrix :: struct {
		m0, m4, m8, m12:  f32, // Matrix first row (4 components)
		m1, m5, m9, m13:  f32, // Matrix second row (4 components)
		m2, m6, m10, m14: f32, // Matrix third row (4 components)
		m3, m7, m11, m15: f32, // Matrix fourth row (4 components)
	}
}
