#+vet
package main

import "core:fmt"
import "base:intrinsics"
import "core:os"
import "base:runtime"
import z "shared:z80"
import a "libs:amstrad"

Z80 :: z.Z80
bank64kb :: z.bank64kb
snapshot :: a.snapshot

cycles_per_tick :: 100
mem_size :: 0x10000
memory64kb :: [mem_size]u8

memory : memory64kb
running: bool = false
put_chars: bool = false

size_16kb :: z.size_16kb
mask_16kb :: z.mask_16kb
size_64kb :: z.size_64kb

//p_image := #load("data/mode2.raw")
p_image := #load("data/pinup.raw")
/*
foreign import mode2 "data/mode2.asm"
//foreign import mode2 "data/pinup2.asm"
foreign mode2 {imagedata: [16000]u8}
p_image := imagedata
*/

/*
https://www.chibiakumas.com/z80/AmstradCPC.php
https://neuro-sys.github.io/2019/10/01/amstrad-cpc-crtc.html
*/

log_port :: proc "contextless" (prefix: string, port: z.zuint16, value: z.zuint8) {
	context = runtime.default_context()
	fmt.print(prefix)
	fmt.printf("[0x%2X]=0x%2X", port, value)
	if value >= 32 {fmt.printf(" '%v'", rune(value))}
	fmt.println()
}

// z_get_app :: #force_inline proc(zcontext: rawptr) -> papp {
// 	if zcontext == nil {panic("Missing app!")}
// 	return papp(zcontext)
// }

z_fetch_opcode :: proc "c" (zcontext: papp, address: z.zuint16) -> z.zuint8 {
	//app := z_get_app(zcontext)
	//fmt.printfln("fetch_opcode[%d]=0x%2X", address, memory[address])
	return memory[address]
}

z_fetch :: proc "c" (zcontext: papp, address: z.zuint16) -> z.zuint8 {
	//app := z_get_app(zcontext)
	//fmt.printfln("fetch[%d]=0x%2X", address, memory[address])
	return memory[address]
}

z_read :: proc "c" (zcontext: papp, address: z.zuint16) -> z.zuint8 {
	//app := z_get_app(zcontext)
	//fmt.printfln("read[%d]=0x%2X", address, memory[address])
	return memory[address]
}

z_write :: proc "c" (zcontext: papp, address: z.zuint16, value: z.zuint8) {
	//app := z_get_app(zcontext)
	//fmt.printfln("write[0x%4X]=0x%2X", address, value)
	memory[address] = value
}

z_in :: proc "c" (zcontext: papp, address: z.zuint16) -> z.zuint8 {
	//app := z_get_app(zcontext)
	port := address & 0xFF
	value: z.zuint8 = 0
	switch port {
	case 1:
		value = 1
	case:
		// fmt.printf("in[0x%2X]=0x%2X", port, value)
		// if value >= 32 {fmt.printf(" '%v'", rune(value))}
		// fmt.println()
		log_port("in", port, value)
	}
	return value
}

z_out :: proc "c" (zcontext: papp, address: z.zuint16, value: z.zuint8) {
	//app := z_get_app(zcontext)
	app := zcontext
	port := address & 0xFF
	switch port {
	case 1:
		switch value {
		case '\n': /* Line Feed */
		case '\f': /*skip Form Feed*/
		//case '\r': /*skip Carriage Return*/
		//case: fmt.print(rune(value))
		case: put_char(app.pvBits, value)
		}
	case:
		// fmt.printf("out[0x%2X]=0x%2X", port, value)
		// if value >= 32 {fmt.printf(" '%v'", rune(value))}
		// fmt.println()
		log_port("out", port, value)
	}
}

z_halt :: proc "c" (zcontext: papp, signal: z.zuint8) {
	context = runtime.default_context()
	//app := z_get_app(zcontext)
	app := zcontext
	fmt.println()
	fmt.printfln("halt %d pc=%d", signal, app.cpu.pc)
	running = signal == 0
}

reset :: proc() {
	fmt.println("memory reset")
	runtime.mem_zero(&memory, mem_size)
}

load_rom :: proc(filename: string) {
	//reset()
	fmt.printfln("loading rom %v", filename)
	data, ok := os.read_entire_file(filename)
	if ok {
		defer delete(data)
		rom_size := min(len(data), len(memory))
		intrinsics.mem_copy(&memory[0], &data[0], rom_size)
	} else {
		fmt.panicf("Unable to load rom %v", filename)
	}
}

init_cpu :: proc (z80: ^Z80) {
	z80.fetch_opcode = (z.Z80Read)(z_fetch_opcode)
	z80.fetch        = (z.Z80Read)(z_fetch)
	z80.read         = (z.Z80Read)(z_read)
	z80.write        = (z.Z80Write)(z_write)
	z80.in_          = (z.Z80Read)(z_in)
	z80.out          = (z.Z80Write)(z_out)
	z80.halt         = (z.Z80Halt)(z_halt)
}
