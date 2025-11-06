#+vet
package main

import "base:intrinsics"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import win32 "core:sys/windows"
import a "libs:amstrad"
import owin "libs:tlc/win32app"
import "shared:obug"

ROM_PATH : string
AMSTRAD_PATH : string

application :: struct {
	#subtype settings: owin.window_settings,
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

run :: proc() -> (exit_code: int) {
	fmt.println("Amstrad")

	cpu: Z80
	init_cpu(&cpu)
	app: application = {
		settings = owin.window_settings {
			options = {.Center},
			dwStyle = owin.DEFAULT_WS_STYLE,
			dwExStyle = owin.DEFAULT_WS_EX_STYLE,
			sleep = owin.DEFAULT_SLEEP,
			window_size = {WIDTH, HEIGHT * SCREEN_HEIGHT_SCALE},
			wndproc = wndproc,
			title = TITLE,
		},
		cpu = &cpu,
	}
	cpu.context_ = &app

	//z.z80_power(&cpu, true)

	snapshot_path := filepath.join({AMSTRAD_PATH, "pinup.sna"}, allocator = context.temp_allocator)
	fmt.printfln("loading snapshot %s", snapshot_path)
	ss: snapshot
	err := a.load_snapshot(snapshot_path, &ss, memory[:])
	assert(err == os.ERROR_NONE)

	// cpu.pc = ss.PC
	// cpu.sp = ss.SP
	// fmt.printfln("CPU %v", cpu)

	rom_path := filepath.join({ROM_PATH, "hello.rom"}, allocator = context.temp_allocator)
	load_rom(rom_path)

	running = true
	exit_code = run_app(&app)

	//fmt.printfln("app %#v", app)
	fmt.printfln("total %v (%v)", total, reps)

	fmt.println("Done.")
	return
}

main :: proc() {
	ROM_PATH = filepath.clean("../data/z80/") or_else panic("filepath.clean")
	AMSTRAD_PATH = filepath.clean("../examples/amstrad/data/") or_else panic("filepath.clean")
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}
