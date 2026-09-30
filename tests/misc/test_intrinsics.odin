package test_misc

import "base:intrinsics"

@(test)
intrinsics_constant :: proc(t: ^testing.T) {
	v :: intrinsics.constant_log2(32)
	expect_value(t, v, 5)

	f :: intrinsics.constant_trunc(3.14)
	expect_value(t, f, 3)
}

@(test)
intrinsics_bit_count :: proc(t: ^testing.T) {
	v: u32 = 0b00110011000
	expect_value(t, intrinsics.count_ones(v), 4)
	expect_value(t, intrinsics.count_zeros(v), 28)
	expect_value(t, intrinsics.count_leading_zeros(v), 23)
	expect_value(t, intrinsics.count_trailing_zeros(v), 3)
}
