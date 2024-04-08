package main

import "core:fmt"

pow :: proc(x: i32) -> i32 {
	return x * x
}

sign :: proc(x: i32) -> i32 {
	return -1 if x < 0 else 1
}

callback :: #type proc(i32) -> i32

main :: proc() {
	callbacks := make([dynamic]callback, 0, 0)
	defer delete(callbacks)

	append(&callbacks, callback(pow))
	append(&callbacks, callback(pow))
	append(&callbacks, callback(pow))
	append(&callbacks, callback(sign))

	for p, i in callbacks {
		if (p != nil) {
			fmt.printfln("Result: %d", p(i32(i)))
		}
	}
}
