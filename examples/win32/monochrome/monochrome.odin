package monochrome

import "base:intrinsics"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "base:runtime"
import "core:time"
import win32 "core:sys/windows"

// defines
L				:: intrinsics.constant_utf16_cstring
color			:: [4]u8
wstring			:: win32.wstring
utf8_to_wstring	:: win32.utf8_to_wstring
int2			:: [2]i32

// constants
COLOR_MODE :: 2

BLACK :: color{0, 0, 0, 255}
WHITE :: color{255, 255, 255, 255}

//TITLE :: "Monochrome Bitmap"
WIDTH :: 320
HEIGHT :: 200
CENTER :: true

ZOOM :: 1
FPS :: 10

IDT_TIMER1: win32.UINT_PTR : 10001

color_bits :: 1
palette_count :: 1 << color_bits
color_palette :: [palette_count]color

BITMAPINFO :: struct {
	bmiHeader: win32.BITMAPINFOHEADER,
	bmiColors: color_palette,
}

screen_buffer :: [^]u8
bwidth :: WIDTH / ZOOM
bheight :: HEIGHT / ZOOM

msg: [6]wstring = {L("Tik"), L("Tok"), L("Ping"), L("Pong"), L("Yin"), L("Yang")}

print_info :: proc() {
	fmt.printfln("color_bits             =%v", color_bits)
	fmt.printfln("palette_count          =%v", palette_count)
	fmt.printfln("len(color_palette)     =%v", len(color_palette))
	fmt.printfln("size_of(color)         =%v", size_of(color))
	fmt.printfln("size_of(color_palette) =%v", size_of(color_palette))
}

ConfigFlag :: enum u32 {
	CENTER = 1,
}
ConfigFlags :: distinct bit_set[ConfigFlag;u32]

Window :: struct {
	name:          wstring,
	size:          int2,
	fps:           i32,
	control_flags: ConfigFlags,
}

Game :: struct {
	tick_rate: time.Duration,
	last_tick: time.Time,
	pause:     bool,
	colors:    []color,
	size:      int2,
	timer_id:  win32.UINT_PTR,
	tick:      u32,
	hbitmap:   win32.HBITMAP,
	pvBits:    screen_buffer,
}

show_error_and_panic :: proc(msg: string, loc := #caller_location) {
	text := win32.utf8_to_wstring(fmt.tprintf("%s\nLast error: %x\n", msg, win32.GetLastError()))
	win32.MessageBoxW(nil, text, L("Panic"), win32.MB_ICONSTOP | win32.MB_OK)
	panic(msg, loc = loc)
}

get_rect_size :: #force_inline proc(rect: ^win32.RECT) -> int2 {return {(rect.right - rect.left), (rect.bottom - rect.top)}}

set_app :: #force_inline proc(hwnd: win32.HWND, app: ^Game) {win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, win32.LONG_PTR(uintptr(app)))}

get_app :: #force_inline proc(hwnd: win32.HWND) -> ^Game {return (^Game)(rawptr(uintptr(win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA))))}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	pcs := (^win32.CREATESTRUCTW)(rawptr(uintptr(lparam)))
	app := (^Game)(pcs.lpCreateParams)
	if app == nil {show_error_and_panic("Missing app!")}
	fmt.println(#procedure, hwnd, pcs, app)
	set_app(hwnd, app)

	app.timer_id = win32.SetTimer(hwnd, IDT_TIMER1, 1000 / FPS, nil)
	if app.timer_id == 0 {show_error_and_panic("No timer")}

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	bitmap_info := BITMAPINFO {
		bmiHeader = win32.BITMAPINFOHEADER {
			biSize          = size_of(win32.BITMAPINFOHEADER),
			biWidth         = bwidth,
			biHeight        = -bheight, // minus for top-down
			biPlanes        = 1,
			biBitCount      = 1,
			biCompression   = win32.BI_RGB,
			biClrUsed       = 2,
		},
	}

	if palette_count > 1 {
		scale := 1 / f32(palette_count - 1);rbg: [3]f32;w: f32
		for i in 0 ..< palette_count {
			w = scale * f32(i)
			when COLOR_MODE == 1 {
				rbg = [3]f32{rand.float32(), rand.float32(), rand.float32()}
			} else {
				rbg = [3]f32{w, w, w}
			}
			rbg *= 255
			bitmap_info.bmiColors[i] = color{u8(rbg.b), u8(rbg.g), u8(rbg.r), 0}
		}
	}

	when COLOR_MODE == 2 {
		if palette_count >= 2 {
			bitmap_info.bmiColors[0] = color{255, 0, 0, 0}
			bitmap_info.bmiColors[1] = color{0, 255, 255, 0}
		}
	}

	app.hbitmap = win32.CreateDIBSection(hdc, cast(^win32.BITMAPINFO)&bitmap_info, win32.DIB_RGB_COLORS, &app.pvBits, nil, 0)

	fmt.println("app.hbitmap:", app.hbitmap, app.pvBits)
	pvBits := app.pvBits
	if pvBits != nil {
		for i in 0 ..< bwidth * bheight / 8 {
			pvBits[i] = u8(rand.int31_max(255))
		}
	}

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	app := get_app(hwnd)
	fmt.println(#procedure, hwnd, app)
	if app == nil {show_error_and_panic("Missing app!")}
	if app.timer_id != 0 {
		if !win32.KillTimer(hwnd, app.timer_id) {
			win32.MessageBoxW(nil, L("Unable to kill timer"), L("Error"), win32.MB_OK)
		}
		app.timer_id = 0
	}
	if app.hbitmap != nil {
		if !win32.DeleteObject(win32.HGDIOBJ(app.hbitmap)) {
			win32.MessageBoxW(nil, L("Unable to delete hbitmap"), L("Error"), win32.MB_OK)
		}
		app.hbitmap = nil
	}
	win32.PostQuitMessage(0) // exit code
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	app := get_app(hwnd)
	if app == nil {return 0}

	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps)
	defer win32.EndPaint(hwnd, &ps)

	if (app.hbitmap != nil) {
		hdc_source := win32.CreateCompatibleDC(ps.hdc)
		defer win32.DeleteDC(hdc_source)

		win32.SelectObject(hdc_source, win32.HGDIOBJ(app.hbitmap))
		client_size := get_rect_size(&ps.rcPaint)
		//win32.BitBlt(ps.hdc, 0, 0, bwidth, bheight, hdc_source, 0, 0, win32.SRCCOPY)
		win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, bwidth, bheight, win32.SRCCOPY)
	}

	win32.SetBkMode(ps.hdc, .TRANSPARENT)
	win32.DrawTextW(ps.hdc, msg[app.tick % len(msg)], -1, &ps.rcPaint, .DT_SINGLELINE | .DT_CENTER | .DT_VCENTER)

	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch win32.UINT_PTR(wparam) {
	case IDT_TIMER1:
		app := get_app(hwnd)
		if app != nil {
			app.tick += 1
			win32.RedrawWindow(hwnd, nil, nil, .RDW_INVALIDATE | .RDW_UPDATENOW)
		}
	case:
		fmt.println(#procedure, hwnd, wparam, lparam)
	}
	return 0
}


// odinfmt: disable

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b':	win32.PostMessageW(hwnd, win32.WM_CLOSE, 0, 0)
	case '\t':		fmt.println("tab")
	case '\r':		fmt.println("return")
	case 'p':		show_error_and_panic("Test Panic")
	}
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:	return 1
	case win32.WM_PAINT:		return WM_PAINT(hwnd)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_TIMER:		return WM_TIMER(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

// odinfmt: enable

register_class :: proc(instance: win32.HINSTANCE) -> win32.ATOM {
	icon: win32.HICON = win32.LoadIconW(instance, win32.MAKEINTRESOURCEW(1))
	if icon == nil {icon = win32.LoadIconW(nil, win32.wstring(win32._IDI_APPLICATION))}
	if icon == nil {show_error_and_panic("Missing icon")}
	cursor := win32.LoadCursorW(nil, wstring(win32._IDC_ARROW))
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
	return win32.RegisterClassExW(&wcx)
}

unregister_class :: proc(atom: win32.ATOM, instance: win32.HINSTANCE) {
	if atom == 0 {show_error_and_panic("atom is zero")}
	if !win32.UnregisterClassW(win32.LPCWSTR(uintptr(atom)), instance) {show_error_and_panic("UnregisterClassW")}
}

adjust_size_for_style :: proc(size: ^int2, dwStyle: win32.DWORD) {
	rect := win32.RECT{0, 0, size.x, size.y}
	if win32.AdjustWindowRect(&rect, dwStyle, false) {
		size^ = {i32(rect.right - rect.left), i32(rect.bottom - rect.top)}
	}
}

center_window :: proc(position: ^int2, size: int2) {
	if deviceMode: win32.DEVMODEW; win32.EnumDisplaySettingsW(nil, win32.ENUM_CURRENT_SETTINGS, &deviceMode) {
		dmsize := int2{i32(deviceMode.dmPelsWidth), i32(deviceMode.dmPelsHeight)} // is there an easier way to describe this?
		position^ = (dmsize - size) / 2
	}
}

create_window :: #force_inline proc(atom: win32.ATOM, window_name: win32.LPCTSTR, style, ex_style: win32.DWORD, position: int2, size: int2, instance: win32.HINSTANCE, lpParam: win32.LPVOID) -> win32.HWND {
	if atom == 0 {show_error_and_panic("atom is zero")}
	return win32.CreateWindowExW(ex_style, win32.LPCWSTR(uintptr(atom)), window_name, style, position.x, position.y, size.x, size.y, nil, nil, instance, lpParam)
}

message_loop :: proc() -> int {
	msg: win32.MSG
	for win32.GetMessageW(&msg, nil, 0, 0) > 0 {
		win32.TranslateMessage(&msg)
		win32.DispatchMessageW(&msg)
	}
	return int(msg.wParam)
}

run :: proc() -> int {
	window := Window {
		name = L("Monochrome Bitmap"),
		size = {640, 400},
		fps  = 60,
		control_flags = {.CENTER},
	}
	game := Game {
		tick_rate = 300 * time.Millisecond,
		last_tick = time.now(),
		pause     = true,
		colors    = []color{BLACK, WHITE},
		size      = {64, 64},
		//window    = window,
	}
	fmt.printfln("game=%p\n%v", &game, game)
	defer fmt.printfln("game=%p\n%v", &game, game)

	instance := win32.HINSTANCE(win32.GetModuleHandleW(nil))
	if (instance == nil) {show_error_and_panic("No instance")}
	atom := register_class(instance)
	if atom == 0 {show_error_and_panic("Failed to register window class")}
	defer unregister_class(atom, instance)

	dwStyle :: win32.WS_OVERLAPPED | win32.WS_CAPTION | win32.WS_SYSMENU
	dwExStyle :: win32.WS_EX_OVERLAPPEDWINDOW

	size := window.size
	position := int2{i32(win32.CW_USEDEFAULT), i32(win32.CW_USEDEFAULT)}
	adjust_size_for_style(&size, dwStyle)
	if .CENTER in window.control_flags {
		center_window(&position, size)
	}
	hwnd := create_window(atom, window.name, dwStyle, dwExStyle, position, size, instance, &game)
	if hwnd == nil {show_error_and_panic("Failed to create window")}

	win32.ShowWindow(hwnd, win32.SW_SHOWDEFAULT)
	win32.UpdateWindow(hwnd)

	return message_loop()
}

main :: proc() {
	exit_code := run()
	print_info()
	fmt.println("Done.", exit_code)
	os.exit(exit_code)
}
