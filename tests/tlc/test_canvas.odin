package test_tlc

import "core:testing"
import win32 "core:sys/windows"
import o "libs:ounit"
import "libs:tlc/canvas"

expect_value :: proc(t: ^testing.T, act: canvas.byte4, exp: canvas.byte4, loc := #caller_location) {
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp, loc = loc)
}

@(test)
verify_w95_colors :: proc(t: ^testing.T) {
	o.expect_value(t, len(canvas.W95_COLORS), 16)
	expect_value(t, canvas.W95_BLACK			, canvas.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, canvas.W95_WHITE			, canvas.byte4{0xFF, 0xFF, 0xFF, 0xFF})
}

@(test)
verify_c64_colors :: proc(t: ^testing.T) {
	o.expect_value(t, len(canvas.C64_COLORS), 16)
	expect_value(t, canvas.C64_BLACK			, canvas.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, canvas.C64_WHITE			, canvas.byte4{0xFF, 0xFF, 0xFF, 0xFF})
}

@(test)
verify_amstrad_colors :: proc(t: ^testing.T) {
	o.expect_value(t, len(canvas.AMSTRAD_COLORS), 27)

	expect_value(t, canvas.AMSTRAD_BLACK		, canvas.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, canvas.AMSTRAD_BRIGHT_WHITE	, canvas.byte4{0xFF, 0xFF, 0xFF, 0xFF})

	expect_value(t, canvas.AMSTRAD_BLACK		, canvas.W95_BLACK)
	expect_value(t, canvas.AMSTRAD_BLUE  		, canvas.W95_NAVY)
	expect_value(t, canvas.AMSTRAD_BRIGHT_BLUE  , canvas.W95_BLUE)
	expect_value(t, canvas.AMSTRAD_RED  		, canvas.W95_MAROON)
	expect_value(t, canvas.AMSTRAD_MAGENTA  	, canvas.W95_PURPLE)

	expect_value(t, canvas.AMSTRAD_GREEN		, canvas.W95_GREEN)
}
