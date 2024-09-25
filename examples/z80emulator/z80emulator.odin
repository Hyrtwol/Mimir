#+vet
package z80emulator

import "core:fmt"
import "core:os"
import "base:runtime"
import z80 "shared:z80"

dump_cpu :: false
cycles_per_tick :: 100
mem_size :: 0x10000
running: bool = false

zstate :: struct {
	memory: []z80.zuint8,
}
zcontext :: ^zstate

z_fetch_opcode :: proc(zc: zcontext, address: z80.zuint16) -> z80.zuint8 {
	//fmt.printfln("fetch_opcode[%d]=0x%2X", address, memory[address])
	return zc.memory[address]
}

z_fetch :: proc(zc: zcontext, address: z80.zuint16) -> z80.zuint8 {
	//fmt.printfln("fetch[%d]=0x%2X", address, memory[address])
	return zc.memory[address]
}

z_read :: proc(zc: zcontext, address: z80.zuint16) -> z80.zuint8 {
	//fmt.printfln("read[%d]=0x%2X", address, memory[address])
	return zc.memory[address]
}

z_write :: proc(zc: zcontext, address: z80.zuint16, value: z80.zuint8) {
	//fmt.printfln("write[0x%4X]=0x%2X", address, value)
	zc.memory[address] = value
}

z_in :: proc(zc: zcontext, address: z80.zuint16) -> z80.zuint8 {
	port := address & 0xFF
	value: z80.zuint8 = 0
	switch port {
	case 1:
		value = 1
	case:
		fmt.printf("in[0x%2X]=0x%2X", port, value)
		if value >= 32 {fmt.printf(" '%v'", rune(value))}
		fmt.println()
	}
	return value
}

z_out :: proc(zc: zcontext, address: z80.zuint16, value: z80.zuint8) {
	port := address & 0xFF
	switch port {
	case 1:
		switch value {
			case '\n': fmt.println(flush = true) /* Line Feed */
			case '\f': /*skip Form Feed*/
			case '\r': /*skip Carriage Return*/
			case: fmt.print(rune(value))
		}
	case:
		fmt.printf("out[0x%2X]=0x%2X", port, value)
		if value >= 32 {fmt.printf(" '%v'", rune(value))}
		fmt.println()
	}
}

z_halt :: proc(zc: zcontext, signal: z80.zuint8) {
	fmt.printfln("\nhalt %d", signal)
	running = false
}

z_reti :: proc(zc: zcontext) {
	fmt.println(#procedure)
}

z_retn :: proc(zc: zcontext) {
	fmt.println(#procedure)
}

z_illegal :: proc(zcpu: z80.PZ80, opcode: z80.zuint8) -> z80.zuint8 {
	//context = runtime.default_context()
	fmt.println(#procedure, opcode)
	return 10
}

reset :: proc(zc: zcontext) {
	fmt.println(#procedure, len(zc.memory))
	runtime.memset(&zc.memory[0], 0, mem_size)
}

load_rom :: proc(zc: zcontext, filename: string) {
	fmt.println(#procedure, filename)
	reset(zc)

	data, ok := os.read_entire_file(filename)
	if ok {
		assert(len(data) <= len(zc.memory))
		defer delete(data)
		rom_size := len(data)
		for i in 0 ..< rom_size {
			zc.memory[i] = data[i]
		}
	} else {
		fmt.panicf("Unable to load rom %v\n", filename)
	}
}

main :: proc() {
	fmt.println("Z80 Emulator")

	state: zstate = {
		memory = make([]z80.zuint8, mem_size),
	}
	defer delete(state.memory)

	cpu: z80.Z80 = {
		fetch_opcode = z80.Z80Read(z_fetch_opcode),
		fetch        = z80.Z80Read(z_fetch),
		read         = z80.Z80Read(z_read),
		write        = z80.Z80Write(z_write),
		in_          = z80.Z80Read(z_in),
		out          = z80.Z80Write(z_out),
		halt         = z80.Z80Halt(z_halt),
		context_     = &state,
		nop          = nil,
		nmia         = nil,
		inta         = nil,
		int_fetch    = nil,
		ld_i_a       = nil,
		ld_r_a       = nil,
		reti         = z80.Z80Notify(z_reti),
		retn         = z80.Z80Notify(z_retn),
		hook         = nil,
		illegal      = z80.Z80Illegal(z_illegal),
		options      = 0,
	}

	load_rom(&state, "../data/z80/hello.rom")

	z80.z80_power(&cpu, true)
	z80.z80_instant_reset(&cpu)

	fmt.println("Run...")
	running = true
	total: z80.zusize = 0
	reps := 0
	for running {
		total += z80.z80_run(&cpu, cycles_per_tick)
		reps += 1
	}
	fmt.printfln("total %v (%v)", total, reps)

	if dump_cpu {fmt.printfln("CPU %v", cpu)}

	fmt.println("Done.")
}
