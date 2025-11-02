// https://en.wikipedia.org/wiki/Camera_matrix
// https://github.com/ssloy/tinyrenderer/wiki/Lesson-5-Moving-the-camera
// https://learn.microsoft.com/en-us/windows/win32/direct3d10/d3d10-graphics-programming-guide-resources-coordinates
package tinyrenderer

import "base:intrinsics"
import "core:container/queue"
import "core:fmt"
import "core:math"
import lg "core:math/linalg"
import "core:math/rand"
import "core:mem"
import "core:os"
import "core:slice"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"
import "shared:obug"

_ :: fmt

byte4 :: cv.byte4
int2 :: cv.int2
int3 :: cv.int3
float2 :: cv.float2
float3 :: cv.float3
float4 :: cv.float4
float3x3 :: cv.float3x3
float4x3 :: cv.float4x3
float4x4 :: cv.float4x4

width: i32 : 160
height: i32 : width * 3 / 4
ZOOM :: 6
FOV_ANGLE :: 90

do_rotate := true
rot_y: f32 = 0

fov: f32
aspect: f32
near, far: f32 = 1, 10

viewport, proj, view, rotate: float4x4

zbuffer: [width * height]f32
flip_z_axis := true

pics_w: i32 : 32
pics_h: i32 : pics_w
pics_pixel_byte_size: i32 : size_of(byte4)
pics_buf_pixel_count: i32 : pics_w * pics_h
pics_buf_byte_size: i32 : pics_buf_pixel_count * pics_pixel_byte_size
pics_buf :: [pics_buf_pixel_count]byte4
pics_size :: float2{f32(pics_w), f32(pics_h)}
pics_tex_lookup :: int2{pics_w, 1}

pics_data := #load("../raycaster/pics32.dat")
pics_count := i32(len(pics_data)) / pics_buf_byte_size
textures: []pics_buf = slice.from_ptr((^pics_buf)(&pics_data[0]), int(pics_count))

light_dir := float3{1, -1, 1} // light source
eye := float3{1, -2.5, 3} // camera position
center := float3{0, 0, 0} // camera direction
up := float3{0, 1, 0} // camera up vector

vert_count :: 6
vertices: [vert_count]cv.VS_INPUT = {
	{{-1, 0, 0}, {-1, 0, 0}, {0.0, 0.5}},
	{{ 1, 0, 0}, { 1, 0, 0}, {1.0, 0.5}},
	{{ 0,-1, 0}, { 0,-1, 0}, {0.5, 0.5}},
	{{ 0, 1, 0}, { 0, 1, 0}, {0.5, 0.5}},
	{{ 0, 0,-1}, { 0, 0,-1}, {0.5, 0.0}},
	{{ 0, 0, 1}, { 0, 0, 1}, {0.5, 1.0}},
}
vert: [vert_count]cv.VS_OUTPUT
triangles := [?]int3{{3, 4, 0}, {3, 0, 5}, {3, 5, 1}, {3, 1, 4}, {2, 0, 4}, {2, 5, 0}, {2, 1, 5}, {2, 4, 1}}
models: [9]cv.Model
shader: cv.Shader

// application :: struct {
// 	#subtype app: ca.application,
// 	shader: cv.Shader
// }

vs_default :: proc "contextless" (shader: ^cv.Shader, input: ^cv.VS_INPUT, output: ^cv.VS_OUTPUT) {
	output.position = shader.proj_view_model * cv.to_float4(input.position)
	output.normal = lg.normalize(input.normal)
	output.texcoord = input.texcoord
}

sample2D :: proc "contextless" (uv: float2) -> byte4 {
	uv := cv.to_int2(lg.fract(uv) * pics_size)
	tex_idx := lg.dot(uv, pics_tex_lookup)
	return textures[shader.model.tex][tex_idx]
}

ps_default :: proc "contextless" (shader: ^cv.Shader, bc_clip: float3, color: ^byte4) -> bool {
	color^ = cv.to_color(bc_clip)
	return false
}

ps_normal_color :: proc "contextless" (shader: ^cv.Shader, bc_clip: float3, color: ^byte4) -> bool {
	bn: float3 = lg.normalize(shader.varying_nrm * bc_clip)
	color^ = cv.to_color(bn * 0.5 + 0.5)
	return false
}

ps_uv_color :: proc "contextless" (shader: ^cv.Shader, bc_clip: float3, color: ^byte4) -> bool {
	uv := lg.fract(float2(shader.varying_uv * bc_clip))
	color^ = cv.to_color(float3{uv.x, uv.y, 0})
	return false
}

ps_color :: proc "contextless" (shader: ^cv.Shader, bc_clip: float3, color: ^byte4) -> bool {
	// per-vertex normal interpolation
	bn: float3 = lg.normalize(shader.varying_nrm * bc_clip)

	//d := lg.dot(shader.uniform_l, bn)
	d := lg.dot(light_dir, bn)
	d = clamp(d, 0.2, 1)

	col := shader.model.color
	col *= d
	color^ = cv.to_color(col)

	return false
}

ps_texture :: proc "contextless" (shader: ^cv.Shader, bc_clip: float3, color: ^byte4) -> bool {
	// tex coord interpolation
	//uv := lg.fract(shader.varying_uv * bc_clip)
	//uv := shader.varying_uv
	tex_col := sample2D(shader.varying_uv * bc_clip)
	if tex_col.a == 0 {return true}

	// per-vertex normal interpolation
	bn: float3 = lg.normalize(shader.varying_nrm * bc_clip)

	//d := lg.dot(shader.uniform_l, bn)
	d := lg.dot(light_dir, bn)
	d = clamp(d, 0.2, 1)

	col := shader.model.color
	col *= d
	col *= cv.to_color(tex_col)
	color^ = cv.to_color(col)

	return false
}

on_create :: proc(app: ^ca.application) -> int {
	canvas := &ca.dib.canvas
	size := cv.get_canvas_size(canvas)
	fov = FOV_ANGLE * math.PI / 360
	aspect = f32(size.x) / f32(size.y)
	viewport = cv.create_viewport(size)
	view = lg.matrix4_look_at_f32(eye, center, up, flip_z_axis)
	proj = cv.matrix4_perspective_f32_01(fov, aspect, far, near, flip_z_axis)
	rotate = lg.identity(float4x4)
	light_dir = lg.normalize(light_dir)

	fmt.println("size      :", size)
	fmt.println("viewport  :", viewport)
	fmt.println("view      :", view)
	fmt.println("proj      :", proj)
	fmt.println("light_dir :", light_dir)

	for y in -1 ..= 1 {
		for x in -1 ..= 1 {
			idx := y * 3 + x + 4 // 0..8
			models[idx] = cv.Model {
				trans = lg.matrix4_translate(float3{f32(x), 0, f32(y)} * 2),
				color = cv.color_hue_float4(rand.float32() * math.TAU, 0.3, 0.7),
				tex   = i32(idx), // rand.int31_max(pics_count),
			}
		}
	}

	shader = cv.Shader {
		vs = vs_default,
		//ps = ps_default,
		//ps = ps_color,
		ps = ps_texture,
	}
	return 0
}

on_update :: proc(app: ^ca.application) -> int {

	if .MK_LBUTTON in app.mouse_buttons {
		mp := ca.decode_mouse_pos_ndc(app)
		eye.x = mp.x * 10
		eye.y = mp.y * 5
	}
	if .MK_RBUTTON in app.mouse_buttons {
		mp := ca.decode_mouse_pos_01(app)
		eye = lg.normalize(eye) * (1 + mp.y * 10)
	}
	if .MK_MBUTTON in app.mouse_buttons {
	}

	ch, ok := queue.pop_front_safe(&app.char_queue)
	if ok {
		switch ch {
		case ' ':
			do_rotate ~= true
		case '1':
			shader.ps = ps_default
		case '2':
			shader.ps = ps_color
		case '3':
			shader.ps = ps_texture
		case '4':
			shader.ps = ps_texture_wip
		case '5':
			shader.ps = ps_normal_color
		case '6':
			shader.ps = ps_uv_color
		case:
			fmt.println("ch:", ch)
		}
	}

	canvas := &ca.dib.canvas
	//cv.canvas_clear(canvas, cv.COLOR_BLACK)
	cv.canvas_clear(canvas)
	mem.zero(&zbuffer, size_of(zbuffer))

	view = lg.matrix4_look_at(eye, center, up)
	proj_view := proj * view

	if do_rotate {
		rot_y += app.delta * 0.5
		rotate = cv.matrix4_rotate_y_f32(rot_y)
	}

	update_shader :: #force_inline proc "contextless" (triangle: int3, clip_verts: ^float4x3, shader: ^cv.Shader) {
		update_vs_output :: #force_inline proc "contextless" (vso: ^cv.VS_OUTPUT, pos: ^float4, nrm: ^float3, uv: ^float2) {
			pos^, nrm^, uv^ = vso.position, vso.normal, vso.texcoord
		}
		nrm: float3x3
		update_vs_output(&vert[triangle[0]], &clip_verts[0], &nrm[0], &shader.varying_uv[0])
		update_vs_output(&vert[triangle[1]], &clip_verts[1], &nrm[1], &shader.varying_uv[1])
		update_vs_output(&vert[triangle[2]], &clip_verts[2], &nrm[2], &shader.varying_uv[2])
		// #unroll for vi in 0..<3 {
		//   update_vs_output(&vert[triangle[vi]], &clip_verts[vi], &nrm[vi], &shader.varying_uv[vi])
		// }

		shader.varying_nrm = shader.it_model_view * nrm
		mvv: float4x3 = shader.model_view * clip_verts^
		shader.view_tri = cv.to_float3x3(&mvv)
		// transform the light vector to view coordinates
		shader.uniform_l = lg.normalize((shader.model_view * cv.to_float4(light_dir, 0)).xyz)
	}

	for &model in models {

		shader.model = &model
		shader.model_view = rotate * model.trans * rotate
		shader.it_model_view = lg.inverse_transpose(float3x3(shader.model_view))
		shader.proj_view_model = proj_view * shader.model_view

		for i in 0 ..< vert_count {
			shader->vs(&vertices[i], &vert[i])
		}

		clip_verts: float4x3
		for t in triangles {
			update_shader(t, &clip_verts, &shader)
			cv.draw_triangle(canvas, zbuffer[:], &viewport, &clip_verts, &shader)
		}
	}

	return 0
}

run :: proc() -> (exit_code: int) {
	app := ca.default_application
	app.size = {width, height}
	app.create = on_create
	app.update = on_update
	app.settings.window_size = app.size * ZOOM
	exit_code = ca.run(&app)
	return
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}
