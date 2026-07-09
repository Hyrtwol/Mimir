package main

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:os"
import win32 "core:sys/windows"
import "core:time"
import "libs:tlc/win32app/owin_gl"
import "shared:obug"
import "shared:owin"
import gl "vendor:OpenGL"
import "vendor:glfw"

PROGRAMNAME :: "Program"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 6

TITLE :: "glwin32"
WIDTH :: 640
HEIGHT :: WIDTH * 9 / 16

application :: struct {
	#subtype settings: owin.window_settings,
}

running: b32 = true

get_app :: #force_inline proc(hwnd: win32.HWND) -> ^application {
	app := owin.get_settings(hwnd, application)
	if app == nil {owin.show_error_and_panic("Missing app!")}
	return app
}

// gl_set_proc_address :: proc(p: rawptr, name: cstring) {
// 	(^rawptr)(p)^ = win32.wglGetProcAddress(name)
// }
gl_set_proc_address :: win32.gl_set_proc_address

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

// Called when glfw keystate changes
key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	// Exit program on escape pressed
	if key == glfw.KEY_ESCAPE {
		running = false
	}
}

// Called when glfw window changes size
size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	// Set the OpenGL viewport size
	gl.Viewport(0, 0, width, height)
}

ourOpenGLRenderingContext: win32.HGLRC = nil

// <https://learn.microsoft.com/en-us/windows/win32/opengl/creating-a-rendering-context-and-making-it-current>
WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	app := owin.get_settings_from_lparam(lparam, application)
	if app == nil {owin.show_error_and_panic("Missing app!")}
	owin.set_settings(hwnd, app)

	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, owin_gl.gl_set_proc_address)

	ourWindowHandleToDeviceContext: win32.HDC = win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, ourWindowHandleToDeviceContext)

	// odinfmt: disable
	pfd : win32.PIXELFORMATDESCRIPTOR = {
		size_of(win32.PIXELFORMATDESCRIPTOR),
		1,
		win32.PFD_DRAW_TO_WINDOW | win32.PFD_SUPPORT_OPENGL | win32.PFD_DOUBLEBUFFER,    //Flags
		win32.PFD_TYPE_RGBA,  // The kind of framebuffer. RGBA or palette.
		32,                   // Colordepth of the framebuffer.
		0, 0, 0, 0, 0, 0,
		0,
		0,
		0,
		0, 0, 0, 0,
		24,                   // Number of bits for the depthbuffer
		8,                    // Number of bits for the stencilbuffer
		0,                    // Number of Aux buffers in the framebuffer.
		win32.PFD_MAIN_PLANE,
		0,
		0, 0, 0
	}
	// odinfmt: enable

	letWindowsChooseThisPixelFormat := win32.ChoosePixelFormat(ourWindowHandleToDeviceContext, &pfd)
	fmt.println("letWindowsChooseThisPixelFormat:", letWindowsChooseThisPixelFormat)
	ok := win32.SetPixelFormat(ourWindowHandleToDeviceContext, letWindowsChooseThisPixelFormat, &pfd)
	fmt.println("SetPixelFormat:", ok)

	// HGLRC ourOpenGLRenderingContext = wglCreateContext(ourWindowHandleToDeviceContext);
	ourOpenGLRenderingContext = win32.wglCreateContext(ourWindowHandleToDeviceContext)
	fmt.println("ourOpenGLRenderingContext:", ourOpenGLRenderingContext)
	// wglMakeCurrent (ourWindowHandleToDeviceContext, ourOpenGLRenderingContext);
	ok = win32.wglMakeCurrent(ourWindowHandleToDeviceContext, ourOpenGLRenderingContext)
	fmt.println("wglMakeCurrent:", ok)

	assert(gl.impl_GetString != nil)

	ver := gl.GetString(gl.VERSION)
	fmt.printfln("GL_VERSION=%s", ver)

	return 0
}

// <https://learn.microsoft.com/en-us/windows/win32/opengl/deleting-a-rendering-context>
WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	// app := get_app(hwnd)
	// //wglMakeCurrent(ourWindowHandleToDeviceContext, NULL); Unnecessary; wglDeleteContext will make the context not current
	win32.wglDeleteContext(ourOpenGLRenderingContext)
	owin.post_quit_message(0)
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	app := get_app(hwnd)
	type := owin.WM_SIZE_WPARAM(wparam)
	app.settings.window_size = owin.decode_lparam_as_int2(lparam)
	owin.set_window_text(hwnd, "%s %v %v", app.settings.title, app.settings.window_size, type)
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	// odinfmt: disable
	context = runtime.default_context()
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:	return 1
	case win32.WM_SIZE:          return WM_SIZE(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

run :: proc() -> (exit_code: int) {

	// https://learn.microsoft.com/en-us/windows/win32/opengl/drawing-text-in-a-double-buffered-opengl-window
	// https://stackoverflow.com/questions/6287660/win32-opengl-window-creation

	// hglrc := win32.wglCreateContext(hdc)
	// defer win32.wglDeleteContext(hglrc)
	// ok := win32.SwapBuffers(hdc)


	// Set Window Hints
	// https://www.glfw.org/docs/3.3/window_guide.html#window_hints
	// https://www.glfw.org/docs/3.3/group__window.html#ga7d9c8c62384b1e2821c4dc48952d2033
	glfw.WindowHint(glfw.RESIZABLE, 1)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	if (!glfw.Init()) {
		fmt.println("Failed to initialize GLFW")
		return
	}
	defer glfw.Terminate()

	window := glfw.CreateWindow(512, 512, PROGRAMNAME, nil, nil)
	defer glfw.DestroyWindow(window)

	if window == nil {
		fmt.println("Unable to create window")
		return
	}

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)

	glfw.SetKeyCallback(window, key_callback)
	glfw.SetFramebufferSizeCallback(window, size_callback)

	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

	init()

	for (!glfw.WindowShouldClose(window) && running) {
		// Process waiting events in queue
		glfw.PollEvents()

		update()
		draw()

		glfw.SwapBuffers((window))
	}

	exit()
	return
}

draw_frame :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	hdc := win32.GetDC(hwnd)
	assert(hdc != nil)
	defer win32.ReleaseDC(hwnd, hdc)
	// draw_dib(hwnd, hdc)

	draw()

	sr := owin_gl.SwapBuffers(hdc)
	assert(sr == true)

	return 0
}

app_sleep: time.Duration = time.Millisecond * 20

sleep :: proc(duration: time.Duration) {
	if duration >= 0 {
		time.accurate_sleep(duration)
	}
}

run2 :: proc() -> (exit_code: int) {
	settings := owin.create_window_settings({WIDTH, HEIGHT}, TITLE, wndproc)
	//exit_code = owin.run(&settings)

	_, _, hwnd := owin.prepare_run(&settings)
	res: int
	stopwatch := owin.create_stopwatch()
	stopwatch->start()
	msg: win32.MSG
	for owin.pull_messages(&msg) {

		// app.delta = f32(stopwatch->get_delta_seconds())
		// frame_stats.frame_time += app.delta
		// frame_stats.frame_counter += 1
		// app.tick += 1

		// res = app.update(app)
		// if res != 0 {break}
		// draw_frame(hwnd)

		draw_frame(hwnd)

		sleep(app_sleep)
	}
	stopwatch->stop()
	exit_code = int(msg.wParam)

	return
}

// run3 :: proc() -> (exit_code: int) {
// 	app := ca.default_application
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
		os.exit(obug.tracked_run(run2))
	} else {
		os.exit(run())
	}
}
