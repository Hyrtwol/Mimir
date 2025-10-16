#+vet
package canvas

import "base:intrinsics"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"

_ :: fmt
identity :: linalg.identity
matrix2_rotate_f32 :: linalg.matrix2_rotate_f32
matrix3_rotate_f32 :: linalg.matrix3_rotate_f32
matrix4_rotate_f32 :: linalg.matrix4_rotate_f32

to_float4 :: #force_inline proc "contextless" (v: float3, w: f32 = 1) -> float4 {
	return float4{v.x, v.y, v.z, w}
}

to_float2 :: #force_inline proc "contextless" (v: int2) -> float2 {
	return float2{f32(v.x), f32(v.y)}
}


@(private = "file")
to_float3x3_from_float3x4 :: #force_inline proc "contextless" (m: ^float3x4) -> float3x3 {
	return ((^float3x3)(m))^
}

@(private = "file")
to_float3x3_from_float4x3 :: #force_inline proc "contextless" (m: ^float4x3) -> float3x3 {
	m3x4 := float3x4(m^)
	return to_float3x3_from_float3x4(&m3x4)
}

to_float3x3 :: proc {
	to_float3x3_from_float3x4,
	to_float3x3_from_float4x3,
}


to_int2 :: #force_inline proc "contextless" (v: float2) -> int2 {
	return int2{i32(v.x), i32(v.y)}
}

to_int2_floor :: #force_inline proc "contextless" (v: float2) -> int2 {
	return to_int2(linalg.floor(v))
}

to_int2_ceil :: #force_inline proc "contextless" (v: float2) -> int2 {
	return to_int2(linalg.ceil(v))
}

@(private = "file")
random_position_int2_from_i32 :: #force_inline proc(x, y: i32) -> int2 {
	return {rand.int31_max(x), rand.int31_max(y)}
}

@(private = "file")
random_position_int2_from_u32 :: #force_inline proc(x, y: u32) -> int2 {
	return random_position_int2_from_i32(i32(x), i32(y))
}

@(private = "file")
random_position_int2_from_int2 :: #force_inline proc(dim: int2) -> int2 {
	return random_position_int2_from_i32(dim.x, dim.y)
}

@(private = "file")
random_position_int2_from_uint2 :: #force_inline proc(dim: uint2) -> int2 {
	return random_position_int2_from_u32(dim.x, dim.y)
}

random_position :: proc {
	random_position_int2_from_i32,
	random_position_int2_from_u32,
	random_position_int2_from_int2,
	random_position_int2_from_uint2,
}

random_color_byte :: #force_inline proc() -> u8 {
	return u8(rand.int31_max(256))
}

random_color :: #force_inline proc(alpha: u8 = 255) -> byte4 {
	return {random_color_byte(), random_color_byte(), random_color_byte(), alpha}
}

@(private = "file")
directions: [9]i32 = {1, 0, -1, 0, 1, 1, -1, -1, 1}

//    +---+---+---+
// +1 |   | 3 |   |
//    +---+---+---+
//  0 | 2 |   | 0 |
//    +---+---+---+
// -1 |   | 1 |   |
//    +---+---+---+
//     -1   0  +1
get_direction4 :: #force_inline proc "contextless" (dir: i32) -> int2 {
	return ((^int2)(&directions[dir & 3]))^
}

//    +---+---+---+
// +1 | 7 | 3 | 4 |
//    +---+---+---+
//  0 | 2 |   | 0 |
//    +---+---+---+
// -1 | 6 | 1 | 5 |
//    +---+---+---+
//     -1   0  +1
get_direction8 :: #force_inline proc "contextless" (dir: i32) -> int2 {
	return ((^int2)(&directions[dir & 7]))^
}

get_random_direction4 :: #force_inline proc() -> int2 {
	return get_direction4(rand.int31_max(4))
}

get_random_direction8 :: #force_inline proc() -> int2 {
	return get_direction8(rand.int31_max(8))
}

@(require_results)
matrix4_rotate_x_f32 :: proc "contextless" (angle: f32) -> float4x4 {
	return auto_cast linalg.matrix4_rotate_f32(angle, float3_xunit)
}

@(require_results)
matrix4_rotate_y_f32 :: proc "contextless" (angle: f32) -> float4x4 {
	return auto_cast linalg.matrix4_rotate_f32(angle, float3_yunit)
}

@(require_results)
matrix4_rotate_z_f32 :: proc "contextless" (angle: f32) -> float4x4 {
	return auto_cast linalg.matrix4_rotate_f32(angle, float3_zunit)
}

@(private = "file")
create_viewport_from_xywh :: #force_inline proc "contextless" (x, y, w, h: f32) -> float4x4 {
	return {
		w/2, 0  , 0  , x+w/2,
		0  , h/2, 0  , y+h/2,
		0  , 0  , 1  , 0    ,
		0  , 0  , 0  , 1    ,
	}
}

@(private = "file")
create_viewport_from_size :: #force_inline proc "contextless" (size: int2) -> float4x4 {
	return create_viewport_from_xywh(0, 0, f32(size.x), f32(size.y))
}

create_viewport :: proc {
	create_viewport_from_xywh,
	create_viewport_from_size,
}

/*
mat4 perspective_opengl_rh(
  const float fovy, const float aspect, const float n, const float f)
{
  const float e = 1.0f / std::tan(fovy * 0.5f);
  return {e / aspect, 0.0f,  0.0f,                    0.0f,
          0.0f,       e,     0.0f,                    0.0f,
          0.0f,       0.0f, (f + n) / (n - f),       -1.0f,
          0.0f,       0.0f, (2.0f * f * n) / (n - f), 0.0f};
}

mat4 perspective_directx_rh(
  const float fovy, const float aspect, const float n, const float f)
{
  const float e = 1.0f / std::tan(fovy * 0.5f);
  return {e / aspect, 0.0f,  0.0f,             0.0f,
          0.0f,       e,     0.0f,             0.0f,
          0.0f,       0.0f,  f / (f - n),      1.0f,
          0.0f,       0.0f, (f * n) / (n - f), 0.0f};
}
*/

/*
float fovYRad = DegToRad(fov * 0.5f);
float tanHalfFovy = tanf(fovYRad);
float aspect = width / height;

m[0] = 1.0f / tanHalfFovy;  m[1] = 0.0f;                    m[2] = 0.0f;                                m[3] = 0.0f;
m[4] = 0.0f;                m[5] = aspect / tanHalfFovy;    m[6] = 0.0f;                                m[7] = 0.0f;
m[8] = 0.0f;                m[9] = 0.0f;                    m[10] = zNear / (zFar - zNear);             m[11] = -1.0f;
m[12] = 0.0f;               m[13] = 0.0f;                   m[14] = (zNear * zFar) / (zFar - zNear);    m[15] = 0.0f;
*/

matrix4_perspective_f32 :: linalg.matrix4_perspective_f32

@(require_results)
matrix4_perspective_f32_01 :: proc "contextless" (fovy, aspect, near, far: f32, flip_z_axis := true) -> (m: float4x4) #no_bounds_check {

	tan_half_fovy := math.tan(0.5 * fovy)
	m[0, 0] = 1 / (aspect * tan_half_fovy)
	m[1, 1] = 1 / (tan_half_fovy)
	m[2, 2] = far / (far - near)
	m[3, 2] = +1
	m[2, 3] = -1 * far * near / (far - near)
	if flip_z_axis {m[2] = -m[2]}
	return
}

@(require_results)
perspective_direct3d_lh_dx :: proc "contextless" (fovy, aspect, near, far: f32, flip_z_axis := true) -> (m: float4x4) #no_bounds_check {

	e := 1 / math.tan(0.5 * fovy)
	m = {
		e / aspect, 0.0, 0.0                        , 0.0,
		0.0       , e  , 0.0                        , 0.0,
		0.0       , 0.0, far / (far - near)         , 1.0,
		0.0       , 0.0, (far * near) / (near - far), 0.0,
	}
	return
}

// not working
// reverse_z :: proc(perspective_projection: float4x4) -> float4x4 {
// 	@(static)
// 	m_reverse_z := float4x4{
// 		1.0, 0.0,  0.0, 0.0,
// 		0.0, 1.0,  0.0, 0.0,
// 		0.0, 0.0, -1.0, 0.0,
// 		0.0, 0.0,  1.0, 1.0,
// 	}
//   return perspective_projection * m_reverse_z
// }

// https://www.learnopengles.com/tag/perspective-divide/
perspective_divide :: #force_inline proc "contextless" (v: float4) -> float4 {
	return v / v.w
}

// viewport_transform :: #force_inline proc "contextless" (viewport: ^float4x4, v: float4) -> float4 {
// 	return viewport^ * v
// }

// normalized_device_coordinates
normalized_device_coordinates :: #force_inline proc "contextless" (viewport: ^float4x4, v: float4) -> float4 {
	return viewport^ * (v / v.w)
	//return apply_viewport(viewport, perspective_divide(v))
}

@(require_results)
fract :: proc "contextless" (x: $T) -> T where IS_FLOAT(ELEM_TYPE(T)) {
	f := #force_inline math.floor(x)
	return x - f
}

@(private = "file")
reciprocal_abs_scalar :: #force_inline proc "contextless" (v: float) -> float {
	return (v == 0) ? 1e30 : abs(1 / v)
}

@(private = "file")
reciprocal_abs_vector2 :: #force_inline proc "contextless" (v: float2) -> float2 {
	return float2{reciprocal_abs(v.x), reciprocal_abs(v.y)}
}

reciprocal_abs :: proc {
	reciprocal_abs_scalar,
	reciprocal_abs_vector2,
}
