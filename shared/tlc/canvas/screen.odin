package canvas

import       "core:fmt"
import       "core:intrinsics"
import       "core:math/linalg"
import hlm   "core:math/linalg/hlsl"
import       "core:runtime"
import       "core:strings"
import win32 "core:sys/windows"

screenbuffer :: [^]byte4

fill_screen :: proc(p: screenbuffer, count: i32, col: byte4) {
    for i in 0..<count {
        p[i] = col
    }
}
