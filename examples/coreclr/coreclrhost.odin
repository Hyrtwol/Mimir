package main

import "core:fmt"
import "core:os"
import "core:time"
import clr "vendor:coreclr"

trusted_platform_assemblies: string = #load("trusted_platform_assemblies.txt")

bootstrap :: #type proc "c" () -> cstring
plus_proc :: #type proc "c" (x: f64, y: f64) -> f64

// see gateway.cs
gateway :: struct {
	bootstrap : #type proc "c" () -> cstring,
    plus : #type proc "c" (x: f64, y: f64) -> f64,
}

main :: proc() {
	host := clr.load_coreclr_library()
	assert(host != nil, "load_coreclr_library failure")
	defer
	fmt.print("initialize\n")
	hr := clr.initialize(host, trusted_platform_assemblies)
	assert(hr == 0, fmt.tprintf("initialize (%v)", hr))
	fmt.printf("host=%v\n", host)
	fmt.printf("hostHandle=%v domainId=%v\n", host.hostHandle, host.domainId)

	//delegate: rawptr = nil
	//delegate, hr = clr.create_delegate_2(host, "gateway", "Gateway", entryPointMethodName)
	{
		entryPointMethodName: cstring = "Plus"
		plus: plus_proc
		hr = clr.create_delegate_3(host, "gateway", "Gateway", entryPointMethodName, &plus)
		//assert(hr == 0, fmt.tprintf("create_delegate (%v)", hr))
		fmt.printf("calling %v\n", plus)
		if (plus != nil) {
			q := plus(13, 27)
			fmt.printf("plus=%v\n", q)
		} else {
			fmt.printf("no delegate found for %v\n", entryPointMethodName)
		}
	}
	{
		entryPointMethodName: cstring = "Bootstrap"
		bootstrap: bootstrap
		hr = clr.create_delegate_3(host, "gateway", "Gateway", entryPointMethodName, &bootstrap)
		fmt.printf("calling %v\n", bootstrap)
		if (bootstrap != nil) {
			q := bootstrap()
			fmt.printf("bootstrap=%v\n", q)
		} else {
			fmt.printf("no delegate found for %v\n", entryPointMethodName)
		}
	}

	fmt.print("shutdown\n")
	hr = clr.coreclr_shutdown(host)
	if hr != 0 {fmt.printf("shutdown error %v\n", hr)}
	hr = clr.unload_coreclr_library(host)
	if hr != 0 {fmt.printf("unload error %v\n", hr)}
	fmt.print("done.\n")
}

/*
// typedef bool (*unmanaged_callback_ptr)(const char* actionName, const char* jsonArgs);
unmanaged_callback_ptr :: #type proc "c" (actionName: cstring, jsonArgs: cstring) -> _c.bool

// typedef char* (*managed_direct_method_ptr)(const char* actionName, const char* jsonArgs, unmanaged_callback_ptr unmanagedCallback);
managed_direct_method_ptr :: #type proc "c" (
	actionName: cstring,
	jsonArgs: cstring,
	unmanagedCallback: unmanaged_callback_ptr,
) -> ^_c.char
*/
