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

HRESULT :: win32.HRESULT
HRESULT_DETAILS :: win32.HRESULT_DETAILS
FACILITY :: win32.FACILITY
SEVERITY :: win32.SEVERITY
ERROR_SUCCESS :: win32.ERROR_SUCCESS

SUCCEEDED :: win32.SUCCEEDED
FAILED :: win32.FAILED
IS_ERROR :: win32.IS_ERROR
HRESULT_CODE :: win32.HRESULT_CODE
HRESULT_SEVERITY :: win32.HRESULT_SEVERITY
HRESULT_FACILITY :: win32.HRESULT_FACILITY
MAKE_HRESULT :: win32.MAKE_HRESULT
DECODE_HRESULT :: win32.DECODE_HRESULT
