//
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
float2 :: cv.float2
float3 :: cv.float3
float4 :: cv.float4
float3x3 :: cv.float3x3
float4x4 :: cv.float4x4

width: i32 : 160
height: i32 : width * 3 / 4
ZOOM :: 6

do_rotate := true
rot_y: f32 = 0

fov90: f32 : 90 * math.PI / 360
fov: f32 = fov90
aspect: f32 = f32(width) / f32(height)
near, far: f32 = 1, 10

viewport: mat4x4
proj, view: mat4x4
rotate: mat4x4
proj_view, proj_view_model: mat4x4


zbuffer: [width * height]f32
flip_z_axis := true

pics := #load("../raycaster/pics.dat")
pics_w: i32 : 32
pics_h: i32 : pics_w
pics_ps: i32 : size_of(cv.byte4)
pics_size: i32 : pics_w * pics_h * pics_ps
pics_count := i32(len(pics)) / pics_size


// odinfmt: disable

light_dir := vec3{1, -1, 1} // light source
eye       := vec3{1, -2.5, 3} // camera position
center    := vec3{0, 0, 0} // camera direction
up        := vec3{0, 1, 0} // camera up vector

// odinfmt: enable

barycentric :: #force_inline proc "contextless" (abc: ^mat3x3, x, y: i32) -> vec3 {
	return lg.inverse_transpose(abc^) * vec3{f32(x), f32(y), 1}
}

// vertex_shader :: #type proc(pos: float4, gl_Position: ^float4)
// pixel_shader :: #type proc(shader: ^IShader, bc_clip: float3, color: ^byte4) -> bool

// Model :: struct {
// 	trans: cv.float4x4,
// 	color: byte4,
// }
// IShader :: struct {
// 	model: ^Model,
// 	vs: vertex_shader,
// 	ps: pixel_shader,
// }

vert_count :: 6
vertices: [vert_count]cv.float3 = {{-1, 0, 0}, {1, 0, 0}, {0, -1, 0}, {0, 1, 0}, {0, 0, -1}, {0, 0, 1}}
vert: [vert_count]cv.float4

triangles := [?]cv.int3{{3, 4, 0}, {3, 0, 5}, {3, 5, 1}, {3, 1, 4}, {2, 0, 4}, {2, 5, 0}, {2, 1, 5}, {2, 4, 1}}

models: [9]cv.Model
shader: cv.IShader

vs_default :: proc(shader: ^cv.IShader, pos: float4, gl_Position: ^float4) {
	// varying_uv.set_col(nthvert, model.uv(iface, nthvert));
	// shader.varying_uv = cv.float2x3{
	// 	0,0,0,
	// 	0,0,0,
	// }
	// shader.varying_uv[0] = {0,0}

	// varying_nrm.set_col(nthvert, proj<3>((ModelView).invert_transpose()*embed<4>(model.normal(iface, nthvert), 0.)));
	// gl_Position= ModelView*embed<4>(model.vert(iface, nthvert));
	// view_tri.set_col(nthvert, proj<3>(gl_Position));
	// gl_Position = Projection*gl_Position;
	gl_Position^ = proj_view_model * pos
}

sample2D :: proc(uv: float2) -> cv.byte4 {
	uvf := lg.fract(uv)
	x, y := i32(uvf.x * f32(pics_w)), i32(uvf.y * f32(pics_h))
	tidx := (((y * pics_w + x) * pics_ps) & 4095) + 4096 * shader.model.tex
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

ps_texture_wip :: proc(shader: ^cv.IShader, bc_clip: float3, color: ^byte4) -> bool {
	// per-vertex normal interpolation
	bn: float3 = lg.normalize(shader.varying_nrm * bc_clip)
	// tex coord interpolation
	uv: float2 = shader.varying_uv * bc_clip
	//uv: float2 = bc_clip.xy

	texcol := sample2D(uv)
	if texcol.a == 0 {return true}

	/*
	// for the math refer to the tangent space normal mapping lecture
	// https://github.com/ssloy/tinyrenderer/wiki/Lesson-6bis-tangent-space-normal-mapping
	// float3x3 AI = float3x3{ {view_tri.col(1) - view_tri.col(0), view_tri.col(2) - view_tri.col(0), bn} }.invert();
	A: float3x3
	A[0] = shader.view_tri[1] - shader.view_tri[0]
	A[1] = shader.view_tri[2] - shader.view_tri[0]
	A[2] = bn
	AI := lg.inverse(A)
	// float3 i = AI * float3{varying_uv[0][1] - varying_uv[0][0], varying_uv[0][2] - varying_uv[0][0], 0};
	i := AI * float3{shader.varying_uv[1].x - shader.varying_uv[0].x, shader.varying_uv[2].x - shader.varying_uv[0].x, 0}
	// float3 j = AI * float3{varying_uv[1][1] - varying_uv[1][0], varying_uv[1][2] - varying_uv[1][0], 0};
	j := AI * float3{shader.varying_uv[1].y - shader.varying_uv[0].y, shader.varying_uv[2].y - shader.varying_uv[1].y, 0}
	// float3x3 B = float3x3{ {i.normalized(), j.normalized(), bn} }.transpose();
	B: float3x3
	B[0] = lg.normalize(i)
	B[1] = lg.normalize(j)
	B[2] = bn
	B = lg.transpose(B)
	*/

	// float3 n = (B * model.normal(uv)).normalized(); // transform the normal from the texture to the tangent space
	// double diff = std::max(0., n*uniform_l); // diffuse light intensity
	// float3 r = (n*(n*uniform_l)*2 - uniform_l).normalized(); // reflected light direction, specular mapping is described here: https://github.com/ssloy/tinyrenderer/wiki/Lesson-6-Shaders-for-the-software-renderer
	// double spec = std::pow(std::max(-r.z, 0.), 5+sample2D(model.specular(), uv)[0]); // specular intensity, note that the camera lies on the z-axis (in view), therefore simple -r.z
	// TGAColor c = sample2D(model.diffuse(), uv);
	// for (int i : {0,1,2})
	//     gl_FragColor[i] = std::min<int>(10 + c[i]*(diff + spec), 255); // (a bit of ambient light, diff + spec), clamp the result

	d := lg.dot(shader.uniform_l, bn)
	//d := lg.dot(light_dir, bn)
	d = clamp(d, 0.2, 1)

	//c := d * 0.8 + 0.2
	//col := float4{uv.x, uv.y, 0, 1}


	col := cv.to_color_byte4(texcol)

	//col := shader.model.color
	col *= shader.model.color
	//col *= texcol
	col *= d
	//col += 0.1
	//col = texcol
	//col = lg.clamp(col, 0, 1)
	color^ = cv.to_color(col)

	//color^ = (^cv.byte4)(&pics[tidx])^
	return false
}

on_create :: proc(app: ca.papp) -> int {
	pc := &ca.dib.canvas
	width, height := cv.canvas_size_xy(pc)
	fov = fov90
	aspect = f32(width) / f32(height)
	fmt.println("width, height:", width, height)

	view = lg.matrix4_look_at_f32(eye, center, up, flip_z_axis)
	viewport = cv.create_viewport(0, 0, f32(width), f32(height))
	proj = cv.matrix4_perspective_f32_01(fov, aspect, far, near, flip_z_axis)
	rotate = lg.identity(mat4x4)
	light_dir = lg.normalize(light_dir)

	fmt.println("viewport:", viewport)
	fmt.println("view    :", view)
	fmt.println("proj    :", proj)

	for y in -1 ..= 1 {for x in -1 ..= 1 {
			models[x + y * 3 + 4] = cv.Model {
				trans = lg.matrix4_translate(cv.float3{f32(x), 0, f32(y)} * 2),
				//color = cv.random_color(),
				color = cv.color_hue_float4(rand.float32() * math.PI * 2, 0.3, 0.7),
				tex   = rand.int31_max(pics_count),
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

	pc := &ca.dib.canvas

	#partial switch app.mouse_buttons {
	case .MK_LBUTTON:
		mp := ca.decode_mouse_pos_ndc(app)
		eye.x = mp.x * 10
		eye.y = mp.y * 5
	case .MK_RBUTTON:
		mp := ca.decode_mouse_pos_01(app)
		eye = lg.normalize(eye) * (1 + mp.y * 10)
	case .MK_MBUTTON:
	// mp := ca.decode_mouse_pos_01(app)
	// fov = fov90 + fov90 * mp.y
	// aspect = cv.canvas_aspect(pc)
	// proj = lg.matrix4_perspective(fov, aspect, 1, 10)
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

	cv.canvas_clear(pc, cv.COLOR_BLACK)
	mem.zero(&zbuffer, size_of(zbuffer))

	view = lg.matrix4_look_at(eye, center, up)
	proj_view = proj * view

	if do_rotate {
		rot_y += app.delta * 0.5
		rotate = cv.matrix4_rotate_y_f32(rot_y)
	}

	// for i in 0..<vert_count {vert[i] = cv.to_float4(vertices[i])}

	for &model in models {

		shader.model = &model
		shader.model_view = rotate * model.trans * rotate
		//f33 := float3x3(shader.model_view)
		shader.it_model_view = lg.inverse_transpose(shader.model_view)
		//shader.it_model_view3 = lg.inverse_transpose(float3x3(shader.model_view))
		it_model_view3 := lg.inverse_transpose(float3x3(shader.model_view))
		proj_view_model = proj_view * shader.model_view

		vs := shader.vs
		for i in 0 ..< vert_count {
			vs(&shader, cv.to_float4(vertices[i]), &vert[i])
		}

		for t in triangles {

			v0, v1, v2 := vert[t.x], vert[t.y], vert[t.z]
			n0, n1, n2 := lg.normalize(vertices[t.x]), lg.normalize(vertices[t.y]), lg.normalize(vertices[t.z])
			// varying_uv.set_col(nthvert, model.uv(iface, nthvert));
			// shader.varying_uv[0] = v0.xy
			// shader.varying_uv[1] = v1.xy
			// shader.varying_uv[2] = v2.xy

			shader.varying_uv[0] = vertices[t[0]].xy
			shader.varying_uv[1] = vertices[t[1]].xy
			shader.varying_uv[2] = vertices[t[2]].xy

			// #unroll for vi in 0..<3 {
			// 	shader.varying_uv[vi] = vertices[t[vi]].xy
			// }

			// varying_nrm.set_col(nthvert, proj<3>((ModelView).invert_transpose()*embed<4>(model.normal(iface, nthvert), 0.)));

			// shader.varying_nrm[0] = (shader.it_model_view * cv.to_float4(n0, 0)).xyz
			// shader.varying_nrm[1] = (shader.it_model_view * cv.to_float4(n1, 0)).xyz
			// shader.varying_nrm[2] = (shader.it_model_view * cv.to_float4(n2, 0)).xyz

			// shader.varying_nrm[0] = (shader.it_model_view3 * n0)
			// shader.varying_nrm[1] = (shader.it_model_view3 * n1)
			// shader.varying_nrm[2] = (shader.it_model_view3 * n2)

			shader.varying_nrm[0] = (it_model_view3 * n0)
			shader.varying_nrm[1] = (it_model_view3 * n1)
			shader.varying_nrm[2] = (it_model_view3 * n2)


			// gl_Position= ModelView*embed<4>(model.vert(iface, nthvert));
			// view_tri.set_col(nthvert, proj<3>(gl_Position));
			shader.view_tri[0] = (shader.model_view * v0).xyz
			shader.view_tri[1] = (shader.model_view * v1).xyz
			shader.view_tri[2] = (shader.model_view * v2).xyz

			// uniform_l = proj<3>((ModelView*embed<4>(light_dir, 0.))).normalized(); // transform the light vector to view coordinates
			shader.uniform_l = lg.normalize((shader.model_view * cv.to_float4(light_dir, 0)).xyz)

			cv.draw_triangle(pc, zbuffer[:], &viewport, {v0, v1, v2}, &shader)
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
	//fmt.println("z min/max:", cv.minz, cv.maxz)
}
