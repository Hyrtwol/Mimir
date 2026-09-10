// https://mariuszbartosik.com/opengl-4-x-initialization-in-windows-without-a-framework/
// https://github.com/Lazarus247/project247/blob/master/src/Window.cpp

package main

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import glm "core:math/linalg/glsl"
import "core:os"
import win32 "core:sys/windows"
import "core:time"
import gl "vendor:OpenGL"
import "libs:ogl"
import "libs:tlc/win32app/owin_gl"
import "shared:obug"
import "shared:owin"

int2 :: owin.int2
float3 :: owin.float3

// cow, cube, gazebo, crisscross
//import model "../../data/models/cube"
//import model "../../data/models/platonic/icosahedron"
//Vertex :: model.Vertex

Vertex :: struct {
	pos: [3]f32 `POSITION`,
	col: [4]f32 `COLOR`,
}
vertices := []Vertex {
	// position       color
	{{-0.5, +0.5, 0}, {1.0, 0.0, 0.0, 0.75}},
	{{-0.5, -0.5, 0}, {1.0, 1.0, 0.0, 0.75}},
	{{+0.5, -0.5, 0}, {0.0, 1.0, 0.0, 0.75}},
	{{+0.5, +0.5, 0}, {0.0, 0.0, 1.0, 0.75}},
}

Index :: u16
indices := []Index{0, 1, 2, 2, 3, 0}

perspective: ogl.Perspective = {
	fov    = 45 * math.RAD_PER_DEG,
	aspect = 1,
	near   = 0.1,
	far    = 100.0,
}

camera: ogl.Camera = {
	eye    = {0, 0, -2},
	center = {0, 0, 0},
	up     = {0, 1, 0},
}

WIDTH :: 640
HEIGHT :: WIDTH * 9 / 16
SWAP_INTERVAL :: 1

Application :: struct {
	#subtype settings: owin.Window_Settings,
	delta:    f32,
	tick:     u32,
	hwnd:     win32.HWND,
	hdc:      win32.HDC,
	hglrc:    win32.HGLRC,
}

frame_stats: struct {
	fps:           f32,
	frame_counter: i32,
	frame_time:    f32,
}

mouse_pos: int2 = {0, 0}
is_active: bool = true
is_focused := false
cursor_state: i32 = 0

state: struct {
	t: f32
}

show_cursor :: #force_inline proc(show: bool) {
	cursor_state = owin.show_cursor(show)
	fmt.println(#procedure, cursor_state)
}

clip_cursor :: #force_inline proc "contextless" (hwnd: win32.HWND, clip: bool) -> bool {
	return owin.clip_cursor(hwnd, clip)
}

get_app :: #force_inline proc(hwnd: win32.HWND) -> ^Application {
	app := owin.get_settings(hwnd, Application)
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
	//owin_gl.set_viewport(app.settings.window_size)
	//gl.Viewport(0, 0, **app.settings.window_size)
	// Set the opengl clear color
	// 0-1 rgba values
	gl.ClearColor(0.2, 0.3, 0.3, 1.0)
	// Clear the screen with the set clearcolor
	//gl.Clear(gl.COLOR_BUFFER_BIT)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	// Own drawing code here
}

exit :: proc() {
	// Own termination code here
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

gl_set_proc_address_debug :: proc(p: rawptr, name: cstring) {
	win32.gl_set_proc_address(p, name)
	fmt.println(#procedure, name, (^rawptr)(p)^)
}

init_opengl :: proc(app: ^Application) {
	fmt.println(#procedure)
	assert(app.hdc != nil)

	pixelFormat, ok := owin_gl.choose_and_set_pixel_format(app.hdc)
	fmt.println("pixelFormat:", pixelFormat)
	assert(ok == true)

	app.hglrc = win32.wglCreateContext(app.hdc)
	assert(app.hglrc != nil)
	ok = win32.wglMakeCurrent(app.hdc, app.hglrc)
	assert(ok == true)

	assert(gl.impl_GetString == nil)
	//fmt.println("load_up_to")
	owin_gl.load_up_to()
	assert(gl.impl_GetString != nil)
	assert(gl.impl_DrawArrays != nil)
	assert(gl.impl_GenBuffers != nil)

	ver := gl.GetString(gl.VERSION)
	fmt.printfln("GL_VERSION=%s", ver)

	//dump_extensions(hdc)

	if owin_gl.set_swap_interval(SWAP_INTERVAL) {
		fmt.println("wglSwapIntervalEXT", SWAP_INTERVAL)
	} else {
		fmt.println("...WGL_EXT_swap_control not found")
	}
}

free_opengl :: proc(app: ^Application) {
	fmt.println(#procedure, app.hglrc)
	assert(app.hglrc != nil)
	owin_gl.delete_context(&app.hglrc)
	assert(app.hglrc == nil)
}

set_viewport_size :: proc(app: ^Application) {
	if app.hglrc != nil {
		owin_gl.set_viewport(app.settings.window_size)
		fmt.println("  set_viewport", 0, 0, **app.settings.window_size)
	} else {
		fmt.println("  app.hglrc is nil")
	}
	perspective.aspect = f32(app.settings.window_size.x) / f32(app.settings.window_size.y)
}

// <https://learn.microsoft.com/en-us/windows/win32/opengl/creating-a-rendering-context-and-making-it-current>
WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure, hwnd, lparam)
	app := owin.get_settings_from_lparam(lparam, Application)
	if app == nil {owin.show_error_and_panic("Missing app!")}
	owin.set_settings(hwnd, app)
	show_cursor(false)
	//app.hdc = win32.GetDC(hwnd)
	return 0
}

// <https://learn.microsoft.com/en-us/windows/win32/opengl/deleting-a-rendering-context>
WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	app := get_app(hwnd)
	// free_opengl(app)
	owin.release_dc(hwnd, &app.hdc)

	clip_cursor(hwnd, false)
	if cursor_state < 1 {
		show_cursor(true)
	}

	if app.hwnd == hwnd {
		app.hwnd = nil
	}
	owin.post_quit_message(0)
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	app := get_app(hwnd)
	type := owin.WM_SIZE_WPARAM(wparam)
	app.settings.window_size = owin.decode_lparam_as_int2(lparam)
	owin.set_window_text(hwnd, "%s %v %v", app.settings.title, app.settings.window_size, type)
	clip_cursor(hwnd, true)
	// Set the OpenGL viewport size
	set_viewport_size(app)
	return 0
}

// Sent when a window belonging to a different application than the active window is about to be activated. The message is sent to the application whose window is being activated and to the application whose window is being deactivated.
// * wParam: Indicates whether the window is being activated or deactivated. This parameter is TRUE if the window is being activated; it is FALSE if the window is being deactivated.
// * lParam: The thread identifier. If the wParam parameter is TRUE, lParam is the identifier of the thread that owns the window being deactivated. If wParam is FALSE, lParam is the identifier of the thread that owns the window being activated.
// * Return: If an application processes this message, it should return zero.
WM_ACTIVATEAPP :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	active := wparam != 0
	fmt.println(#procedure, active, cursor_state)
	if is_active != active {
		is_active = active
		clip_cursor(hwnd, active)
	}
	return 0
}

// Sent to both the window being activated and the window being deactivated. If the windows use the same input queue, the message is sent synchronously, first to the window procedure of the top-level window being deactivated, then to the window procedure of the top-level window being activated. If the windows use different input queues, the message is sent asynchronously, so the window is activated immediately.
// * wParam: The low-order word specifies whether the window is being activated or deactivated. This parameter can be one of the following values. The high-order word specifies the minimized state of the window being activated or deactivated. A nonzero value indicates the window is minimized.
// * lParam: A handle to the window being activated or deactivated, depending on the value of the wParam parameter. If the low-order word of wParam is WA_INACTIVE, lParam is the handle to the window being activated. If the low-order word of wParam is WA_ACTIVE or WA_CLICKACTIVE, lParam is the handle to the window being deactivated. This handle can be NULL.
// * Return: If an application processes this message, it should return zero.
WM_ACTIVATE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	activate := owin.WM_ACTIVATE_WPARAM(wparam)
	fmt.println(#procedure, activate, lparam)
	return 0
}

// wparam: A handle to the window that has lost the keyboard focus. This parameter can be NULL.
WM_FOCUS :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, focused: bool) -> win32.LRESULT {
	is_focused = focused
	fmt.println(#procedure, "hwnd=", hwnd, "wparam=", wparam, "is_focused=", is_focused)
	return 0
}

// handle_key_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
// 	input := owin.decode_wm_input(wparam, lparam)
// 	//fmt.println("input", input)
// 	switch input.vk_code {
// 	case win32.VK_ESCAPE:
// 		if input.is_key_released {owin.close_application(hwnd)}
// 	}
// 	return 0
// }

rawinput: win32.RAWINPUT

put_it := 0

WM_INPUT :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	assert(win32.GET_RAWINPUT_CODE_WPARAM(wparam) == .RIM_INPUT)
	owin.get_raw_input_data(win32.HRAWINPUT(lparam), &rawinput)

	switch rawinput.header.dwType {
	case win32.RIM_TYPEMOUSE:
		app := get_app(hwnd)
		mouse_delta: int2 = {rawinput.data.mouse.lLastX, rawinput.data.mouse.lLastY}
		// mouse_delta_f := mouse_delta * 0.1f
		camera.eye += float3{f32(mouse_delta.x), f32(mouse_delta.y), 0} * 0.1
		mouse_pos += mouse_delta
		mouse_pos = linalg.clamp(mouse_pos, int2{0, 0}, app.settings.window_size - 1)
		button_flags := rawinput.data.mouse.usButtonFlags
		switch button_flags {
		case win32.RI_MOUSE_BUTTON_1_DOWN:
			put_it = 1
		case win32.RI_MOUSE_BUTTON_1_UP:
			put_it = 0
		case win32.RI_MOUSE_BUTTON_2_DOWN:
			put_it = 2
		case win32.RI_MOUSE_BUTTON_2_UP:
			put_it = 0
		}
		// switch put_it {
		// case 1:
		// 	set_dot(mouse_pos / ZOOM, cols[selected_color])
		// case 2:
		// 	set_dot(mouse_pos / ZOOM, cols[0])
		// }
		// win32.RedrawWindow(hwnd, nil, nil, .RDW_INVALIDATE | .RDW_UPDATENOW)
	case win32.RIM_TYPEKEYBOARD:
		switch rawinput.data.keyboard.VKey {
		case win32.VK_ESCAPE:
			owin.close_application(hwnd)
		// case win32.VK_0 ..= win32.VK_9:
		// 	selected_color = i32(rawinput.data.keyboard.VKey - win32.VK_0)
		case:
			fmt.println("keyboard:", rawinput.data.keyboard)
		}
	case:
		fmt.println("dwType:", rawinput.header.dwType)
	}

	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	// odinfmt: disable
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:	return 1
	case win32.WM_SIZE:			return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_ACTIVATEAPP:	return WM_ACTIVATEAPP(hwnd, wparam, lparam)
	case win32.WM_ACTIVATE:     return WM_ACTIVATE(hwnd, wparam, lparam)
	case win32.WM_SETFOCUS:		return WM_FOCUS(hwnd, wparam, true)
	case win32.WM_KILLFOCUS:	return WM_FOCUS(hwnd, wparam, false)

	// case win32.WM_KEYDOWN:      return handle_key_input(hwnd, wparam, lparam)
	// case win32.WM_KEYUP:        return handle_key_input(hwnd, wparam, lparam)

	case win32.WM_INPUT:		return WM_INPUT(hwnd, wparam, lparam)

	case win32.WM_CHAR:         panic("WM_CHAR")
	case win32.WM_KEYDOWN:      panic("WM_KEYDOWN")
	case win32.WM_KEYUP:        panic("WM_KEYUP")
	case win32.WM_MOUSEMOVE:    panic("WM_MOUSEMOVE")
	case win32.WM_LBUTTONDOWN:  panic("WM_LBUTTONDOWN")
	case win32.WM_RBUTTONDOWN:  panic("WM_RBUTTONDOWN")

	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

swap_buffers :: proc(hdc: win32.HDC) {
	assert(hdc != nil)
	sr := owin_gl.SwapBuffers(hdc)
	assert(sr == true)
}

run :: proc() -> (exit_code: int) {
	app := Application {
		settings = {
			options = {.Center},
			dwStyle = owin.DEFAULT_WS_STYLE,
			dwExStyle = owin.DEFAULT_WS_EX_STYLE,
			sleep = owin.DEFAULT_SLEEP,
			window_size = {WIDTH, HEIGHT},
			wndproc = wndproc,
		},
	}
	defer {assert(app.hwnd == nil);assert(app.hdc == nil);assert(app.hglrc == nil)}

	_, _, app.hwnd = owin.register_and_create_window(&app)
	// if .Raw_Input in settings.options {
	// 	register_raw_input(app.hwnd)
	// }
	owin.register_raw_input(app.hwnd)
	app.hdc = win32.GetDC(app.hwnd)
	assert(app.hdc != nil)
	// defer owin.release_dc(app.hwnd, &app.hdc)
	// defer owin.release_dc(hwnd, &hdc)
	fmt.println(#procedure, "hdc:", app.hdc)

	init_opengl(&app)
	defer free_opengl(&app)

	fmt.println(#procedure, "app:", app)

	assert(gl.impl_GetString != nil)
	//assert(gl.impl_GenBuffers != nil)

	program := gl.load_shaders_source(vertex_source, fragment_source) or_else panic("Failed to create GLSL program")
	defer gl.DeleteProgram(program)

	uniforms := gl.get_uniforms_from_program(program)
	defer gl.destroy_uniforms(uniforms)
	ui_transform: ^gl.Uniform_Info = &uniforms["u_transform"]
	assert(ui_transform != nil)

	vao: u32
	gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	vbo, ebo: u32
	gl.GenBuffers(1, &vbo); defer gl.DeleteBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo); defer gl.DeleteBuffers(1, &ebo)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(1, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, col))
	gl.EnableVertexAttribArray(1)

	//gl.GenBuffers(1, &ebo); defer gl.DeleteBuffers(1, &ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(indices[0]), raw_data(indices), gl.STATIC_DRAW)

	index_count := i32(len(indices))
	state.t = 0

	owin.show_and_update_window(app.hwnd)

	tick_now := time.tick_now()
	last_tick := tick_now

	msg: win32.MSG
	for owin.pull_messages(&msg) {

		tick_now = time.tick_now()
		app.delta = f32(time.duration_seconds(time.tick_diff(last_tick, tick_now)))
		last_tick = tick_now
		app.tick += 1

		frame_stats.frame_time += app.delta
		frame_stats.frame_counter += 1

		if frame_stats.frame_time >= 2.0 {
			frame_stats.fps = f32(frame_stats.frame_counter) / frame_stats.frame_time
			frame_stats.frame_counter = 0
			frame_stats.frame_time = 0
			fmt.println("fps", frame_stats.fps)
		}

		// res = app.update(app)
		// if res != 0 {break}

		// draw_frame(hwnd)
		// owin_gl.set_viewport(app.settings.window_size)
		draw()

		{
			// rotate about Z axis
			//model := glm.identity(glm.mat4) * glm.mat4Rotate({0, 1, 0}, t)
			state.t += app.delta
			model := glm.mat4Rotate({0, 1, 0}, state.t)
			//view := glm.mat4LookAt(eye = camera.eye, centre = camera.center, up = camera.up)

			view := ogl.camera_look_at(&camera)
			//projection := glm.mat4Perspective(perspective.fov, perspective.aspect, 0.1, 100.0)
			projection := ogl.perspective_projection(&perspective)

			//gl.Enable(gl.DEPTH_TEST)
			//gl.Disable(gl.SCISSOR_TEST)
			//gl.Disable(gl.BLEND)

			gl.BindVertexArray(vao)
			gl.UseProgram(program)
			transform := projection * view * model
			gl.UniformMatrix4fv(ui_transform.location, 1, false, &transform[0, 0])
			gl.DrawElements(gl.TRIANGLES, index_count, gl.UNSIGNED_SHORT, nil)
		}

		swap_buffers(app.hdc)

		//owin.sleep(app.settings.sleep)
	}
	//stopwatch->stop()
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


vertex_source := `#version 460 core

layout(location=0) in vec3 a_position;
layout(location=1) in vec4 a_color;

out vec4 v_color;

uniform mat4 u_transform;

void main() {
	gl_Position = u_transform * vec4(a_position, 1.0);
	v_color = a_color;
}
`

fragment_source := `#version 460 core

in vec4 v_color;

out vec4 o_color;

void main() {
	o_color = v_color;
}
`
