package main

import "base:runtime"
import "core:fmt"
import "core:math"
import glm "core:math/linalg/glsl"
import "core:time"

import gl "vendor:OpenGL"
import "vendor:glfw"
import mu "vendor:microui"

App_State :: struct {
	bg_color:      mu.Color,
	show_quad:     bool,
	show_debug_ui: bool,
}

app_state: App_State

Vertex :: struct {
	pos: glm.vec3,
	col: glm.vec4,
}

running: b32 = true

// Called when glfw keystate changes
key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	context = runtime.default_context()

	fmt.println(#procedure, "key=", key, "scancode=", scancode, "action=", action, "mods=", mods)

	// Exit program on escape pressed
	if key == glfw.KEY_ESCAPE {
		running = false
	}

	mykey: mu.Key
	switch key {
	case glfw.KEY_LEFT_SHIFT, glfw.KEY_RIGHT_SHIFT:
		mykey = .SHIFT
	case glfw.KEY_LEFT_CONTROL, glfw.KEY_RIGHT_CONTROL:
		mykey = .CTRL
	case glfw.KEY_LEFT_ALT, glfw.KEY_RIGHT_ALT:
		mykey = .ALT
	case glfw.KEY_BACKSPACE:
		mykey = .BACKSPACE
	case glfw.KEY_DELETE:
		mykey = .DELETE
	case glfw.KEY_ENTER, glfw.KEY_KP_ENTER:
		mykey = .RETURN
	case glfw.KEY_LEFT:
		mykey = .LEFT
	case glfw.KEY_RIGHT:
		mykey = .RIGHT
	case glfw.KEY_HOME:
		mykey = .HOME
	case glfw.KEY_END:
		mykey = .END
	}

	if action == glfw.RELEASE {
		mu.input_key_up(&debug_ui_context.mu_ctx, mykey)
	} else {
		mu.input_key_down(&debug_ui_context.mu_ctx, mykey)
	}
}

char_callback :: proc "c" (window: glfw.WindowHandle, codepoint: rune) {
	context = runtime.default_context()
	fmt.println(#procedure, "codepoint=", codepoint)
	b, c := runtime.encode_rune(codepoint)
	mu.input_text(&debug_ui_context.mu_ctx, string(b[:c]))
}

mouse_button_callback :: proc "c" (window: glfw.WindowHandle, button, action, mods: i32) {
	context = runtime.default_context()
	// fmt.println(#procedure, "button=", button, "action=", action, "mods=", mods)
	xpos, ypos := glfw.GetCursorPos(window)
	scaled_x := i32(xpos / UI_SCALE)
	scaled_y := i32(ypos / UI_SCALE)

	btn: mu.Mouse
	switch button {
	case glfw.MOUSE_BUTTON_LEFT:
		btn = .LEFT
	case glfw.MOUSE_BUTTON_RIGHT:
		btn = .RIGHT
	case glfw.MOUSE_BUTTON_MIDDLE:
		btn = .MIDDLE
	}

	if action == glfw.PRESS {
		mu.input_mouse_down(&debug_ui_context.mu_ctx, scaled_x, scaled_y, btn)
	} else {
		mu.input_mouse_up(&debug_ui_context.mu_ctx, scaled_x, scaled_y, btn)
	}
}

cursor_position_callback :: proc "c" (window: glfw.WindowHandle, xpos, ypos: f64) {
	context = runtime.default_context()
	//fmt.println(#procedure, "xpos=", xpos, "ypos=", ypos)
	scaled_x := i32(xpos / UI_SCALE)
	scaled_y := i32(ypos / UI_SCALE)
	mu.input_mouse_move(&debug_ui_context.mu_ctx, scaled_x, scaled_y)
}

// Called when glfw window changes size
size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	// Set the OpenGL viewport size
	gl.Viewport(0, 0, width, height)
}

main :: proc() {
	window_context, window_ok := init_sdl_opengl_context()
	if !window_ok {
		return
	}
	defer sdl_opengl_cleanup(window_context)

	main_shader, shader_ok := shader_from_source_strings(vertex_source, fragment_source)
	if !shader_ok {
		fmt.eprintln("Failed to create GLSL program")
		return
	}
	defer cleanup_shader(main_shader)

	use_shader(main_shader)

	vao: u32
	gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	vbo, ebo: u32
	gl.GenBuffers(1, &vbo)
	defer gl.DeleteBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)
	defer gl.DeleteBuffers(1, &ebo)

	vertices := []Vertex {
		// position       color
		{{-0.5, +0.5, 0}, {1.0, 0.0, 0.0, 0.75}},
		{{-0.5, -0.5, 0}, {1.0, 1.0, 0.0, 0.75}},
		{{+0.5, -0.5, 0}, {0.0, 1.0, 0.0, 0.75}},
		{{+0.5, +0.5, 0}, {0.0, 0.0, 1.0, 0.75}},
	}

	indices := []u16{0, 1, 2, 2, 3, 0}
	index_count := i32(len(indices))

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, col))
	gl.EnableVertexAttribArray(1)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(indices[0]), raw_data(indices), gl.STATIC_DRAW)

	if (!debug_ui_init()) {
		fmt.eprintln("Error initializing debug UI")
		return
	}

	start_tick := time.tick_now()

	camera_position: glm.vec3 = {0, 0, -2}
	world_center: glm.vec3 = {0, 0, 0}
	y_up: glm.vec3 = {0, 1, 0}
	camera_fov := math.to_radians_f32(45)
	app_state.bg_color = {100, 100, 100, 255}
	app_state.show_quad = true
	app_state.show_debug_ui = true

	// loop: for {
	for (!glfw.WindowShouldClose(window_context.window) && running) {
		duration := time.tick_since(start_tick)
		t := f32(time.duration_seconds(duration))

		glfw.PollEvents()

		mu.begin(&debug_ui_context.mu_ctx)
		all_windows(&debug_ui_context.mu_ctx)
		run_debug_ui()
		mu.end(&debug_ui_context.mu_ctx)

		bg := app_state.bg_color
		gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.ClearColor(f32(bg.r) / 255, f32(bg.g) / 255, f32(bg.b) / 255, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		if app_state.show_quad {

			gl.Enable(gl.DEPTH_TEST)
			gl.Disable(gl.SCISSOR_TEST)
			gl.Disable(gl.BLEND)

			gl.BindVertexArray(vao)

			// rotate about Z axis
			//model := glm.identity(glm.mat4) * glm.mat4Rotate({0, 1, 0}, t)
			model := glm.mat4Rotate({0, 1, 0}, t)
			view := glm.mat4LookAt(eye = camera_position, centre = world_center, up = y_up)
			projection := glm.mat4Perspective(camera_fov, ASPECT, 0.1, 100.0)

			use_shader(main_shader)
			transform := projection * view * model
			set_shader_uniform_mat4(main_shader, "u_transform", &transform)

			gl.DrawElements(gl.TRIANGLES, index_count, gl.UNSIGNED_SHORT, nil)
		}

		if app_state.show_debug_ui {
			microui_render()
		}

		//SDL.GL_SwapWindow(window_context.window)
		glfw.SwapBuffers(window_context.window)

		free_all(context.temp_allocator)
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
