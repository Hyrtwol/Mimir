package main

import "core:fmt"
import "core:os"
import "core:runtime"
import z80 "shared:z80"

mem_size :: 0x10000
cpu: z80.TZ80
memory: [mem_size]u8

/*
z_read :: proc "c" (zcontext: rawptr, address: z80.zuint16) -> z80.zuint8 {
	context = runtime.default_context()
	value := memory[address]
	fmt.printf("read[%d]=0x%2X\n", address, value)
	return value
}

z_write :: proc "c" (zcontext: rawptr, address: z80.zuint16, value: z80.zuint8) {
	context = runtime.default_context()
	fmt.printf("write[%d]=0x%2X\n", address, value)
	memory[address] = value
}

z_in :: proc "c" (zcontext: rawptr, address: z80.zuint16) -> z80.zuint8 {
	context = runtime.default_context()
	value: z80.zuint8 = 0
	fmt.printf("in[%d]=%d\n", address, value)
	return value
}

z_out :: proc "c" (zcontext: rawptr, address: z80.zuint16, value: z80.zuint8) {
	context = runtime.default_context()
	if value < 32 {
		fmt.printf("out[%d]=0x%2X\n", address, value)
	} else {
		fmt.printf("out[%d]=0x%2X '%v'\n", address, value, rune(value))
	}
}

z_halt :: proc "c" (zcontext: rawptr, signal: z80.zuint8) {
	context = runtime.default_context()
	fmt.printf("halt %d\n", signal)
}

z_notify :: proc "c" (zcontext: rawptr) {
	context = runtime.default_context()
	fmt.print("notify\n")
}

z_illegal :: proc "c" (zcpu: z80.PZ80, opcode: z80.zuint8) -> z80.zuint8 {
	context = runtime.default_context()
	fmt.printf("illegal %d\n", opcode)
	return 10
}
*/

z_read :: proc(zcontext: rawptr, address: z80.zuint16) -> z80.zuint8 {
	value := memory[address]
	fmt.printf("read[%d]=0x%2X\n", address, value)
	return value
}

z_write :: proc(zcontext: rawptr, address: z80.zuint16, value: z80.zuint8) {
	fmt.printf("write[%d]=0x%2X\n", address, value)
	memory[address] = value
}

z_in :: proc(zcontext: rawptr, address: z80.zuint16) -> z80.zuint8 {
	value: z80.zuint8 = 0
	fmt.printf("in[%d]=0x%2X\n", address, value)
	return value
}

z_out :: proc(zcontext: rawptr, address: z80.zuint16, value: z80.zuint8) {
	if value < 32 {
		fmt.printf("out[%d]=0x%2X\n", address, value)
	} else {
		fmt.printf("out[%d]=0x%2X '%v'\n", address, value, rune(value))
	}
}

z_halt :: proc(zcontext: rawptr, signal: z80.zuint8) {
	fmt.printf("halt %d\n", signal)
}

z_notify :: proc(zcontext: rawptr) {
	fmt.print("notify\n")
}

z_illegal :: proc(zcpu: z80.PZ80, opcode: z80.zuint8) -> z80.zuint8 {
	context = runtime.default_context()
	fmt.printf("illegal %d\n", opcode)
	return 10
}

reset :: proc() {
	fmt.print("memory reset\n")
	runtime.memset(&memory, 0, mem_size)
}

load_rom :: proc(filename: string) {
	reset()

	fmt.printf("loading rom %v\n", filename)

	data, ok := os.read_entire_file(filename)
	defer delete(data)

	if ok {
		rom_size := len(data)
		for i in 0 ..< rom_size {
			memory[i] = data[i]
		}
	} else {
		panic(fmt.tprintf("Unable to load rom %v\n", filename))
	}
}

main :: proc() {
	fmt.print("Z80 Emulator\n")

	load_rom("../examples/z80_emulator/hello.rom")

	cpu._context = nil

	cpu.fetch_opcode = z_read
	cpu.fetch = z_read

	cpu.read = z_read
	cpu.write = z_write

	cpu._in = z_in
	cpu.out = z_out

	cpu.halt = z_halt

	cpu.nop = nil
	cpu.nmia = nil
	cpu.inta = nil
	cpu.int_fetch = nil
	cpu.ld_i_a = nil
	cpu.ld_r_a = nil
	cpu.reti = nil
	cpu.retn = nil
	cpu.hook = nil
	cpu.illegal = z_illegal

	//z80.z80_power(&cpu, true)
	//z80.z80_instant_reset(&cpu)

	cycles :: 1000
	res := z80.z80_run(&cpu, cycles)
	fmt.printf("Run %v\n", res)

	fmt.print("Done.\n")
}
