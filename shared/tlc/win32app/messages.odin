#+build windows
#+vet
package win32app

import win32 "core:sys/windows"

decode_lparam_as_int2 :: #force_inline proc "contextless" (lparam: LPARAM) -> int2 {
	return {win32.GET_X_LPARAM(lparam), win32.GET_Y_LPARAM(lparam)}
}

decode_lparam_as_rect :: #force_inline proc "contextless" (lparam: LPARAM) -> ^RECT {
	return (^RECT)(uintptr(lparam))
}

decode_wparam_as_mouse_key_state :: #force_inline proc "contextless" (wparam: WPARAM) -> MOUSE_KEY_STATE {
	return transmute(MOUSE_KEY_STATE)DWORD(wparam)
}

decode_wm_size_params :: #force_inline proc "contextless" (wparam: WPARAM, lparam: LPARAM) -> (type: WM_SIZE_WPARAM, size: int2) {
	return WM_SIZE_WPARAM(wparam), decode_lparam_as_int2(lparam)
}

decode_lparam_as_createstruct :: #force_inline proc "contextless" (lparam: LPARAM) -> ^CREATESTRUCTW {
	return (^CREATESTRUCTW)(rawptr(uintptr(lparam)))
}

MAKELRESULT_FROM_LOHI :: #force_inline proc "contextless" (#any_int l, h: int) -> LRESULT {
	return win32.LRESULT(win32.MAKELONG(l, h))
}

MAKELRESULT_FROM_BOOL :: #force_inline proc "contextless" (result: BOOL) -> LRESULT {
	return win32.LRESULT(transmute(i32)result)
}

MAKELRESULT :: proc {
	MAKELRESULT_FROM_LOHI,
	MAKELRESULT_FROM_BOOL,
}

GET_RAWINPUT_CODE_WPARAM :: win32.GET_RAWINPUT_CODE_WPARAM

HRESULT :: win32.HRESULT
HRESULT_DETAILS :: win32.HRESULT_DETAILS
FACILITY :: win32.FACILITY
SEVERITY :: win32.SEVERITY
ERROR_SUCCESS :: win32.ERROR_SUCCESS

SUCCEEDED :: win32.SUCCEEDED
FAILED :: win32.FAILED
IS_ERROR :: win32.IS_ERROR
HRESULT_CODE :: win32.HRESULT_CODE
HRESULT_SEVERITY :: win32.HRESULT_SEVERITY
HRESULT_FACILITY :: win32.HRESULT_FACILITY
MAKE_HRESULT :: win32.MAKE_HRESULT
//DECODE_HRESULT :: win32.DECODE_HRESULT
