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
