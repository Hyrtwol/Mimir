// +vet
package main

import "core:fmt"
import "core:intrinsics"
import "core:os"
import "core:runtime"
import win32 "core:sys/windows"
// import canvas "shared:tlc/canvas"
// import win32app "shared:tlc/win32app"
import z80 "shared:z80"
import z80m "shared:z80/amstrad"

Z80 :: z80.Z80

cycles_per_tick :: 100
mem_size :: 0x10000
memory: [mem_size]u8
running: bool = false
put_chars: bool = false

size_16kb :: z80m.size_16kb
mask_16kb :: z80m.mask_16kb
size_64kb :: z80m.size_64kb

//p_image := #load("data/mode2.raw")
p_image := #load("data/pinup.raw")
/*
foreign import mode2 "data/mode2.asm"
//foreign import mode2 "data/pinup2.asm"
foreign mode2 {imagedata: [16000]u8}
p_image := imagedata
*/

app :: struct {
	pause:    bool,
	//colors:    []color,
	size:     int2,
	timer_id: win32.UINT_PTR,
	tick:     u32,
	//title:     wstring,
	hbitmap:  win32.HBITMAP,
	pvBits:   screen_buffer,
	cpu: ^Z80,
}
papp :: ^app

/*
https://www.chibiakumas.com/z80/AmstradCPC.php
https://neuro-sys.github.io/2019/10/01/amstrad-cpc-crtc.html
*/

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
		fmt.printf("in[0x%2X]=0x%2X", port, value)
		if value >= 32 {fmt.printf(" '%v'", rune(value))}
		fmt.println()
	}
	return value
}

z_out :: proc(zcontext: rawptr, address: z80.zuint16, value: z80.zuint8) {
	app := papp(zcontext)
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
		fmt.printf("out[0x%2X]=0x%2X %v", port, value, app)
		if value >= 32 {fmt.printf(" '%v'", rune(value))}
		fmt.print("\n")
	}
}

z_halt :: proc(zcontext: rawptr, signal: z80.zuint8) {
	app := papp(zcontext)
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

print_info :: proc() {
	fmt.printfln("color_bits             =%v", color_bits)
	fmt.printfln("palette_count          =%v", palette_count)
	fmt.printfln("len(color_palette)     =%v", len(color_palette))
	fmt.printfln("size_of(color)         =%v", size_of(color))
	fmt.printfln("size_of(color_palette) =%v", size_of(color_palette))
	fmt.printfln("screen_pixel_count     =%v", screen_pixel_count)
	fmt.printfln("screen_byte_count      =%v", screen_byte_count)
}

total: z80.zusize = 0
reps := 0

main :: proc() {
	fmt.print("Amstrad\n")

	sanpshot_path := filepath.clean("examples/amstrad/data/pinup.sna", context.temp_allocator)
	fmt.printfln("reading %s", sanpshot_path)
	ss: am.snapshot
	ram: z80m.bank64kb
	err := am.load_snapshot(sanpshot_path, &ss, ram[:])

	rom_path :: "../data/z80/hello.rom"
	load_rom(rom_path)

	cpu: z80.Z80 = {
		fetch_opcode = z_fetch_opcode,
		fetch        = z_fetch,
		read         = z_read,
		write        = z_write,
		_in          = z_in,
		out          = z_out,
		halt         = z_halt,
	}

	app: app = {
		size = {WIDTH, HEIGHT * HEIGHT_SCALE},
		cpu = &cpu,
	}
	cpu._context = &app


	//z80.z80_power(&cpu, true)
	//fmt.printf("CPU %v\n", cpu)

	running = true
	// total: z80.zusize = 0
	// reps := 0
	// for running {
	// 	total += z80.z80_run(&cpu, cycles_per_tick)
	// 	reps += 1
	// }
	// fmt.printf("total %v (%v)\n", total, reps)

	run_app(&app)

	fmt.printf("total %v (%v)\n", total, reps)
	//print_info()

	fmt.println("Done.")
}
