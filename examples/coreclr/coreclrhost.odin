package example_coreclr

import _c "core:c"
import "core:os"
import "core:fmt"
import "core:runtime"
import clr "vendor:coreclr"

trusted_platform_assemblies: string = #load("trusted_platform_assemblies.txt")

print_if_error :: proc(hr: clr.error, loc := #caller_location) {
	if hr != .ok {fmt.printf("Error %v (0x%X8) @ %v\n", hr, u32(hr), loc)}
}
pie :: print_if_error

event_callback :: proc(ch: ^clr.clr_host, type: clr.event_type, hr: clr.error) {
	fmt.printf("[%v] %v (%p,%p)\n", type, hr, ch.host, ch.hostHandle)
}

create_gateway_delegates :: proc(host: ^clr.clr_host, gateway: ^Gateway) {
	an :: "gateway"
	tn :: "Gateway"
	pie(clr.create_delegate(host, an, tn, "Bootstrap", &gateway.Bootstrap))
	pie(clr.create_delegate(host, an, tn, "Plus", &gateway.Plus))
	pie(clr.create_delegate(host, an, tn, "Sum", &gateway.Sum))
	pie(clr.create_delegate(host, an, tn, "Sum2", &gateway.Sum2))
	pie(clr.create_delegate(host, an, tn, "ManagedDirectMethod", &gateway.ManagedDirectMethod))
}

unmanaged_callback :: proc "c" (actionName: cstring, jsonArgs: cstring) -> _c.bool {
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

execute_clr_host :: proc() {
	host: clr.clr_host = {event_cb = event_callback}

	hr := clr.load_coreclr_library(&host)
	if hr != .ok {fmt.print("Unable to load coreclr library.\n");return}
	defer clr.unload_coreclr_library(&host)

	hr = clr.initialize(&host, trusted_platform_assemblies)
	if hr != .ok {fmt.print("Unable to initialize coreclr host.\n");return}
	defer clr.coreclr_shutdown(&host)

	gateway: Gateway = {}
	create_gateway_delegates(&host, &gateway)

	call_csharp(&gateway)
}

main :: proc() {
	fmt.print(" -=< CoreCLR Host Demo >=- \n")
	execute_clr_host()
	fmt.print("Done.\n")
	os.exit(int(0))
}
