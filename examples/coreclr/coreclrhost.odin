package example_coreclr

import "core:os"
import "core:fmt"
import "core:runtime"
import "core:strings"
import "core:path/filepath"
import clr "vendor:coreclr"


CORECLR_DIR :: "C:\\Program Files\\dotnet\\shared\\Microsoft.NETCore.App\\8.0.2"

trusted_platform_assemblies: string

trusted_platform_assemblies = string(#load("trusted_platform_assemblies.txt"))

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

	f:= gateway.Plus(13, 27)
	fmt.printf("Plus=%v\n", f)

	s := gateway.Bootstrap()
	fmt.printf("Bootstrap=%v\n", s)

	fmt.print("ManagedDirectMethod\n")
	ok := gateway.ManagedDirectMethod("funky", "json doc", unmanaged_callback)
	fmt.printf("Result: '%v'\n", ok)
}

execute_clr_host :: proc() -> clr.error {
	host: clr.clr_host = {event_cb = event_callback}

	// Prepare the coreclr lib
	clr.load_coreclr_library(&host, CORECLR_DIR) or_return
	defer clr.unload_coreclr_library(&host)

	// Prepare the coreclr host
	clr.initialize(&host, CORECLR_DIR, "SampleHost", string(trusted_platform_assemblies)) or_return
	defer clr.shutdown(&host)

	// Prepare the delegates for calling C#
	gateway: Gateway = {}
	create_gateway_delegates(&host, &gateway) or_return

	call_csharp(&gateway)

	return .ok
}

main :: proc() {
	fmt.print(" -=< CoreCLR Host Demo >=- \n")

	path := CORECLR_DIR

	pkg_path, pkg_path_ok := filepath.abs(path)
	if !pkg_path_ok {
		return
	}

	path_pattern := fmt.tprintf("%s/*.dll", pkg_path)
	matches, err := filepath.glob(path_pattern)
	defer delete(matches)

	if err != nil {
		fmt.printf("Oh no %v\n", err)
		return
	}

	tpa := strings.join(matches, ";")
	fmt.print(tpa)


	/*
	hr := execute_clr_host()
	fmt.printf("exit %v\n", hr)
	os.exit(int(hr))
	*/
}
