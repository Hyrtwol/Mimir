// +build windows
package sys_windows_ex

import "core:math/fixed"

// https://learn.microsoft.com/en-us/windows/win32/api/wingdi/
// https://github.com/tpn/winsdk-7/blob/master/v7.1A/Include/WinGDI.h
foreign import gdi32 "system:Gdi32.lib"

@(default_calling_convention="system")
foreign gdi32 {
	// https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-createcompatibledc
	CreateCompatibleDC :: proc(hdc: HDC) -> HDC ---
	// https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-deletedc
	DeleteDC :: proc(hdc: HDC) -> BOOL ---
}

// https://github.com/tpn/winsdk-7/blob/master/v7.1A/Include/WinGDI.h#L646C1-L647C55
FXPT16DOT16 :: fixed.Fixed16_16
FXPT2DOT30 :: distinct fixed.Fixed(i32, 30)

CIEXYZ :: FXPT2DOT30

CIEXYZTRIPLE :: struct {
	ciexyzRed:   CIEXYZ,
	ciexyzGreen: CIEXYZ,
	ciexyzBlue:  CIEXYZ,
}

// https://github.com/tpn/winsdk-7/blob/master/v7.1A/Include/WinGDI.h#L756C1-L781C59
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
