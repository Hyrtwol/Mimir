// +build windows
package sys_windows_ex

import "core:math/fixed"

// https://learn.microsoft.com/en-us/windows/win32/api/wingdi/
// https://github.com/tpn/winsdk-7/blob/master/v7.1A/Include/WinGDI.h
foreign import gdi32 "system:Gdi32.lib"

@(default_calling_convention="system")
foreign gdi32 {
	CreateCompatibleDC :: proc(hdc: HDC) -> HDC ---
	DeleteDC :: proc(hdc: HDC) -> BOOL ---
}

FXPT2DOT30 :: distinct fixed.Fixed(i32, 30)

CIEXYZ :: struct {
	ciexyzX: FXPT2DOT30,
	ciexyzY: FXPT2DOT30,
	ciexyzZ: FXPT2DOT30,
}

CIEXYZTRIPLE :: struct {
	ciexyzRed:   CIEXYZ,
	ciexyzGreen: CIEXYZ,
	ciexyzBlue:  CIEXYZ,
}

// https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmapv5header
BITMAPV5HEADER :: struct {
	bV5Size:          DWORD,
	bV5Width:         LONG,
	bV5Height:        LONG,
	bV5Planes:        WORD,
	bV5BitCount:      WORD,
	bV5Compression:   DWORD,
	bV5SizeImage:     DWORD,
	bV5XPelsPerMeter: LONG,
	bV5YPelsPerMeter: LONG,
	bV5ClrUsed:       DWORD,
	bV5ClrImportant:  DWORD,
	bV5RedMask:       DWORD,
	bV5GreenMask:     DWORD,
	bV5BlueMask:      DWORD,
	bV5AlphaMask:     DWORD,
	bV5CSType:        DWORD,
	bV5Endpoints:     CIEXYZTRIPLE,
	bV5GammaRed:      DWORD,
	bV5GammaGreen:    DWORD,
	bV5GammaBlue:     DWORD,
	bV5Intent:        DWORD,
	bV5ProfileData:   DWORD,
	bV5ProfileSize:   DWORD,
	bV5Reserved:      DWORD,
}
