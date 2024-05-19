package fft

import "core:bytes"
import "core:fmt"
import "base:runtime"
import "core:testing"
import "shared:ounit"

@(private)
expect_u32 :: proc(t: ^testing.T, act, exp: u32) {
	testing.expectf(t, act == exp, "0x%8X (should be: 0x8X)", act, exp)
}
@(private)
expect_i32 :: proc(t: ^testing.T, act, exp: i32) {
	testing.expectf(t, act == exp, "0x%8X (should be: 0x8X)", act, exp)
}
@(private)
expect_it :: proc {
	expect_u32,
	expect_i32,
}

// f64(real(z)), f64(imag(z))

@(test)
verify_lwids :: proc(t: ^testing.T) {
	expect_it(t, i32(cMaxPrimeFactor), 1021)
}
