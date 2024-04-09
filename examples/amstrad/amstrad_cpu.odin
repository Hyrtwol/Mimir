// +vet
package main

import "core:fmt"
import "core:intrinsics"
import "core:os"
import "core:runtime"
import z "shared:z80"
import a "libs:amstrad"

Z80 :: z.Z80
//PZ80 :: z.PZ80 // todo rename pZ80
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

z_get_app :: #force_inline proc(zcontext: rawptr) -> papp {
	if zcontext == nil {panic("Missing app!")}
	return papp(zcontext)
}

z_fetch_opcode :: proc(zcontext: rawptr, address: z.zuint16) -> z.zuint8 {
	//app := z_get_app(zcontext)
	//fmt.printf("fetch_opcode[%d]=0x%2X\n", address, memory[address])
	return memory[address]
}

z_fetch :: proc(zcontext: rawptr, address: z.zuint16) -> z.zuint8 {
	//app := z_get_app(zcontext)
	//fmt.printf("fetch[%d]=0x%2X\n", address, memory[address])
	return memory[address]
}

z_read :: proc(zcontext: rawptr, address: z.zuint16) -> z.zuint8 {
	//app := z_get_app(zcontext)
	//fmt.printf("read[%d]=0x%2X\n", address, memory[address])
	return memory[address]
}

z_write :: proc(zcontext: rawptr, address: z.zuint16, value: z.zuint8) {
	//app := z_get_app(zcontext)
	//fmt.printf("write[0x%4X]=0x%2X\n", address, value)
	memory[address] = value
}

z_in :: proc(zcontext: rawptr, address: z.zuint16) -> z.zuint8 {
	//app := z_get_app(zcontext)
	port := address & 0xFF
	value: z.zuint8 = 0
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

z_out :: proc(zcontext: rawptr, address: z.zuint16, value: z.zuint8) {
	app := z_get_app(zcontext)
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
		//fmt.printf("out[0x%2X]=0x%2X %v", port, value, app)
		fmt.printf("out[0x%2X]=0x%2X", port, value)
		if value >= 32 {fmt.printf(" '%v'", rune(value))}
		fmt.print("\n")
	}
}

z_halt :: proc(zcontext: rawptr, signal: z.zuint8) {
	app := z_get_app(zcontext)
	fmt.printf("\nhalt %d pc=%d\n", signal, app.cpu.pc)
	running = signal == 0
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

init_cpu :: proc (z80: ^Z80) {
	z80.fetch_opcode = z_fetch_opcode
	z80.fetch        = z_fetch
	z80.read         = z_read
	z80.write        = z_write
	z80.in_          = z_in
	z80.out          = z_out
	z80.halt         = z_halt
}
