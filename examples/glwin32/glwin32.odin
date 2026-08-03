// https://mariuszbartosik.com/opengl-4-x-initialization-in-windows-without-a-framework/
// https://github.com/Lazarus247/project247/blob/master/src/Window.cpp

package main

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:math"
import glm "core:math/linalg/glsl"
import "core:os"
import win32 "core:sys/windows"
import "core:time"
import "libs:tlc/win32app/owin_gl"
import "shared:obug"
import "shared:owin"
import gl "vendor:OpenGL"

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


WIDTH :: 640
HEIGHT :: WIDTH * 9 / 16
SWAP_INTERVAL :: 1

Application :: struct {
	#subtype settings: owin.Window_Settings,
	delta:    f32,
	tick:     u32,
	hglrc:    win32.HGLRC,
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

// // Called when glfw window changes size
// size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
// 	// Set the OpenGL viewport size
// 	gl.Viewport(0, 0, width, height)
// }

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

init_opengl :: proc(app: ^Application, hdc: win32.HDC) {
	fmt.println(#procedure)
	assert(hdc != nil)

	pixelFormat, ok := owin_gl.choose_and_set_pixel_format(hdc)
	fmt.println("pixelFormat:", pixelFormat)
	assert(ok == true)

	app.hglrc = win32.wglCreateContext(hdc)
	assert(app.hglrc != nil)
	ok = win32.wglMakeCurrent(hdc, app.hglrc)
	assert(ok == true)


	assert(gl.impl_GetString == nil)
	//fmt.println("load_up_to")
	owin_gl.load_up_to()
	//gl.load_up_to(4, 6, win32.gl_set_proc_address)
	//gl.load_up_to(4, 6, gl_set_proc_address_debug)
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
	// hdc: win32.HDC = win32.GetDC(hwnd)
	// defer win32.ReleaseDC(hwnd, hdc)
	// fmt.println("  hdc:", hdc)
	// init_opengl(app, hdc)
	return 0
}

// <https://learn.microsoft.com/en-us/windows/win32/opengl/deleting-a-rendering-context>
WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	app := get_app(hwnd)
	// free_opengl(app)
	owin.post_quit_message(0)
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	app := get_app(hwnd)
	type := owin.WM_SIZE_WPARAM(wparam)
	app.settings.window_size = owin.decode_lparam_as_int2(lparam)
	owin.set_window_text(hwnd, "%s %v %v", app.settings.title, app.settings.window_size, type)
	// Set the OpenGL viewport size
	set_viewport_size(app)
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
	// app.settings.sleep = time.Millisecond * 20
	//_, _, hwnd := owin.prepare_run(&app)
	inst, atom, hwnd := owin.register_and_create_window(&app)
	// if .Raw_Input in settings.options {
	// 	register_raw_input(hwnd)
	// }
	hdc := win32.GetDC(hwnd)
	assert(hdc != nil)
	defer {res := win32.ReleaseDC(hwnd, hdc); fmt.println(#procedure, "ReleaseDC", res)}
	// defer owin.release_dc(hwnd, &hdc)
	fmt.println(#procedure, "hdc:", hdc)

	init_opengl(&app, hdc)
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
	t: f32 = 0

	owin.show_and_update_window(hwnd)

	//res: int
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

		// draw_frame(hwnd)
		// owin_gl.set_viewport(app.settings.window_size)
		draw()

		{

			//gl.Enable(gl.DEPTH_TEST)
			//gl.Disable(gl.SCISSOR_TEST)
			//gl.Disable(gl.BLEND)

			gl.BindVertexArray(vao)
			gl.UseProgram(program)
			transform := projection * view * model
			gl.UniformMatrix4fv(ui_transform.location, 1, false, &transform[0, 0])
			gl.DrawElements(gl.TRIANGLES, index_count, gl.UNSIGNED_SHORT, nil)
		}

		swap_buffers(hdc)

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
