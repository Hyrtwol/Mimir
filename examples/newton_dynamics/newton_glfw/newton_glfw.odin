package newton_glfw

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import glm "core:math/linalg/glsl"
import "core:os"
import "core:time"
import newton "shared:newton_dynamics"
import "shared:obug"
import gl "vendor:OpenGL"
import "vendor:glfw"

float3 :: glm.vec3
float4x4 :: glm.mat4
quaternion :: glm.quat
Mesh :: newton.Mesh

g :: 9.8
TRIANGULATE_WITH_NEWTON :: false

// odinfmt: disable
vertex_sources:= [?]string {
	string(#load("shaders/pos.vs")),
	string(#load("shaders/pos_tex.vs")),
	string(#load("shaders/pos_nml.vs")),
	string(#load("shaders/pos_tex_nml.vs")),
}

fragment_sources:= [?]string {
	string(#load("shaders/col.fs")),
	string(#load("shaders/tex.fs")),
	string(#load("shaders/lit.fs")),
}
// odinfmt: enable


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

aspect: f32 = 1
camera_up: float3 = linalg.normalize(float3{0, 1, 0}) // camera up vector

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

vertex_flags :: 0b00000010

Index :: u16
Vertex :: struct {
	pos: newton.float3 `POSITION`,
	nml: newton.float3 `NORMAL`,
}

World_User_Data :: u32

collisions: [dynamic]^newton.Collision
bodies: [dynamic]^newton.Body
meshes: [dynamic]^newton.Mesh
render_items: [dynamic]Render_Item

Render_Item :: struct {
	// Specifies a constant that should be added to each element of indices when choosing elements from the enabled vertex arrays.
	base_vertex:   i32,
	base_index:    i32,
	count:         i32,
	texture_index: i32,
	transform:     float4x4,
}

// Render_Item_Tex :: struct {
// 	render_item:   ^Render_Item,
// 	texture_index: i32,
// 	transform:     float4x4,
// }

set_transform_callback :: proc "c" (body: ^newton.Body, transform: ^float4x4, threadIndex: i32) {
	render_item := newton.body_get_user_data(body, ^Render_Item)
	if render_item != nil {
		render_item.transform = transform^
	}
}

origos := [?]float3{{6, 3, 0}, {-6, 3, 0}}

//lightPos : float3 = linalg.normalize(float3{1,1,1})
lightPos: float3 = float3{0, 10, 0}
ambient: float3 = float3{0.1, 0.1, 0.1}

FORCE_FACTOR :: 20

force_and_torque_callback :: proc "c" (body: ^newton.Body, timestep: f32, threadIndex: i32) {
	mass: f32
	inertia: float3
	newton.BodyGetMass(body, &mass, &inertia.x, &inertia.y, &inertia.z)
	// Newton.NewtonBodyGetMatrix(_body, out var matrix);
	position: float3
	newton.BodyGetPosition(body, &position)

	force: float3 = {0, 0, 0}
	for origo in origos {
		v := origo - position
		sqrMagnitude := linalg.dot(v, v) // aka vector_length2
		if sqrMagnitude > 0.1 {
			if sqrMagnitude > 1 {
				v *= FORCE_FACTOR * mass / (sqrMagnitude * math.sqrt(sqrMagnitude))
			} else {
				v *= FORCE_FACTOR * mass * math.sqrt(sqrMagnitude)
			}
			force += v
		}
	}

	force.y -= mass * g
	newton.BodySetForce(body, &force)
}

on_world_destroy :: proc "c" (world: ^newton.World) {
	context = runtime.default_context()
	fmt.println("on_world_destroy", world)
}

run :: proc() -> (exit_code: int) {
	fmt.println("Newton Dynamics")
	defer fmt.println("Done.", exit_code)

	texture_data := make([dynamic]texture_def, 0, 0)
	defer delete(texture_data)
	load_texture_data(&texture_data)
	for td in texture_data {fmt.println("Image:", td.size, len(td.data)); assert(td.data != nil)}
	defer {for td in texture_data {delete(td.data)}}

	write_globals()

	world := newton.Create()
	defer newton.Destroy(world)
	newton.world_set_user_data(world, World_User_Data(0xDEADBEEF))
	newton.WorldSetDestructorCallback(world, on_world_destroy)

	write_world(world)

	when #defined(material) {
		fmt.println("size_of(model.material)=", size_of(material))
	}

	// Create collisions

	collisions = make([dynamic]^newton.Collision)
	defer {{for &collision in collisions {newton.DestroyCollision(collision)}}; delete(collisions)}
	append(&collisions, newton.CreateBox(world, 400, 2, 400, i32(len(collisions)), nil))
	append(&collisions, newton.CreateSphere(world, 0.5, i32(len(collisions)), nil))
	append(&collisions, newton.CreateSphere(world, 1.0, i32(len(collisions)), nil))
	append(&collisions, newton.CreateBox(world, 1.0, 1.0, 1.0, i32(len(collisions)), nil))
	append(&collisions, newton.CreateBox(world, 1.0, 0.5, 2.0, i32(len(collisions)), nil))
	append(&collisions, newton.CreateCylinder(world, 0.5, 0.5, 1.5, i32(len(collisions)), nil))
	append(&collisions, newton.CreateCylinder(world, 0.3, 0.6, 1.5, i32(len(collisions)), nil))
	append(&collisions, newton.CreateCapsule(world, 0.5, 0.5, 1.5, i32(len(collisions)), nil))
	append(&collisions, newton.CreateCapsule(world, 0.4, 0.6, 1.2, i32(len(collisions)), nil))
	append(&collisions, newton.CreateCone(world, 0.5, 2.0, i32(len(collisions)), nil))
	append(&collisions, newton.CreateCone(world, 1.0, 1.0, i32(len(collisions)), nil))
	append(&collisions, newton.CreateChamferCylinder(world, 0.5, 0.6, i32(len(collisions)), nil))
	append(&collisions, newton.CreateChamferCylinder(world, 0.5, 1.0, i32(len(collisions)), nil))
	for &collision in collisions {write_collision(collision)}

	// Create meshes

	meshes = make([dynamic]^newton.Mesh)
	defer {{for &mesh in meshes {newton.MeshDestroy(mesh)}}; delete(meshes)}
	for i in 0 ..< len(collisions) {
		mesh := newton.MeshCreateFromCollision(collisions[i])
		if TRIANGULATE_WITH_NEWTON {newton.MeshTriangulate(mesh)}
		write_mesh(mesh)
		append(&meshes, mesh)
	}

	// Create vertices & indices

	total_vertex_count, total_point_count: i32 = 0, 0
	for &mesh in meshes {
		total_vertex_count += newton.MeshGetPointCount(mesh)
		total_point_count += newton.MeshGetTotalIndexCount(mesh)
	}
	fmt.println("total_vertex_count=", total_vertex_count, "total_point_count=", total_point_count)

	vertices := make([dynamic]Vertex, 0, total_vertex_count)
	defer delete(vertices)
	indices := make([dynamic]Index, 0, total_point_count)
	defer delete(indices)

	// Create reader items

	render_items = make([dynamic]Render_Item, 0)
	defer delete(render_items)

	{
		image_mask := i32(len(texture_data) - 1)
		for &mesh, idx in meshes {

			m_vertices := newton.get_vertices(mesh, Vertex, allocator = context.temp_allocator)
			m_indices := newton.get_indices(mesh, Index, allocator = context.temp_allocator)

			ri := Render_Item {
				base_vertex   = i32(len(vertices)),
				base_index    = i32(len(indices)),
				count         = i32(len(m_indices)),
				texture_index = ((i32(idx) % image_mask) + 1) if idx > 0 else 0,
			}

			append(&render_items, ri)

			append_elems(&vertices, ..m_vertices)
			append_elems(&indices, ..m_indices)
		}
	}

	for &ri, i in render_items {fmt.println(i, ri)}

	write_world_count(world)

	// Create bodies

	bodies = make([dynamic]^newton.Body, 0, 8)
	defer {{for &body in bodies {newton.DestroyBody(body)}}; delete(bodies)}

	{
		identity := linalg.identity(newton.float4x4)
		ofs := float3{f32(len(collisions)) * -0.5, 0, 0}
		for &collision, i in collisions {
			body := newton.CreateDynamicBody(world, collision, &identity)
			newton.body_set_user_data(body, &render_items[i])
			newton.BodySetTransformCallback(body, set_transform_callback)

			mtx: newton.float4x4
			if i == 0 {
				mtx = linalg.matrix4_translate(float3{0, -1, 0})
			} else {
				newton.BodySetForceAndTorqueCallback(body, force_and_torque_callback)
				mass: f32 = 10
				newton.BodySetMassProperties(body, mass, collision)
				mtx = linalg.matrix4_translate(float3{f32(i) * 1, 4 + f32(i), 0} + ofs) * linalg.matrix4_rotate(f32(i), camera_up)
			}
			newton.BodySetMatrix(body, &mtx)

			append(&bodies, body)
		}
	}
	for &body in bodies {write_body(body)}

	assert(len(collisions) == len(meshes))
	assert(len(collisions) == len(render_items))
	assert(len(collisions) == len(bodies))

	// Init glfw

	if !glfw.Init() {
		fmt.eprintln("Failed to initialize GLFW")
		return
	}
	defer glfw.Terminate()

	window_handle := CreateWindowCentered()
	if window_handle == nil {
		fmt.eprintln("GLFW has failed to load the window.")
		return
	}
	defer glfw.DestroyWindow(window_handle)

	// Load OpenGL context or the "state" of OpenGL.
	glfw.MakeContextCurrent(window_handle)

	glfw.SwapInterval(1)

	glfw.SetKeyCallback(window_handle, key_callback)
	glfw.SetFramebufferSizeCallback(window_handle, size_callback)

	// Load OpenGL function pointers with the specified OpenGL major and minor version.
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

	size_callback(window_handle, glfw.GetFramebufferSize(window_handle))

	vertex_source := vertex_sources[vertex_flags]
	fragment_source := fragment_sources[2]

	fmt.println("vertex_source:")
	fmt.println(vertex_source)
	fmt.println("fragment_source:")
	fmt.println(fragment_source)

	program := gl.load_shaders_source(vertex_source, fragment_source) or_else panic("Failed to create GLSL program")
	defer gl.DeleteProgram(program)

	gl.UseProgram(program)

	uniforms: gl.Uniforms = gl.get_uniforms_from_program(program)
	defer gl.destroy_uniforms(uniforms)
	fmt.println("uniforms", len(uniforms))
	for u in uniforms {
		fmt.println("uniform", u)
	}

	vao: u32
	gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	// initialization of OpenGL buffers
	vbo, ebo: u32
	gl.GenBuffers(1, &vbo); defer gl.DeleteBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo); defer gl.DeleteBuffers(1, &ebo)

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


	textures := make([]Texture, len(texture_data))
	defer delete(textures)
	gl.GenTextures(i32(len(textures)), &textures[0])
	defer gl.DeleteTextures(i32(len(textures)), &textures[0])

	for ti in 0 ..< len(textures) {
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
		gl.GenerateMipmap(gl.TEXTURE_2D)

		// Texture wrapping options.
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)

		// Texture filtering options.
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	}

	gl.ClearColor(0.10, 0.15, 0.20, 1.0)
	gl.Enable(gl.CULL_FACE)
	gl.Enable(gl.DEPTH_TEST)

	start_tick := time.tick_now()
	last_tick := start_tick
	delta: f32

	ui_transform: ^gl.Uniform_Info = &uniforms["u_transform"]
	assert(ui_transform != nil)
	u_proj_view: ^gl.Uniform_Info = &uniforms["u_proj_view"]
	assert(u_proj_view != nil)

	u_lightPos: ^gl.Uniform_Info = &uniforms["lightPos"]
	assert(u_lightPos != nil)
	gl.Uniform3fv(u_lightPos.location, 1, &lightPos[0])
	fmt.println("uniform", u_lightPos.name, lightPos)

	u_ambient: ^gl.Uniform_Info = &uniforms["ambient"]
	assert(u_ambient != nil)
	gl.Uniform3fv(u_ambient.location, 1, &ambient[0])
	fmt.println("uniform", u_ambient.name, ambient)

	for !glfw.WindowShouldClose(window_handle) {

		start_tick = time.tick_now()
		delta = f32(time.duration_seconds(time.tick_diff(last_tick, start_tick)))
		last_tick = start_tick

		// Process all incoming events like keyboard press, window resize, and etc.
		glfw.PollEvents()

		newton.Update(world, delta)
		//fmt.println("LastUpdateTime", newton.GetLastUpdateTime(world), delta)

		//gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		view := glm.mat4LookAt({0, 10, 20}, {0, 0, 0}, camera_up)
		proj := glm.mat4Perspective(45, aspect, 0.1, 100.0)
		proj_view := proj * view
		gl.UniformMatrix4fv(u_proj_view.location, 1, false, &proj_view[0, 0])

		ut: float4x4
		for &ri in render_items {
			//gl.ActiveTexture(gl.TEXTURE0)
			gl.BindTexture(gl.TEXTURE_2D, textures[ri.texture_index])
			//ut = proj_view * ri.transform
			//gl.UniformMatrix4fv(u_proj_view.location, 1, false, &proj_view[0, 0])
			gl.UniformMatrix4fv(ui_transform.location, 1, false, &ri.transform[0, 0])
			//gl.UniformMatrix4fv(ui_transform.location, 1, false, &ut[0, 0])
			//gl.DrawElements(gl.TRIANGLES, i32(len(indices) * size_of(indices[0])), gl.UNSIGNED_SHORT, nil)
			gl.DrawElementsBaseVertex(gl.TRIANGLES, ri.count, gl.UNSIGNED_SHORT, rawptr(uintptr(ri.base_index * 2)), ri.base_vertex)
		}

		glfw.SwapBuffers(window_handle)
	}

	return
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_ESCAPE {
		glfw.SetWindowShouldClose(window, true)
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
