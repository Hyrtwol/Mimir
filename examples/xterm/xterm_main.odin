package main

import "core:fmt"
import vt "shared:xterm"

main :: proc() {
	size := vt.int2{10,10}
	vt.set_cursor_position_home()
	vt.print_horizontal_border(size, true)
	fmt.println()
	vt.print_vertical_border(size, "Hello")
	fmt.println()
	vt.print_horizontal_border(size, false)
	fmt.println()

	vt.set_cursor_position({2,2})
	fmt.print("Benny")

	vt.set_cursor_position({4,1})

	// ch: [1]byte
	// os.read(os.stdin, ch[:])
}
