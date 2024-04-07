package main

import "core:fmt"
import "core:intrinsics"
import "core:math"
import "core:math/linalg"
import hlm "core:math/linalg/hlsl"
import "core:math/noise"
import "core:math/rand"
import "core:mem"
import "core:runtime"
import "core:simd"
import "core:strings"
import win32 "core:sys/windows"
import "core:time"
import canvas "libs:tlc/canvas"
import win32app "libs:tlc/win32app"

L :: intrinsics.constant_utf16_cstring

TITLE :: "Raw Input"
WIDTH :: 640
HEIGHT :: WIDTH * 9 / 16
CENTER :: true
ZOOM :: 8

settings := win32app.create_window_settings(TITLE, WIDTH, HEIGHT, wndproc)

dib: canvas.DIB
colidx := 1
cols := canvas.C64_COLORS

icon: win32.HICON

mouse_pos: win32app.int2 = {0, 0}

decode_scrpos :: proc(lparam: win32.LPARAM) -> win32app.int2 {
	size := win32app.decode_lparam(lparam)
	scrpos := size / ZOOM
	return scrpos
}

setdot :: proc(pos: win32app.int2, col: canvas.byte4) {
	i := pos.y * dib.size.x + pos.x
	if i >= 0 && i < dib.pixel_count {
		dib.pvBits[i] = col
	}
}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.print("WM_CREATE\n")

	//sc := win32.ShowCursor(false)
	//fmt.printf("ShowCursor %v\n", sc)

	client_size := win32app.get_client_size(hwnd)

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	dib = canvas.dib_create_v5(hdc, client_size / ZOOM)
	if dib.pvBits != nil {
		canvas.dib_clear(&dib, {50, 100, 150, 255})
	}

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.print("WM_DESTROY\n")
	canvas.dib_free_section(&dib)
	//win32.ShowCursor(true)
	win32.PostQuitMessage(0)
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	size := win32app.decode_lparam(lparam)
	new_title := fmt.tprintf("%s %v %v\n", TITLE, size, dib.size)
	win32.SetWindowTextW(hwnd, win32.utf8_to_wstring(new_title))
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps) // todo check if defer can be used for EndPaint
	defer win32.EndPaint(hwnd, &ps)

	hdc_source := win32.CreateCompatibleDC(ps.hdc)
	defer win32.DeleteDC(hdc_source)

	win32.SelectObject(hdc_source, win32.HGDIOBJ(dib.hbitmap))
	client_size := win32app.get_rect_size(&ps.rcPaint)
	win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, dib.size.x, dib.size.y, win32.SRCCOPY)

	win32.DrawIcon(ps.hdc, mouse_pos.x, mouse_pos.y, icon)

	return 0
}

is_active: bool = false

WM_ACTIVATEAPP :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	active := wparam != 0
	fmt.printf("WM_ACTIVATEAPP %v\n", active)
	if is_active == active {return 0}
	if active {

	} else {

	}
	return 0
}

rawinput: win32.RAWINPUT = {}

WM_INPUT :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {

	dwSize: win32.UINT
	win32.GetRawInputData(win32.HRAWINPUT(lparam), win32.RID_INPUT, nil, &dwSize, size_of(win32.RAWINPUTHEADER))
	if dwSize == 0 {return 0}
	//assert(dwSize > size_of(win32.RAWINPUT), "dwSize too big")
	if dwSize > size_of(win32.RAWINPUT) {win32app.show_error_and_panic("dwSize too big");return 0}

	raw := &rawinput

	if win32.GetRawInputData(win32.HRAWINPUT(lparam), win32.RID_INPUT, raw, &dwSize, size_of(win32.RAWINPUTHEADER)) != dwSize {
		win32app.show_error_and_panic("GetRawInputData Failed")
		return 0
	}

	switch raw.header.dwType {
	case win32.RIM_TYPEMOUSE:
		{
			mouse_delta: win32app.int2 = {raw.data.mouse.lLastX, raw.data.mouse.lLastY}
			mouse_pos += mouse_delta
			// mouse_pos.x = clamp(mouse_pos.x, 0, WIDTH - 1)
			// mouse_pos.y = clamp(mouse_pos.y, 0, HEIGHT - 1)
			mouse_pos = {clamp(mouse_pos.x, 0, WIDTH - 1),clamp(mouse_pos.y, 0, HEIGHT - 1)}

			/*fmt.printf(
				"mouse %v %v %v %v %v\n",
				raw.data.mouse.usFlags,
				mouse_delta, mouse_pos,
				raw.data.mouse.DUMMYUNIONNAME.DUMMYSTRUCTNAME.usButtonFlags,
				cast(i16)raw.data.mouse.DUMMYUNIONNAME.DUMMYSTRUCTNAME.usButtonData)
			*/
			win32.RedrawWindow(hwnd, nil, nil, .RDW_INVALIDATE | .RDW_UPDATENOW)
		}
	case win32.RIM_TYPEKEYBOARD:
		{
			fmt.printf("keyboard %v\n", raw.data.keyboard)
			if raw.data.keyboard.VKey == 27 {
				win32.DestroyWindow(hwnd)
			}
		}
	case:
			fmt.printf("dwType %v\n", raw.header.dwType)
	}

	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	// odinfmt: disable
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:	return 1
	case win32.WM_SIZE:			return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_PAINT:		return WM_PAINT(hwnd, wparam, lparam)
	case win32.WM_ACTIVATEAPP:	return WM_ACTIVATEAPP(hwnd, wparam, lparam)
	//case win32.WM_ACTIVATE: return WM_ACTIVATE(hwnd, wparam, lparam)
	case win32.WM_INPUT:		return WM_INPUT(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

main :: proc() {

	icon = win32.LoadIconW(nil, win32.wstring(win32._IDI_QUESTION))
	fmt.printf("icon %v\n", icon)

	rid := [2]win32.RAWINPUTDEVICE {
		{usUsagePage = win32.HID_USAGE_PAGE_GENERIC, usUsage = win32.HID_USAGE_GENERIC_MOUSE, dwFlags = win32.RIDEV_NOLEGACY, hwndTarget = nil},
		{usUsagePage = win32.HID_USAGE_PAGE_GENERIC, usUsage = win32.HID_USAGE_GENERIC_KEYBOARD, dwFlags = win32.RIDEV_NOLEGACY, hwndTarget = nil},
	}

	if (!win32.RegisterRawInputDevices(&rid[0], len(rid), size_of(rid[0]))) {
		win32app.show_error_and_panic("RegisterRawInputDevices Failed")
	}

	win32app.run(&settings)
}
