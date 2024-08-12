// +build windows
// +vet
package win32app

import "core:fmt"
import "core:time"
import fp "core:path/filepath"
import win32 "core:sys/windows"
//import ow "shared:owin"

int2 :: [2]i32

IDT_TIMER1: win32.UINT_PTR : 10001
IDT_TIMER2: win32.UINT_PTR : 10002
IDT_TIMER3: win32.UINT_PTR : 10003
IDT_TIMER4: win32.UINT_PTR : 10004

decode_lparam_as_int2 :: #force_inline proc "contextless" (lparam: win32.LPARAM) -> int2 {
	return {win32.GET_X_LPARAM(lparam), win32.GET_Y_LPARAM(lparam)}
}

decode_wparam_as_mouse_key_state :: #force_inline proc "contextless" (wparam: win32.WPARAM) -> MOUSE_KEY_STATE {
	return transmute(MOUSE_KEY_STATE)win32.DWORD(wparam)
}

show_message_box :: #force_inline proc(caption: string, text: string, type: UINT = win32.MB_ICONSTOP | win32.MB_OK) {
	win32.MessageBoxW(nil, utf8_to_wstring(text), utf8_to_wstring(caption), type)
}

show_message_boxf :: #force_inline proc(caption: string, format: string, args: ..any) {
	show_message_box(caption, fmt.tprintf(format, ..args))
}

show_error :: #force_inline proc(msg: string, loc := #caller_location) {
	show_message_boxf("Panic", "%s\nLast error: %x\n%v\n", msg, win32.GetLastError(), loc)
}

show_error_and_panic :: proc(msg: string, loc := #caller_location) {
	show_error(msg, loc = loc)
	fmt.panicf("%s (Last error: %x)", msg, win32.GetLastError(), loc = loc)
}

show_error_and_panicf :: proc(format: string, args: ..any, loc := #caller_location) {
	show_error_and_panic(fmt.tprintf(format, ..args), loc = loc)
}

show_last_error :: proc(caption: string, loc := #caller_location) {
	fmt.eprintln(caption)
	last_error := win32.GetLastError()
	error_text: [512]win32.WCHAR
	error_wstring := wstring(&error_text)
	cch := win32.FormatMessageW(win32.FORMAT_MESSAGE_FROM_SYSTEM | win32.FORMAT_MESSAGE_IGNORE_INSERTS, nil, last_error, LANGID_NEUTRAL_DEFAULT, error_wstring, len(error_text) - 1, nil)
	if (cch != 0) {return}
	error_string, err := wstring_to_utf8(&error_wstring[0], int(cch))
	if err == .None {
		fmt.eprintln(error_string)
	} else {
		fmt.eprintfln("Last error code: %d (0x%8X)", last_error)
	}
}

show_last_errorf :: #force_inline proc(format: string, args: ..any, loc := #caller_location) {
	show_last_error(fmt.tprintf(format, ..args), loc = loc)
}

get_rect_size :: #force_inline proc "contextless" (rect: ^RECT) -> int2 {
	return {(rect.right - rect.left), (rect.bottom - rect.top)}
}

get_client_size :: proc "contextless" (hwnd: HWND) -> int2 {
	rect: RECT
	win32.GetClientRect(hwnd, &rect)
	return get_rect_size(&rect)
}

adjust_window_size :: proc "contextless" (size: int2, dwStyle, dwExStyle: u32) -> int2 {
	rect := RECT{0, 0, size.x, size.y}
	if win32.AdjustWindowRectEx(&rect, dwStyle, false, dwExStyle) {
		return get_rect_size(&rect)
	}
	return size
}

adjust_size_for_style :: proc(size: ^int2, dwStyle: win32.DWORD) {
	rect := RECT{0, 0, size.x, size.y}
	if win32.AdjustWindowRect(&rect, dwStyle, false) {
		size^ = get_rect_size(&rect)
	}
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
	if (module_handle == nil) {show_error_and_panic("No Module Handle")}
	return module_handle
}

get_instance :: proc() -> HINSTANCE {
	instance := win32.HINSTANCE(win32.GetModuleHandleW(nil))
	if (instance == nil) {show_error_and_panic("No instance")}
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

IDI_ICON1 :: 101

register_window_class :: proc(instance: HINSTANCE, wndproc: win32.WNDPROC) -> win32.ATOM {

	icon: win32.HICON = win32.LoadIconW(instance, win32.MAKEINTRESOURCEW(IDI_ICON1))
	if icon == nil {icon = win32.LoadIconW(nil, win32.wstring(win32._IDI_APPLICATION))}
	if icon == nil {icon = win32.LoadIconW(nil, win32.wstring(win32._IDI_QUESTION))}
	if icon == nil {show_error_and_panic("Missing icon")}

	cursor: win32.HCURSOR = win32.LoadCursorW(nil, win32.wstring(win32._IDC_ARROW))
	if cursor == nil {show_error_and_panic("Missing cursor")}

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
	if atom == 0 {show_error_and_panic("Failed to register window class")}
	return atom
}

unregister_window_class :: proc(atom: win32.ATOM, instance: win32.HINSTANCE) {
	if atom == 0 {show_error_and_panic("atom is zero")}
	if !win32.UnregisterClassW(win32.LPCWSTR(uintptr(atom)), instance) {show_error_and_panic("UnregisterClassW")}
}

create_window :: proc(instance: win32.HINSTANCE, atom: win32.ATOM, dwStyle, dwExStyle: u32, settings: ^window_settings) -> win32.HWND {
	if atom == 0 {show_error_and_panic("atom is zero")}

	size := adjust_window_size(settings.window_size, dwStyle, dwExStyle)
	position := get_window_position(size, settings.center)

	return win32.CreateWindowExW(dwExStyle, win32.LPCWSTR(uintptr(atom)), utf8_to_wstring(settings.title), dwStyle, position.x, position.y, size.x, size.y, nil, nil, instance, settings)
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
	sleep:       time.Duration,
}
psettings :: ^window_settings

set_settings :: #force_inline proc(hwnd: win32.HWND, settings: psettings) {win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, win32.LONG_PTR(uintptr(settings)))}
get_settings :: #force_inline proc(hwnd: win32.HWND) -> psettings {return (psettings)(rawptr(uintptr(win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA))))}

@(private = "file")
create_window_settings_sw :: proc(size: int2, wndproc: win32.WNDPROC) -> window_settings {
	fmt.println(#procedure)
	settings: window_settings = {
		window_size = size,
		center      = true,
		wndproc     = wndproc,
		dwStyle     = default_dwStyle,
		dwExStyle   = default_dwExStyle,
		run         = run,
		sleep       = time.Millisecond * 10,
	}
	return settings
}

@(private = "file")
create_window_settings_tsw :: proc(title: string, size: int2, wndproc: win32.WNDPROC) -> window_settings {
	fmt.println(#procedure)
	settings := create_window_settings_sw(size, wndproc)
	settings.title = title
	return settings
}

@(private = "file")
create_window_settings_twhw :: #force_inline proc(title: string, width: i32, height: i32, wndproc: win32.WNDPROC) -> window_settings {
	fmt.println(#procedure)
	return create_window_settings_tsw(title, {width, height}, wndproc)
}

@(private = "file")
create_window_settings_sw2 :: #force_inline proc(size: int2, wndproc: WNDPROC) -> window_settings {
	fmt.println(#procedure)
	return create_window_settings_sw(size, win32.WNDPROC(wndproc))
}

@(private = "file")
create_window_settings_tsw2 :: #force_inline proc(title: string, size: int2, wndproc: WNDPROC) -> window_settings {
	fmt.println(#procedure)
	return create_window_settings_tsw(title, size, win32.WNDPROC(wndproc))
}

create_window_settings :: proc {
	create_window_settings_sw,
	create_window_settings_tsw,
	create_window_settings_twhw,
	create_window_settings_sw2,
	create_window_settings_tsw2,
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

prepare_run :: proc(settings: ^window_settings) -> (inst: win32.HINSTANCE, atom: win32.ATOM, hwnd: win32.HWND) {
	module_handle := get_module_handle()
	if settings.title == "" {
		settings.title = fp.stem(get_module_filename(module_handle))
	}
	inst = win32.HINSTANCE(module_handle)
	atom = register_window_class(inst, settings.wndproc)
	hwnd = create_and_show_window(inst, atom, settings)
	return
}

run :: proc(settings: ^window_settings) -> win32.HWND {
	_, _, hwnd := prepare_run(settings)
	loop_messages()
	return hwnd
}

// run :: proc(settings: ^window_settings, ) {
// 	_, _, hwnd := win32app.prepare_run(&settings)
// 	for win32app.pull_messages() {

// 		//delta = stopwatch->get_delta_seconds()
// 		//frame_time += delta
// 		//res = app.update(&app)
// 	}
// }

// default no draw background erase
WM_ERASEBKGND_NODRAW :: #force_inline proc(hwnd: win32.HWND, wparam: win32.WPARAM) -> win32.LRESULT {
	return 1
}

@(private)
RedrawWindowNow :: #force_inline proc(hwnd: HWND) -> BOOL {
	return win32.RedrawWindow(hwnd, nil, nil, .RDW_INVALIDATE | .RDW_UPDATENOW | .RDW_NOCHILDREN)
}

redraw_window :: proc {
	win32.RedrawWindow,
	RedrawWindowNow,
}

invalidate :: #force_inline proc "contextless" (hwnd: win32.HWND) {
	win32.InvalidateRect(hwnd, nil, false)
}

@(private)
SetWindowText :: #force_inline proc(hwnd: HWND, text: string) -> BOOL {
	return win32.SetWindowTextW(hwnd, utf8_to_wstring(text))
}

set_window_textf :: #force_inline proc(hwnd: HWND, format: string, args: ..any) -> BOOL {
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
			show_message_boxf("Error", "Unable to kill timer %X\n%v", timer_id^, loc)
		}
	}
}

close_application :: #force_inline proc "contextless" (hwnd: win32.HWND) {
	win32.PostMessageW(hwnd, win32.WM_CLOSE, 0, 0)
}

post_quit_message :: #force_inline proc "contextless" (#any_int exit_code: INT = 0) {
	win32.PostQuitMessage(exit_code)
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

create_bmi_header :: proc(size: int2, top_down: bool, color_bit_count: win32.WORD) -> win32.BITMAPINFOHEADER {
	bmp_header := win32.BITMAPINFOHEADER {
		biSize        = size_of(win32.BITMAPINFOHEADER),
		biWidth       = size.x,
		biHeight      = -size.y if top_down else size.y,
		biPlanes      = 1,
		biBitCount    = color_bit_count,
		biCompression = win32.BI_RGB,
	}
	return bmp_header
}

create_dib_section :: #force_inline proc "contextless" (hdc: HDC, pbmi: ^win32.BITMAPINFO, usage: UINT, ppvBits: win32.VOID, hSection: HANDLE = nil, offset: DWORD = 0) -> HBITMAP {
	return win32.CreateDIBSection(hdc, pbmi, usage, ppvBits, hSection, offset)
}

@(private)
delete_object_hgdiobj :: #force_inline proc "contextless" (hgdiobj: ^HGDIOBJ) -> bool {
	if hgdiobj^ != nil {
		if win32.DeleteObject(hgdiobj^) {
			hgdiobj^ = nil
			return true
		}
	}
	return false
}

@(private)
delete_object_hbitmap :: #force_inline proc "contextless" (hbitmap: ^HBITMAP) -> bool {
	return delete_object_hgdiobj((^HGDIOBJ)(hbitmap))
}

delete_object :: proc {
	delete_object_hgdiobj,
	delete_object_hbitmap,
}

/*key_input :: struct {
}*/

get_createstruct_from_lparam :: #force_inline proc "contextless" (lparam: win32.LPARAM) -> ^CREATESTRUCTW {
	return (^CREATESTRUCTW)(rawptr(uintptr(lparam)))
}

get_settings_from_createstruct :: #force_inline proc "contextless" (pcs: ^CREATESTRUCTW) -> psettings {
	return psettings(pcs.lpCreateParams) if pcs != nil else nil
}

get_settings_from_lparam :: #force_inline proc(lparam: win32.LPARAM) -> psettings {
	pcs := get_createstruct_from_lparam(lparam)
	return get_settings_from_createstruct(pcs)
}

show_cursor :: #force_inline proc "contextless" (show: bool) -> INT {
	return win32.ShowCursor(win32.BOOL(show))
}

clip_cursor :: proc(hwnd: win32.HWND, clip: bool) -> (ok: bool) {
	if clip {
		rect: win32.RECT
		ok = bool(win32.GetWindowRect(hwnd, &rect))
		if ok {
			ok = bool(win32.ClipCursor(&rect))
		}
	} else {
		ok = bool(win32.ClipCursor(nil))
	}
	return
}

draw_marker :: proc(hdc: HDC, p: int2, size: i32 = 10) {
	// win32.BeginPath(hdc)
	win32.MoveToEx(hdc, p.x - size, p.y, nil)
	win32.LineTo(hdc, p.x + size, p.y)
	win32.MoveToEx(hdc, p.x, p.y - size, nil)
	win32.LineTo(hdc, p.x, p.y + size)
	// win32.EndPath(hdc)
	// win32.StrokePath(hdc)
}

draw_grid :: proc(hdc: HDC, p, cell, dim: int2) {
	// win32.BeginPath(hdc)
	size := cell * dim
	x, y: i32
	for i in 0 ..< dim.x {
		x = i * cell.x
		win32.MoveToEx(hdc, x, 0, nil)
		win32.LineTo(hdc, x, size.y)
	}
	for i in 0 ..< dim.y {
		y = i * cell.y
		win32.MoveToEx(hdc, 0, y, nil)
		win32.LineTo(hdc, size.x, y)
	}

	// win32.EndPath(hdc)
	// win32.StrokePath(hdc)
}

/*
	ok: win32.BOOL
	pts: [2]win32.POINT
	pts[0] = {p.x - siz, p.y}
	pts[1] = {p.x + siz, p.y}
	ok = win32.Polyline(hdc, &pts[0], 2)
	assert(ok == true, "Polyline")
	pts[0] = {p.x, p.y - siz}
	pts[1] = {p.x, p.y + siz}
	ok = win32.Polyline(hdc, &pts[0], 2)
	assert(ok == true, "Polyline")
*/

/*
void Marker(LONG x, LONG y, HWND hwnd)
{
    HDC hdc;

    hdc = GetDC(hwnd);
        MoveToEx(hdc, (int) x - 10, (int) y, nil);
        LineTo(hdc, (int) x + 10, (int) y);
        MoveToEx(hdc, (int) x, (int) y - 10, nil);
        LineTo(hdc, (int) x, (int) y + 10);

    ReleaseDC(hwnd, hdc);
}
*/

@(private)
select_object_hbitmap :: #force_inline proc "contextless" (hdc: win32.HDC, hbitmap: win32.HBITMAP) -> win32.HGDIOBJ {
	return win32.SelectObject(hdc, win32.HGDIOBJ(hbitmap))
}

select_object :: proc {
	win32.SelectObject,
	select_object_hbitmap,
}

@(private)
stretch_blt_size :: #force_inline proc "contextless" (dest_hdc: HDC, dest_size: int2, src_hdc: HDC, src_size: int2, rop: win32.ROP = .SRCCOPY) -> BOOL {
	return win32.StretchBlt(dest_hdc, 0, 0, dest_size.x, dest_size.y, src_hdc, 0, 0, src_size.x, src_size.y, win32.DWORD(rop))
}

stretch_blt :: proc {
	win32.StretchBlt,
	stretch_blt_size,
}

@(private)
bit_blt_size :: #force_inline proc "contextless" (dest_hdc: HDC, size: int2, src_hdc: HDC, rop: win32.ROP = .SRCCOPY) -> BOOL {
	return win32.BitBlt(dest_hdc, 0, 0, size.x, size.y, src_hdc, 0, 0, win32.DWORD(rop))
}

bit_blt :: proc {
	win32.BitBlt,
	bit_blt_size,
}
