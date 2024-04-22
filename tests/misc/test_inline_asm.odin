package test_misc

import "core:bytes"
import "core:fmt"
import "core:runtime"
import "core:testing"
import win32app "libs:tlc/win32app"

@(test)
can_i_inline_asm :: proc(t: ^testing.T) {
	exp: u32 = 10
	act := asm(u32, u32) -> u32{`add $0, $1
		 mov $1, $2`,"r,r,=r"}(3, 7)
	testing.expect(t, act == exp)
}

// https://learn.microsoft.com/en-us/cpp/intrinsics/rdtsc
__rdtsc :: #force_inline proc() -> i64 {
	return asm() -> i64{`rdtsc`,"=r"}()
}

@(test)
can_i_call_rdtsc :: proc(t: ^testing.T) {
	reps :: 100000
	exp: u64 = 0

	stopwatch := win32app.create_stopwatch()
	stopwatch->start()

	act := __rdtsc()
	for i in 0..<reps {
		exp += exp*exp
	}
	act2 := __rdtsc()

	stopwatch->stop()
	elapsed_ms := stopwatch->get_elapsed_ms()

	clock_cycles := act2 - act

	fmt.printfln("rdtsc start  : %d", act)
	fmt.printfln("rdtsc stop   : %d", act2)
	fmt.printfln("clock cycles : %d", clock_cycles)
	fmt.printfln("avg. cc      : %f", f64(clock_cycles) / reps)
	fmt.printfln("time         : %fs ms", elapsed_ms)
}

@(test)
call_asm_proc :: proc(t: ^testing.T) {
	testing.expect(t, inline_asm(3, 7) == 10)
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

g_res: u32 = 0

@(export)
can_call :: proc() {g_res += 1}

inline_asm_call :: proc "contextless" () {
	// odinfmt: disable
	asm() {"call can_call",""}();
	// odinfmt: enable
}
