package main

import "core:fmt"
import glm "core:math/linalg/glsl"

import gl "vendor:OpenGL"
import mu "vendor:microui"

Microui_Vertex :: struct {
    pos : glm.vec2,
    tex : glm.vec2,
    col : [4]u8,
}

Debug_UI_Context :: struct {
    mu_ctx :       mu.Context,
    mu_shader :    Shader,
    mu_vao :       u32,
    mu_vbo :       u32,
    mu_ebo :       u32,
    mu_atlas_tex : u32,

    // Buffers for batching draw commands
    vert_buf :     [dynamic]Microui_Vertex,
    index_buf :    [dynamic]u32,

	log_buf:         [1 << 16]byte,
	log_buf_len:     int,
	log_buf_updated: bool,
	bg:              mu.Color,
}

debug_ui_context : Debug_UI_Context

DEBUG_UI_VERTEX_SOURCE := `#version 330 core
layout(location=0) in vec2 a_position;
layout(location=1) in vec2 a_tex_coord;
layout(location=2) in vec4 a_color;

out vec2 v_tex_coord;
out vec4 v_color;

uniform mat4 u_projection;

void main() {
	gl_Position = u_projection * vec4(a_position, 0.0, 1.0);
	v_tex_coord = a_tex_coord;
	v_color = a_color;
}
`


DEBUG_UI_FRAGMENT_SOURCE := `#version 330 core
in vec2 v_tex_coord;
in vec4 v_color;
out vec4 o_color;

uniform sampler2D u_texture;

void main() {
	// Sample the alpha channel from the atlas and multiply by vertex color
	float alpha = texture(u_texture, v_tex_coord).r;
    o_color = vec4(v_color.rgb, v_color.a * alpha);
}
`


debug_ui_init :: proc() -> bool {
    shader, shader_ok := shader_from_source_strings(DEBUG_UI_VERTEX_SOURCE, DEBUG_UI_FRAGMENT_SOURCE)
    if !shader_ok {
        fmt.eprintln("Error compiling debug UI shader")
        return false
    }

    debug_ui_context.mu_shader = shader

    gl.GenVertexArrays(1, &debug_ui_context.mu_vao)
    gl.GenBuffers(1, &debug_ui_context.mu_vbo)
    gl.GenBuffers(1, &debug_ui_context.mu_ebo)

    gl.BindVertexArray(debug_ui_context.mu_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, debug_ui_context.mu_vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, debug_ui_context.mu_ebo)

    gl.EnableVertexAttribArray(0) // pos
    gl.EnableVertexAttribArray(1) // tex
    gl.EnableVertexAttribArray(2) // col
    gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(Microui_Vertex), offset_of(Microui_Vertex, pos))
    gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(Microui_Vertex), offset_of(Microui_Vertex, tex))
    gl.VertexAttribPointer(2, 4, gl.UNSIGNED_BYTE, true, size_of(Microui_Vertex), offset_of(Microui_Vertex, col))

    // Create atlas texture
    gl.GenTextures(1, &debug_ui_context.mu_atlas_tex)
    gl.BindTexture(gl.TEXTURE_2D, debug_ui_context.mu_atlas_tex)
    gl.TexImage2D(
        gl.TEXTURE_2D,
        0,
        gl.R8, // Internal format: Store as 8-bit Red channel
        mu.DEFAULT_ATLAS_WIDTH,
        mu.DEFAULT_ATLAS_HEIGHT,
        0,
        gl.RED, // Source format: The data we provide is in the Red channel
        gl.UNSIGNED_BYTE,
        &mu.default_atlas_alpha,
    )
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

    // Initialize microui context
    mu.init(&debug_ui_context.mu_ctx)
    debug_ui_context.mu_ctx.text_width = mu.default_atlas_text_width
    debug_ui_context.mu_ctx.text_height = mu.default_atlas_text_height

    return true
}


// Flushes the vertex/index buffers to the GPU and issues a draw call
microui_flush :: proc() {
    if len(debug_ui_context.index_buf) == 0 {
        return
    }

    gl.BindVertexArray(debug_ui_context.mu_vao)

    // Upload vertex and index data to GPU
    gl.BindBuffer(gl.ARRAY_BUFFER, debug_ui_context.mu_vbo)
    gl.BufferData(
        gl.ARRAY_BUFFER,
        len(debug_ui_context.vert_buf) * size_of(Microui_Vertex),
        raw_data(debug_ui_context.vert_buf),
        gl.STREAM_DRAW,
    )

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, debug_ui_context.mu_ebo)
    gl.BufferData(
        gl.ELEMENT_ARRAY_BUFFER,
        len(debug_ui_context.index_buf) * size_of(u32),
        raw_data(debug_ui_context.index_buf),
        gl.STREAM_DRAW,
    )

    // Draw the batch
    gl.DrawElements(gl.TRIANGLES, i32(len(debug_ui_context.index_buf)), gl.UNSIGNED_INT, nil)

    // Reset buffers for the next batch
    clear(&debug_ui_context.vert_buf)
    clear(&debug_ui_context.index_buf)
}

// Pushes a quad to the vertex/index buffers
microui_push_quad :: proc(dst, src : mu.Rect, color : mu.Color) {
    idx := u32(len(debug_ui_context.vert_buf))

    atlas_w, atlas_h := f32(mu.DEFAULT_ATLAS_WIDTH), f32(mu.DEFAULT_ATLAS_HEIGHT)
    u0, v0 := f32(src.x) / atlas_w, f32(src.y) / atlas_h
    u1, v1 := f32(src.x + src.w) / atlas_w, f32(src.y + src.h) / atlas_h

    x0, y0 := f32(dst.x), f32(dst.y)
    x1, y1 := f32(dst.x + dst.w), f32(dst.y + dst.h)

    col := [4]u8{color.r, color.g, color.b, color.a}

    append(
        &debug_ui_context.vert_buf,
        Microui_Vertex{{x0, y0}, {u0, v0}, col},
        Microui_Vertex{{x1, y0}, {u1, v0}, col},
        Microui_Vertex{{x1, y1}, {u1, v1}, col},
        Microui_Vertex{{x0, y1}, {u0, v1}, col},
    )

    append(&debug_ui_context.index_buf, idx, idx + 1, idx + 2, idx, idx + 2, idx + 3)
}

// Process the Microui command list and render it
microui_render :: proc() {
    // Prepare OpenGL state for 2D UI rendering
    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.Disable(gl.CULL_FACE)
    gl.Disable(gl.DEPTH_TEST)
    gl.Enable(gl.SCISSOR_TEST)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, debug_ui_context.mu_atlas_tex)

    use_shader(debug_ui_context.mu_shader)

    // Set up orthographic projection
    projection_matrix := glm.mat4Ortho3d(0, f32(WINDOW_WIDTH) / UI_SCALE, f32(WINDOW_HEIGHT) / UI_SCALE, 0, -1, 1)
    set_shader_uniform_mat4(debug_ui_context.mu_shader, "u_projection", &projection_matrix)
    set_shader_uniform_int(debug_ui_context.mu_shader, "u_texture", 0)

    // Process commands
    command_backing : ^mu.Command
    for variant in mu.next_command_iterator(&debug_ui_context.mu_ctx, &command_backing) {
        #partial switch cmd in variant {
        case ^mu.Command_Text:
            dst := mu.Rect{cmd.pos.x, cmd.pos.y, 0, 0}
            for ch in cmd.str {
                if ch & 0xc0 == 0x80 {continue}
                r := min(int(ch), 127)
                src := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
                dst.w, dst.h = src.w, src.h
                microui_push_quad(dst, src, cmd.color)
                dst.x += dst.w
            }
        case ^mu.Command_Rect:
            // Use the special white pixel in the atlas for solid colors
            white_pixel_rect := mu.default_atlas[mu.DEFAULT_ATLAS_WHITE]
            microui_push_quad(cmd.rect, white_pixel_rect, cmd.color)
        case ^mu.Command_Icon:
            src := mu.default_atlas[cmd.id]
            x := cmd.rect.x + (cmd.rect.w - src.w) / 2
            y := cmd.rect.y + (cmd.rect.h - src.h) / 2
            microui_push_quad(mu.Rect{x, y, src.w, src.h}, src, cmd.color)
        case ^mu.Command_Clip:
            microui_flush() // Flush before changing scissor rect
            gl.Scissor(cmd.rect.x, WINDOW_HEIGHT - (cmd.rect.y + cmd.rect.h), cmd.rect.w, cmd.rect.h)
        }
    }
    microui_flush() // Flush remaining commands at the end of the frame

    // Reset scissor to full screen
    gl.Scissor(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
}

// Defines and processes the UI for our application
run_debug_ui :: proc() {
    if !app_state.show_debug_ui {
        return
    }

    // mu.begin(&debug_ui_context.mu_ctx)

    // open and close UI with F1, don't let UI be closed by clicking X
    if mu.window(&debug_ui_context.mu_ctx, "Controls", {10, 10, 200, 150}, {.NO_CLOSE}) {
        mu.layout_row(&debug_ui_context.mu_ctx, {-1}, 0)
        mu.label(&debug_ui_context.mu_ctx, "Simple UI Controls")

        mu.layout_row(&debug_ui_context.mu_ctx, {-1}, 0)
        if .CHANGE in mu.checkbox(&debug_ui_context.mu_ctx, "Show 3D Quad", &app_state.show_quad) {
            fmt.println("show_quad changed to", app_state.show_quad)
        }

        mu.layout_row(&debug_ui_context.mu_ctx, {20, -1})
        mu.label(&debug_ui_context.mu_ctx, "BG:")

        // A helper to create a u8 slider
        u8_slider :: proc(val : ^u8, lo, hi : int) {
            ctx := &debug_ui_context.mu_ctx

            // Push the memory address of `val` as a unique ID for this slider.
            mu.push_id(ctx, uintptr(val))

            // This static var is now safe because Microui uses the ID stack
            // to distinguish between the controls that use it.
            @(static) tmp : mu.Real
            tmp = mu.Real(val^)
            mu.slider(ctx, &tmp, f32(lo), f32(hi), 0, "%.0f", {})
            val^ = u8(tmp)

            // Pop the ID to restore the stack for the next control.
            mu.pop_id(ctx)
        }

        mu.layout_begin_column(&debug_ui_context.mu_ctx)
        u8_slider(&app_state.bg_color.r, 0, 255)
        u8_slider(&app_state.bg_color.g, 0, 255)
        u8_slider(&app_state.bg_color.b, 0, 255)
        mu.layout_end_column(&debug_ui_context.mu_ctx)

        mu.layout_begin_column(&debug_ui_context.mu_ctx)
		tt := "Hello?"
		tl := len(tt)
		mu.textbox(&debug_ui_context.mu_ctx, ([]u8)(raw_data(tt)[:tl]), &tl, {})
        mu.layout_end_column(&debug_ui_context.mu_ctx)
    }

   // mu.end(&debug_ui_context.mu_ctx)
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
	debug_ui_context.log_buf_len += copy(debug_ui_context.log_buf[debug_ui_context.log_buf_len:], str)
	debug_ui_context.log_buf_len += copy(debug_ui_context.log_buf[debug_ui_context.log_buf_len:], "\n")
	debug_ui_context.log_buf_updated = true
}

read_log :: proc() -> string {
	return string(debug_ui_context.log_buf[:debug_ui_context.log_buf_len])
}

reset_log :: proc() {
	debug_ui_context.log_buf_updated = true
	debug_ui_context.log_buf_len = 0
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
				mu.label(ctx, "Red:");u8_slider(ctx, &debug_ui_context.bg.r, 0, 255)
				mu.label(ctx, "Green:");u8_slider(ctx, &debug_ui_context.bg.g, 0, 255)
				mu.label(ctx, "Blue:");u8_slider(ctx, &debug_ui_context.bg.b, 0, 255)
			}
			mu.layout_end_column(ctx)

			r := mu.layout_next(ctx)
			mu.draw_rect(ctx, r, debug_ui_context.bg)
			mu.draw_box(ctx, mu.expand_rect(r, 1), ctx.style.colors[.BORDER])
			mu.draw_control_text(ctx, fmt.tprintf("#%02x%02x%02x", debug_ui_context.bg.r, debug_ui_context.bg.g, debug_ui_context.bg.b), r, .TEXT, {.ALIGN_CENTER})
		}
	}

	if mu.window(ctx, "Log Window", {350, 40, 300, 200}, opts) {
		mu.layout_row(ctx, {-1}, -28)
		mu.begin_panel(ctx, "Log")
		mu.layout_row(ctx, {-1}, -1)
		mu.text(ctx, read_log())
		if debug_ui_context.log_buf_updated {
			panel := mu.get_current_container(ctx)
			panel.scroll.y = panel.content_size.y
			debug_ui_context.log_buf_updated = false
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
