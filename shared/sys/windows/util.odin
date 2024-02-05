// +build windows
package sys_windows_ex

import "base:runtime"
import "base:intrinsics"
import win32 "core:sys/windows"

L :: intrinsics.constant_utf16_cstring

LOWORD :: win32.LOWORD
HIWORD :: win32.HIWORD
GET_X_LPARAM :: win32.GET_X_LPARAM
GET_Y_LPARAM :: win32.GET_Y_LPARAM
MAKE_WORD :: win32.MAKE_WORD

// #define MAKELONG(a, b)    ((LONG)(((WORD)(((DWORD_PTR)(a)) & 0xffff)) | ((DWORD)((WORD)(((DWORD_PTR)(b)) & 0xffff))) << 16))
MAKELONG :: #force_inline proc "contextless" (a, b: INT) -> LONG {
	return LONG( (a & 0xffff) | (( b & 0xffff ) << 16 ) )
}

// #define LOBYTE(w)         ((BYTE)(((DWORD_PTR)(w)) & 0xff))
LOBYTE :: #force_inline proc "contextless" (x: WORD) -> BYTE {
	return BYTE(x & 0xff)
}

// #define HIBYTE(w)         ((BYTE)((((DWORD_PTR)(w)) >> 8) & 0xff))
HIBYTE :: #force_inline proc "contextless" (x: WORD) -> BYTE {
	return BYTE(x >> 8)
}

// #define POINTTOPOINTS(pt) (MAKELONG((short)((pt).x), (short)((pt).y)))

// #define MAKEWPARAM(l, h)  ((WPARAM)(DWORD)MAKELONG(l, h))
MAKEWPARAM :: #force_inline proc "contextless" (l, h: INT) -> WPARAM {
	return cast(WPARAM)MAKELONG(l, h)
}
// #define MAKELPARAM(l, h)  ((LPARAM)(DWORD)MAKELONG(l, h))
MAKELPARAM :: #force_inline proc "contextless" (l, h: INT) -> LPARAM {
	return cast(LPARAM)MAKELONG(l, h)
}
// #define MAKELRESULT(l, h) ((LRESULT)(DWORD)MAKELONG(l, h))
MAKELRESULT_FROM_LOHI :: #force_inline proc "contextless" (l, h: INT) -> LRESULT {
	return cast(LRESULT)MAKELONG(l, h)
}

MAKELRESULT_FROM_BOOL :: #force_inline proc "contextless" (result: BOOL) -> LRESULT {
	return cast(LRESULT)transmute(i32)result
}

MAKELRESULT :: proc{
	MAKELRESULT_FROM_LOHI,
	MAKELRESULT_FROM_BOOL,
}
