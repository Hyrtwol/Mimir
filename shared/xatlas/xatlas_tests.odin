package xatlas

import "core:bytes"
import "core:fmt"
import "core:runtime"
import "core:testing"

@(test)
verify_sizes :: proc(t: ^testing.T) {
	act, exp: u32

	act = size_of(xatlasChart)
	exp = 32
	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))

	// act = size_of(register_pair)
	// exp = 2
	// testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))
}

// @(test)
// verify_flags :: proc(t: ^testing.T) {
// 	act, exp: u32

// 	act = Z80_SF | Z80_ZF | Z80_YF | Z80_HF | Z80_XF | Z80_PF | Z80_NF | Z80_CF
// 	exp = 255
// 	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))
// }

// @(test)
// verify_options :: proc(t: ^testing.T) {
// 	act, exp: u32

// 	act = Z80_OPTION_OUT_VC_255 | Z80_OPTION_LD_A_IR_BUG | Z80_OPTION_HALT_SKIP | Z80_OPTION_XQ | Z80_OPTION_IM0_RETX_NOTIFICATIONS | Z80_OPTION_YQ
// 	exp = 63
// 	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))

// 	act = Z80_MODEL_ZILOG_NMOS
// 	exp = 42
// 	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))

// 	act = Z80_MODEL_ZILOG_CMOS
// 	exp = 41
// 	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))

// 	act = Z80_MODEL_NEC_NMOS
// 	exp = 2
// 	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))

// 	act = Z80_MODEL_ST_CMOS
// 	exp = 35
// 	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))
// }

// @(test)
// verify_consts_max_cycles :: proc(t: ^testing.T) {
// 	act: zusize = Z80_MAXIMUM_CYCLES
// 	exp: zusize = 18446744073709551585
// 	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))
// }

// @(test)
// verify_consts_max_cycles_per_step :: proc(t: ^testing.T) {
// 	act: zuint32 = Z80_MAXIMUM_CYCLES_PER_STEP
// 	exp: zuint32 = 23
// 	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))
// }
