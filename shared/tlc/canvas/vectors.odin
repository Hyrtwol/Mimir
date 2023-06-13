package canvas

import          "core:fmt"
import          "core:intrinsics"
import          "core:math/linalg"
import hlm      "core:math/linalg/hlsl"
import          "core:runtime"
import          "core:strings"
import win32    "core:sys/windows"
import win32app "../win32app"

byte4 :: win32app.byte4
int2  :: win32app.int2
ZERO2 :: win32app.ZERO2

// Color Palette

COLOR_BLACK     : byte4 : { 0x00, 0x00, 0x00, 0xFF }
COLOR_RED       : byte4 : { 0x00, 0x00, 0xFF, 0xFF }
COLOR_GREEN     : byte4 : { 0x00, 0xFF, 0x00, 0xFF }
COLOR_BLUE      : byte4 : { 0xFF, 0x00, 0x00, 0xFF }
COLOR_WHIT      : byte4 : { 0xFF, 0xFF, 0xFF, 0xFF }

// Windows 95 Palette

W95_BLACK       : byte4 : { 0x00, 0x00, 0x00, 0xFF }
W95_MAROON      : byte4 : { 0x80, 0x00, 0x00, 0xFF }
W95_GREEN       : byte4 : { 0x00, 0x80, 0x00, 0xFF }
W95_OLIVE       : byte4 : { 0x80, 0x80, 0x00, 0xFF }
W95_NAVY        : byte4 : { 0x00, 0x00, 0x80, 0xFF }
W95_PURPLE      : byte4 : { 0x80, 0x00, 0x80, 0xFF }
W95_TEAL        : byte4 : { 0x00, 0x80, 0x80, 0xFF }
W95_SILVER      : byte4 : { 0xC0, 0xC0, 0xC0, 0xFF }
W95_GRAY        : byte4 : { 0x80, 0x80, 0x80, 0xFF }
W95_RED         : byte4 : { 0xFF, 0x00, 0x00, 0xFF }
W95_LIME        : byte4 : { 0x00, 0xFF, 0x00, 0xFF }
W95_YELLOW      : byte4 : { 0xFF, 0xFF, 0x00, 0xFF }
W95_BLUE        : byte4 : { 0x00, 0x00, 0xFF, 0xFF }
W95_FUCHSIA     : byte4 : { 0xFF, 0xFF, 0xFF, 0xFF }
W95_AQUA        : byte4 : { 0x00, 0xFF, 0xFF, 0xFF }
W95_WHITE       : byte4 : { 0xFF, 0xFF, 0xFF, 0xFF }

W95_COLORS : [16]byte4 : {
    W95_BLACK       ,
    W95_MAROON      ,
    W95_GREEN       ,
    W95_OLIVE       ,
    W95_NAVY        ,
    W95_PURPLE      ,
    W95_TEAL        ,
    W95_SILVER      ,
    W95_GRAY        ,
    W95_RED         ,
    W95_LIME        ,
    W95_YELLOW      ,
    W95_BLUE        ,
    W95_FUCHSIA     ,
    W95_AQUA        ,
    W95_WHITE      	}

// C64 Palette

C64_BLACK       : byte4 : { 0x00, 0x00, 0x00, 0xFF }
C64_WHITE       : byte4 : { 0xFF, 0xFF, 0xFF, 0xFF }
C64_RED         : byte4 : { 0x68, 0x37, 0x2B, 0xFF }
C64_CYAN	    : byte4 : { 0x70, 0xA4, 0xB2, 0xFF }
C64_PURPLE      : byte4 : { 0x6F, 0x3D, 0x86, 0xFF }
C64_GREEN       : byte4 : { 0x58, 0x8D, 0x43, 0xFF }
C64_BLUE	    : byte4 : { 0x35, 0x28, 0x79, 0xFF }
C64_YELLOW      : byte4 : { 0xB8, 0xC7, 0x6F, 0xFF }
C64_ORANGE      : byte4 : { 0x6F, 0x4F, 0x25, 0xFF }
C64_BROWN       : byte4 : { 0x43, 0x39, 0x00, 0xFF }
C64_LIGHT_RED	: byte4 : { 0x9A, 0x67, 0x59, 0xFF }
C64_DARK_GREY   : byte4 : { 0x44, 0x44, 0x44, 0xFF }
C64_GREY	    : byte4 : { 0x6C, 0x6C, 0x6C, 0xFF }
C64_LIGHT_GREEN : byte4 : { 0x9A, 0xD2, 0x84, 0xFF }
C64_LIGHT_BLUE  : byte4 : { 0x6C, 0x5E, 0xB5, 0xFF }
C64_LIGHT_GREY	: byte4 : { 0x95, 0x95, 0x95, 0xFF }

C64_COLORS : [16]byte4 : {
    C64_BLACK       ,
    C64_WHITE       ,
    C64_RED         ,
    C64_CYAN	    ,
    C64_PURPLE      ,
    C64_GREEN       ,
    C64_BLUE	    ,
    C64_YELLOW      ,
    C64_ORANGE      ,
    C64_BROWN       ,
    C64_LIGHT_RED	,
    C64_DARK_GREY   ,
    C64_GREY	    ,
    C64_LIGHT_GREEN ,
    C64_LIGHT_BLUE  ,
    C64_LIGHT_GREY	}
