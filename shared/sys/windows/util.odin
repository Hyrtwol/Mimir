#+build windows
package sys_windows_ex

//import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import win32 "core:sys/windows"

LOWORD :: win32.LOWORD
HIWORD :: win32.HIWORD
LOBYTE :: win32.LOBYTE
HIBYTE :: win32.HIBYTE
MAKEWORD :: win32.MAKEWORD
MAKELONG :: win32.MAKELONG
MAKELRESULT :: win32.MAKELRESULT
MAKEWPARAM :: win32.MAKEWPARAM
MAKELPARAM :: win32.MAKELPARAM
GET_X_LPARAM :: win32.GET_X_LPARAM
GET_Y_LPARAM :: win32.GET_Y_LPARAM
/*
#define MAKELONG(a, b)    ((LONG)(((WORD)(((DWORD_PTR)(a)) & 0xffff)) | ((DWORD)((WORD)(((DWORD_PTR)(b)) & 0xffff))) << 16))
MAKELONG :: #force_inline proc "contextless" (a, b: INT) -> LONG {
	return LONG((a & 0xffff) | ((b & 0xffff) << 16))
}

// #define LOBYTE(w)         ((BYTE)(((DWORD_PTR)(w)) & 0xff))
LOBYTE :: #force_inline proc "contextless" (w: WORD) -> BYTE {
	return BYTE(w & 0xff)
}

// #define HIBYTE(w)         ((BYTE)((((DWORD_PTR)(w)) >> 8) & 0xff))
HIBYTE :: #force_inline proc "contextless" (w: WORD) -> BYTE {
	return BYTE(w >> 8)
}

#define POINTTOPOINTS(pt) (MAKELONG((short)((pt).x), (short)((pt).y)))

// #define MAKEWPARAM(l, h)  ((WPARAM)(DWORD)MAKELONG(l, h))
MAKEWPARAM :: #force_inline proc "contextless" (l, h: INT) -> WPARAM {
	return WPARAM(MAKELONG(l, h))
}
// #define MAKELPARAM(l, h)  ((LPARAM)(DWORD)MAKELONG(l, h))
MAKELPARAM :: #force_inline proc "contextless" (l, h: INT) -> LPARAM {
	return LPARAM(MAKELONG(l, h))
}

MAKELRESULT_FROM_LOHI :: #force_inline proc "contextless" (l, h: INT) -> LRESULT {
	return LRESULT(MAKELONG(l, h))
}

MAKELRESULT_FROM_BOOL :: #force_inline proc "contextless" (result: BOOL) -> LRESULT {
	return LRESULT(transmute(i32)result)
}

MAKELRESULT :: proc {
	MAKELRESULT_FROM_LOHI,
	MAKELRESULT_FROM_BOOL,
}

tprintf :: proc(fmt: string, args: ..any) -> string {
	str: strings.Builder
	strings.builder_init(&str, context.temp_allocator)
	sbprintf(&str, fmt, ..args)
	return strings.to_string(str)
}

utf8_to_wstring :: proc(s: string, allocator := context.temp_allocator) -> wstring {
	if res := utf8_to_utf16(s, allocator); res != nil {
		return &res[0]
	}
	return nil
}

ctprintf :: proc(format: string, args: ..any, newline := false) -> cstring {
	str: strings.Builder
	strings.builder_init(&str, context.temp_allocator)
	sbprintf(&str, format, ..args, newline=newline)
	strings.write_byte(&str, 0)
	s := strings.to_string(str)
	return cstring(raw_data(s))
}

str  := fmt.tprintf(format, args)
cstr := fmt.ctprintf(format, args)
wstr := fmt.wtprintf(format, args) ? clashes with fmt.wprintf() a bit :/
*/

/*
wtprintf :: proc(format: string, args: ..any, allocator := context.temp_allocator) -> win32.wstring {
	// str: strings.Builder
	// strings.builder_init(&str, context.temp_allocator)
	// sbprintf(&str, format, ..args)
	// strings.write_byte(&str, 0)
	// s := strings.to_string(str)
	// return cstring(raw_data(s))

	str := fmt.tprintf(format, args)
	return win32.utf8_to_wstring(str)
}
*/
