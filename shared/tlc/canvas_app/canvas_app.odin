package canvas_app

import "base:intrinsics"
import "base:runtime"
import "core:container/queue"
import "core:fmt"
import "core:math/linalg"
import win32 "core:sys/windows"
import "core:time"
import cv "libs:tlc/canvas"
import win32app "libs:tlc/win32app"

TimerTickPS :: 5

int2 :: cv.int2
color: cv.color
dib: win32app.DIB

settings := win32app.create_window_settings(int2{640, 480}, wndproc)
app_action :: #type proc(app: papp) -> int

on_idle :: proc(app: papp) -> int {return 0}

application :: struct {
	pause:                   bool,
	size:                    int2,
	timer_id:                win32.UINT_PTR,
	delta:                   f32,
	tick:                    u32,
	create, update, destroy: app_action,
	mouse_pos:               int2,
	mouse_buttons:           win32app.MOUSE_KEY_STATE,
	char_queue:              queue.Queue(u8),
}
papp :: ^application

app: application = {
	size    = {320, 240},
	create  = on_idle,
	update  = on_idle,
	destroy = on_idle,
}

frame_stats: struct {
	fps:           f32,
	frame_counter: i32,
	frame_time:    f32,
}

set_app :: #force_inline proc(hwnd: win32.HWND, app: papp) {
	win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, win32.LONG_PTR(uintptr(app)))
}

get_app :: #force_inline proc(hwnd: win32.HWND) -> papp {
	app := (papp)(rawptr(uintptr(win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA))))
	if app == nil {win32app.show_error_and_panic("Missing app!")}
	return app
}

get_settings :: #force_inline proc(lparam: win32.LPARAM) -> win32app.psettings {
	pcs := win32app.get_createstruct_from_lparam(lparam)
	if pcs == nil {win32app.show_error_and_panic("Missing pcs!");return nil}
	settings := win32app.psettings(pcs.lpCreateParams)
	if settings == nil {win32app.show_error_and_panic("Missing settings!")}
	return settings
}

// 0..1
decode_mouse_pos_01 :: #force_inline proc "contextless" (app: papp) -> cv.float2 {
	LO :: cv.float2{0, 0}
	HI :: cv.float2{1, 1}
	normalized_mouse_pos := cv.to_float2(app.mouse_pos) / cv.to_float2(settings.window_size)
	return linalg.clamp(normalized_mouse_pos, LO, HI)
}

// normalized device coordinates -1..1
decode_mouse_pos_ndc :: #force_inline proc "contextless" (app: papp) -> cv.float2 {
	return decode_mouse_pos_01(app) * 2 - 1
}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	settings := get_settings(lparam)
	app := (papp)(settings.app)
	if app == nil {win32app.show_error_and_panic("Missing app!");return 1}
	set_app(hwnd, app)

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	dib = win32app.dib_create_v5(hdc, app.size)
	if dib.canvas.pvBits == nil {win32app.show_error_and_panic("No DIB");return 1}
	cv.canvas_clear(&dib, cv.COLOR_BLACK)

	app->create()

	app.timer_id = win32app.set_timer(hwnd, win32app.IDT_TIMER1, 1000 / TimerTickPS)
	assert(app.timer_id != 0)

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	app := get_app(hwnd)
	app->destroy()
	win32app.dib_free_section(&dib)
	win32app.kill_timer(hwnd, &app.timer_id)
	assert(app.timer_id == 0)
	win32app.post_quit_message(0)

	return 0
}

set_window_text :: #force_inline proc(hwnd: win32.HWND) {
	win32app.set_window_textf(hwnd, "%s %v %v FPS: %f", settings.title, settings.window_size, dib.canvas.size, frame_stats.fps)
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	//app := get_app(hwnd)
	settings.window_size = win32app.decode_lparam_as_int2(lparam)
	set_window_text(hwnd)
	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	//fmt.println(#procedure, hwnd, wparam)
	// app := get_app(hwnd)
	frame_stats.fps = f32(frame_stats.frame_counter) / frame_stats.frame_time
	frame_stats.frame_counter = 0
	frame_stats.frame_time = 0
	set_window_text(hwnd)
	return 0
}

draw_dib :: #force_inline proc(hwnd: win32.HWND, hdc: win32.HDC) {
	//app := get_app(hwnd)
	win32app.draw_dib(hwnd, hdc, settings.window_size, &dib)
}

draw_frame :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)
	draw_dib(hwnd, hdc)
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	ps: win32.PAINTSTRUCT
	hdc := win32.BeginPaint(hwnd, &ps)
	if hdc != nil {
		defer win32.EndPaint(hwnd, &ps)
		draw_dib(hwnd, hdc)
	}
	return 0
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	app := get_app(hwnd)
	queue.push_front(&app.char_queue, u8(wparam))
	return 0
}

handle_key_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	app := get_app(hwnd)
	vk_code := win32.LOWORD(wparam) // virtual-key code
	key_flags := win32.HIWORD(lparam)
	repeat_count := win32.LOWORD(lparam) // repeat count, > 0 if several keydown messages was combined into one message
	scan_code := win32.WORD(win32.LOBYTE(key_flags)) // scan code
	is_extended_key := (key_flags & win32.KF_EXTENDED) == win32.KF_EXTENDED // extended-key flag, 1 if scancode has 0xE0 prefix
	if is_extended_key {scan_code = win32.MAKEWORD(scan_code, 0xE0)}
	was_key_down := (key_flags & win32.KF_REPEAT) == win32.KF_REPEAT // previous key-state flag, 1 on autorepeat
	is_key_released := (key_flags & win32.KF_UP) == win32.KF_UP // transition-state flag, 1 on keyup

	switch (vk_code)
	{
	case win32.VK_SHIFT: // converts to VK_LSHIFT or VK_RSHIFT
	case win32.VK_CONTROL: // converts to VK_LCONTROL or VK_RCONTROL
	case win32.VK_MENU:
		// converts to VK_LMENU or VK_RMENU
		vk_code = win32.LOWORD(win32.MapVirtualKeyW(win32.DWORD(scan_code), win32.MAPVK_VSC_TO_VK_EX))
		break
	}

	switch vk_code {
	case win32.VK_ESCAPE:
		if is_key_released {win32app.close_application(hwnd)}
	//case: fmt.printfln("key: %4d 0x%4X %8d ke: %t kd: %t kr: %t", vk_code, key_flags, scan_code, is_extended_key, was_key_down, is_key_released)
	}
	_ = was_key_down
	_ = repeat_count
	_ = app
	return 0
}

handle_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	app.mouse_pos = win32app.decode_lparam_as_int2(lparam)
	//app.mouse_buttons = win32app.MOUSE_KEY_STATE(wparam)
	app.mouse_buttons = transmute(win32app.MOUSE_KEY_STATE)win32.DWORD(wparam)
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	// odinfmt: disable
	switch msg {
	case win32.WM_CREATE:       return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:      return WM_DESTROY(hwnd)
	case win32.WM_SIZE:         return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_PAINT:        return WM_PAINT(hwnd)
	case win32.WM_ERASEBKGND:   return 1 // 0x0014
	case win32.WM_CHAR:         return WM_CHAR(hwnd, wparam, lparam) // 0x0102
	case win32.WM_TIMER:        return WM_TIMER(hwnd, wparam, lparam) // 0x0113
	//case win32.WM_KEYDOWN:		return handle_key_input(hwnd, wparam, lparam)
	case win32.WM_KEYUP:		return handle_key_input(hwnd, wparam, lparam)
	case win32.WM_MOUSEMOVE:    return handle_input(hwnd, wparam, lparam) // 0x0200
	case win32.WM_LBUTTONDOWN:  return handle_input(hwnd, wparam, lparam)
	case win32.WM_RBUTTONDOWN:  return handle_input(hwnd, wparam, lparam)
	case:                       return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

run :: proc() {
	// queue.init(&app.char_queue)
	// defer queue.destroy(&app.char_queue)

	settings.app = &app
	_, _, hwnd := win32app.prepare_run(&settings)
	res: int

	stopwatch := win32app.create_stopwatch()
	stopwatch->start()
	for win32app.pull_messages() {

		app.delta = f32(stopwatch->get_delta_seconds())
		frame_stats.frame_time += app.delta
		frame_stats.frame_counter += 1
		app.tick += 1

		res = app.update(&app)
		if res != 0 {break}
		draw_frame(hwnd)
		if settings.sleep >= 0 {
			time.accurate_sleep(settings.sleep)
		}
	}
	stopwatch->stop()
}
