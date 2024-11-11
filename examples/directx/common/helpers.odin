package directx_common

import "core:fmt"
import win32 "core:sys/windows"

// TODO rename to pif
panic_if_failed :: proc(res: win32.HRESULT, message: string = #caller_expression(res), loc := #caller_location) {
	if win32.SUCCEEDED(res) {
		return
	}

	hr := win32.HRESULT_DETAILS(res)
	fmt.panicf("Error %v %v (0x%0x)\n\t%v\n\t%v", win32.System_Error(hr.Code), hr, u32(hr), message, loc)
}
