package amstrad

import "core:fmt"
import "core:math/linalg"
import "core:os"
import "core:runtime"
import win32 "core:sys/windows"
import win32ex "shared:sys/windows"
import canvas "shared:tlc/canvas"
import win32app "shared:tlc/win32app"
import z80 "shared:z80"

cycles_per_tick :: 100
mem_size :: 0x10000
memory: [mem_size]u8
running: bool = false

z_fetch_opcode :: proc(zcontext: rawptr, address: z80.zuint16) -> z80.zuint8 {
	//fmt.printf("fetch_opcode[%d]=0x%2X\n", address, memory[address])
	return memory[address]
}

z_fetch :: proc(zcontext: rawptr, address: z80.zuint16) -> z80.zuint8 {
	//fmt.printf("fetch[%d]=0x%2X\n", address, memory[address])
	return memory[address]
}

z_read :: proc(zcontext: rawptr, address: z80.zuint16) -> z80.zuint8 {
	//fmt.printf("read[%d]=0x%2X\n", address, memory[address])
	return memory[address]
}

z_write :: proc(zcontext: rawptr, address: z80.zuint16, value: z80.zuint8) {
	//fmt.printf("write[0x%4X]=0x%2X\n", address, value)
	memory[address] = value
}

z_in :: proc(zcontext: rawptr, address: z80.zuint16) -> z80.zuint8 {
	port := address & 0xFF
	value: z80.zuint8 = 0
	switch port {
	case 1:
		value = 1
	case:
		{
			fmt.printf("in[0x%2X]=0x%2X", port, value)
			if value >= 32 {fmt.printf(" '%v'", rune(value))}
			fmt.print("\n")
		}
	}
	return value
}

z_out :: proc(zcontext: rawptr, address: z80.zuint16, value: z80.zuint8) {
	port := address & 0xFF
	switch port {
	case 1:
		fmt.print(rune(value))
	case:
		{
			fmt.printf("out[0x%2X]=0x%2X", port, value)
			if value >= 32 {fmt.printf(" '%v'", rune(value))}
			fmt.print("\n")
		}
	}
}

z_halt :: proc(zcontext: rawptr, signal: z80.zuint8) {
	fmt.printf("halt %d\n", signal)
	running = false
}

reset :: proc() {
	//fmt.print("memory reset\n")
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
	fmt.print("Amstrad\n")

	load_rom("../data/z80/hello.rom")

	cpu: z80.TZ80 = {
		fetch_opcode = z_fetch_opcode,
		fetch        = z_fetch,
		read         = z_read,
		write        = z_write,
		_in          = z_in,
		out          = z_out,
		halt         = z_halt,
	}
	z80.z80_power(&cpu, true)
	//fmt.printf("CPU %v\n", cpu)

	running = true
	total: z80.zusize = 0
	reps := 0
	for running {
		total += z80.z80_run(&cpu, cycles_per_tick)
		reps += 1
	}
	fmt.printf("total %v (%v)\n", total, reps)

	fmt.print("Done.\n")
}
