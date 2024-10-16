#+build windows
#+vet
package win32app

import "core:fmt"
import fp "core:path/filepath"
import win32 "core:sys/windows"
//import ow "shared:owin"

get_module_handle :: proc(lpModuleName: wstring = nil) -> HMODULE {
	module_handle := win32.GetModuleHandleW(lpModuleName)
	if (module_handle == nil) {show_error_and_panic("No Module Handle")}
	return module_handle
}

// get_instance :: proc() -> HINSTANCE {return HINSTANCE(get_module_handle())}

get_module_filename :: proc(module: HMODULE, allocator := context.temp_allocator) -> string {
	wname: [512]WCHAR
	cc := win32.GetModuleFileNameW(module, &wname[0], len(wname) - 1)
	if cc > 0 {
		name, err := wstring_to_utf8(&wname[0], int(cc), allocator)
		if err == .None {
			return name
		}
	}
	return "?"
}

load_icon :: proc(instance: HINSTANCE) -> HICON {
	icon: HICON = win32.LoadIconW(instance, win32.MAKEINTRESOURCEW(IDI_ICON1))
	if icon == nil {icon = win32.LoadIconW(nil, wstring(win32._IDI_APPLICATION))}
	if icon == nil {icon = win32.LoadIconW(nil, wstring(win32._IDI_QUESTION))}
	if icon == nil {show_error_and_panic("Missing icon")}
	return icon
}

load_cursor :: proc() -> HCURSOR {
	cursor: HCURSOR = win32.LoadCursorW(nil, wstring(win32._IDC_ARROW))
	if cursor == nil {show_error_and_panic("Missing cursor")}
	return cursor
}

register_window_class :: proc(instance: HINSTANCE, wndproc: win32.WNDPROC) -> ATOM {

	icon := load_icon(instance)
	cursor := load_cursor()

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

	atom := win32.RegisterClassExW(&wcx)
	if atom == 0 {show_error_and_panic("Failed to register window class")}
	return atom
}

unregister_window_class :: proc(atom: ATOM, instance: HINSTANCE) {
	if atom == 0 {show_error_and_panic("atom is zero")}
	if !win32.UnregisterClassW(win32.LPCWSTR(uintptr(atom)), instance) {show_error_and_panic("UnregisterClassW")}
}

create_window :: proc(instance: HINSTANCE, atom: ATOM, settings: ^window_settings) -> HWND {
	if atom == 0 {show_error_and_panic("atom is zero")}

	if settings.dwStyle == {} {settings.dwStyle = default_dwStyle}
	if settings.dwExStyle == {} {settings.dwExStyle = default_dwExStyle}

	size := adjust_window_size(settings.window_size, settings.dwStyle, settings.dwExStyle)
	position := get_window_position(size, settings.center)

	hwnd := win32.CreateWindowExW(settings.dwExStyle, win32.LPCWSTR(uintptr(atom)), utf8_to_wstring(settings.title), settings.dwStyle, position.x, position.y, size.x, size.y, nil, nil, instance, settings)
	if hwnd == nil {show_error_and_panic("create_window failed")}
	return hwnd
}

register_and_create_window :: proc(settings: ^window_settings) -> (instance: HINSTANCE, atom: ATOM, hwnd: HWND) {
	module_handle := get_module_handle()
	if settings.title == "" {
		settings.title = fp.stem(get_module_filename(module_handle))
	}
	instance = win32.HINSTANCE(module_handle)
	atom = register_window_class(instance, settings.wndproc)
	hwnd = create_window(instance, atom, settings)
	return
}

show_and_update_window :: proc(hwnd: HWND, nCmdShow: win32.INT = win32.SW_SHOWDEFAULT) {
	win32.ShowWindow(hwnd, nCmdShow)
	win32.UpdateWindow(hwnd)
}

translate_and_dispatch_message :: #force_inline proc "contextless" (msg: ^win32.MSG) {
	win32.TranslateMessage(msg)
	win32.DispatchMessageW(msg)
}

pull_messages :: proc(hwnd: HWND = nil) -> bool {
	msg: win32.MSG
	for win32.PeekMessageW(&msg, hwnd, 0, 0, win32.PM_REMOVE) {

		translate_and_dispatch_message(&msg)

		if (msg.message == win32.WM_QUIT) {
			//fmt.printfln("msg.wParam=", msg.wParam)
			return false
		}
	}
	return true
}

pull_messages_msg :: proc(msg: ^win32.MSG, hwnd: HWND = nil) -> bool {
	for win32.PeekMessageW(msg, hwnd, 0, 0, win32.PM_REMOVE) {

		translate_and_dispatch_message(msg)

		if (msg.message == win32.WM_QUIT) {
			//fmt.printfln("msg.wParam=", msg.wParam)
			return false
		}
	}
	return true
}

loop_messages :: proc(hwnd: HWND = nil) -> int {
	msg: win32.MSG
	for win32.GetMessageW(&msg, hwnd, 0, 0) > 0 {
		win32.TranslateMessage(&msg)
		win32.DispatchMessageW(&msg)
	}
	return int(msg.wParam)
}

prepare_run :: proc(settings: ^window_settings) -> (inst: HINSTANCE, atom: ATOM, hwnd: HWND) {
	inst, atom, hwnd = register_and_create_window(settings)
	show_and_update_window(hwnd)
	return
}

run :: proc(settings: ^window_settings) -> int {
	_, _, _ = prepare_run(settings)
	exit_code := loop_messages()
	return exit_code
}

// default no draw background erase
WM_ERASEBKGND_NODRAW :: #force_inline proc(hwnd: HWND, wparam: WPARAM) -> LRESULT {
	return 1
}

@(private = "file")
redraw_window_now :: #force_inline proc(hwnd: HWND) -> BOOL {
	return win32.RedrawWindow(hwnd, nil, nil, .RDW_INVALIDATE | .RDW_UPDATENOW | .RDW_NOCHILDREN)
}

redraw_window :: proc {
	win32.RedrawWindow,
	redraw_window_now,
}

invalidate_window :: #force_inline proc "contextless" (hwnd: HWND) {
	win32.InvalidateRect(hwnd, nil, false)
}

@(private = "file")
set_window_text_utf8 :: #force_inline proc(hwnd: HWND, text: string) -> BOOL {
	return win32.SetWindowTextW(hwnd, utf8_to_wstring(text))
}

@(private = "file")
set_window_textf :: #force_inline proc(hwnd: HWND, format: string, args: ..any) -> BOOL {
	return set_window_text_utf8(hwnd, fmt.tprintf(format, ..args))
}

set_window_text :: proc {
	win32.SetWindowTextW,
	set_window_text_utf8,
	set_window_textf,
}

set_timer :: proc(hwnd: HWND, id_event: UINT_PTR, elapse: UINT) -> UINT_PTR {
	timer_id := win32.SetTimer(hwnd, id_event, elapse, nil)
	if timer_id == 0 {show_error_and_panic("No timer")}
	return timer_id
}

kill_timer :: proc(hwnd: HWND, timer_id: ^UINT_PTR, loc := #caller_location) {
	if timer_id^ != 0 {
		if win32.KillTimer(hwnd, timer_id^) {
			timer_id^ = 0
		} else {
			show_message_boxf("Error", "Unable to kill timer %X\n%v", timer_id^, loc)
		}
	}
}

close_application :: #force_inline proc "contextless" (hwnd: HWND) {
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

dib_usage :: enum UINT {
	DIB_RGB_COLORS = win32.DIB_RGB_COLORS,
	DIB_PAL_COLORS = win32.DIB_PAL_COLORS,
}

create_dib_section :: #force_inline proc "contextless" (hdc: HDC, pbmi: ^win32.BITMAPINFO, usage: dib_usage, ppvBits: win32.VOID, hSection: HANDLE = nil, offset: DWORD = 0) -> HBITMAP {
	return win32.CreateDIBSection(hdc, pbmi, UINT(usage), ppvBits, hSection, offset)
}

@(private = "file")
delete_object_hgdiobj :: #force_inline proc "contextless" (hgdiobj: ^HGDIOBJ) -> bool {
	if hgdiobj^ != nil {
		if win32.DeleteObject(hgdiobj^) {
			hgdiobj^ = nil
			return true
		}
	}
	return false
}

@(private = "file")
delete_object_hbitmap :: #force_inline proc "contextless" (hbitmap: ^HBITMAP) -> bool {
	return delete_object_hgdiobj((^HGDIOBJ)(hbitmap))
}

delete_object :: proc {
	delete_object_hgdiobj,
	delete_object_hbitmap,
}

/*key_input :: struct {
}*/

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
	win32.MoveToEx(hdc, p.x - size, p.y, nil)
	win32.LineTo(hdc, p.x + size, p.y)
	win32.MoveToEx(hdc, p.x, p.y - size, nil)
	win32.LineTo(hdc, p.x, p.y + size)
}

draw_grid :: proc(hdc: HDC, p, cell, dim: int2) {
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

@(private = "file")
select_object_hbitmap :: #force_inline proc "contextless" (hdc: win32.HDC, hbitmap: win32.HBITMAP) -> win32.HGDIOBJ {
	return win32.SelectObject(hdc, win32.HGDIOBJ(hbitmap))
}

select_object :: proc {
	win32.SelectObject,
	select_object_hbitmap,
}

@(private = "file")
stretch_blt_size :: #force_inline proc "contextless" (dest_hdc: HDC, dest_size: int2, src_hdc: HDC, src_size: int2, rop: win32.ROP = .SRCCOPY) -> BOOL {
	return win32.StretchBlt(dest_hdc, 0, 0, dest_size.x, dest_size.y, src_hdc, 0, 0, src_size.x, src_size.y, win32.DWORD(rop))
}

stretch_blt :: proc {
	win32.StretchBlt,
	stretch_blt_size,
}

@(private = "file")
bit_blt_size :: #force_inline proc "contextless" (dest_hdc: HDC, size: int2, src_hdc: HDC, rop: win32.ROP = .SRCCOPY) -> BOOL {
	return win32.BitBlt(dest_hdc, 0, 0, size.x, size.y, src_hdc, 0, 0, win32.DWORD(rop))
}

bit_blt :: proc {
	win32.BitBlt,
	bit_blt_size,
}
