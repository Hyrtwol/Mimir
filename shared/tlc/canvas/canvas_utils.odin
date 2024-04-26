package canvas

import "core:math/rand"

@(private)
random_position_uint2 :: #force_inline proc(dim: uint2, r: ^rand.Rand) -> int2 {
	return {(rand.int31_max(i32(dim.x), r)), (rand.int31_max(i32(dim.y), r))}
}

@(private)
random_position_int2 :: #force_inline proc(dim: int2, r: ^rand.Rand) -> int2 {
	return random_position_uint2(transmute(uint2)dim, r)
}

random_position :: proc {
	random_position_uint2,
	random_position_int2,
}

random_color :: #force_inline proc(r: ^rand.Rand, alpha: u8 = 255) -> byte4 {
	return {u8(rand.int31_max(256, r)), u8(rand.int31_max(256, r)), u8(rand.int31_max(256, r)), alpha}
}

/*
	+---+---+---+
 +1 |   | 0 |   |
	+---+---+---+
  0 | 3 |   | 1 |
	+---+---+---+
 -1 |   | 2 |   |
	+---+---+---+
	 -1   0  +1
*/
get_direction4 :: #force_inline proc "contextless" (dir: i32) -> int2 {
	//               0, 1
	//                  1, 0
	//                     0, -1
    //                        -1, 0
	@(static)
	moves: [5]i32 = {0, 1, 0, -1, 0}
	return ((^int2)(&moves[dir & 3]))^
}

/*
	+---+---+---+
 +1 | 6 | 0 | 1 |
	+---+---+---+
  0 | 3 |   | 7 |
	+---+---+---+
 -1 | 5 | 4 | 2 |
	+---+---+---+
	 -1   0  +1
*/
get_direction8 :: #force_inline proc "contextless" (dir: i32) -> int2 {
	//               0, 1
	//                  1, 1
	//                     1, -1
	//                        -1, 0
	//                            0, -1
	//                               -1, -1
	//                                   -1, 1
	//                                       1, 0
	@(static)
	moves: [9]i32 = {0, 1, 1, -1, 0, -1, -1, 1, 0}
	return ((^int2)(&moves[dir & 7]))^
}
