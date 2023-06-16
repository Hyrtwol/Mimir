package win32app

import       "core:fmt"
import       "core:intrinsics"
import       "core:math/fixed"
import       "core:math/linalg"
import hlm   "core:math/linalg/hlsl"
import       "core:runtime"
import       "core:strings"
import win32 "core:sys/windows"

// https://learn.microsoft.com/en-us/windows/win32/api/wingdi/
/*
foreign import gdi32 "system:Gdi32.lib"

@(default_calling_convention="stdcall")
foreign gdi32 {
}
*/

FXPT2DOT30 :: distinct fixed.Fixed(i32, 30)
CIEXYZ :: FXPT2DOT30

CIEXYZTRIPLE :: struct {
	ciexyzRed:   CIEXYZ,
	ciexyzGreen: CIEXYZ,
	ciexyzBlue:  CIEXYZ,
}

BITMAPV5HEADER :: struct {
	bV5Size:          win32.DWORD,
	bV5Width:         win32.LONG,
	bV5Height:        win32.LONG,
	bV5Planes:        win32.WORD,
	bV5BitCount:      win32.WORD,
	bV5Compression:   win32.DWORD,
	bV5SizeImage:     win32.DWORD,
	bV5XPelsPerMeter: win32.LONG,
	bV5YPelsPerMeter: win32.LONG,
	bV5ClrUsed:       win32.DWORD,
	bV5ClrImportant:  win32.DWORD,
	bV5RedMask:       win32.DWORD,
	bV5GreenMask:     win32.DWORD,
	bV5BlueMask:      win32.DWORD,
	bV5AlphaMask:     win32.DWORD,
	bV5CSType:        win32.DWORD,
	bV5Endpoints:     CIEXYZTRIPLE,
	bV5GammaRed:      win32.DWORD,
	bV5GammaGreen:    win32.DWORD,
	bV5GammaBlue:     win32.DWORD,
	bV5Intent:        win32.DWORD,
	bV5ProfileData:   win32.DWORD,
	bV5ProfileSize:   win32.DWORD,
	bV5Reserved:      win32.DWORD,
}
