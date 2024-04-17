// +vet
package main

import "core:fmt"
import fp "core:path/filepath"
import "core:intrinsics"
import a "libs:amstrad"
import win32 "core:sys/windows"

ROM_PATH := fp.clean("../data/z80/")
AMSTRAD_PATH := fp.clean("../examples/amstrad/data/")

application :: struct {
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
papp :: ^application

main :: proc() {
	fmt.print("Amstrad\n")

	snapshot_path := fp.join({AMSTRAD_PATH, "pinup.sna"}, allocator = context.temp_allocator)
	fmt.printfln("reading %s", snapshot_path)
	ss: snapshot
	//ram: bank64kb
	err := a.load_snapshot(snapshot_path, &ss, memory[:])
	assert(err == 0)

	rom_path := fp.join({ROM_PATH, "hello.rom"}, allocator = context.temp_allocator)
	load_rom(rom_path)

	cpu: Z80
	init_cpu(&cpu)
	app: application = {
		size = {WIDTH, HEIGHT * HEIGHT_SCALE},
		cpu = &cpu,
	}
	cpu.context_ = &app

	//z.z80_power(&cpu, true)

	// cpu.pc = ss.PC
	// cpu.sp = ss.SP
	// fmt.printf("CPU %v\n", cpu)

	running = true
	run_app(&app)

	fmt.printf("total %v (%v)\n", total, reps)
	//print_info()

	fmt.println("Done.")
}
