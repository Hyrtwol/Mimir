package win32app

import       "core:fmt"
import       "core:intrinsics"
import       "core:math/linalg"
import hlm   "core:math/linalg/hlsl"
import       "core:runtime"
import       "core:strings"
import win32 "core:sys/windows"

L :: intrinsics.constant_utf16_cstring


LRESULT_FALSE : win32.LRESULT : 0
LRESULT_TRUE  : win32.LRESULT : 1

// how to cast TRUE to LRESULT ?
MAKELRESULT :: proc(result: win32.BOOL) -> win32.LRESULT {
    return LRESULT_TRUE if result else LRESULT_FALSE
}

/*
thought i should remap the win32 calls but didn't find all mappings so will stick with W for now
also note sure how to "map" the string constants without alot of when's :p
maybe i'll try again when i learned a bit more odin...

USE_ANSI :: false
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
*/
