// +build windows
package win32app

import       "core:fmt"
import       "core:intrinsics"
import       "core:math/linalg"
import hlm   "core:math/linalg/hlsl"
import       "core:runtime"
import       "core:strings"
import win32 "core:sys/windows"

BYTE :: win32.BYTE
BOOL :: win32.BOOL
WORD :: win32.WORD
LONG :: win32.LONG
UINT :: win32.UINT
DWORD :: win32.DWORD
WCHAR :: win32.WCHAR
DWORD_PTR :: win32.DWORD_PTR
UINT_PTR :: win32.UINT_PTR

LPVOID :: win32.LPVOID
LPCVOID :: win32.LPCVOID
LPUINT :: win32.LPUINT
LPSTR :: win32.LPSTR
LPCSTR :: win32.LPCSTR
LPWSTR :: win32.LPWSTR
LPCWSTR :: win32.LPCWSTR
LPDWORD :: win32.LPDWORD
LPRECT :: win32.LPRECT

HANDLE :: win32.HANDLE
HMODULE :: win32.HMODULE
HINSTANCE :: win32.HINSTANCE
HWND :: win32.HWND
HDC :: win32.HDC
HRGN :: win32.HRGN

LPARAM :: win32.LPARAM
LRESULT :: win32.LRESULT

RECT :: win32.RECT
MMRESULT :: win32.MMRESULT
WAVERR_BASE :: win32.WAVERR_BASE

c_int :: win32.c_int

byte4 :: distinct [4]u8
int2  :: hlm.int2
ZERO2 : int2 : {0, 0}

L :: intrinsics.constant_utf16_cstring

// #define MAKEWORD(a, b)      ((WORD)(((BYTE)(((DWORD_PTR)(a)) & 0xff)) | ((WORD)((BYTE)(((DWORD_PTR)(b)) & 0xff))) << 8))
MAKE_WORD :: win32.MAKE_WORD
// #define MAKELONG(a, b)      ((LONG)(((WORD)(((DWORD_PTR)(a)) & 0xffff)) | ((DWORD)((WORD)(((DWORD_PTR)(b)) & 0xffff))) << 16))
// #define LOWORD(l)           ((WORD)(((DWORD_PTR)(l)) & 0xffff))
LOWORD :: win32.LOWORD
// #define HIWORD(l)           ((WORD)((((DWORD_PTR)(l)) >> 16) & 0xffff))
HIWORD :: win32.HIWORD
// #define LOBYTE(w)           ((BYTE)(((DWORD_PTR)(w)) & 0xff))
// #define HIBYTE(w)           ((BYTE)((((DWORD_PTR)(w)) >> 8) & 0xff))

// #define POINTTOPOINTS(pt)      (MAKELONG((short)((pt).x), (short)((pt).y)))
// #define MAKEWPARAM(l, h)      ((WPARAM)(DWORD)MAKELONG(l, h))
// #define MAKELPARAM(l, h)      ((LPARAM)(DWORD)MAKELONG(l, h))
// #define MAKELRESULT(l, h)     ((LRESULT)(DWORD)MAKELONG(l, h))

MAKELRESULT :: #force_inline proc "contextless" (result: BOOL) -> LRESULT {
	return cast(LRESULT)transmute(i32)result
}

// #define GET_X_LPARAM(lp)                        ((int)(short)LOWORD(lp))
// #define GET_Y_LPARAM(lp)                        ((int)(short)HIWORD(lp))

GET_X_LPARAM :: win32.GET_X_LPARAM
GET_Y_LPARAM :: win32.GET_Y_LPARAM

GET_XY_LPARAM :: #force_inline proc "contextless" (lparam: LPARAM) -> int2 {
	return int2({GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)})
}
