package newton_glfw

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:image"
import "core:image/png"
import "core:math"
import "core:math/linalg"
import glm "core:math/linalg/glsl"
import "core:os"
import "core:time"
import newton "shared:newton_dynamics"
import "shared:obug"
import gl "vendor:OpenGL"
import "vendor:glfw"

_ :: png
vec3 :: glm.vec3
mat4 :: glm.mat4
Mesh :: newton.Mesh

SCALE :: 0.2

// odinfmt: disable
image_file_bytes:= [?][]u8 {
	#load("../../../data/images/uv_checker_x.png"),
	#load("../../../data/images/uv_checker_y.png"),
	#load("../../../data/images/uv_checker_z.png"),
	#load("../../../data/images/uv_checker_w.png"),
}
image_count :: len(image_file_bytes)
image_mask :: image_count - 1

vertex_sources:= [?]string {
	string(#load("shaders/pos.vs")),
	string(#load("shaders/pos_tex.vs")),
	string(#load("shaders/pos_nml.vs")),
	string(#load("shaders/pos_tex_nml.vs")),
}

fragment_sources:= [?]string {
	string(#load("shaders/col.fs")),
	string(#load("shaders/tex.fs")),
}
// odinfmt: enable

WINDOW_TITLE :: "Mimir"
WINDOW_WIDTH :: 640
WINDOW_HEIGHT :: WINDOW_WIDTH * 3 / 4

// @note You might need to lower this to 3.3 depending on how old your graphics card is.
GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 6

// Create alias types for vertex array / buffer objects
VAO :: u32
VBO :: u32
ShaderProgram :: u32
Texture :: u32

// Global variables.
global_vao: VAO
global_shader: ShaderProgram

running: b32 = true
aspect: f32 = 1

material :: struct {
	name:             string,
	ambient:          [3]f32,
	diffuse:          [3]f32,
	emission:         [3]f32,
	specular:         [3]f32,
	specularExponent: f32,
	opacity:          f32,
}

materials: []material = {
	{
		name = "crisscross",
		ambient = {0.00000, 0.00000, 0.00000},
		diffuse = {0.78431, 0.78431, 0.78431},
		emission = {0.00000, 0.00000, 0.00000},
		specular = {0.00000, 0.00000, 0.00000},
		specularExponent = 400.00000,
		opacity = 1.00000,
	},
}

texture_def :: struct {
	size: [2]i32,
	data: []u8,
}

vertex_flags :: 0b00000010

Vertex :: struct {
	pos: newton.float3 `POSITION`,
	nml: newton.float3 `NORMAL`,
}

Index :: u16

vertices: []Vertex
collisions: []^newton.Collision
bodies: [dynamic]^newton.Body
meshes: []^newton.Mesh
shapeId: i32 = 0

Render_Item :: struct {
	// Specifies a constant that should be added to each element of indices when choosing elements from the enabled vertex arrays.
	base_vertex: i32,
	base_index:  i32,
	count:      i32,
}
render_items: []Render_Item

on_world_destroy :: proc "c" (world: ^newton.World) {
	context = runtime.default_context()
	fmt.println("on_world_destroy", world)
}

run :: proc() -> (exit_code: int) {
	fmt.println("Newton Dynamics")
	defer fmt.println("Done.")

	write_globals()

	world := newton.Create()
	defer newton.Destroy(world)
	user_data: u32 = 0xDEADBEEF
	newton.WorldSetUserData(world, rawptr(uintptr(user_data)))
	newton.WorldSetDestructorCallback(world, on_world_destroy)

	write_world(world)

	when #defined(material) {
		fmt.println("size_of(model.material)=", size_of(material))
	}

	// Create collisions
	collisions = make([]^newton.Collision, 10)
	{
		collisions[shapeId] = newton.CreateBox(world, 400, 2, 400, shapeId, nil);shapeId += 1
		collisions[shapeId] = newton.CreateSphere(world, 0.5, shapeId, nil);shapeId += 1
		collisions[shapeId] = newton.CreateBox(world, 1.0, 1.0, 1.0, shapeId, nil);shapeId += 1
		collisions[shapeId] = newton.CreateBox(world, 1.0, 0.5, 2.0, shapeId, nil);shapeId += 1
		collisions[shapeId] = newton.CreateCylinder(world, 0.5, 0.5, 1.5, shapeId, nil);shapeId += 1
		collisions[shapeId] = newton.CreateCylinder(world, 0.3, 0.6, 1.5, shapeId, nil);shapeId += 1
		collisions[shapeId] = newton.CreateCapsule(world, 0.5, 0.5, 1.5, shapeId, nil);shapeId += 1
		collisions[shapeId] = newton.CreateCapsule(world, 0.4, 0.6, 1.2, shapeId, nil);shapeId += 1
		collisions[shapeId] = newton.CreateCone(world, 0.5, 2.0, shapeId, nil);shapeId += 1
		collisions[shapeId] = newton.CreateChamferCylinder(world, 0.5, 0.6, shapeId, nil);shapeId += 1
	}
	defer {{for &collision in collisions {newton.DestroyCollision(collision)}};delete(collisions)}

	for &collision in collisions {write_collision(collision)}

	// Create meshes
	//mesh_count := len(collisions)
	meshes = make([]^newton.Mesh, len(collisions))
	defer {{for &mesh in meshes {newton.MeshDestroy(mesh)}};delete(meshes)}
	for i in 0 ..< len(meshes) {
		mesh := newton.MeshCreateFromCollision(collisions[i])
		// newton.MeshTriangulate(mesh)
		write_mesh(mesh)
		meshes[i] = mesh
	}

	render_items := make([]Render_Item, len(meshes))
	defer delete(render_items)

	total_vertex_count, total_point_count: i32 = 0, 0
	for &mesh, idx in meshes {
		total_vertex_count += newton.MeshGetPointCount(mesh)
		total_point_count += newton.MeshGetTotalIndexCount(mesh)
	}
	fmt.println("total_vertex_count=", total_vertex_count, "total_point_count=", total_point_count)

	vertices := make([]Vertex, total_vertex_count)
	defer delete(vertices)
	//indices := make([]u16, total_point_count)
	//indices := make([dynamic]u16, total_point_count, total_point_count)
	indices := make([dynamic]u16, 0, total_point_count)
	defer delete(indices)

	/*
	m := meshes[3]
	vertices = newton.get_vertices(m, Vertex)
	defer delete(vertices)
	indices := newton.get_indices(m, u16)
	defer delete(indices)
	*/
	{
		vertex_size := i32(size_of(Vertex))
		//ofs: i32 = 0
		vi, ii: i32 = 0, 0
		for &mesh, idx in meshes {
			// point_count := MeshGetPointCount(mesh)
			// index_count := newton.MeshGetTotalIndexCount(mesh)
			// MeshGetVertexChannel(mesh, vertex_size, &vertices[ofs].pos)
			// MeshGetNormalChannel(mesh, vertex_size, &vertices[ofs].nml)

			m_vertices := newton.get_vertices(mesh, Vertex)
			defer delete(m_vertices)
			m_indices := newton.get_indices(mesh, u16)
			defer delete(m_indices)

			ri := Render_Item {
				base_vertex = vi,
				base_index  = ii,
				count      = i32(len(m_indices)),
			}
			for v in m_vertices {
				vertices[vi] = v;vi += 1
			}
			for i in m_indices {
				//indices[ii] = i;ii += 1
				append(&indices, i);ii += 1
			}
			//ofs += ri.count
			//ofs += i32(len(m_vertices))
			render_items[idx] = ri
		}
	}
	//assert(len(indices) == int(total_point_count))
	for &ri, i in render_items {fmt.println(i, ri)}

	write_world_count(world)

	// Create bodies

	bodies = make([dynamic]^newton.Body, 0, 8)
	defer {{for &body in bodies {newton.DestroyBody(body)}};delete(bodies)}

	identity := linalg.identity(newton.float4x4)
	for &collision, i in collisions {
		body := newton.CreateDynamicBody(world, collision, &identity)
		mtx := linalg.matrix4_translate(newton.float3{f32(i), 0, 0}) * linalg.matrix4_rotate(f32(i), newton.float3{0, 1, 0})
		newton.BodySetMatrix(body, &mtx)
		append(&bodies, body)
	}

	for &body, i in bodies {write_body(body)}

	// Init glfw

	if !bool(glfw.Init()) {
		fmt.eprintln("Failed to initialize GLFW")
		return
	}
	defer glfw.Terminate()

	window_handle := glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE, nil, nil)
	defer glfw.DestroyWindow(window_handle)

	if window_handle == nil {
		fmt.eprintln("GLFW has failed to load the window.")
		return
	}

	// Load OpenGL context or the "state" of OpenGL.
	glfw.MakeContextCurrent(window_handle)

	glfw.SwapInterval(1)

	glfw.SetKeyCallback(window_handle, key_callback)
	glfw.SetFramebufferSizeCallback(window_handle, size_callback)

	// Load OpenGL function pointers with the specified OpenGL major and minor version.
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

	size_callback(window_handle, glfw.GetFramebufferSize(window_handle))

	vertex_source := vertex_sources[vertex_flags]
	fragment_source := fragment_sources[1]

	program := gl.load_shaders_source(vertex_source, fragment_source) or_else panic("Failed to create GLSL program")
	defer gl.DeleteProgram(program)

	gl.UseProgram(program)

	uniforms := gl.get_uniforms_from_program(program)
	defer gl.destroy_uniforms(uniforms)

	texture_data: [image_count]texture_def
	{
		options := image.Options{.alpha_add_if_missing}
		for ti in 0 ..< image_count {
			img: ^image.Image
			err: image.Error

			img, err = png.load_from_bytes(image_file_bytes[ti], options)
			if err != nil {
				fmt.println("ERROR: Image:", "failed to load.")
				return
			}
			defer png.destroy(img)
			tex_def: texture_def
			tex_def.size = {i32(img.width), i32(img.height)}

			// Copy bytes from icon buffer into slice.
			data := make([]u8, len(img.pixels.buf))
			for b, i in img.pixels.buf {
				data[i] = b
			}
			tex_def.data = data

			fmt.println("Image:", tex_def.size)

			texture_data[ti] = tex_def
		}
	}
	for td in texture_data {assert(td.data != nil)}
	defer for td in texture_data {delete(td.data)}

	vao: u32
	gl.GenVertexArrays(1, &vao);defer gl.DeleteVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	// initialization of OpenGL buffers
	vbo, ebo: u32
	gl.GenBuffers(1, &vbo);defer gl.DeleteBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo);defer gl.DeleteBuffers(1, &ebo)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)

	fmt.printfln("vertex_flags: 0b%8b", vertex_flags)

	size_of_vertex := i32(size_of(Vertex))
	when vertex_flags == 0b01 {
		gl.EnableVertexAttribArray(0)
		gl.EnableVertexAttribArray(1)
		gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of_vertex, offset_of(Vertex, pos))
		gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of_vertex, offset_of(Vertex, texcoord))
	} else when vertex_flags == 0b10 {
		gl.EnableVertexAttribArray(0)
		gl.EnableVertexAttribArray(1)
		gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of_vertex, offset_of(Vertex, pos))
		gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of_vertex, offset_of(Vertex, nml))
	} else when vertex_flags == 0b11 {
		gl.EnableVertexAttribArray(0)
		gl.EnableVertexAttribArray(1)
		gl.EnableVertexAttribArray(2)
		gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of_vertex, offset_of(Vertex, pos))
		gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of_vertex, offset_of(Vertex, texcoord))
		gl.VertexAttribPointer(2, 3, gl.FLOAT, false, size_of_vertex, offset_of(Vertex, nml))
	} else {
		gl.EnableVertexAttribArray(0)
		gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of_vertex, offset_of(Vertex, pos))
	}

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(indices[0]), raw_data(indices), gl.STATIC_DRAW)


	textures := make([]Texture, image_count)
	defer delete(textures)
	gl.GenTextures(i32(len(textures)), &textures[0])
	defer gl.DeleteTextures(i32(len(textures)), &textures[0])

	for ti in 0 ..< image_count {
		//gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, textures[ti])
		gl.TexImage2D(
			gl.TEXTURE_2D, // texture type
			0, // level of detail number (default = 0)
			gl.RGBA, // texture format
			texture_data[ti].size.x, // width
			texture_data[ti].size.y, // height
			0, // border, must be 0
			gl.RGBA, // pixel data format
			gl.UNSIGNED_BYTE, // data type of pixel data
			&texture_data[ti].data[0], // image data
		)

		// Texture wrapping options.
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)

		// Texture filtering options.
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	}

	gl.ClearColor(0.10, 0.15, 0.20, 1.0)
	gl.Enable(gl.CULL_FACE)
	gl.Enable(gl.DEPTH_TEST)

	start_tick := time.tick_now()
	last_tick := start_tick

	t: f32

	ui_transform := &uniforms["u_transform"]
	u_transform: [8]glm.mat4

	for !glfw.WindowShouldClose(window_handle) && running {

		start_tick = time.tick_now()
		delta := f32(time.duration_seconds(time.tick_diff(last_tick, start_tick)))
		last_tick = start_tick

		t += delta
		//if t > math.PI * 2 {t -= math.PI * 4}

		// Process all incoming events like keyboard press, window resize, and etc.
		glfw.PollEvents()

		//gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		// SetLocalPositionAndRotation(target, ref _bodys[i].TransformMatrix);

		pos := glm.vec3{glm.cos(t * 2), glm.sin(t * 2), 0}
		pos *= 1.3

		model_transform := glm.identity(glm.mat4)
		model_transform *= glm.mat4Translate(pos)
		//model_transform *= glm.mat4Scale({SCALE, SCALE, SCALE})

		view := glm.mat4LookAt({0, -1, 4}, {0, 0, 0}, {0, 0, 1})
		proj := glm.mat4Perspective(45, aspect, 0.1, 100.0)
		proj_view := proj * view

		// u_transform[0] = proj_view * model_transform * glm.mat4Rotate({0, 1, 1}, t*1.0)
		// u_transform[1] = proj_view * model_transform * glm.mat4Rotate({1, 1, 1}, t*1.1)
		// u_transform[2] = proj_view * model_transform * glm.mat4Rotate({1, 1, 0}, t*1.2)
		// u_transform[3] = proj_view * model_transform * glm.mat4Rotate({1, 0, 1}, t*1.3)
		// u_transform[4] = proj_view * glm.mat4Rotate({0, 1, 1}, t*1.4) * model_transform
		// u_transform[5] = proj_view * glm.mat4Rotate({1, 1, 1}, t*1.5) * model_transform
		// u_transform[6] = proj_view * glm.mat4Rotate({1, 1, 0}, t*1.6) * model_transform
		// u_transform[7] = proj_view * glm.mat4Rotate({1, 0, 1}, t*1.7) * model_transform

		for i in 0 ..< len(u_transform) {
			u_transform[i] = proj_view * glm.mat4Rotate({f32(i), 1, 1}, t * (0.2 * f32(i))) * model_transform
		}

		for i in 0 ..< len(u_transform) {
			//gl.ActiveTexture(gl.TEXTURE0)
			gl.BindTexture(gl.TEXTURE_2D, textures[i & image_mask])
			gl.UniformMatrix4fv(ui_transform.location, 1, false, &u_transform[i & 7][0, 0])
			ri := &render_items[1 + i]
			//gl.DrawElements(gl.TRIANGLES, i32(len(indices) * size_of(indices[0])), gl.UNSIGNED_SHORT, nil)
			gl.DrawElementsBaseVertex(gl.TRIANGLES, ri.count, gl.UNSIGNED_SHORT, rawptr(uintptr(ri.base_index * 2)), ri.base_vertex)
		}

		glfw.SwapBuffers(window_handle)
	}
	return
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_ESCAPE {
		running = false
	}
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	// Set the OpenGL viewport size
	gl.Viewport(0, 0, width, height)
	aspect = f32(width) / f32(height)
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}
