package directx_common

import "base:runtime"
import win32 "core:sys/windows"
import owin "libs:tlc/win32app"

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_DESTROY:
		owin.post_quit_message();return 0
	case win32.WM_ERASEBKGND:
		return 1 // skip
	case win32.WM_CHAR:
		{
			switch wparam {
			case '\x1b':
				win32.DestroyWindow(hwnd) // ESC
			}
			return 0
		}
	case:
		return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}
