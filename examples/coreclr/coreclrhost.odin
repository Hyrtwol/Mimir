package example_coreclr

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:runtime"
import "core:strings"
import clr "vendor:coreclr"

//trusted_platform_assemblies := string(#load("trusted_platform_assemblies.txt"))

CORECLR_DIR :: "C:\\Program Files\\dotnet\\shared\\Microsoft.NETCore.App\\8.0.2"

print_if_error :: proc(hr: clr.error, loc := #caller_location) {
	if hr != .ok {fmt.printf("Error %v (0x%X8) @ %v\n", hr, u32(hr), loc)}
}

event_callback :: proc(ch: ^clr.clr_host, type: clr.event_type, hr: clr.error) {
	fmt.printf("[%v] %v (%p,%p)\n", type, hr, ch.host, ch.hostHandle)
}

create_gateway_delegates :: proc(host: ^clr.clr_host, gateway: ^Gateway) -> (res: clr.error) {
	an :: "gateway"
	tn :: "Gateway"
	print_if_error(clr.create_delegate(host, an, tn, "Bootstrap", &gateway.Bootstrap))
	print_if_error(clr.create_delegate(host, an, tn, "Plus", &gateway.Plus))
	print_if_error(clr.create_delegate(host, an, tn, "Sum", &gateway.Sum))
	print_if_error(clr.create_delegate(host, an, tn, "Sum2", &gateway.Sum2))
	print_if_error(clr.create_delegate(host, an, tn, "ManagedDirectMethod", &gateway.ManagedDirectMethod))
	return .ok
}

unmanaged_callback :: proc "c" (actionName: cstring, jsonArgs: cstring) -> bool {
	context = runtime.default_context()
	fmt.printf("Odin>> %s, %v\n", actionName, jsonArgs)
	return true
}

call_csharp :: proc(gateway: ^Gateway) {

	f := gateway.Plus(13, 27)
	fmt.printf("Plus=%v\n", f)

	s := gateway.Bootstrap()
	fmt.printf("Bootstrap=%v\n", s)

	fmt.print("ManagedDirectMethod\n")
	ok := gateway.ManagedDirectMethod("funky", "json doc", unmanaged_callback)
	fmt.printf("Result: '%v'\n", ok)
}

execute_clr_host :: proc(tpa: string) -> clr.error {
	host: clr.clr_host = {
		event_cb = event_callback,
	}

	// Prepare the coreclr lib
	clr.load_coreclr_library(&host, CORECLR_DIR) or_return
	defer clr.unload_coreclr_library(&host)

	// Prepare the coreclr host
	clr.initialize(&host, CORECLR_DIR, "SampleHost", tpa) or_return
	defer clr.shutdown(&host)

	// Prepare the delegates for calling C#
	gateway: Gateway = {}
	create_gateway_delegates(&host, &gateway) or_return

	call_csharp(&gateway)

	return .ok
}

asm_scan :: proc(totmatches: ^[dynamic]string, path: string, pattern: string = "*.dll") {
	pkg_path, pkg_path_ok := filepath.abs(path)
	if !pkg_path_ok {return}
	path_pattern := filepath.join({pkg_path, pattern}, context.temp_allocator)
	matches, err := filepath.glob(path_pattern, context.temp_allocator)
	if err != .None {return}
	append_elems(totmatches, ..matches)
}

get_list_separator :: proc() -> string {
	b, n := runtime.encode_rune(filepath.LIST_SEPARATOR)
	return string(b[:n])
}

write_tpa :: proc(tpa_path: string, assemblies: []string) {
	path, ok := filepath.abs(tpa_path)
	if ok {
		txt := strings.join(assemblies[:], "\n")
		fmt.printfln("tpa_path: %s", path)
		fd, err := os.open(path, os.O_CREATE | os.O_WRONLY)
		if err != 0 {return}
		defer os.close(fd)
		for assembly in assemblies {
			os.write_string(fd, assembly)
			os.write_string(fd, "\n")
		}
	}
}

create_tpa :: proc(path: string) -> string {
	assemblies := make([dynamic]string, 0, 200)
	defer delete(assemblies)
	asm_scan(&assemblies, CORECLR_DIR)
	asm_scan(&assemblies, "../examples/coreclr")
	write_tpa("tpa.txt", assemblies[:])
	return strings.join(assemblies[:], get_list_separator())
}

main :: proc() {
	fmt.print(" -=< CoreCLR Host Demo >=- \n")
	tpa := create_tpa("../examples/coreclr")
	hr := execute_clr_host(tpa)
	fmt.printfln("exit %v\n", hr)
	os.exit(int(hr))
}
