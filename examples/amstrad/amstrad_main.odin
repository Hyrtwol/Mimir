#+vet
package main

import "base:intrinsics"
import "core:fmt"
import "core:os"
import fp "core:path/filepath"
import win32 "core:sys/windows"
import a "libs:amstrad"
import "libs:tlc/win32app"
import "shared:obug"

ROM_PATH := fp.clean("../data/z80/")
AMSTRAD_PATH := fp.clean("../examples/amstrad/data/")

application :: struct {
	#subtype settings: win32app.window_settings,
	pause:    bool,
	//colors:    []color,
	//screen_size:     int2,
	timer_id: win32.UINT_PTR,
	tick:     u32,
	//title:     wstring,
	hbitmap:  win32.HBITMAP,
	pvBits:   screen_buffer,
	cpu:      ^Z80,
}
papp :: ^application

run :: proc() {
	fmt.println("Amstrad")

	cpu: Z80
	init_cpu(&cpu)
	app: application = {
		settings = win32app.create_window_settings(TITLE, WIDTH, HEIGHT * SCREEN_HEIGHT_SCALE, wndproc),
		//screen_size = {WIDTH, HEIGHT * SCREEN_HEIGHT_SCALE},
		cpu = &cpu,
	}
	cpu.context_ = &app

	//z.z80_power(&cpu, true)

	snapshot_path := fp.join({AMSTRAD_PATH, "pinup.sna"}, allocator = context.temp_allocator)
	fmt.printfln("loading snapshot %s", snapshot_path)
	ss: snapshot
	err := a.load_snapshot(snapshot_path, &ss, memory[:])
	assert(err == os.ERROR_NONE)

	// cpu.pc = ss.PC
	// cpu.sp = ss.SP
	// fmt.printfln("CPU %v", cpu)

	rom_path := fp.join({ROM_PATH, "hello.rom"}, allocator = context.temp_allocator)
	load_rom(rom_path)

	running = true
	run_app(&app)

	//fmt.printfln("app %#v", app)
	fmt.printfln("total %v (%v)", total, reps)

	fmt.println("Done.")
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		obug.exit(obug.tracked_run(run))
	} else {
		run()
	}
}
