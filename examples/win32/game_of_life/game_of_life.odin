// +vet
package game_of_life

/*********************************************************************
                            GAME  OF  LIFE
                            (using win32)

 This example shows a simple setup for a game with Input processing,
 updating game state and drawing game state to the screen.

 You can
 * Left-Click to bring a cell alive
 * Right-Click to kill a cell
 * Press <Space> to (un)pause the game
 * Press <Esc> to close the game

 The game starts paused.

**********************************************************************/

import "base:intrinsics"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "base:runtime"
import win32 "core:sys/windows"
import "core:time"
import win32app "libs:tlc/win32app"

// defines
L				:: intrinsics.constant_utf16_cstring
wstring			:: win32.wstring
//utf8_to_wstring	:: win32.utf8_to_wstring
color			:: [4]u8
int2			:: [2]i32

show_error_and_panic :: win32app.show_error_and_panic

// constants
COLOR_MODE :: 1

BLACK :: color{0, 0, 0, 255}
WHITE :: color{255, 255, 255, 255}

TITLE :: "Game Of Life"
WIDTH :: 512
HEIGHT :: 512
CENTER :: true

ZOOM :: 4
FPS :: 10

HELP := L(`ESC - Quit
P - Toggle Pause
H - Toggle Help
C - Change Colors`)
show_help := true

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
	tick_rate:         time.Duration,
	last_tick:         time.Time,
	pause:             bool,
	colors:            []color,
	size:              int2,
	world, next_world: ^World,
	timer_id:          win32.UINT_PTR,
	tick:              u32,
	hbitmap:           win32.HBITMAP,
	pvBits:            screen_buffer,
}

World :: struct {
	width:  i32,
	height: i32,
	alive:  []u8,
}

Cell :: struct {
	width:  f32,
	height: f32,
}

User_Input :: struct {
	left_mouse_clicked:   bool,
	right_mouse_clicked:  bool,
	toggle_pause:         bool,
	mouse_world_position: i32,
	mouse_tile_x:         i32,
	mouse_tile_y:         i32,
}


/*
 Game Of Life rules:
 * (1) A cell with 2 alive neighbors stays alive/dead
 * (2) A cell with 3 alive neighbors stays/becomes alive
 * (3) Otherwise: the cell dies/stays dead.

 reads from world, writes into next_world
*/
update_world :: #force_inline proc(world: ^World, next_world: ^World) {
	for x: i32 = 0; x < world.width; x += 1 {
		for y: i32 = 0; y < world.height; y += 1 {
			neighbors := count_neighbors(world, x, y)
			index := y * world.width + x
			switch neighbors {
			case 2:
				{next_world.alive[index] = world.alive[index]}
			case 3:
				{next_world.alive[index] = 1}
			case:
				{next_world.alive[index] = 0}
			}
		}
	}
}

/*
 Just a branch-less version of adding adding all neighbors together
*/
count_neighbors :: #force_inline proc(w: ^World, x: i32, y: i32) -> u8 {
	// our world is a torus!
	left := (x - 1) %% w.width
	right := (x + 1) %% w.width
	up := (y - 1) %% w.height
	down := (y + 1) %% w.height

	top_left := w.alive[up * w.width + left]
	top := w.alive[up * w.width + x]
	top_right := w.alive[up * w.width + right]

	mid_left := w.alive[y * w.width + left]
	mid_right := w.alive[y * w.width + right]

	bottom_left := w.alive[down * w.width + left]
	bottom := w.alive[down * w.width + x]
	bottom_right := w.alive[down * w.width + right]

	top_row := top_left + top + top_right
	mid_row := mid_left + mid_right
	bottom_row := bottom_left + bottom + bottom_right

	total := top_row + mid_row + bottom_row
	return total
}

draw_world :: #force_inline proc(pvBits: screen_buffer, world: ^World) {
	runtime.mem_copy(pvBits, &world.alive[0], int(world.width * world.height))
}

get_rect_size :: #force_inline proc(rect: ^win32.RECT) -> int2 {return {(rect.right - rect.left), (rect.bottom - rect.top)}}

set_app :: #force_inline proc(hwnd: win32.HWND, app: ^Game) {win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, win32.LONG_PTR(uintptr(app)))}

get_app :: #force_inline proc(hwnd: win32.HWND) -> ^Game {return (^Game)(rawptr(uintptr(win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA))))}

get_app_from_createstruct :: #force_inline proc "contextless" (pcs: ^win32.CREATESTRUCTW) -> ^Game {
	return (^Game)(pcs.lpCreateParams) if pcs != nil else nil
}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	pcs := win32app.decode_lparam_as_createstruct(lparam)
	app := get_app_from_createstruct(pcs)
	if app == nil {show_error_and_panic("Missing app!")}
	set_app(hwnd, app)
	app.timer_id = win32app.set_timer(hwnd, win32app.IDT_TIMER1, 1000 / FPS)
	if app.timer_id == 0 {show_error_and_panic("No timer")}

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	bitmap_info := BITMAPINFO {
		bmiHeader = win32.BITMAPINFOHEADER {
			biSize          = size_of(win32.BITMAPINFOHEADER),
			biWidth         = bwidth,
			biHeight        = -bheight, // minus for top-down
			biPlanes        = 1,
			biBitCount      = 8,
			biCompression   = win32.BI_RGB,
			biClrUsed       = palette_count,
			biClrImportant  = 0,
		},
	}

	if palette_count > 0 {
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
	app.hbitmap = win32app.create_dib_section(hdc, cast(^win32.BITMAPINFO)&bitmap_info, .DIB_RGB_COLORS, &app.pvBits)

	if app.world != nil {
		cc := app.world.width * app.world.height
		for i in 0 ..< cc {app.world.alive[i] = u8(rand.int31_max(2))}
		for i in 0 ..< cc {app.next_world.alive[i] = u8(rand.int31_max(2))}
	}
	app.pause = false

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	app := get_app(hwnd)
	if app == nil {show_error_and_panic("Missing app!")}
	win32app.kill_timer(hwnd, &app.timer_id)
	if !win32app.delete_object(&app.hbitmap) {
		win32app.show_message_box("Unable to delete hbitmap", "Error")
	}
	win32app.post_quit_message(0)
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	app := get_app(hwnd)
	if app == nil {return 0}

	ps: win32.PAINTSTRUCT
	hdc := win32.BeginPaint(hwnd, &ps)
	defer win32.EndPaint(hwnd, &ps)

	if app.hbitmap != nil {
		hdc_source := win32.CreateCompatibleDC(hdc)
		defer win32.DeleteDC(hdc_source)

		win32.SelectObject(hdc_source, win32.HGDIOBJ(app.hbitmap))
		client_size := get_rect_size(&ps.rcPaint)
		win32.StretchBlt(hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, bwidth, bheight, win32.SRCCOPY)
	}

	if show_help {
		rect: win32.RECT = {20, 20, 160, 220}
		win32.RoundRect(hdc, rect.left, rect.top, rect.right, rect.bottom, 20, 20)
		win32.InflateRect(&rect, -10, -10)
		win32.DrawTextW(hdc, HELP, -1, &rect, .DT_TOP)
	}

	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch win32.UINT_PTR(wparam) {
	case IDT_TIMER1:
		app := get_app(hwnd)
		if app != nil {
			app.tick += 1
			if !app.pause {
				update_world(app.world, app.next_world)
				app.world, app.next_world = app.next_world, app.world
				draw_world(app.pvBits, app.world)
			}
			win32app.redraw_window(hwnd)
		}
	case:
		fmt.println(#procedure, hwnd, wparam, lparam)
	}
	return 0
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b':
		win32app.close_application(hwnd)
	case 'h':
		show_help ~= true
	case 'p':
		app := get_app(hwnd)
		app.pause ~= true
		if !app.pause {
			show_help = false
		}
	case ' ':
		app := get_app(hwnd)
		siz := app.world.width * app.world.height
		idx := rand.int31_max(siz)
		app.world.alive[idx] = 1
	}
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	// odinfmt: disable
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:	return 1 // paint should fill out the client area so no need to erase the background
	case win32.WM_PAINT:		return WM_PAINT(hwnd)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_TIMER:		return WM_TIMER(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

center_window :: proc(position: ^int2, size: int2) {
	if deviceMode: win32.DEVMODEW; win32.EnumDisplaySettingsW(nil, win32.ENUM_CURRENT_SETTINGS, &deviceMode) {
		dmsize := int2{i32(deviceMode.dmPelsWidth), i32(deviceMode.dmPelsHeight)} // is there an easier way to describe this?
		position^ = (dmsize - size) / 2
	}
}

create_window :: #force_inline proc(
	atom: win32.ATOM,
	window_name: win32.LPCTSTR,
	style, ex_style: win32.DWORD,
	position: int2,
	size: int2,
	instance: win32.HINSTANCE,
	lpParam: win32.LPVOID,
) -> win32.HWND {
	if atom == 0 {show_error_and_panic("atom is zero")}
	return win32.CreateWindowExW(ex_style, win32.LPCWSTR(uintptr(atom)), window_name, style, position.x, position.y, size.x, size.y, nil, nil, instance, lpParam)
}

// loop_messages :: proc() -> int {
// 	msg: win32.MSG
// 	for win32.GetMessageW(&msg, nil, 0, 0) > 0 {
// 		win32.TranslateMessage(&msg)
// 		win32.DispatchMessageW(&msg)
// 	}
// 	return int(msg.wParam)
// }

run :: proc() -> int {
	window := Window {
		name          = L("Game Of Life"),
		size          = {512, 512},
		fps           = 10,
		control_flags = {.CENTER},
	}
	game := Game {
		tick_rate = 300 * time.Millisecond,
		last_tick = time.now(),
		pause     = true,
		colors    = []color{BLACK, WHITE},
		size      = {bwidth, bheight},
	}
	world := World{game.size.x, game.size.y, make([]u8, game.size.x * game.size.y)}
	next_world := World{game.size.x, game.size.y, make([]u8, game.size.x * game.size.y)}
	defer delete(world.alive)
	defer delete(next_world.alive)
	game.world = &world
	game.next_world = &next_world

	instance := win32.HINSTANCE(win32.GetModuleHandleW(nil))
	if (instance == nil) {show_error_and_panic("No instance")}
	//atom := register_class(instance)
	atom := win32app.register_window_class(instance, wndproc)
	if atom == 0 {show_error_and_panic("Failed to register window class")}
	defer win32app.unregister_window_class(atom, instance)

	dwStyle :: win32.WS_OVERLAPPED | win32.WS_CAPTION | win32.WS_SYSMENU
	dwExStyle :: win32.WS_EX_OVERLAPPEDWINDOW

	size := window.size
	position := int2{i32(win32.CW_USEDEFAULT), i32(win32.CW_USEDEFAULT)}
	win32app.adjust_size_for_style(&size, dwStyle)
	if .CENTER in window.control_flags {
		center_window(&position, size)
	}
	hwnd := create_window(atom, window.name, dwStyle, dwExStyle, position, size, instance, &game)
	if hwnd == nil {show_error_and_panic("Failed to create window")}

	win32.ShowWindow(hwnd, win32.SW_SHOWDEFAULT)
	win32.UpdateWindow(hwnd)

	return win32app.loop_messages()
}

main :: proc() {
	exit_code := run()
	fmt.println("Done.", exit_code)
	os.exit(exit_code)
}
