package z80

import "core:bytes"
import "core:fmt"
import "core:runtime"
import "core:testing"
import o "shared:ounit"
import a "amstrad"

@(test)
verify_sizes :: proc(t: ^testing.T) {
	act, exp: u32

	act = size_of(TZ80)
	exp = 208
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)

	// act = size_of(register_pair)
	// exp = 2
	// testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)
}

@(test)
verify_flags :: proc(t: ^testing.T) {
	act, exp: u32

	act = Z80_SF | Z80_ZF | Z80_YF | Z80_HF | Z80_XF | Z80_PF | Z80_NF | Z80_CF
	exp = 255
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)
}

@(test)
verify_options :: proc(t: ^testing.T) {
	act, exp: u32

	act = Z80_OPTION_OUT_VC_255 | Z80_OPTION_LD_A_IR_BUG | Z80_OPTION_HALT_SKIP | Z80_OPTION_XQ | Z80_OPTION_IM0_RETX_NOTIFICATIONS | Z80_OPTION_YQ
	exp = 63
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)

	act = Z80_MODEL_ZILOG_NMOS
	exp = 42
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)

	act = Z80_MODEL_ZILOG_CMOS
	exp = 41
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)

	act = Z80_MODEL_NEC_NMOS
	exp = 2
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)

	act = Z80_MODEL_ST_CMOS
	exp = 35
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)
}

@(test)
verify_consts_max_cycles :: proc(t: ^testing.T) {
	act: zusize = Z80_MAXIMUM_CYCLES
	exp: zusize = 18446744073709551585
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)
}

@(test)
verify_consts_max_cycles_per_step :: proc(t: ^testing.T) {
	act: zuint32 = Z80_MAXIMUM_CYCLES_PER_STEP
	exp: zuint32 = 23
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)
}

@(test)
verify_z80_memory :: proc(t: ^testing.T) {
	_64kb :: 1 << 16
	_16kb :: 1 << 14
	o.expect_value(t, a.size_64kb, _64kb)
	o.expect_value(t, a.size_16kb, _16kb)
	o.expect_value(t, len(a.bank16kb), _16kb)
	o.expect_value(t, size_of(a.bank16kb), _16kb)
	//o.expect_value(t, size_of(a.banks), _64kb)

	bank_select : [4]i32 = {0,0,0,0}

	ram : [4]a.bank16kb = ---
	rom : [2]a.bank16kb = ---

	read, write : [4]a.ptr16kb

	write = {&ram[0],&ram[1],&ram[2],&ram[3]}
	read  = {&rom[0],&ram[1],&ram[2],&rom[1]}

	banks : a.bank4x16 = {
		{ &ram[0], &rom[0] },
		{ &ram[1], &ram[1] },
		{ &ram[2], &ram[2] },
		{ &ram[3], &rom[1] },
	}
	banks[1][0][666] = 0xCD
	o.expect_value(t, banks[1][0][666], 0xCD)
}
