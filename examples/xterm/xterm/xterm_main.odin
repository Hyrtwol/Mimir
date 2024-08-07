package main

import "base:intrinsics"
import "core:math/rand"
import "shared:xterm"

main :: proc() {
	using xterm

	size := int2{10, 10}
	set_cursor_position_home()
	print_horizontal_border(size, true)
	println()
	print_vertical_border(size, "Hello")
	println()
	print_vertical_border(size, "Hello")
	println()
	print_horizontal_border(size, false)
	println()

	set_cursor_position({2, 2})
	print("Benny")

	set_cursor_position({5, 1})

	for _ in 0 ..< 4 {
		printfln(rgb{u8(rand.int31_max(255)), u8(rand.int31_max(255)), u8(rand.int31_max(255))}, "hello")
	}

	println("bye", "bye")
}
