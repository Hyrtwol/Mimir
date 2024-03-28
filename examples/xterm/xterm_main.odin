package main

import "core:bytes"
import "core:fmt"
import "core:runtime"
import "core:os"
import vt "shared:xterm"

main :: proc() {
	size := vt.int2{10,10}
	vt.print_horizontal_border(size, true)
	fmt.println()
	vt.print_vertical_border(size, "Hello")
	fmt.println()
	vt.print_horizontal_border(size, false)
	fmt.println()

	vt.set_cursor_position({2,2})
	fmt.print("Benny")

	// ch: [1]byte
	// os.read(os.stdin, ch[:])
}
