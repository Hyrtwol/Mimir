#+build windows
#+vet
package win32app

import win32 "core:sys/windows"
import "core:time"

window_settings :: struct {
	title:       string,
	window_size: int2,
	center:      bool,
	dwStyle:     WS_STYLES,
	dwExStyle:   WS_EX_STYLES,
	wndproc:     win32.WNDPROC,
	run:         proc(this: ^window_settings) -> int,
	app:         rawptr,
	sleep:       time.Duration,
}
psettings :: ^window_settings

set_settings :: #force_inline proc(hwnd: win32.HWND, settings: psettings) {win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, win32.LONG_PTR(uintptr(settings)))}
get_settings :: #force_inline proc(hwnd: win32.HWND) -> psettings {return (psettings)(rawptr(uintptr(win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA))))}

default_window_settings :: proc() -> window_settings {
	return window_settings {
		center      = true,
		dwStyle     = default_dwStyle,
		dwExStyle   = default_dwExStyle,
		sleep       = default_sleep,
	}
}

@(private = "file")
create_window_settings_sw :: proc(size: int2, wndproc: win32.WNDPROC) -> window_settings {
	//fmt.println(#procedure)
	settings := default_window_settings()
	settings.window_size = size
	settings.wndproc = wndproc
	settings.run = run
	return settings
}

@(private = "file")
create_window_settings_tsw :: proc(title: string, size: int2, wndproc: win32.WNDPROC) -> window_settings {
	//fmt.println(#procedure)
	settings := create_window_settings_sw(size, wndproc)
	settings.title = title
	return settings
}

@(private = "file")
create_window_settings_twhw :: #force_inline proc(title: string, width: i32, height: i32, wndproc: win32.WNDPROC) -> window_settings {
	//fmt.println(#procedure)
	return create_window_settings_tsw(title, {width, height}, wndproc)
}

@(private = "file")
create_window_settings_sw2 :: #force_inline proc(size: int2, wndproc: WNDPROC) -> window_settings {
	//fmt.println(#procedure)
	return create_window_settings_sw(size, win32.WNDPROC(wndproc))
}

@(private = "file")
create_window_settings_tsw2 :: #force_inline proc(title: string, size: int2, wndproc: WNDPROC) -> window_settings {
	//fmt.println(#procedure)
	return create_window_settings_tsw(title, size, win32.WNDPROC(wndproc))
}

create_window_settings :: proc {
	create_window_settings_sw,
	create_window_settings_tsw,
	create_window_settings_twhw,
	create_window_settings_sw2,
	create_window_settings_tsw2,
}
