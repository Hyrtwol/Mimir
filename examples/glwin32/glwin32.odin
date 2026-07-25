// https://mariuszbartosik.com/opengl-4-x-initialization-in-windows-without-a-framework/
// https://github.com/Lazarus247/project247/blob/master/src/Window.cpp

package main

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"
import win32 "core:sys/windows"
import "core:time"
import "libs:tlc/win32app/owin_gl"
import "shared:obug"
import "shared:owin"
import gl "vendor:OpenGL"
import "vendor:glfw"

WIDTH :: 640
HEIGHT :: WIDTH * 9 / 16
SWAP_INTERVAL :: 1

application :: struct {
	#subtype settings: owin.window_settings,
	delta:    f32,
	tick:     u32,
	hglrc:    win32.HGLRC,
}

running: b32 = true

get_app :: #force_inline proc(hwnd: win32.HWND) -> ^application {
	app := owin.get_settings(hwnd, application)
	if app == nil {owin.show_error_and_panic("Missing app!")}
	return app
}

init :: proc() {
	// Own initialization code there
}

update :: proc() {
	// Own update code here
}

draw :: proc() {
	// Set the opengl clear color
	// 0-1 rgba values
	gl.ClearColor(0.2, 0.3, 0.3, 1.0)
	// Clear the screen with the set clearcolor
	gl.Clear(gl.COLOR_BUFFER_BIT)

	// Own drawing code here
}

exit :: proc() {
	// Own termination code here
}

// Called when glfw window changes size
size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	// Set the OpenGL viewport size
	gl.Viewport(0, 0, width, height)
}

dump_extensions :: proc(hdc: win32.HDC) {
	extensions := gl.GetString(gl.EXTENSIONS)
	fmt.println("gl_extensions", extensions)
	// extension_list := strings.split(string(extensions), " ", context.temp_allocator) or_else panic("strings.split")
	// for ex in extension_list {
	// 	fmt.printfln("   \"%s\"", ex)
	// }
	if (win32.wglGetExtensionsStringARB != nil) {
		exstr := win32.wglGetExtensionsStringARB(hdc)
		fmt.println("exstr", exstr)
	}
}

// <https://learn.microsoft.com/en-us/windows/win32/opengl/creating-a-rendering-context-and-making-it-current>
WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	app := owin.get_settings_from_lparam(lparam, application)
	if app == nil {owin.show_error_and_panic("Missing app!")}
	owin.set_settings(hwnd, app)

	assert(gl.impl_GetString == nil)
	owin_gl.load_up_to()
	assert(gl.impl_GetString != nil)

	hdc: win32.HDC = win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	pixelFormat, ok := owin_gl.choose_and_set_pixel_format(hdc)
	fmt.println("pixelFormat:", pixelFormat)
	assert(ok == true)

	app.hglrc = win32.wglCreateContext(hdc)
	assert(app.hglrc != nil)
	ok = win32.wglMakeCurrent(hdc, app.hglrc)
	assert(ok == true)

	ver := gl.GetString(gl.VERSION)
	fmt.printfln("GL_VERSION=%s", ver)

	owin_gl.init_wgl_extensions()

	//dump_extensions(hdc)

	if owin_gl.set_swap_interval(SWAP_INTERVAL) {
		fmt.println("...using WGL_EXT_swap_control", SWAP_INTERVAL)
	} else {
		fmt.println("...WGL_EXT_swap_control not found")
	}

	return 0
}

// <https://learn.microsoft.com/en-us/windows/win32/opengl/deleting-a-rendering-context>
WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	app := get_app(hwnd)
	if app == nil {owin.show_error_and_panic("Missing app!")}
	// wglMakeCurrent(hdc, NULL); Unnecessary; wglDeleteContext will make the context not current
	ok := win32.wglDeleteContext(app.hglrc)
	assert(ok == true)
	owin.post_quit_message(0)
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	app := get_app(hwnd)
	type := owin.WM_SIZE_WPARAM(wparam)
	app.settings.window_size = owin.decode_lparam_as_int2(lparam)
	owin.set_window_text(hwnd, "%s %v %v", app.settings.title, app.settings.window_size, type)
	// Set the OpenGL viewport size
	gl.Viewport(0, 0, expand_values(app.settings.window_size))
	fmt.println("gl.Viewport", 0, 0, expand_values(app.settings.window_size))
	return 0
}

handle_key_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	input := owin.decode_wm_input(wparam, lparam)
	//fmt.println("input", input)
	switch input.vk_code {
	case win32.VK_ESCAPE:
		if input.is_key_released {owin.close_application(hwnd)}
	}
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	// odinfmt: disable
	context = runtime.default_context()
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:	return 1
	case win32.WM_SIZE:         return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_KEYDOWN:      return handle_key_input(hwnd, wparam, lparam)
	case win32.WM_KEYUP:        return handle_key_input(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

draw_frame :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	hdc := win32.GetDC(hwnd)
	assert(hdc != nil)
	defer win32.ReleaseDC(hwnd, hdc)
	draw()
	swap_buffers(hdc)
	return 0
}
*/

swap_buffers :: proc(hdc: win32.HDC) {
	assert(hdc != nil)
	sr := owin_gl.SwapBuffers(hdc)
	assert(sr == true)
}

run :: proc() -> (exit_code: int) {
	app := application {
		//settings = owin.create_window_settings({WIDTH, HEIGHT}, TITLE, wndproc),
		settings = {
			options = {.Center},
			dwStyle = owin.DEFAULT_WS_STYLE,
			dwExStyle = owin.DEFAULT_WS_EX_STYLE,
			sleep = owin.DEFAULT_SLEEP,
			window_size = {WIDTH, HEIGHT},
			wndproc = wndproc,
		},
	}
	// app.settings.sleep = time.Millisecond * 20
	_, _, hwnd := owin.prepare_run(&app)
	res: int
	stopwatch := owin.create_stopwatch()
	stopwatch->start()
	msg: win32.MSG
	for owin.pull_messages(&msg) {

		app.delta = f32(stopwatch->get_delta_seconds())
		// frame_stats.frame_time += app.delta
		// frame_stats.frame_counter += 1
		app.tick += 1

		// res = app.update(app)
		// if res != 0 {break}
		draw_frame(hwnd)
		owin.sleep(app.settings.sleep)
	}
	stopwatch->stop()
	exit_code = int(msg.wParam)

	return
}

// run3 :: proc() -> (exit_code: int) {
// 	app := ca.DEFAULT_APPLICATION
// 	app.size = {WIDTH, HEIGHT}
// 	app.create = on_create
// 	app.update = on_update
// 	app.destroy = on_destroy
// 	app.settings.window_size = app.size * ZOOM
// 	app.settings.title = "Diffusion Limited Aggregation"
// 	exit_code = ca.run(&app)
// 	return
// }

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}
