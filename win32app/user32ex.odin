package user32ex

import "core:fmt"
import "core:intrinsics"
import "core:math/linalg"
import "core:runtime"
import "core:strings"
import win32 "core:sys/windows"

L :: intrinsics.constant_utf16_cstring

USE_ANSI :: false

MAKELRESULT :: proc(result: win32.BOOL) -> win32.LRESULT {
    return 1 if result else 0
}

// how to cast TRUE to LRESULT ?
// win32.FALSE win32.TRUE
LRESULT_FALSE : win32.LRESULT : 0
LRESULT_TRUE  : win32.LRESULT : 1

foreign import user32 "system:User32.lib"
@(default_calling_convention="stdcall") // not sure if stdcall here is scoped to foreign only? moved it inline for now.
foreign user32 {
	DrawTextA :: proc "stdcall" (hDC: win32.HDC, lpchText: win32.LPCSTR, cchText: win32.c_int, lprc: win32.LPRECT, format: DrawTextFormat) -> win32.c_int ---
	DrawTextW :: proc "stdcall" (hDC: win32.HDC, lpchText: win32.LPCWSTR, cchText: win32.c_int, lprc: win32.LPRECT, format: DrawTextFormat) -> win32.c_int ---
}

when USE_ANSI {
    DefWindowProc :: win32.DefWindowProcA
    LoadIcon      :: win32.LoadIconA
    LoadCursor    :: win32.LoadCursorA
    DrawText      :: DrawTextA
}
else {
    DefWindowProc :: win32.DefWindowProcW
    LoadIcon      :: win32.LoadIconW
    LoadCursor    :: win32.LoadCursorW
    DrawText      :: DrawTextW
}

/*
DT_TOP                  :: 0x00000000
DT_LEFT                 :: 0x00000000
DT_CENTER               :: 0x00000001
DT_RIGHT                :: 0x00000002
DT_VCENTER              :: 0x00000004
DT_BOTTOM               :: 0x00000008
DT_WORDBREAK            :: 0x00000010
DT_SINGLELINE           :: 0x00000020
DT_EXPANDTABS           :: 0x00000040
DT_TABSTOP              :: 0x00000080
DT_NOCLIP               :: 0x00000100
DT_EXTERNALLEADING      :: 0x00000200
DT_CALCRECT             :: 0x00000400
DT_NOPREFIX             :: 0x00000800
DT_INTERNAL             :: 0x00001000
DT_EDITCONTROL          :: 0x00002000
DT_PATH_ELLIPSIS        :: 0x00004000
DT_END_ELLIPSIS         :: 0x00008000
DT_MODIFYSTRING         :: 0x00010000
DT_RTLREADING           :: 0x00020000
DT_WORD_ELLIPSIS        :: 0x00040000
DT_NOFULLWIDTHCHARBREAK :: 0x00080000
DT_HIDEPREFIX           :: 0x00100000
DT_PREFIXONLY           :: 0x00200000
*/

DrawTextFormat :: enum u32 {
    DT_TOP = 0x00000000,
    DT_LEFT = 0x00000000,
    DT_CENTER = 0x00000001,
    DT_RIGHT = 0x00000002,
    DT_VCENTER = 0x00000004,
    DT_BOTTOM = 0x00000008,
    DT_WORDBREAK = 0x00000010,
    DT_SINGLELINE = 0x00000020,
    DT_EXPANDTABS = 0x00000040,
    DT_TABSTOP = 0x00000080,
    DT_NOCLIP = 0x00000100,
    DT_EXTERNALLEADING = 0x00000200,
    DT_CALCRECT = 0x00000400,
    DT_NOPREFIX = 0x00000800,
    DT_INTERNAL = 0x00001000,
    DT_EDITCONTROL = 0x00002000,
    DT_PATH_ELLIPSIS = 0x00004000,
    DT_END_ELLIPSIS = 0x00008000,
    DT_MODIFYSTRING = 0x00010000,
    DT_RTLREADING = 0x00020000,
    DT_WORD_ELLIPSIS = 0x00040000,
    DT_NOFULLWIDTHCHARBREAK = 0x00080000,
    DT_HIDEPREFIX = 0x00100000,
    DT_PREFIXONLY = 0x00200000
}
