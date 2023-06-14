package win32app

import       "core:fmt"
import       "core:intrinsics"
import       "core:math/linalg"
import hlm   "core:math/linalg/hlsl"
import       "core:runtime"
import       "core:strings"
import win32 "core:sys/windows"

byte4 :: distinct [4]u8
int2  :: hlm.int2
ZERO2 : int2 : {0, 0}
