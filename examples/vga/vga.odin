package vga

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import "core:os"
import win32 "core:sys/windows"
import "core:time"
import cv "libs:tlc/canvas"
import owin "libs:tlc/win32app"
import "shared:obug"

int2 :: [2]i32
color :: [4]u8
color_bits :: 8
palette_count :: 1 << color_bits
color_palette :: [palette_count]color

SCREEN_WIDTH :: 320
SCREEN_HEIGHT :: 200
SCREEN_PIXEL_COUNT :: SCREEN_WIDTH * SCREEN_HEIGHT
SCREEN_BYTE_COUNT :: SCREEN_PIXEL_COUNT * color_bits / 8
SCREEN_SIZE :: int2{SCREEN_WIDTH, SCREEN_HEIGHT}

TITLE :: "VGA"
ZOOM :: 5
IDT_TIMER1: win32.UINT_PTR : 10001
IDT_TIMER1_FPS :: 5

screen_buffer :: [^]u8

BITMAPINFO :: struct {
	bmiHeader: win32.BITMAPV5HEADER,
	bmiColors: color_palette,
}

application :: struct {
	#subtype settings: owin.window_settings,
	pause:    bool,
	timer_id: win32.UINT_PTR,
	delta:    f32,
	tick:     u32,
	hbitmap:  win32.HBITMAP,
	pvBits:   screen_buffer,
}

frame_stats: struct {
	fps:           f32,
	frame_counter: i32,
	frame_time:    f32,
}

#assert(palette_count == 256)
#assert(SCREEN_PIXEL_COUNT == 64000)
#assert(SCREEN_BYTE_COUNT == 64000)
#assert(size_of(win32.BITMAPV5HEADER) == 124)
//#assert(size_of(color_palette) == 64)
//#assert(size_of(BITMAPINFO) == 124 + 64)

//dib: owin.DIB
selected_color: u8 = 1
cols := cv.VGA_COLORS

mouse_pos: owin.int2 = {0, 0}
is_active: bool = true
is_focused := false
cursor_state: i32 = 0

show_cursor :: #force_inline proc(app: ^application, show: bool) {
	cursor_state = owin.show_cursor(show)
	fmt.println(#procedure, cursor_state)
}

clip_cursor :: #force_inline proc "contextless" (hwnd: win32.HWND, clip: bool) -> bool {
	return owin.clip_cursor(hwnd, clip)
}

decode_scrpos :: #force_inline proc "contextless" (lparam: win32.LPARAM) -> owin.int2 {
	size := owin.decode_lparam_as_int2(lparam)
	return size / ZOOM
}

set_dot :: #force_inline proc "contextless" (pvBits: screen_buffer, pos: owin.int2, col: u8) {
	if u32(pos.x) < SCREEN_WIDTH && u32(pos.y) < SCREEN_HEIGHT {
		pvBits[pos.y * SCREEN_WIDTH + pos.x] = col
	}
}

get_app :: #force_inline proc(hwnd: win32.HWND) -> ^application {
	app := owin.get_settings(hwnd, application)
	if app == nil {owin.show_error_and_panic("Missing app!")}
	return app
}

@(private = "file")
set_window_text :: #force_inline proc(hwnd: win32.HWND) {
	app := get_app(hwnd)
	owin.set_window_text(hwnd, "%s %v %v FPS: %f", app.settings.title, app.settings.window_size, SCREEN_SIZE, frame_stats.fps)
}

@(private = "file")
draw_dib :: #force_inline proc(hwnd: win32.HWND, hdc: win32.HDC) {
	app := get_app(hwnd)
	if (app.hbitmap != nil) {
		hdc_source := win32.CreateCompatibleDC(hdc)
		defer win32.DeleteDC(hdc_source)

		ws := app.settings.window_size
		win32.SelectObject(hdc_source, win32.HGDIOBJ(app.hbitmap))
		win32.StretchBlt(hdc, 0, 0, ws.x, ws.y, hdc_source, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, win32.SRCCOPY)
	}
}

@(private = "file")
draw_frame :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	hdc := win32.GetDC(hwnd)
	assert(hdc != nil)
	defer win32.ReleaseDC(hwnd, hdc)
	draw_dib(hwnd, hdc)
	return 0
}


WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)

	app := owin.get_settings_from_lparam(lparam, application)
	if app == nil {owin.show_error_and_panic("Missing app!")}
	owin.set_settings(hwnd, app)

	bitmap_info := BITMAPINFO {
		bmiHeader = win32.BITMAPV5HEADER {
			bV5Size        = size_of(win32.BITMAPV5HEADER),
			bV5Width       = SCREEN_WIDTH,
			bV5Height      = -SCREEN_HEIGHT, // minus for top-down
			bV5Planes      = 1,
			bV5BitCount    = color_bits,
			bV5Compression = win32.BI_RGB,
			bV5ClrUsed     = palette_count,
		},
	}

	for i in 0 ..< min(palette_count, len(cv.VGA_COLORS)) {
		bitmap_info.bmiColors[i] = cv.VGA_COLORS[i]
	}

	show_cursor(app, false)

	client_size := owin.get_client_size(hwnd)

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	app.hbitmap = owin.create_dib_section(hdc, cast(^win32.BITMAPINFO)&bitmap_info, .DIB_RGB_COLORS, &app.pvBits)

	app.timer_id = owin.set_timer(hwnd, IDT_TIMER1, 1000 / IDT_TIMER1_FPS)

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	app := get_app(hwnd)
	owin.kill_timer(hwnd, &app.timer_id)
	clip_cursor(hwnd, false)
	if cursor_state < 1 {
		show_cursor(app, true)
	}

	if !owin.delete_object(&app.hbitmap) {owin.show_message_box("Unable to delete hbitmap", "Error")}

	//owin.dib_free(&dib)
	owin.post_quit_message()
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	// type := owin.WM_SIZE_WPARAM(wparam)
	app := get_app(hwnd)
	app.settings.window_size = owin.decode_lparam_as_int2(lparam)
	fmt.println(#procedure, hwnd, app.settings.window_size)
	set_window_text(hwnd)
	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	// app := get_app(hwnd)
	frame_stats.fps = f32(frame_stats.frame_counter) / frame_stats.frame_time
	frame_stats.frame_counter = 0
	frame_stats.frame_time = 0
	set_window_text(hwnd)
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	ps: win32.PAINTSTRUCT
	hdc := win32.BeginPaint(hwnd, &ps)
	assert(hdc != nil)
	defer win32.EndPaint(hwnd, &ps)
	draw_dib(hwnd, hdc)
	return 0
}

WM_ACTIVATEAPP :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	active := wparam != 0
	fmt.println(#procedure, active, cursor_state)
	if is_active != active {
		is_active = active
		clip_cursor(hwnd, active)
	}
	return 0
}

WM_ACTIVATE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	activate := owin.WM_ACTIVATE_WPARAM(wparam)
	fmt.println(#procedure, activate, lparam)
	return 0
}

// wparam: A handle to the window that has lost the keyboard focus. This parameter can be NULL.
WM_FOCUS :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, focused: bool) -> win32.LRESULT {
	is_focused = focused
	fmt.println(#procedure, hwnd, "wparam=", wparam, "is_focused=", is_focused)
	return 0
}

rawinput: win32.RAWINPUT = {}

put_it := 0

WM_INPUT :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	assert(win32.GET_RAWINPUT_CODE_WPARAM(wparam) == .RIM_INPUT)
	owin.get_raw_input_data(win32.HRAWINPUT(lparam), &rawinput)

	switch rawinput.header.dwType {
	case win32.RIM_TYPEMOUSE:
		app := get_app(hwnd)
		mouse_delta: owin.int2 = {rawinput.data.mouse.lLastX, rawinput.data.mouse.lLastY}
		mouse_pos = linalg.clamp(mouse_pos + mouse_delta, cv.int2_zero, app.settings.window_size - 1)
		button_flags := rawinput.data.mouse.usButtonFlags
		switch button_flags {
		case win32.RI_MOUSE_BUTTON_1_DOWN:
			put_it = 1
		case win32.RI_MOUSE_BUTTON_1_UP:
			put_it = 0
		case win32.RI_MOUSE_BUTTON_2_DOWN:
			put_it = 2
		case win32.RI_MOUSE_BUTTON_2_UP:
			put_it = 0
		}
		switch put_it {
		case 1:
			set_dot(app.pvBits, mouse_pos / ZOOM, selected_color)
		case 2:
			set_dot(app.pvBits, mouse_pos / ZOOM, 0)
		}
	//win32.RedrawWindow(hwnd, nil, nil, .RDW_INVALIDATE | .RDW_UPDATENOW)
	case win32.RIM_TYPEKEYBOARD:
		switch rawinput.data.keyboard.VKey {
		case win32.VK_ESCAPE:
			owin.close_application(hwnd)
		case win32.VK_0 ..= win32.VK_9:
			selected_color = u8(rawinput.data.keyboard.VKey - win32.VK_0)
		case:
			fmt.println("keyboard:", rawinput.data.keyboard)
		}
	case:
		fmt.println("dwType:", rawinput.header.dwType)
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
	case win32.WM_PAINT:		return WM_PAINT(hwnd)
	case win32.WM_ACTIVATEAPP:	return WM_ACTIVATEAPP(hwnd, wparam, lparam)
	case win32.WM_ACTIVATE:     return WM_ACTIVATE(hwnd, wparam, lparam)
	case win32.WM_SETFOCUS:		return WM_FOCUS(hwnd, wparam, true)
	case win32.WM_KILLFOCUS:	return WM_FOCUS(hwnd, wparam, false)

	case win32.WM_TIMER:		return WM_TIMER(hwnd, wparam, lparam)

	case win32.WM_INPUT:		return WM_INPUT(hwnd, wparam, lparam)

	case win32.WM_CHAR:         panic("WM_CHAR")
	case win32.WM_KEYDOWN:      panic("WM_KEYDOWN")
	case win32.WM_KEYUP:        panic("WM_KEYUP")
	case win32.WM_MOUSEMOVE:    panic("WM_MOUSEMOVE")
	case win32.WM_LBUTTONDOWN:  panic("WM_LBUTTONDOWN")
	case win32.WM_RBUTTONDOWN:  panic("WM_RBUTTONDOWN")

	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

run :: proc() -> (exit_code: int) {

	app: application = {
		settings = owin.window_settings {
			options = {.Center, .Raw_Input},
			dwStyle = owin.DEFAULT_WS_STYLE,
			dwExStyle = owin.DEFAULT_WS_EX_STYLE,
			sleep = owin.DEFAULT_SLEEP,
			window_size = {SCREEN_WIDTH * ZOOM, SCREEN_HEIGHT * ZOOM},
			wndproc = wndproc,
			title = TITLE,
		},
	}

	_, _, hwnd := owin.prepare_run(&app)

	stopwatch := owin.create_stopwatch()
	stopwatch->start()

	p: int2 = {10, 10}
	d: int2 = {1, 1}
	c: u8 = 0

	msg: win32.MSG
	for owin.pull_messages(&msg) {

		app.delta = f32(stopwatch->get_delta_seconds())
		frame_stats.frame_time += app.delta
		frame_stats.frame_counter += 1
		app.tick += 1

		//res = app.update(app)
		//if res != 0 {break}

		for _ in 0..<256 {
			p += d
			if p.x == 0 || p.x == SCREEN_WIDTH - 1 {
				d.x = -d.x
			}
			if p.y == 0 || p.y == SCREEN_HEIGHT - 1 {
				d.y = -d.y
			}
			set_dot(app.pvBits, p, c)
			c += 1
		}

		draw_frame(hwnd)
		owin.sleep(app.settings.sleep)
	}

	stopwatch->stop()
	exit_code = int(msg.wParam)

	return
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}
