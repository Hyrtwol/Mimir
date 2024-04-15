package main

import "core:intrinsics"
import "core:math/rand"
import "shared:xterm"

main :: proc() {
	using xterm

	rng := rand.create(u64(intrinsics.read_cycle_counter()))
	size := int2{10, 10}
	set_cursor_position_home()
	print_horizontal_border(size, true)
	println()
	print_vertical_border(size, "Hello")
	println()
	print_horizontal_border(size, false)
	println()

	set_cursor_position({2, 2})
	print("Benny")

	set_cursor_position({4, 1})

	for _ in 0 ..< 4 {
		printfln(rgb{u8(rand.int31_max(255, &rng)), u8(rand.int31_max(255, &rng)), u8(rand.int31_max(255, &rng))}, "hello")
	}

	println("bye", "bye")
}
