package test_z80

import "core:bytes"
import "core:fmt"
import "core:runtime"
import "core:testing"
import o "shared:ounit"
import z ".."
import a "../amstrad"

expectf :: testing.expectf
expect_size :: o.expect_size
expect_value :: o.expect_value
expect_value_64 :: o.expect_value_64

zuint32 :: z.zuint32
zusize :: z.zusize

@(test)
verify_sizes :: proc(t: ^testing.T) {
	act, exp: u32

	act = size_of(z.Z80)
	exp = 208
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)

	// act = size_of(register_pair)
	// exp = 2
	// testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)
}

@(test)
verify_flags :: proc(t: ^testing.T) {
	act, exp: u32

	act = z.Z80_SF | z.Z80_ZF | z.Z80_YF | z.Z80_HF | z.Z80_XF | z.Z80_PF | z.Z80_NF | z.Z80_CF
	exp = 255
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)
}

@(test)
verify_options :: proc(t: ^testing.T) {
	act, exp: u32

	act = z.Z80_OPTION_OUT_VC_255 | z.Z80_OPTION_LD_A_IR_BUG | z.Z80_OPTION_HALT_SKIP | z.Z80_OPTION_XQ | z.Z80_OPTION_IM0_RETX_NOTIFICATIONS | z.Z80_OPTION_YQ
	exp = 63
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)

	act = z.Z80_MODEL_ZILOG_NMOS
	exp = 42
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)

	act = z.Z80_MODEL_ZILOG_CMOS
	exp = 41
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)

	act = z.Z80_MODEL_NEC_NMOS
	exp = 2
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)

	act = z.Z80_MODEL_ST_CMOS
	exp = 35
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)
}

@(test)
verify_consts_max_cycles :: proc(t: ^testing.T) {
	act: zusize = z.Z80_MAXIMUM_CYCLES
	exp: zusize = 18446744073709551585
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)
}

@(test)
verify_consts_max_cycles_per_step :: proc(t: ^testing.T) {
	act: zuint32 = z.Z80_MAXIMUM_CYCLES_PER_STEP
	exp: zuint32 = 25
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

	//bank_select : [4]i32 = {0,0,0,0}

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
