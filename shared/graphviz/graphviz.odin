package graphviz

import "core:fmt"
import "core:os/os2"
import "core:path/filepath"
import "core:reflect"
import "core:time"
import "libs:tlc/win32app"

DOT_EXE :: "%GRAPHVIZ%\\dot.exe"

// https://stackoverflow.com/questions/14784405/how-to-set-the-output-size-in-graphviz-for-the-dot-format

output_formats :: enum {
	png,
	svg,
}

execute_dot :: proc(dot_path: string, output_file: string) {
	full_exe, err := win32app.expand_environment_strings(DOT_EXE)
	if err != 0 {fmt.panicf("expand_environment_strings error: %v", err)}

	ext := filepath.ext(output_file)
	if len(ext) > 0 && ext[0] == '.' {
		ext = ext[1:]
	}
	output_format, ok := reflect.enum_from_name(output_formats, ext)
	fmt.printfln("output_format: %v", output_format)
	if !ok {return}

	desc: os2.Process_Desc = {
		command = {
			full_exe,
			fmt.tprintf("-T%v", output_format),
			fmt.tprintf("-o%s", output_file),
			//"-Gsize=3,5\\!", "-Gdpi=200",
			//"-v",
			dot_path,
		},
	}

	fmt.printfln("process_start: %v", desc)
	process, e1 := os2.process_start(desc)
	if e1 != os2.ERROR_NONE {fmt.panicf("process_start error: %v", e1)}
	defer {
		fmt.printfln("process_close: %v", process)
		e3 := os2.process_close(process)
		if e3 != os2.ERROR_NONE {fmt.panicf("process_wait error: %v", e3)}
	}

	fmt.printfln("process_wait: %v", process)
	process_state, e2 := os2.process_wait(process, time.Second * 5)
	if e2 != os2.ERROR_NONE {fmt.printfln("process_wait error: %v", e2);return}
	fmt.printfln("process_wait result: %v", process_state)
}
