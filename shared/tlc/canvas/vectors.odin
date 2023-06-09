package canvas

import       "core:fmt"
import       "core:intrinsics"
import       "core:math/linalg"
import hlm   "core:math/linalg/hlsl"
import       "core:runtime"
import       "core:strings"
import win32 "core:sys/windows"

byte4    :: distinct [4]u8
byteRGBA :: distinct [4]u8
byteBGRA :: distinct [4]u8

RED   : byte4 : {  0,   0, 255, 255}
GREEN : byte4 : {  0, 255,   0, 255}
BLUE  : byte4 : {255,   0,   0, 255}

ZERO2 : hlm.int2 : {0,0}
