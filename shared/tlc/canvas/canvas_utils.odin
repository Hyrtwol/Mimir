// +vet
package canvas

import "core:intrinsics"
import "core:math/linalg"
import "core:math/rand"

to_float4 :: #force_inline proc "contextless" (v: float3, w: f32 = 1) -> float4 {
	return float4{v.x, v.y, v.z, w}
}

to_float2 :: #force_inline proc "contextless" (v: int2) -> float2 {
	return float2{f32(v.x), f32(v.y)}
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

@(require_results)
create_rng :: #force_inline proc () -> (res: rand.Rand) {
	return rand.create(u64(intrinsics.read_cycle_counter()))
}


@(private)
random_position_int_xy :: #force_inline proc(x, y: i32, r: ^rand.Rand) -> int2 {
	return {rand.int31_max(x, r), rand.int31_max(y, r)}
}

@(private)
random_position_uint_xy :: #force_inline proc(x, y: u32, r: ^rand.Rand) -> int2 {
	return random_position_int_xy(i32(x), i32(y), r)
}

@(private)
random_position_int2 :: #force_inline proc(dim: int2, r: ^rand.Rand) -> int2 {
	return random_position_int_xy(dim.x, dim.y, r)
}

@(private)
random_position_uint2 :: #force_inline proc(dim: uint2, r: ^rand.Rand) -> int2 {
	return random_position_uint_xy(dim.x, dim.y, r)
}

random_position :: proc {
	random_position_int_xy,
	random_position_uint_xy,
	random_position_int2,
	random_position_uint2,
}

random_color_byte :: #force_inline proc(r: ^rand.Rand) -> u8 {
	return u8(rand.int31_max(256, r))
}

random_color :: #force_inline proc(r: ^rand.Rand, alpha: u8 = 255) -> byte4 {
	return {random_color_byte(r), random_color_byte(r), random_color_byte(r), alpha}
}

@(private)
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

@(require_results)
matrix4_rotate_x_f32 :: proc "c" (angle: f32) -> float4x4 {
	return auto_cast linalg.matrix4_rotate(angle, float3{1, 0, 0})
}

@(require_results)
matrix4_rotate_y_f32 :: proc "c" (angle: f32) -> float4x4 {
	return auto_cast linalg.matrix4_rotate(angle, float3{0, 1, 0})
}

@(require_results)
matrix4_rotate_z_f32 :: proc "c" (angle: f32) -> float4x4 {
	return auto_cast linalg.matrix4_rotate(angle, float3{0, 0, 1})
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

mat4 perspective_direct3d_lh(
  const float fovy, const float aspect, const float n, const float f)
{
  const float e = 1.0f / std::tan(fovy * 0.5f);
  return {e / aspect, 0.0f,  0.0f,             0.0f,
          0.0f,       e,     0.0f,             0.0f,
          0.0f,       0.0f,  f / (f - n),      1.0f,
          0.0f,       0.0f, (f * n) / (n - f), 0.0f};
}
*/

// https://www.learnopengles.com/tag/perspective-divide/
perspective_divide ::  #force_inline proc "contextless" (v: float4) -> float4 {
	return v / v.w
}

// normalized_device_coordinates
normalized_device_coordinates ::  #force_inline proc "contextless" (viewport: ^float4x4, v: float4) -> float4 {
	return viewport^ * (v / v.w)
}
