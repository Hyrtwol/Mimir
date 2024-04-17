package canvas

import "core:math/rand"

@(private)
random_position_int2 :: #force_inline proc(dim: int2, r: ^rand.Rand) -> int2 {
	return {(rand.int31_max(dim.x, r)), (rand.int31_max(dim.y, r))}
}

@(private)
random_position_uint2 :: #force_inline proc(dim: uint2, r: ^rand.Rand) -> int2 {
	return random_position_int2(transmute(int2)dim, r)
}

random_position :: proc {
	random_position_int2,
	random_position_uint2,
}

random_color :: #force_inline proc(r: ^rand.Rand, alpha: u8 = 255) -> byte4 {
	return {u8(rand.int31_max(256, r)), u8(rand.int31_max(256, r)), u8(rand.int31_max(256, r)), alpha}
}
