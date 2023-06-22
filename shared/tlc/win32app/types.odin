// +build windows
package win32app

import "core:math/fixed"
import win32 "core:sys/windows"

c_int :: win32.c_int

DWORD :: win32.DWORD
BYTE :: win32.BYTE
BOOL :: win32.BOOL
WORD :: win32.WORD
LONG :: win32.LONG
INT :: win32.INT
UINT :: win32.UINT
WCHAR :: win32.WCHAR
DWORD_PTR :: win32.DWORD_PTR
UINT_PTR :: win32.UINT_PTR

LPVOID :: win32.LPVOID
LPCVOID :: win32.LPCVOID
LPUINT :: win32.LPUINT
LPSTR :: win32.LPSTR
LPCSTR :: win32.LPCSTR
LPWSTR :: win32.LPWSTR
LPCWSTR :: win32.LPCWSTR
LPDWORD :: win32.LPDWORD
LPRECT :: win32.LPRECT

HANDLE :: win32.HANDLE
HMODULE :: win32.HMODULE
HINSTANCE :: win32.HINSTANCE
HWND :: win32.HWND
HDC :: win32.HDC
HRGN :: win32.HRGN

LPARAM :: win32.LPARAM
WPARAM :: win32.WPARAM
LRESULT :: win32.LRESULT

POINT :: win32.POINT
RECT :: win32.RECT

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
