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

    mu.begin(&debug_ui_context.mu_ctx)

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
    }

    mu.end(&debug_ui_context.mu_ctx)
}
