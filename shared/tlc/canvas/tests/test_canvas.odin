package test_canvas

import cv ".."
import "core:fmt"
import win32 "core:sys/windows"
import "core:testing"
import o "shared:ounit"

expect_value :: proc(t: ^testing.T, act: cv.byte4, exp: cv.byte4, loc := #caller_location) {
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp, loc = loc)
}

@(test)
verify_w95_colors :: proc(t: ^testing.T) {
	o.expect_value(t, len(cv.W95_COLORS), 16)
	expect_value(t, cv.W95_BLACK			, cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, cv.W95_WHITE			, cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})
}

@(test)
verify_c64_colors :: proc(t: ^testing.T) {
	o.expect_value(t, len(cv.C64_COLORS), 16)
	expect_value(t, cv.C64_BLACK			, cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, cv.C64_WHITE			, cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})
	expect_value(t, cv.get_color_c64(.BLACK), cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, cv.get_color_c64(.WHITE), cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})
}

@(test)
verify_amstrad_colors :: proc(t: ^testing.T) {
	o.expect_value(t, len(cv.AMSTRAD_COLORS), 27)

	expect_value(t, cv.AMSTRAD_BLACK		, cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, cv.AMSTRAD_BRIGHT_WHITE	, cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})

	expect_value(t, cv.AMSTRAD_BLACK		, cv.W95_BLACK)
	expect_value(t, cv.AMSTRAD_BLUE  		, cv.W95_NAVY)
	expect_value(t, cv.AMSTRAD_BRIGHT_BLUE  , cv.W95_BLUE)
	expect_value(t, cv.AMSTRAD_RED  		, cv.W95_MAROON)
	expect_value(t, cv.AMSTRAD_MAGENTA  	, cv.W95_PURPLE)

	expect_value(t, cv.AMSTRAD_GREEN		, cv.W95_GREEN)

	expect_value(t, cv.get_color(cv.AMSTRAD_COLOR.BLACK), cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, cv.get_color(cv.AMSTRAD_COLOR.BRIGHT_WHITE), cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})

	expect_value(t, cv.get_color_amstrad(.BLACK), cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, cv.get_color_amstrad(.BRIGHT_WHITE), cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})
}

@(private)
print_map :: proc(m: [3][3]i32) {
	prefix :: "// "
	format :: "% 2d"
	for y in i32(0) ..< 3 {
		fmt.println(prefix + "   +---+---+---+")
		iy := 2 - y
		fmt.printf(prefix + format + " ", iy - 1)
		cy := m[iy]
		for x in i32(0) ..< 3 {
			c := cy[x]
			fmt.print("|")
			if c >= 0 {
				fmt.printf(format + " ", c)
			} else {
				fmt.print("   ")
			}
		}
		fmt.println("|")
	}
	fmt.println(prefix + "   +---+---+---+")
	fmt.print(prefix + "  ")
	for y in i32(0) ..< 3 {
		fmt.printf("  " + format, y - 1)
	}
	fmt.println()
}

@(test)
direction4 :: proc(t: ^testing.T) {
	m: [3][3]i32
	for y in i32(0) ..< 3 {
		for x in i32(0) ..< 3 {
			m[y][x] = -1
		}
	}
	for i in i32(0) ..< 4 {
		d := cv.get_direction4(i) + 1
		m[d.y][d.x] = i
	}

	print_map(m)
}

@(test)
direction8 :: proc(t: ^testing.T) {
	m: [3][3]i32
	for y in i32(0) ..< 3 {
		for x in i32(0) ..< 3 {
			m[y][x] = -1
		}
	}
	for i in i32(0) ..< 8 {
		d := cv.get_direction8(i) + 1
		m[d.y][d.x] = i
	}

	print_map(m)
}

@(test)
to_color :: proc(t: ^testing.T) {
	o.expect_value(t, f32(255.99609375), cv.color_scale_f2b)

	expect_value(t, 000, cv.to_color(-0.10000))
	expect_value(t, 000, cv.to_color(+0.00000))
	expect_value(t, 000, cv.to_color(+0.00390))
	expect_value(t, 001, cv.to_color(+0.00391))
	expect_value(t, 127, cv.to_color(+0.50000))
	expect_value(t, 128, cv.to_color(+0.50001))
	expect_value(t, 254, cv.to_color(+0.99610))
	expect_value(t, 255, cv.to_color(+0.99611))
	expect_value(t, 255, cv.to_color(+1.00000))
	expect_value(t, 255, cv.to_color(+1.10000))

	expect_value(t, {0x3F, 0x7F, 0xBF, 0xFF}, cv.to_color(cv.float4{0.25, 0.5, 0.75, 1.0}))
}
