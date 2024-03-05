package test_misc

import "core:bytes"
import "core:fmt"
import "core:runtime"
import "core:testing"
import "shared:ounit"

vec2 :: [2]i32

@(test)
can_i_swizzle :: proc(t: ^testing.T) {
	using ounit
	v: vec2 = {3, 7}
	expect_value(t, v[0], 3)
	expect_value(t, v[1], 7)
	expect_value(t, v.x, 3)
	expect_value(t, v.y, 7)
}
