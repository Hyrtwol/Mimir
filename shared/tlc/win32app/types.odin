// +build windows
// +vet
package win32app

import "core:intrinsics"
import win32 "core:sys/windows"

L :: intrinsics.constant_utf16_cstring
wstring :: win32.wstring
utf8_to_wstring :: win32.utf8_to_wstring
wstring_to_utf8 :: win32.wstring_to_utf8
utf8_to_utf16 :: win32.utf8_to_utf16
utf16_to_utf8 :: win32.utf16_to_utf8

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
HGDIOBJ :: win32.HGDIOBJ
HBITMAP :: win32.HBITMAP

POINT :: win32.POINT
RECT :: win32.RECT

LPARAM :: win32.LPARAM
WPARAM :: win32.WPARAM
LRESULT :: win32.LRESULT
CREATESTRUCTW :: win32.CREATESTRUCTW

WM_SIZE_WPARAM :: enum WPARAM {
	RESTORED  = win32.SIZE_RESTORED,
	MINIMIZED = win32.SIZE_MINIMIZED,
	MAXIMIZED = win32.SIZE_MAXIMIZED,
	MAXSHOW   = win32.SIZE_MAXSHOW,
	MAXHIDE   = win32.SIZE_MAXHIDE,
}

WM_MSG :: enum UINT {
	WM_CREATE      = win32.WM_CREATE,
	WM_DESTROY     = win32.WM_DESTROY,
	WM_ERASEBKGND  = win32.WM_ERASEBKGND,
	WM_SETFOCUS    = win32.WM_SETFOCUS,
	WM_KILLFOCUS   = win32.WM_KILLFOCUS,
	WM_SIZE        = win32.WM_SIZE,
	WM_PAINT       = win32.WM_PAINT,
	WM_CHAR        = win32.WM_CHAR,
	WM_TIMER       = win32.WM_TIMER,
	WM_MOUSEMOVE   = win32.WM_MOUSEMOVE,
	WM_LBUTTONDOWN = win32.WM_LBUTTONDOWN,
	WM_RBUTTONDOWN = win32.WM_RBUTTONDOWN,
}

WNDPROC :: #type proc "system" (HWND, WM_MSG, WPARAM, LPARAM) -> LRESULT
