package tests_misc

import "core:bytes"
import "core:fmt"
import "core:runtime"
import win32 "core:sys/windows"
import "core:testing"
import win32ex "shared:sys/windows"

@(test)
can_i_inline_asm :: proc(t: ^testing.T) {
	exp: u32 = 10
	act := asm(u32, u32) -> u32{`add $0, $1
		 mov $1, $2`,"r,r,=r"}(3, 7)
	testing.expect(t, act == exp, fmt.tprintf("inline_asm: %v (should be: %v)", act, exp))
}

@(test)
call_asm_proc :: proc(t: ^testing.T) {
	exp: u32 = 10
	act := inline_asm(3, 7)
	testing.expect(t, act == exp, fmt.tprintf("inline_asm: %v (should be: %v)", act, exp))
}

inline_asm :: proc "contextless" (x: u32, y: u32) -> u32 {
	// odinfmt: disable
	return asm(u32, u32) -> u32 {
		`add $0, $1
		 mov $1, $2`,
		"r,r,=r",
	}(x, y);
	// odinfmt: enable
}

@(test)
call_asm_that_call_a_proc :: proc(t: ^testing.T) {
	g_res = 0
	exp: u32 = 1
	inline_asm_call()
	testing.expect(t, g_res == exp, fmt.tprintf("inline_asm: %v (should be: %v)", g_res, exp))
}

g_res := 0

can_call :: proc() {g_res = 1}

inline_asm_call :: proc "contextless" () {
	// odinfmt: disable
	asm() {
		`call .can_call`,
		"",
	}();
	// odinfmt: enable
}
