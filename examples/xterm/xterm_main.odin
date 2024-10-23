package main

import "base:intrinsics"
import "core:math/rand"
import xt "shared:xterm"

main :: proc() {
	size := xt.int2{10, 10}
	xt.set_cursor_position_home()
	xt.print_horizontal_border(size, true)
	xt.println()
	xt.print_vertical_border(size, "Hello")
	xt.println()
	xt.print_vertical_border(size, "Hello")
	xt.println()
	xt.print_horizontal_border(size, false)
	xt.println()

	xt.set_cursor_position({2, 2})
	xt.print("Benny")

	xt.set_cursor_position({5, 1})

	for _ in 0 ..< 4 {
		xt.printfln(xt.rgb{u8(rand.int31_max(255)), u8(rand.int31_max(255)), u8(rand.int31_max(255))}, "hello")
	}

	xt.println("bye", "bye")
}
