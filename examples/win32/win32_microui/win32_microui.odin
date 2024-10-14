#+vet
package main

import "core:fmt"
import "base:runtime"
import "core:container/queue"
import win32 "core:sys/windows"
import mud "libs:microui/demo"
import cv "libs:tlc/canvas"
import "libs:tlc/win32app"
import mu "vendor:microui"

_ :: mud

ZOOM :: 4
FPS :: 5

IDT_TIMER1: win32.UINT_PTR : 10001
timer1_id: win32.UINT_PTR

DIB :: win32app.DIB
canvas :: cv.canvas

mouse_event :: struct {
	pos: win32app.int2,
	mu_button: mu.Mouse,
	state: i32,
}

char_queue:      queue.Queue(u8)
mouse_queue:     queue.Queue(mouse_event)

application :: struct {
	mu_ctx:          mu.Context,
	log_buf:         [1 << 16]byte,
	log_buf_len:     int,
	log_buf_updated: bool,
	bg:              mu.Color,
	atlas_texture:   win32app.DIB,
	//char_queue:      queue.Queue(u8),
	//mouse_queue:     queue.Queue(mouse_event),
}
papp :: ^application

state: application = {
	bg = {90, 95, 100, 255},
}

screen_buffer :: cv.screen_buffer

bitmap_handle : win32.HGDIOBJ // win32.HBITMAP
bitmap_size   : win32app.int2 = {mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT}
bitmap_count  : i32
pvBits        : screen_buffer

bg_brush: win32.HBRUSH

mouse_pos : win32app.int2

// mouse_buttons: win32app.MOUSE_KEY_STATE

// buttons_to_key := [?]struct {
// 	wi_button: win32app.MOUSE_KEY_STATE,
// 	mu_button: mu.Mouse,
// }{{{.MK_LBUTTON}, .LEFT}, {{.MK_RBUTTON}, .RIGHT}, {{.MK_MBUTTON}, .MIDDLE}}

show_atlas := false

set_app :: #force_inline proc(hwnd: win32.HWND, app: ^application) {win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, win32.LONG_PTR(uintptr(app)))}

get_app :: #force_inline proc(hwnd: win32.HWND) -> ^application {return (^application)(rawptr(uintptr(win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA))))}

convert_mu_color :: #force_inline proc(mu_color: mu.Color) -> win32.COLORREF {return (transmute(win32.COLORREF)mu_color) & 0xFFFFFF}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	pcs := win32app.decode_lparam_as_createstruct(lparam)
	if pcs == nil {win32app.show_error_and_panic("Missing pcs!");return 1}
	settings := win32app.psettings(pcs.lpCreateParams)
	if settings == nil {win32app.show_error_and_panic("Missing settings!");return 1}
	win32app.set_settings(hwnd, settings)

	app := (papp)(settings.app)
	if app == nil {win32app.show_error_and_panic("Missing app!");return 1}

	//client_size := win32app.get_client_size(hwnd)
	//bitmap_size = client_size / ZOOM

	bg_brush = win32.HBRUSH(win32.GetStockObject(win32.BLACK_BRUSH))

	{
		hdc := win32.GetDC(hwnd)
		defer win32.ReleaseDC(hwnd, hdc)
		color_byte_count :: 4
		color_bit_count :: color_byte_count * 8
		bmi_header := win32app.create_bmi_header(bitmap_size, true, color_bit_count)
		bitmap_handle = win32.HGDIOBJ(win32app.create_dib_section(hdc, cast(^win32.BITMAPINFO)&bmi_header, .DIB_RGB_COLORS, &pvBits))
	}

	if pvBits != nil {
		bitmap_count = bitmap_size.x * bitmap_size.y
		for alpha, i in mu.default_atlas_alpha {
			pvBits[i] = {alpha, alpha, alpha, alpha}
		}
	} else {
		bitmap_size = {0, 0}
		bitmap_count = 0
	}

	timer1_id = win32app.set_timer(hwnd, IDT_TIMER1, 1000 / FPS)

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	settings := win32app.get_settings(hwnd)
	if settings == nil {win32app.show_error_and_panic("Missing settings!");return 1}
	// app := settings.app
	// if app == nil {win32app.show_error_and_panic("Missing app!");return 1}
	win32app.kill_timer(hwnd, &timer1_id)
	win32app.delete_object(&bitmap_handle)
	bitmap_size = {0, 0}
	bitmap_count = 0
	pvBits = nil
	win32app.post_quit_message(0)
	return 0
}

// first := 5

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	settings := win32app.get_settings(hwnd)
	if settings == nil {win32app.show_error_and_panic("Missing settings!");return 1}

	app := (papp)(settings.app)
	if app == nil {win32app.show_error_and_panic("Missing app!");return 1}

	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps) // todo check if defer can be used for EndPaint
	defer win32.EndPaint(hwnd, &ps)
	hdc_source := win32.CreateCompatibleDC(ps.hdc)
	defer win32.DeleteDC(hdc_source)

	// if first > 0 {
	// 	fmt.println("rcPaint:", ps.rcPaint, win32app.get_rect_size(&ps.rcPaint), win32app.get_client_size(hwnd))
	// 	first -= 1
	// }

	if bitmap_handle != nil {
		//client_size := win32app.get_rect_size(&ps.rcPaint)

		dc_brush := win32.HBRUSH(win32.GetStockObject(win32.DC_BRUSH))

		{
			ocol := win32.SetDCBrushColor(ps.hdc, convert_mu_color(app.bg))
			//win32.Rectangle(hdc, &ps.rcPaint)
			win32.FillRect(ps.hdc, &ps.rcPaint, dc_brush)
			win32.SetDCBrushColor(ps.hdc, ocol)
		}

		//win32.FillRect(ps.hdc, &ps.rcPaint, bg_brush)

		ctx := &app.mu_ctx
		if ctx != nil {

			mu.input_mouse_move(ctx, mouse_pos.x, mouse_pos.y)

			for {
				mv := queue.pop_front_safe(&mouse_queue) or_break
				fmt.println(mv)
				// mouse_event :: struct {
				// 	pos: win32app.int2,
				// 	mu_button: mu.Mouse,
				// 	state: i32,
				// }
				if mv.state == -1 {
					//mu.input_mouse_down(ctx, mouse_pos.x, mouse_pos.y, mv.mu_button)
					mu.input_mouse_down(ctx, mv.pos.x, mv.pos.y, mv.mu_button)
				}
				if mv.state == 1 {
					//mu.input_mouse_up(ctx, mouse_pos.x, mouse_pos.y, mv.mu_button)
					mu.input_mouse_up(ctx, mv.pos.x, mv.pos.y, mv.mu_button)
				}
			}

			for {
				//ch, ok := queue.pop_front_safe(&app.char_queue)
				ch := queue.pop_front_safe(&char_queue) or_break
				fmt.println(ch)
				/*
				{ 	// text input
					text_input: [512]byte = ---
					text_input_offset := 0
					for text_input_offset < len(text_input) {
						ch := rl.GetCharPressed()
						if ch == 0 {
							break
						}
						b, w := utf8.encode_rune(ch)
						copy(text_input[text_input_offset:], b[:w])
						text_input_offset += w
					}
					mu.input_text(ctx, string(text_input[:text_input_offset]))
				}
				*/
			}


			mu.begin(ctx)
			all_windows(ctx)
			mu.end(ctx)

			render(ctx, &ps, hdc_source)
		}

		if show_atlas {
			win32.SelectObject(hdc_source, bitmap_handle)
			win32.BitBlt(ps.hdc, 0, 0, bitmap_size.x, bitmap_size.y, hdc_source, 0, 0, win32.SRCCOPY)
		}
	}
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	settings := win32app.get_settings(hwnd)
	type := win32app.WM_SIZE_WPARAM(wparam)
	size := win32app.decode_lparam_as_int2(lparam)
	if settings == nil {win32app.show_error_and_panicf("Missing settings in %v", #procedure);return 1}
	//fmt.println(#procedure, hwnd, type, size)
	settings.window_size = size
	win32app.set_window_text(hwnd, "%s %v %v", settings.title, settings.window_size, type)
	return 0
}

WM_SIZING :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	// wParam - The edge of the window that is being sized.
	type := win32app.WM_SIZING_WPARAM(wparam)
	// lParam - A pointer to a RECT structure with the screen coordinates of the drag rectangle. To change the size or position of the drag rectangle, an application must change the members of this structure.
	rect := win32app.decode_lparam_as_rect(lparam)
	size := win32app.get_rect_size(rect)
	fmt.println(#procedure, hwnd, type, rect, size)
	return 0
}

WM_ENTERSIZEMOVE :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	return 0
}

WM_EXITSIZEMOVE :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	//size := win32app.get_client_size(hwnd)
	//fmt.println(#procedure, hwnd, size)
	//first = 3
	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	win32app.redraw_window(hwnd)
	//app := get_app(hwnd)
	//fmt.println(#procedure, app.mu_ctx.frame)
	return 0
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b': win32app.close_application(hwnd)
	//case ' ':    win32app.redraw_window(hwnd)
	case:
		fmt.printfln("WM_CHAR %4d 0x%4x 0x%4x 0x%4x", wparam, wparam, win32.HIWORD(lparam), win32.LOWORD(lparam))
		app := get_app(hwnd)
		if app != nil {
			//assert(&app.char_queue != nil)
			//fmt.printfln("char_queue: %v", char_queue)
			//queue.push_front(&app.char_queue, u8(wparam))
			queue.push_front(&char_queue, u8(wparam))
		}
	}
	return 0
}

handle_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM, updown: i32) -> win32.LRESULT {
	//app := get_app(hwnd)
	//mouse_buttons := win32app.decode_wparam_as_mouse_key_state(wparam)
	mouse_pos = win32app.decode_lparam_as_int2(lparam)
	//fmt.println(#procedure, mouse_buttons, updown, wparam)

	// switch wparam {
	// case 1:
	// 	//win32.InvalidateRect(hwnd, nil, false)
	// case 2:
	// 	//win32.InvalidateRect(hwnd, nil, false)
	// case 3:
	// 	//win32.InvalidateRect(hwnd, nil, false)
	// case 4:
	// 	//fmt.printfln("input %d %v", wparam, decode_scrpos(lparam))
	// case:
	// 	fmt.printfln("input %d %v", wparam, mouse_pos)
	// }


	// if .MK_LBUTTON in mouse_buttons {
	// 	queue.push_front(&mouse_queue, mouse_event{mouse_pos, .LEFT, updown})
	// }
	// if .MK_RBUTTON in mouse_buttons {
	// 	queue.push_front(&mouse_queue, mouse_event{mouse_pos, .RIGHT, updown})
	// }
	// if .MK_MBUTTON in mouse_buttons {
	// 	queue.push_front(&mouse_queue, mouse_event{mouse_pos, .MIDDLE, updown})
	// }

	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_CREATE:        return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:       return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:    return 1
	//case win32.WM_SETFOCUS:    return WM_SETFOCUS(hwnd, wparam)
	//case win32.WM_KILLFOCUS:   return WM_KILLFOCUS(hwnd, wparam)
	case win32.WM_SIZE:          return WM_SIZE(hwnd, wparam, lparam)
	//case win32.WM_SIZING:        return WM_SIZING(hwnd, wparam, lparam)
	//case win32.WM_ENTERSIZEMOVE: return WM_ENTERSIZEMOVE(hwnd)
	case win32.WM_EXITSIZEMOVE:  return WM_EXITSIZEMOVE(hwnd)
	case win32.WM_PAINT:         return WM_PAINT(hwnd)
	//case win32.WM_KEYUP:       return handle_key_input(hwnd, wparam, lparam)
	case win32.WM_CHAR:          return WM_CHAR(hwnd, wparam, lparam)

	case win32.WM_MOUSEMOVE:	return handle_input(hwnd, wparam, lparam, 0)
	case win32.WM_LBUTTONDOWN:	{queue.push_front(&mouse_queue, mouse_event{win32app.decode_lparam_as_int2(lparam), .LEFT, -1});return 0}
	case win32.WM_LBUTTONUP:	{queue.push_front(&mouse_queue, mouse_event{win32app.decode_lparam_as_int2(lparam), .LEFT, 1});return 0}
	// case win32.WM_RBUTTONDOWN:	return handle_input(hwnd, wparam, lparam, -1)
	// case win32.WM_RBUTTONUP:	return handle_input(hwnd, wparam, lparam, 1)
	// case win32.WM_MBUTTONDOWN:	return handle_input(hwnd, wparam, lparam, -1)
	// case win32.WM_MBUTTONUP:	return handle_input(hwnd, wparam, lparam, 1)

	case win32.WM_TIMER:         return WM_TIMER(hwnd, wparam, lparam)
	case:                        return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

//pixels : [][4]u8

main :: proc() {
	//rl.InitWindow(960, 540, "microui-odin")
	//defer rl.CloseWindow()

	//queue.init(&state.char_queue)
	//defer queue.destroy(&state.char_queue)
	queue.init(&char_queue)
	defer queue.destroy(&char_queue)
	queue.init(&mouse_queue)
	defer queue.destroy(&mouse_queue)

	ctx := &state.mu_ctx
	mu.init(ctx)

	ctx.text_width = mu.default_atlas_text_width
	ctx.text_height = mu.default_atlas_text_height

	settings := win32app.default_window_settings
	settings.window_size = {800, 600}
	settings.wndproc = wndproc
	settings.dwStyle = win32app.default_dwStyle | win32.WS_SIZEBOX
	settings.app = &state
	win32app.run(&settings)


	// image := rl.Image {
	// 	data    = raw_data(pixels),
	// 	width   = mu.DEFAULT_ATLAS_WIDTH,
	// 	height  = mu.DEFAULT_ATLAS_HEIGHT,
	// 	mipmaps = 1,
	// 	format  = .UNCOMPRESSED_R8G8B8A8,
	// }
	// state.atlas_texture = rl.LoadTextureFromImage(image)
	// defer rl.UnloadTexture(state.atlas_texture)

	//rl.SetTargetFPS(60)
	/*
	main_loop: for !rl.WindowShouldClose() {
		{ 	// text input
			text_input: [512]byte = ---
			text_input_offset := 0
			for text_input_offset < len(text_input) {
				ch := rl.GetCharPressed()
				if ch == 0 {
					break
				}
				b, w := utf8.encode_rune(ch)
				copy(text_input[text_input_offset:], b[:w])
				text_input_offset += w
			}
			mu.input_text(ctx, string(text_input[:text_input_offset]))
		}

		// mouse coordinates
		mouse_pos := [2]i32{rl.GetMouseX(), rl.GetMouseY()}
		mu.input_mouse_move(ctx, mouse_pos.x, mouse_pos.y)
		mu.input_scroll(ctx, 0, i32(rl.GetMouseWheelMove() * -30))

		// mouse buttons
		@(static)
		buttons_to_key := [?]struct {
			rl_button: rl.MouseButton,
			mu_button: mu.Mouse,
		}{{.LEFT, .LEFT}, {.RIGHT, .RIGHT}, {.MIDDLE, .MIDDLE}}
		for button in buttons_to_key {
			if rl.IsMouseButtonPressed(button.rl_button) {
				mu.input_mouse_down(ctx, mouse_pos.x, mouse_pos.y, button.mu_button)
			} else if rl.IsMouseButtonReleased(button.rl_button) {
				mu.input_mouse_up(ctx, mouse_pos.x, mouse_pos.y, button.mu_button)
			}

		}

		// keyboard
		@(static)
		keys_to_check := [?]struct {
			rl_key: rl.KeyboardKey,
			mu_key: mu.Key,
		} {
			{.LEFT_SHIFT, .SHIFT},
			{.RIGHT_SHIFT, .SHIFT},
			{.LEFT_CONTROL, .CTRL},
			{.RIGHT_CONTROL, .CTRL},
			{.LEFT_ALT, .ALT},
			{.RIGHT_ALT, .ALT},
			{.ENTER, .RETURN},
			{.KP_ENTER, .RETURN},
			{.BACKSPACE, .BACKSPACE},
		}
		for key in keys_to_check {
			if rl.IsKeyPressed(key.rl_key) {
				mu.input_key_down(ctx, key.mu_key)
			} else if rl.IsKeyReleased(key.rl_key) {
				mu.input_key_up(ctx, key.mu_key)
			}
		}

		mu.begin(ctx)
		all_windows(ctx)
		mu.end(ctx)

		hdc, hdc_source: win32.HDC
		render(ctx, hdc, hdc_source)
	}
	*/
}

ftn := win32.BLENDFUNCTION {
	BlendOp             = win32.AC_SRC_OVER,
	BlendFlags          = 0,
	SourceConstantAlpha = 255,
	AlphaFormat         = win32.AC_SRC_ALPHA,
}

render :: proc(ctx: ^mu.Context, ps: ^win32.PAINTSTRUCT, hdc_source: win32.HDC) {

	// rl.ClearBackground(transmute(rl.Color)state.bg)

	// rl.BeginDrawing()
	// defer rl.EndDrawing()

	// hrgn = CreateRectRgn(aptRect[0].x, aptRect[0].y, aptRect[2].x, aptRect[2].y);

	// rl.BeginScissorMode(0, 0, rl.GetScreenWidth(), rl.GetScreenHeight())
	// defer rl.EndScissorMode()

	//todo win32.SelectClipRgn(hdc, nil)
	hdc := ps.hdc

	original := win32.SelectObject(hdc, win32.GetStockObject(win32.DC_PEN))
	defer win32.SelectObject(hdc, original)

	//brush := win32.HBRUSH(win32.GetStockObject(win32.DC_BRUSH))
	dc_brush := win32.GetStockObject(win32.DC_BRUSH)

	// docs says width=0 should yield a 1 pixel line but so far i get 2, same for 1 :/
	//hPen := win32.CreatePen(win32.PS_SOLID, 0, win32.RGB(0,0,0));
	//defer win32.DeleteObject(win32.HGDIOBJ(hPen))


	// {
	// 	col := (transmute(win32.COLORREF)state.bg) & 0xFFFFFF
	// 	ocol := win32.SetDCBrushColor(hdc, col)
	// 	//win32.Rectangle(hdc, &ps.rcPaint)
	// 	win32.FillRect(hdc, &ps.rcPaint, brush)
	// 	win32.SetDCBrushColor(hdc, ocol)
	// }

	win32.SetBkMode(hdc, .TRANSPARENT)

	command_backing: ^mu.Command
	for variant in mu.next_command_iterator(ctx, &command_backing) {
		switch cmd in variant {
		case ^mu.Command_Text:
			pos := [2]i32{cmd.pos.x, cmd.pos.y}
			/*
			for ch in cmd.str do if ch & 0xc0 != 0x80 {
				r := min(int(ch), 127)
				rect := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
				//render_texture(rect, pos, cmd.color)
				win32.AlphaBlend(hdc, pos.x, pos.y, rect.w, rect.h, hdc_source, rect.x, rect.y, rect.w, rect.h, ftn)
				pos.x += rect.w
			}
			*/
			win32.SetTextColor(hdc, convert_mu_color(cmd.color))
			win32.TextOutW(hdc, pos.x, pos.y, win32.utf8_to_wstring(cmd.str), i32(len(cmd.str)))

		case ^mu.Command_Rect:
			//rl.DrawRectangle(cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h, transmute(rl.Color)cmd.color)
			old_brush := win32.SelectObject(hdc, win32.HGDIOBJ(dc_brush))
			old_color := win32.SetDCBrushColor(hdc, convert_mu_color(cmd.color))
			//old_pen := win32.SelectObject(hdc, win32.HGDIOBJ(hPen));
			old_pen := win32.SelectObject(hdc, win32.HGDIOBJ(win32app.HPEN_NULL))
			win32.Rectangle(hdc, cmd.rect.x, cmd.rect.y, cmd.rect.x + cmd.rect.w, cmd.rect.y + cmd.rect.h)
			//win32.FillRect(hdc, &cmd.rect, win32.HBRUSH(dc_brush))
			win32.SelectObject(hdc, old_pen)
			win32.SetDCBrushColor(hdc, old_color)
			win32.SelectObject(hdc, old_brush)

		case ^mu.Command_Icon:
			rect := mu.default_atlas[cmd.id]
			x := cmd.rect.x + (cmd.rect.w - rect.w) / 2
			y := cmd.rect.y + (cmd.rect.h - rect.h) / 2
			//render_texture(rect, {x, y}, cmd.color)
			win32.AlphaBlend(hdc, x, y, rect.w, rect.h, hdc_source, rect.x, rect.y, rect.w, rect.h, ftn)

		case ^mu.Command_Clip:
			// rl.EndScissorMode()
			// rl.BeginScissorMode(cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h)
			// https://learn.microsoft.com/en-us/windows/win32/gdi/clipping-output
			// To remove a device-context's clipping region, specify a NULL region handle.
			//fmt.printfln("clip: %v", cmd.rect)

		case ^mu.Command_Jump:
			unreachable()
		}
	}
}


u8_slider :: proc(ctx: ^mu.Context, val: ^u8, lo, hi: u8) -> (res: mu.Result_Set) {
	mu.push_id(ctx, uintptr(val))

	@(static)
	tmp: mu.Real
	tmp = mu.Real(val^)
	res = mu.slider(ctx, &tmp, mu.Real(lo), mu.Real(hi), 0, "%.0f", {.ALIGN_CENTER})
	val^ = u8(tmp)
	mu.pop_id(ctx)
	return
}

write_log :: proc(str: string) {
	state.log_buf_len += copy(state.log_buf[state.log_buf_len:], str)
	state.log_buf_len += copy(state.log_buf[state.log_buf_len:], "\n")
	state.log_buf_updated = true
}

read_log :: proc() -> string {
	return string(state.log_buf[:state.log_buf_len])
}
reset_log :: proc() {
	state.log_buf_updated = true
	state.log_buf_len = 0
}


all_windows :: proc(ctx: ^mu.Context) {
	@(static)
	opts := mu.Options{.NO_CLOSE}

	if mu.window(ctx, "Demo Window", {40, 40, 300, 450}, opts) {
		if .ACTIVE in mu.header(ctx, "Window Info") {
			win := mu.get_current_container(ctx)
			mu.layout_row(ctx, {54, -1}, 0)
			mu.label(ctx, "Position:")
			mu.label(ctx, fmt.tprintf("%d, %d", win.rect.x, win.rect.y))
			mu.label(ctx, "Size:")
			mu.label(ctx, fmt.tprintf("%d, %d", win.rect.w, win.rect.h))
		}

		if .ACTIVE in mu.header(ctx, "Window Options") {
			mu.layout_row(ctx, {120, 120, 120}, 0)
			for opt in mu.Opt {
				state := opt in opts
				if .CHANGE in mu.checkbox(ctx, fmt.tprintf("%v", opt), &state) {
					if state {
						opts += {opt}
					} else {
						opts -= {opt}
					}
				}
			}
		}

		if .ACTIVE in mu.header(ctx, "Test Buttons", {.EXPANDED}) {
			mu.layout_row(ctx, {86, -110, -1})
			mu.label(ctx, "Test buttons 1:")
			if .SUBMIT in mu.button(ctx, "Button 1") {write_log("Pressed button 1")}
			if .SUBMIT in mu.button(ctx, "Button 2") {write_log("Pressed button 2")}
			mu.label(ctx, "Test buttons 2:")
			if .SUBMIT in mu.button(ctx, "Button 3") {write_log("Pressed button 3")}
			if .SUBMIT in mu.button(ctx, "Button 4") {write_log("Pressed button 4")}
		}

		if .ACTIVE in mu.header(ctx, "Tree and Text", {.EXPANDED}) {
			mu.layout_row(ctx, {140, -1})
			mu.layout_begin_column(ctx)
			if .ACTIVE in mu.treenode(ctx, "Test 1") {
				if .ACTIVE in mu.treenode(ctx, "Test 1a") {
					mu.label(ctx, "Hello")
					mu.label(ctx, "world")
				}
				if .ACTIVE in mu.treenode(ctx, "Test 1b") {
					if .SUBMIT in mu.button(ctx, "Button 1") {write_log("Pressed button 1")}
					if .SUBMIT in mu.button(ctx, "Button 2") {write_log("Pressed button 2")}
				}
			}
			if .ACTIVE in mu.treenode(ctx, "Test 2") {
				mu.layout_row(ctx, {53, 53})
				if .SUBMIT in mu.button(ctx, "Button 3") {write_log("Pressed button 3")}
				if .SUBMIT in mu.button(ctx, "Button 4") {write_log("Pressed button 4")}
				if .SUBMIT in mu.button(ctx, "Button 5") {write_log("Pressed button 5")}
				if .SUBMIT in mu.button(ctx, "Button 6") {write_log("Pressed button 6")}
			}
			if .ACTIVE in mu.treenode(ctx, "Test 3") {
				@(static)
				checks := [3]bool{true, false, true}
				mu.checkbox(ctx, "Checkbox 1", &checks[0])
				mu.checkbox(ctx, "Checkbox 2", &checks[1])
				mu.checkbox(ctx, "Checkbox 3", &checks[2])

			}
			mu.layout_end_column(ctx)

			mu.layout_begin_column(ctx)
			mu.layout_row(ctx, {-1})
			mu.text(ctx, "Lorem ipsum dolor sit amet, consectetur adipiscing " + "elit. Maecenas lacinia, sem eu lacinia molestie, mi risus faucibus " + "ipsum, eu varius magna felis a nulla.")
			mu.layout_end_column(ctx)
		}

		if .ACTIVE in mu.header(ctx, "Background Colour", {.EXPANDED}) {
			mu.layout_row(ctx, {-78, -1}, 68)
			mu.layout_begin_column(ctx)
			{
				mu.layout_row(ctx, {46, -1}, 0)
				mu.label(ctx, "Red:");u8_slider(ctx, &state.bg.r, 0, 255)
				mu.label(ctx, "Green:");u8_slider(ctx, &state.bg.g, 0, 255)
				mu.label(ctx, "Blue:");u8_slider(ctx, &state.bg.b, 0, 255)
			}
			mu.layout_end_column(ctx)

			r := mu.layout_next(ctx)
			mu.draw_rect(ctx, r, state.bg)
			mu.draw_box(ctx, mu.expand_rect(r, 1), ctx.style.colors[.BORDER])
			mu.draw_control_text(ctx, fmt.tprintf("#%02x%02x%02x", state.bg.r, state.bg.g, state.bg.b), r, .TEXT, {.ALIGN_CENTER})
		}
	}

	if mu.window(ctx, "Log Window", {350, 40, 300, 200}, opts) {
		mu.layout_row(ctx, {-1}, -28)
		mu.begin_panel(ctx, "Log")
		mu.layout_row(ctx, {-1}, -1)
		mu.text(ctx, read_log())
		if state.log_buf_updated {
			panel := mu.get_current_container(ctx)
			panel.scroll.y = panel.content_size.y
			state.log_buf_updated = false
		}
		mu.end_panel(ctx)

		@(static)
		buf: [128]byte
		@(static)
		buf_len: int
		submitted := false
		mu.layout_row(ctx, {-70, -1})
		if .SUBMIT in mu.textbox(ctx, buf[:], &buf_len) {
			mu.set_focus(ctx, ctx.last_id)
			submitted = true
		}
		if .SUBMIT in mu.button(ctx, "Submit") {
			submitted = true
		}
		if submitted {
			write_log(string(buf[:buf_len]))
			buf_len = 0
		}
	}

	if mu.window(ctx, "Style Window", {350, 250, 300, 240}) {
		@(static)
		colors := [mu.Color_Type]string {
			.TEXT         = "text",
			.SELECTION_BG = "selection bg",
			.BORDER       = "border",
			.WINDOW_BG    = "window bg",
			.TITLE_BG     = "title bg",
			.TITLE_TEXT   = "title text",
			.PANEL_BG     = "panel bg",
			.BUTTON       = "button",
			.BUTTON_HOVER = "button hover",
			.BUTTON_FOCUS = "button focus",
			.BASE         = "base",
			.BASE_HOVER   = "base hover",
			.BASE_FOCUS   = "base focus",
			.SCROLL_BASE  = "scroll base",
			.SCROLL_THUMB = "scroll thumb",
		}

		sw := i32(f32(mu.get_current_container(ctx).body.w) * 0.14)
		mu.layout_row(ctx, {80, sw, sw, sw, sw, -1})
		for label, col in colors {
			mu.label(ctx, label)
			u8_slider(ctx, &ctx.style.colors[col].r, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].g, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].b, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].a, 0, 255)
			mu.draw_rect(ctx, mu.layout_next(ctx), ctx.style.colors[col])
		}
	}

}
