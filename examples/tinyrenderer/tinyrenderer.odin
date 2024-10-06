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
//import win32 "core:sys/windows"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"
import "shared:obug"

_ :: fmt

vec2 :: lg.Vector2f32
vec3 :: lg.Vector3f32
vec4 :: lg.Vector4f32
mat3x3 :: lg.Matrix3x3f32
mat4x4 :: lg.Matrix4x4f32
byte4 :: cv.byte4
int2 :: cv.int2
float2 :: cv.float2
float3 :: cv.float3
float4 :: cv.float4
float3x3 :: cv.float3x3
//float3x4 :: cv.float3x4
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

viewport: mat4x4
proj, view: mat4x4
rotate: mat4x4
proj_view, proj_view_model: mat4x4

zbuffer: [width * height]f32
flip_z_axis := true

pics := #load("../raycaster/pics32.dat")
pics_w: i32 : 32
pics_h: i32 : pics_w
pics_ps: i32 : size_of(cv.byte4)
pics_byte_size: i32 : pics_w * pics_h * pics_ps
pics_count := i32(len(pics)) / pics_byte_size

light_dir := vec3{1, -1, 1} // light source
eye       := vec3{1, -2.5, 3} // camera position
center    := vec3{0, 0, 0} // camera direction
up        := vec3{0, 1, 0} // camera up vector

vert_count :: 6
vertices: [vert_count]cv.float3 = {{-1, 0, 0}, {1, 0, 0}, {0, -1, 0}, {0, 1, 0}, {0, 0, -1}, {0, 0, 1}}
vert: [vert_count]cv.float4
triangles := [?]cv.int3{{3, 4, 0}, {3, 0, 5}, {3, 5, 1}, {3, 1, 4}, {2, 0, 4}, {2, 5, 0}, {2, 1, 5}, {2, 4, 1}}
models: [9]cv.Model
shader: cv.IShader

vs_default :: proc(shader: ^cv.IShader, pos: float4, gl_Position: ^float4) {
	gl_Position^ = proj_view_model * pos
}

pics_size :: float2{f32(pics_w), f32(pics_h)}
pics_tex_lookup :: int2{pics_w  * pics_ps, pics_ps}

sample2D :: proc(uv: float2) -> cv.byte4 {
	uv := cv.to_int2(lg.fract(uv) * pics_size)
	tidx := lg.dot(uv, pics_tex_lookup)
	tidx += 4096 * shader.model.tex
	return (^cv.byte4)(&pics[tidx])^
}

ps_default :: proc(shader: ^cv.IShader, bc_clip: float3, color: ^byte4) -> bool {
	color^ = cv.to_color(bc_clip)
	return false
}

ps_color :: proc(shader: ^cv.IShader, bc_clip: float3, color: ^byte4) -> bool {
	// per-vertex normal interpolation
	bn: float3 = lg.normalize(shader.varying_nrm * bc_clip)
	//d := lg.dot(shader.uniform_l, bn)
	d := lg.dot(light_dir, bn)
	d = clamp(d, 0, 1)
	c := d * 0.8 + 0.2
	col := float4{c, c, c, 0}
	color^ = cv.to_color(shader.model.color * col)
	return false
}

ps_texture :: proc(shader: ^cv.IShader, bc_clip: float3, color: ^byte4) -> bool {
	// per-vertex normal interpolation
	bn: float3 = lg.normalize(shader.varying_nrm * bc_clip)
	// tex coord interpolation
	uv: float2 = shader.varying_uv * bc_clip

	texcol := sample2D(uv)
	if texcol.a == 0 {return true}

	//d := lg.dot(shader.uniform_l, bn)
	d := lg.dot(light_dir, bn)
	d = clamp(d, 0.2, 1)

	col := cv.to_color_byte4(texcol)
	col *= shader.model.color
	col *= d
	color^ = cv.to_color(col)

	return false
}

on_create :: proc(app: ca.papp) -> int {
	canvas := &ca.dib.canvas
	size := cv.get_canvas_size(canvas)
	fov = FOV_ANGLE * math.PI / 360
	aspect = f32(size.x) / f32(size.y)
	viewport = cv.create_viewport(size)
	view = lg.matrix4_look_at_f32(eye, center, up, flip_z_axis)
	proj = cv.matrix4_perspective_f32_01(fov, aspect, far, near, flip_z_axis)
	rotate = lg.identity(mat4x4)
	light_dir = lg.normalize(light_dir)

	fmt.println("size      :", size)
	fmt.println("viewport  :", viewport)
	fmt.println("view      :", view)
	fmt.println("proj      :", proj)
	fmt.println("light_dir :", light_dir)

	for y in -1 ..= 1 {for x in -1 ..= 1 {
			idx := y * 3 + x + 4 // 0..8
			models[idx] = cv.Model {
				trans = lg.matrix4_translate(cv.float3{f32(x), 0, f32(y)} * 2),
				color = cv.color_hue_float4(rand.float32() * math.PI * 2, 0.3, 0.7),
				tex   = i32(idx), // rand.int31_max(pics_count),
			}
		}}

	shader = cv.IShader {
		vs = vs_default,
		//ps = ps_default,
		//ps = ps_color,
		ps = ps_texture,
	}
	return 0
}

on_update :: proc(app: ca.papp) -> int {

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
		case:
			fmt.println("ch:", ch)
		}
	}

	canvas := &ca.dib.canvas
	//cv.canvas_clear(canvas, cv.COLOR_BLACK)
	cv.canvas_clear(canvas)
	mem.zero(&zbuffer, size_of(zbuffer))

	view = lg.matrix4_look_at(eye, center, up)
	proj_view = proj * view

	if do_rotate {
		rot_y += app.delta * 0.5
		rotate = cv.matrix4_rotate_y_f32(rot_y)
	}

	for &model in models {

		shader.model = &model
		shader.model_view = rotate * model.trans * rotate
		shader.it_model_view = lg.inverse_transpose(shader.model_view)
		//shader.it_model_view3 = lg.inverse_transpose(float3x3(shader.model_view))

		model_view_3x3 := float3x3(shader.model_view)
		it_model_view_3x3 := lg.inverse_transpose(model_view_3x3)
		proj_view_model = proj_view * shader.model_view

		for i in 0 ..< vert_count {
			shader->vs(cv.to_float4(vertices[i]), &vert[i])
		}

		v: cv.float4x3
		n: float3x3
		for t in triangles {

			v[0], v[1], v[2] = vert[t.x], vert[t.y], vert[t.z]
			n[0], n[1], n[2] = lg.normalize(vertices[t.x]), lg.normalize(vertices[t.y]), lg.normalize(vertices[t.z])

			shader.varying_nrm = it_model_view_3x3 * n

			shader.varying_uv[0] = vertices[t[0]].xy
			shader.varying_uv[1] = vertices[t[1]].xy
			shader.varying_uv[2] = vertices[t[2]].xy

			// #unroll for vi in 0..<3 {
			//   shader.varying_uv[vi] = vertices[t[vi]].xy
			// }

			mvv : cv.float4x3 = shader.model_view * v
			shader.view_tri = cv.to_float3x3(&mvv)

			// transform the light vector to view coordinates
			shader.uniform_l = lg.normalize((shader.model_view * cv.to_float4(light_dir, 0)).xyz)

			//cv.draw_triangle(canvas, zbuffer[:], &viewport, {v0, v1, v2}, &shader)
			cv.draw_triangle(canvas, zbuffer[:], &viewport, {v[0], v[1], v[2]}, &shader)
		}
	}

	return 0
}

run :: proc() {
	ca.app.size = {width, height}
	ca.app.create = on_create
	ca.app.update = on_update
	ca.settings.window_size = ca.app.size * ZOOM
	ca.run()
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		obug.tracked_run(run)
	} else {
		run()
	}
}
