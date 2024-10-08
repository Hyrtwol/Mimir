#+build windows
package sys_windows_ex

import win32 "core:sys/windows"
import "base:intrinsics"

L :: intrinsics.constant_utf16_cstring

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

PDRAWTEXTPARAMS :: win32.PDRAWTEXTPARAMS
