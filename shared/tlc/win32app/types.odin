package win32app

import       "core:fmt"
import       "core:intrinsics"
import       "core:math/linalg"
import hlm   "core:math/linalg/hlsl"
import       "core:runtime"
import       "core:strings"
import win32 "core:sys/windows"

BYTE :: win32.BYTE
WORD :: win32.WORD
LONG :: win32.LONG
LPVOID :: win32.LPVOID
LPCVOID :: win32.LPCVOID
UINT :: win32.UINT
UINT_PTR :: win32.UINT_PTR
LPUINT :: win32.LPUINT
LPWSTR :: win32.LPWSTR
LPDWORD :: win32.LPDWORD
DWORD :: win32.DWORD
DWORD_PTR :: win32.DWORD_PTR
WCHAR :: win32.WCHAR
MMRESULT :: win32.MMRESULT
WAVERR_BASE :: win32.WAVERR_BASE
HANDLE :: win32.HANDLE

byte4 :: distinct [4]u8
int2  :: hlm.int2
ZERO2 : int2 : {0, 0}
