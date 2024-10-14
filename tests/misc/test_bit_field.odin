package test_misc

import "core:fmt"
import "core:os"
import "core:strings"
import "core:testing"
import "shared:ounit"

@(test)
bit_fields :: proc(t: ^T) {

	My_Enum :: enum u8 {A, B, C, D}
	SOME_CONSTANT :: 7

	Foo :: bit_field u16 {          // backing type must be an integer or array of integers
		x: i32     | 3,             // signed integers will be signed extended on use
		y: u16     | 2 + 3,         // general expressions
		z: My_Enum | SOME_CONSTANT, // ability to define the bit-width elsewhere
		w: bool    | 2 when SOME_CONSTANT > 10 else 1,
	}

	v := Foo{}
	v.x = 7 // truncates the value to fit into 3 bits

	expect_size(t, Foo, 2)
	expect_value(t, v.x, 3)
	//expect_value(t, v, 3)
}
