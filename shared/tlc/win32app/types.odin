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
LRESULT :: win32.LRESULT

HWND :: win32.HWND
HDC :: win32.HDC
HANDLE :: win32.HANDLE
HRGN :: win32.HRGN

MMRESULT :: win32.MMRESULT
WAVERR_BASE :: win32.WAVERR_BASE

c_int :: win32.c_int

byte4 :: distinct [4]u8
int2  :: hlm.int2
ZERO2 : int2 : {0, 0}

L :: intrinsics.constant_utf16_cstring

MAKELRESULT :: proc(result: BOOL) -> LRESULT {
	return cast(LRESULT)transmute(i32)result
}
