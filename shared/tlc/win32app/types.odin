#+build windows
#+vet
package win32app

import "base:intrinsics"
import win32 "core:sys/windows"
import "core:time"

int2 :: [2]i32

Millisecond :: time.Millisecond
Duration :: time.Duration
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

ATOM :: win32.ATOM
HANDLE :: win32.HANDLE

HMODULE :: win32.HMODULE
HINSTANCE :: win32.HINSTANCE
HMENU :: win32.HMENU
HWND :: win32.HWND
HDC :: win32.HDC
HRGN :: win32.HRGN
HGDIOBJ :: win32.HGDIOBJ
HBITMAP :: win32.HBITMAP
HPEN :: win32.HPEN
HBRUSH :: win32.HBRUSH
HICON :: win32.HICON
HCURSOR :: win32.HCURSOR

LPARAM :: win32.LPARAM
WPARAM :: win32.WPARAM
LRESULT :: win32.LRESULT

POINT :: win32.POINT
RECT :: win32.RECT

CREATESTRUCTW :: win32.CREATESTRUCTW

RAWINPUT_CODE :: win32.RAWINPUT_CODE

WS_STYLES :: win32.WS_STYLES
WS_EX_STYLES :: win32.WS_EX_STYLES

WS_EX_LEFT: WS_EX_STYLES : {}
WS_EX_RIGHTSCROLLBAR: WS_EX_STYLES : {}
WS_EX_LTRREADING: WS_EX_STYLES : {}
WS_EX_OVERLAPPEDWINDOW: WS_EX_STYLES : {.WS_EX_WINDOWEDGE, .WS_EX_CLIENTEDGE}
WS_EX_PALETTEWINDOW: WS_EX_STYLES : {.WS_EX_WINDOWEDGE, .WS_EX_TOOLWINDOW, .WS_EX_TOPMOST}

CREATESTRUCT :: struct {
	lpCreateParams: LPVOID,
	hInstance:      HINSTANCE,
	hMenu:          HMENU,
	hwndParent:     HWND,
	cy:             i32,
	cx:             i32,
	y:              i32,
	x:              i32,
	style:          WS_STYLES,
	lpszName:       LPCWSTR,
	lpszClass:      LPCWSTR,
	dwExStyle:      WS_EX_STYLES,
}

WM_SIZE_WPARAM :: enum WPARAM {
	RESTORED  = win32.SIZE_RESTORED,
	MINIMIZED = win32.SIZE_MINIMIZED,
	MAXIMIZED = win32.SIZE_MAXIMIZED,
	MAXSHOW   = win32.SIZE_MAXSHOW,
	MAXHIDE   = win32.SIZE_MAXHIDE,
}

WM_SIZING_WPARAM :: enum WPARAM {
	WMSZ_LEFT        = win32.WMSZ_LEFT,
	WMSZ_RIGHT       = win32.WMSZ_RIGHT,
	WMSZ_TOP         = win32.WMSZ_TOP,
	WMSZ_TOPLEFT     = win32.WMSZ_TOPLEFT,
	WMSZ_TOPRIGHT    = win32.WMSZ_TOPRIGHT,
	WMSZ_BOTTOM      = win32.WMSZ_BOTTOM,
	WMSZ_BOTTOMLEFT  = win32.WMSZ_BOTTOMLEFT,
	WMSZ_BOTTOMRIGHT = win32.WMSZ_BOTTOMRIGHT,
}

WM_MSG :: enum UINT {
	WM_CREATE      = win32.WM_CREATE,
	WM_DESTROY     = win32.WM_DESTROY,
	WM_ERASEBKGND  = win32.WM_ERASEBKGND,
	WM_SETFOCUS    = win32.WM_SETFOCUS,
	WM_KILLFOCUS   = win32.WM_KILLFOCUS,
	WM_SIZE        = win32.WM_SIZE,
	WM_SIZING      = win32.WM_SIZING,
	WM_PAINT       = win32.WM_PAINT,
	WM_CHAR        = win32.WM_CHAR,
	WM_TIMER       = win32.WM_TIMER,
	WM_MOUSEMOVE   = win32.WM_MOUSEMOVE,
	WM_LBUTTONDOWN = win32.WM_LBUTTONDOWN,
	WM_RBUTTONDOWN = win32.WM_RBUTTONDOWN,
}

WNDPROC :: #type proc "system" (hwnd: HWND, msg: WM_MSG, wparam: WPARAM, lparam: LPARAM) -> LRESULT

// Key State Masks for Mouse Messages

MOUSE_KEY_STATE_FLAG :: enum DWORD {
	MK_LBUTTON,
	MK_RBUTTON,
	MK_SHIFT,
	MK_CONTROL,
	MK_MBUTTON,
	MK_XBUTTON1,
	MK_XBUTTON2,
}

MOUSE_KEY_STATE :: bit_set[MOUSE_KEY_STATE_FLAG;DWORD]
