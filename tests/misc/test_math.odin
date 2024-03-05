package test_misc

import "core:bytes"
import "core:fmt"
import "core:runtime"
import "core:testing"
import "shared:ounit"

vec2 :: [2]f32

@(test)
can_i_swizzle :: proc(t: ^testing.T) {
	using ounit
	v: vec2 = {3, 7}
	expect_value(v.x, 3)
	expect_value(v.y, 7)
}
