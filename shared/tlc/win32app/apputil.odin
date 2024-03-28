// +build windows
package win32app

import "core:fmt"
import "core:math/rand"
import win32 "core:sys/windows"

int2 :: [2]i32

IDT_TIMER1: win32.UINT_PTR : 10001
IDT_TIMER2: win32.UINT_PTR : 10002
IDT_TIMER3: win32.UINT_PTR : 10003
IDT_TIMER4: win32.UINT_PTR : 10004

decode_lparam :: #force_inline proc "contextless" (lparam: win32.LPARAM) -> int2 {
	return {win32.GET_X_LPARAM(lparam), win32.GET_Y_LPARAM(lparam)}
}

show_messagebox :: proc(caption: string, text: string, type: UINT = win32.MB_ICONSTOP | win32.MB_OK) {
	win32.MessageBoxW(nil, utf8_to_wstring(text), utf8_to_wstring(caption), type)
}

show_messageboxf :: proc(caption: string, format: string, args: ..any) {
	show_messagebox(caption, fmt.tprintf(format, ..args))
}

show_error :: proc(msg: string, loc := #caller_location) {
	show_messageboxf("Panic", "%s\nLast error: %x\n%v\n", msg, win32.GetLastError(), loc)
}

show_error_and_panic :: proc(msg: string, loc := #caller_location) {
	show_error(msg, loc = loc)
	fmt.panicf("%s (Last error: %x)", msg, win32.GetLastError(), loc = loc)
}

show_last_error :: proc(caption: string, loc := #caller_location) {
	error_text: [512]win32.WCHAR

	fmt.eprintln(caption)
	last_error := win32.GetLastError()

	error_wstring := wstring(&error_text)
	cch := win32.FormatMessageW(win32.FORMAT_MESSAGE_FROM_SYSTEM | win32.FORMAT_MESSAGE_IGNORE_INSERTS, nil, last_error, win32.LANGID_NEUTRAL, error_wstring, len(error_text) - 1, nil)
	if (cch != 0) {return}
	error_string, err := wstring_to_utf8(&error_wstring[0], int(cch))
	if err == .None {
		fmt.eprintln(error_string)
	} else {
		fmt.eprintfln("Last error code: %d (0x%8X)", last_error)
	}
}

show_last_errorf :: proc(format: string, args: ..any, loc := #caller_location) {
	show_last_error(fmt.tprintf(format, ..args), loc = loc)
}


get_rect_size :: #force_inline proc(rect: ^RECT) -> int2 {
	return {(rect.right - rect.left), (rect.bottom - rect.top)}
}

get_client_size :: proc(hwnd: HWND) -> int2 {
	rect: RECT
	win32.GetClientRect(hwnd, &rect)
	return get_rect_size(&rect)
}

adjust_window_size :: proc(size: int2, dwStyle, dwExStyle: u32) -> int2 {
	rect := RECT{0, 0, size.x, size.y}
	if win32.AdjustWindowRectEx(&rect, dwStyle, false, dwExStyle) {
		return get_rect_size(&rect)
	}
	return size
}

get_window_position :: proc(size: int2, center: bool) -> int2 {
	if center {
		if deviceMode: win32.DEVMODEW; win32.EnumDisplaySettingsW(nil, win32.ENUM_CURRENT_SETTINGS, &deviceMode) {
			dmsize: int2 = {i32(deviceMode.dmPelsWidth), i32(deviceMode.dmPelsHeight)} // is there an easier way to describe this?
			return (dmsize - size) / 2
		}
	}
	return {win32.CW_USEDEFAULT, win32.CW_USEDEFAULT}
}

get_module_handle :: proc(lpModuleName: wstring = nil) -> HMODULE {
	module_handle := win32.GetModuleHandleW(lpModuleName)
	if (module_handle == nil) {
		show_error_and_panic("No Module Handle")
	}
	return module_handle
}

get_instance :: proc() -> HINSTANCE {
	instance := win32.HINSTANCE(win32.GetModuleHandleW(nil))
	if (instance == nil) {
		show_error_and_panic("No instance")
	}
	return instance
}

get_module_filename :: proc(module: win32.HMODULE, allocator := context.temp_allocator) -> string {
	wname: [512]win32.WCHAR
	cc := win32.GetModuleFileNameW(module, &wname[0], len(wname) - 1)
	if cc != 0 {
		name, err := wstring_to_utf8(&wname[0], int(cc), allocator)
		if err == .None {
			return name
		}
	}
	return "?"
}

register_window_class :: proc(instance: HINSTANCE, wndproc: win32.WNDPROC) -> win32.ATOM {

	icon: win32.HICON = win32.LoadIconW(instance, win32.MAKEINTRESOURCEW(1))
	if icon == nil {
		icon = win32.LoadIconW(nil, win32.wstring(win32._IDI_APPLICATION))
	}
	if icon == nil {
		icon = win32.LoadIconW(nil, win32.wstring(win32._IDI_QUESTION))
	}
	if (icon == nil) {
		show_error_and_panic("Missing icon")
	}

	cursor: win32.HCURSOR = win32.LoadCursorW(nil, win32.wstring(win32._IDC_ARROW))
	if (cursor == nil) {
		show_error_and_panic("Missing cursor")
	}

	wcx := win32.WNDCLASSEXW {
		cbSize        = size_of(win32.WNDCLASSEXW),
		style         = win32.CS_HREDRAW | win32.CS_VREDRAW | win32.CS_OWNDC,
		lpfnWndProc   = wndproc,
		cbClsExtra    = 0,
		cbWndExtra    = 0,
		hInstance     = instance,
		hIcon         = icon,
		hCursor       = cursor,
		hbrBackground = nil,
		lpszMenuName  = nil,
		lpszClassName = L("OdinMainClass"),
		hIconSm       = icon,
	}

	atom: win32.ATOM = win32.RegisterClassExW(&wcx)
	if atom == 0 {
		show_error_and_panic("Failed to register window class")
	}
	return atom
}

create_window :: proc(instance: win32.HINSTANCE, atom: win32.ATOM, dwStyle, dwExStyle: u32, settings: ^window_settings) -> win32.HWND {

	size := adjust_window_size(settings.window_size, dwStyle, dwExStyle)
	position := get_window_position(size, settings.center)

	hwnd: win32.HWND = win32.CreateWindowExW(
		dwExStyle,
		win32.LPCWSTR(uintptr(atom)),
		utf8_to_wstring(settings.title),
		dwStyle,
		position.x, position.y,
		size.x, size.y,
		nil, nil,
		instance,
		//settings.app,
		settings,
	)

	return hwnd
}

default_dwStyle :: win32.WS_OVERLAPPED | win32.WS_CAPTION | win32.WS_SYSMENU
default_dwExStyle :: win32.WS_EX_OVERLAPPEDWINDOW

window_settings :: struct {
	title:       string,
	window_size: int2,
	center:      bool,
	dwStyle:     u32,
	dwExStyle:   u32,
	wndproc:     win32.WNDPROC,
	run:         proc(this: ^window_settings) -> win32.HWND,
	app:         rawptr,
}
psettings :: ^window_settings

set_settings :: #force_inline proc(hwnd: win32.HWND, settings: psettings) {win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, win32.LONG_PTR(uintptr(settings)))}
get_settings :: #force_inline proc(hwnd: win32.HWND) -> psettings {return (psettings)(rawptr(uintptr(win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA))))}


@(private = "file")
create_window_settings_1 :: proc(title: string, size: int2, wndproc: win32.WNDPROC) -> window_settings {
	settings: window_settings = {
		title       = title,
		window_size = size,
		center      = true,
		wndproc     = wndproc,
		dwStyle     = default_dwStyle,
		dwExStyle   = default_dwExStyle,
		run         = run,
	}
	return settings
}

@(private = "file")
create_window_settings_2 :: proc(title: string, width: i32, height: i32, wndproc: win32.WNDPROC) -> window_settings {
	return create_window_settings_1(title, {width, height}, wndproc)
}

@(private = "file")
create_window_settings_3 :: proc(title: string, size: int2, wndproc: WNDPROC) -> window_settings {
	return create_window_settings_1(title, size, win32.WNDPROC(wndproc))
}

create_window_settings :: proc {
	create_window_settings_1,
	create_window_settings_2,
	create_window_settings_3,
}

register_and_create_window :: proc(settings: ^window_settings) -> win32.HWND {
	if settings.dwStyle == 0 {settings.dwStyle = default_dwStyle}
	if settings.dwExStyle == 0 {settings.dwExStyle = default_dwExStyle}
	instance := get_instance()
	assert(instance != nil)
	atom := register_window_class(instance, settings.wndproc)
	assert(atom != 0)
	hwnd := create_window(instance, atom, settings.dwStyle, settings.dwExStyle, settings)
	assert(hwnd != nil)
	return hwnd
}

create_and_show_window :: proc(instance: win32.HINSTANCE, atom: win32.ATOM, settings: ^window_settings) -> win32.HWND {
	if settings.dwStyle == 0 {settings.dwStyle = default_dwStyle}
	if settings.dwExStyle == 0 {settings.dwExStyle = default_dwExStyle}
	hwnd: win32.HWND = create_window(instance, atom, settings.dwStyle, settings.dwExStyle, settings)
	if hwnd == nil {
		show_error_and_panic("CreateWindowEx failed")
	}

	win32.ShowWindow(hwnd, win32.SW_SHOWDEFAULT)
	win32.UpdateWindow(hwnd)

	return hwnd
}

pull_messages :: proc() -> bool {
	msg: win32.MSG
	for win32.PeekMessageW(&msg, nil, 0, 0, win32.PM_REMOVE) {

		win32.TranslateMessage(&msg)
		win32.DispatchMessageW(&msg)

		if (msg.message == win32.WM_QUIT) {
			return false
		}
	}
	return true
}

loop_messages :: proc() {
	msg: win32.MSG
	for win32.GetMessageW(&msg, nil, 0, 0) {
		win32.TranslateMessage(&msg)
		win32.DispatchMessageW(&msg)
	}
}

/*run_wndproc :: proc(settings: ^window_settings, wndproc: win32.WNDPROC) -> win32.HWND {
	inst := get_instance()
	atom := register_window_class(inst, wndproc)
	hwnd := create_and_show_window(inst, atom, settings)
	loop_messages()
	return hwnd
}

run_settings :: proc(settings: ^window_settings) -> win32.HWND {
	inst := get_instance()
	atom := register_window_class(inst, settings.wndproc)
	hwnd := create_and_show_window(inst, atom, settings)
	loop_messages()
	return hwnd
}

run :: proc {
	run_settings,
	run_wndproc,
}*/

run :: proc(settings: ^window_settings) -> win32.HWND {
	mh := get_module_handle()
	fmt.println("title:", settings.title)
	if settings.title == "" {
		settings.title = get_module_filename(mh)
		fmt.println("title:", settings.title)
	}
	inst := win32.HINSTANCE(mh)
	atom := register_window_class(inst, settings.wndproc)
	hwnd := create_and_show_window(inst, atom, settings)
	loop_messages()
	return hwnd
}

// default no draw background erase
WM_ERASEBKGND_NODRAW :: #force_inline proc(hwnd: win32.HWND, wparam: win32.WPARAM/*A handle to the device context.*/) -> win32.LRESULT {
	return 1
}

@(private)
RedrawWindowNow :: #force_inline proc(hwnd: HWND) -> BOOL{
	return win32.RedrawWindow(hwnd, nil, nil, .RDW_INVALIDATE | .RDW_UPDATENOW)
}

redraw_window :: proc {
	win32.RedrawWindow,
	RedrawWindowNow,
}

@(private)
SetWindowText :: #force_inline proc(hwnd: HWND, text: string) -> BOOL{
	return win32.SetWindowTextW(hwnd, utf8_to_wstring(text))
}

set_window_textf :: #force_inline proc(hwnd: HWND, format: string, args: ..any) -> BOOL{
	return SetWindowText(hwnd, fmt.tprintf(format, ..args))
}

set_window_text :: proc {
	win32.SetWindowTextW,
	SetWindowText,
}

set_timer :: proc(hwnd: win32.HWND, id_event: UINT_PTR, elapse: win32.UINT) -> win32.UINT_PTR {
	timer_id := win32.SetTimer(hwnd, id_event, elapse, nil)
	if timer_id == 0 {show_error_and_panic("No timer")}
	return timer_id
}

kill_timer :: proc(hwnd: win32.HWND, timer_id: ^win32.UINT_PTR, loc := #caller_location) {
	if timer_id^ != 0 {
		if win32.KillTimer(hwnd, timer_id^) {
			timer_id^ = 0
		} else {
			show_messageboxf("Error", "Unable to kill timer %X\n%v", timer_id^, loc)
		}
	}
}

close_application :: #force_inline proc "contextless" (hwnd: win32.HWND) {
	win32.PostMessageW(hwnd, win32.WM_CLOSE, 0, 0)
}

is_user_interactive :: proc() -> bool {
	is_user_non_interactive := false
	process_window_station := win32.GetProcessWindowStation()
	if process_window_station != nil {
		length_needed: win32.DWORD = 0
		user_object_flags: win32.USEROBJECTFLAGS
		if (win32.GetUserObjectInformationW(win32.HANDLE(process_window_station), .UOI_FLAGS, &user_object_flags, size_of(win32.USEROBJECTFLAGS), &length_needed)) {
			assert(length_needed == size_of(win32.USEROBJECTFLAGS))
			is_user_non_interactive = (user_object_flags.dwFlags & 1) == 0
		}
	}
	return !is_user_non_interactive
}

create_bmi_header :: proc(size: int2, top_down: bool, color_bit_count: win32.WORD, pels_per_meter: int2 = default_pels_per_meter) -> win32.BITMAPINFOHEADER {
	bmp_header := win32.BITMAPINFOHEADER {
		biSize          = size_of(win32.BITMAPINFOHEADER),
		biWidth         = size.x,
		biHeight        = -size.y if top_down else size.y,
		biPlanes        = 1,
		biBitCount      = color_bit_count,
		biCompression   = win32.BI_RGB,
		biSizeImage     = 0,
		biXPelsPerMeter = pels_per_meter.x,
		biYPelsPerMeter = pels_per_meter.y,
		biClrUsed       = 0,
		biClrImportant  = 0,
	}
	return bmp_header
}

delete_object :: proc(bitmap_handle: ^win32.HGDIOBJ) {
	if bitmap_handle^ != nil {
		if win32.DeleteObject(bitmap_handle^) {
			bitmap_handle^ = nil
		}
	}
}

/*key_input :: struct {
}*/

// https://cplusplus.com/reference/cwchar/wprintf/
// int wprintf (const wchar_t* format, ...);
// wtprintf :: proc(format: string, args: ..any) -> win32.wstring {
// 	str := fmt.tprintf(format, ..args)
// 	return utf8_to_wstring(str)
// }
// int fwprintf (FILE* stream, const wchar_t* format, ...);
