package app3d

import "base:intrinsics"
import "base:runtime"
import "core:container/queue"
import "core:fmt"
import "core:math/linalg"
import win32 "core:sys/windows"
import "core:time"
import owin "../win32app"

int2 :: [2]i32
color: [4]byte

app_action :: #type proc(app: ^application) -> int

key_state_count :: 128
key_state :: bool
key_states :: [key_state_count]key_state

application :: struct {
	#subtype settings:       owin.window_settings,
	pause:                   bool,
	size:                    int2,
	timer_id:                win32.UINT_PTR,
	delta:                   f32,
	tick:                    u32,
	create, update, destroy: app_action,
	mouse_pos:               int2,
	mouse_buttons:           owin.MOUSE_KEY_STATE,
	keys:                    key_states,
	char_queue:              queue.Queue(u8),
}

on_idle :: proc(app: ^application) -> int {return 0}

default_application :: application {
	settings = owin.window_settings {
		options     = {.Center},
		dwStyle     = owin.default_dwStyle,
		dwExStyle   = owin.default_dwExStyle,
		sleep       = owin.default_sleep,
		window_size = {640, 480},
		wndproc = wndproc,
	},
	size     = {320, 240},
	create   = on_idle,
	update   = on_idle,
	destroy  = on_idle,
}

frame_stats: struct {
	fps:           f32,
	frame_counter: i32,
	frame_time:    f32,
}

get_app :: #force_inline proc(hwnd: win32.HWND) -> ^application {
	app := owin.get_settings(hwnd, application)
	if app == nil {owin.show_error_and_panic("Missing app!")}
	return app
}
