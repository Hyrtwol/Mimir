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
	for y in i32(0) ..< 3 {
		fmt.println("   +---+---+---+")
		iy := 2 - y
		fmt.printf("% 2d ", iy - 1)
		cy := m[iy]
		for x in i32(0) ..< 3 {
			c := cy[x]
			fmt.print("|")
			if c >= 0 {
				fmt.printf("% 2d ", c)
			} else {
				fmt.print("   ")
			}
		}
		fmt.println("|")
	}
	fmt.println("   +---+---+---+")
	fmt.println("    -1   0   1")
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
		d := cv.get_direction4(i)
		fmt.println("dir", i, d)
		d += 1
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
		d := cv.get_direction8(i)
		fmt.println("dir", i, d)
		d += 1
		m[d.y][d.x] = i
	}

	print_map(m)
}
