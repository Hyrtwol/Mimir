//
package tinyrenderer

import "core:container/queue"
import "core:fmt"
import "core:intrinsics"
import "core:math"
import lg "core:math/linalg"
import "core:math/rand"
import win32 "core:sys/windows"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"

_ :: fmt

vec2 :: lg.Vector2f32
vec3 :: lg.Vector3f32
vec4 :: lg.Vector4f32
mat3x3 :: lg.Matrix3x3f32
mat4x4 :: lg.Matrix4x4f32
byte4 :: cv.byte4
int2 :: cv.int2

width: i32 : 160
height: i32 : width * 3 / 4
ZOOM :: 6

do_rotate := true
rot_y: f32 = 0

fov90: f32 : 90 * math.PI / 360
fov: f32 = fov90
aspect: f32 = f32(width) / f32(height)

rng := rand.create(u64(intrinsics.read_cycle_counter()))

// ModelView: mat4x4
Viewport: mat4x4
// Projection: mat4x4
proj, view, model: mat4x4



// odinfmt: disable

light_dir := vec3{1, 1, 1} // light source
eye       := vec3{1, -2.5, 3} // camera position
center    := vec3{0, 0, 0} // camera direction
up        := vec3{0, 1, 0} // camera up vector

// https://en.wikipedia.org/wiki/Camera_matrix
// https://github.com/ssloy/tinyrenderer/wiki/Lesson-5-Moving-the-camera
// https://learn.microsoft.com/en-us/windows/win32/direct3d10/d3d10-graphics-programming-guide-resources-coordinates

create_viewport :: #force_inline proc "contextless" (x, y, w, h: f32) -> mat4x4 {
	return {
		w/2, 0  , 0  , x+w/2,
		0  , h/2, 0  , y+h/2,
		0  , 0  , 1  , 0    ,
		0  , 0  , 0  , 1    ,
	}
}

// odinfmt: enable

barycentric :: #force_inline proc "contextless" (abc: ^mat3x3, x, y: i32) -> vec3 {
	return lg.inverse_transpose(abc^) * vec3{f32(x), f32(y), 1}
}

IShader :: struct {}

//fragment :: proc(shader: ^IShader, bc_clip :vec3, color: ^byte4) -> bool {return false}
fragment_shader :: #type proc(shader: ^IShader, bc_clip: vec3, color: ^byte4) -> bool

vert_count :: 6
vertices: [vert_count]cv.float3 = {{-1, 0, 0}, {1, 0, 0}, {0, -1, 0}, {0, 1, 0}, {0, 0, -1}, {0, 0, 1}}
vert: [vert_count]cv.float4

triangles := [?]cv.int3{{3, 4, 0}, {3, 0, 5}, {3, 5, 1}, {3, 1, 4}, {2, 0, 4}, {2, 5, 0}, {2, 1, 5}, {2, 4, 1}}

models: [6]cv.float4x4

on_create :: proc(app: ca.papp) -> int {
	pc := &ca.dib.canvas
	width, height := cv.canvas_size(pc)
	fov = fov90
	aspect = f32(width) / f32(height)
	fmt.println("width, height:", width, height)

	view = lg.matrix4_look_at(eye, center, up)
	Viewport = create_viewport(0, 0, f32(width), f32(height))
	proj = lg.matrix4_perspective(fov, aspect, 0.1, 10)
	fmt.println("model:", model)
	fmt.println("view :", view)
	fmt.println("proj :", proj)

	models = {
		lg.matrix4_translate(cv.float3{0, 0, 0}),
		lg.matrix4_translate(cv.float3{2, 0, 0}),
		lg.matrix4_translate(cv.float3{-2, 0, 0}),
		lg.matrix4_translate(cv.float3{0, 0, -2}),
		lg.matrix4_translate(cv.float3{2, 0, -2}),
		lg.matrix4_translate(cv.float3{-2, 0, -2}),
	}

	// for i in 0..<vert_count {
	// 	vert[i] = cv.to_float4(vertices[i])
	// }

	return 0
}

on_update :: proc(app: ca.papp) -> int {

	pc := &ca.dib.canvas

	#partial switch app.mouse_buttons {
	case .MK_LBUTTON:
		mp := ca.decode_mouse_pos_01(app) // 0..1
		eye.x = (mp.x - 0.5) * 10
		eye.y = -2.5 + mp.y * 5
	case .MK_RBUTTON:
		mp := ca.decode_mouse_pos_01(app) // 0..1
		eye = lg.normalize(eye) * (2 + mp.y * 5)
	case .MK_MBUTTON:
		mp := ca.decode_mouse_pos_01(app) // 0..1
		fov = fov90 + fov90 * mp.y
		aspect = cv.canvas_aspect(pc)
		proj = lg.matrix4_perspective(fov, aspect, 0.1, 10)
	}

	ch, ok := queue.pop_front_safe(&app.char_queue)
	if ok {
		switch ch {
		case ' ':
			do_rotate ~= true
		case:
			fmt.println("ch:", ch)
		}
	}

	cv.canvas_clear(pc, cv.COLOR_BLACK)

	view = lg.matrix4_look_at(eye, center, up)
	proj_view := proj * view

	if do_rotate {
		rot_y += f32(app.delta) * 0.5
	}
	model := cv.matrix4_rotate_y_f32(rot_y)

	// for i in 0..<vert_count {
	// 	vert[i] = cv.to_float4(vertices[i])
	// }

	for &m in models {

		fm := m * model
		proj_view_model := proj_view * fm

		for i in 0 ..< vert_count {
			v := cv.to_float4(vertices[i])
			v = proj_view_model * v
			v = cv.normalized_device_coordinates(&Viewport, v)
			vert[i] = v
		}

		for t in triangles {
			v0, v1, v2 := vert[t.x], vert[t.y], vert[t.z]
			cv.draw_triangle(pc, {v0, v1, v2})
		}
	}

	return 0
}

main :: proc() {
	ca.app.size = {width, height}
	ca.app.create = on_create
	ca.app.update = on_update
	ca.settings.window_size = ca.app.size * ZOOM
	ca.run()
	fmt.println("app:", ca.app)
}
