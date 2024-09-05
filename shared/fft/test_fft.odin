package fft

import "core:bytes"
import "core:fmt"
import "base:runtime"
import "core:testing"
//import "shared:ounit"

expect_value :: testing.expect_value

// f64(real(z)), f64(imag(z))

@(test)
verify_lwids :: proc(t: ^testing.T) {
	expect_value(t, i32(cMaxPrimeFactor), 1021)
}
