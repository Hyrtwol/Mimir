// +vet
package canvas

import "core:math/rand"
import lg "core:math/linalg"

to_float4 :: #force_inline proc "contextless" (v: float3, w: f32 = 1) -> float4 {
	return float4{v.x, v.y, v.z, w}
}

to_int2 :: #force_inline proc "contextless" (v: float2) -> int2 {
	return int2{i32(v.x), i32(v.y)}
}

to_int2_floor :: #force_inline proc "contextless" (v: float2) -> int2 {
	return to_int2(lg.floor(v))
}

to_int2_ceil :: #force_inline proc "contextless" (v: float2) -> int2 {
	return to_int2(lg.ceil(v))
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

random_color :: #force_inline proc(r: ^rand.Rand, alpha: u8 = 255) -> byte4 {
	return {u8(rand.int31_max(256, r)), u8(rand.int31_max(256, r)), u8(rand.int31_max(256, r)), alpha}
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
