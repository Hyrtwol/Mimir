package newton_glfw

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
//import "core:math"
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
Mesh :: newton.Mesh

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

vertex_flags :: 0b00000010

Index :: u16
Vertex :: struct {
	pos: newton.float3 `POSITION`,
	nml: newton.float3 `NORMAL`,
}

World_User_Data :: u32
Body_User_Data :: i32

shapeId: i32 = 0
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

Render_Item_Tex :: struct {
	render_item:   ^Render_Item,
	texture_index: i32,
	transform:     float4x4,
}

set_transform_callback :: proc "c" (body: ^newton.Body, matrix4x4: ^float4x4, threadIndex: i32) {
	ud := newton.body_get_user_data(body, Body_User_Data)
	if ud < i32(len(render_items)) {
		render_items[ud].transform = matrix4x4^
	}
}

force_and_torque_callback :: proc "c" (body: ^newton.Body, timestep: f32, threadIndex: i32) {
	mass: f32
	vector: float3 = {0, 0, 0}
	newton.BodyGetMass(body, &mass, &vector.x, &vector.y, &vector.z)
	force: float3 = {0, 0, 0}
	/*
	Newton.NewtonBodyGetMatrix(_body, out var matrix);
	Vector3 position = matrix.GetPosition();
	Vector3[] origo = Origo;
	for (int i = 0; i < origo.Length; i++)
	{
		Vector3 vector2 = origo[i] - position;
		float sqrMagnitude = vector2.sqrMagnitude;
		if (sqrMagnitude > 4f)
		{
			float num = (float)Math.Sqrt(sqrMagnitude);
			vector2 *= 1000f * mass / (sqrMagnitude * num);
		}
		else if (sqrMagnitude < 0.5f)
		{
			vector2 = Vector3.zero;
		}
		else
		{
			vector2 *= 1000f * mass / sqrMagnitude / 2f;
		}

		force += vector2;
	}
	*/

	force.y = (0 - mass) * 9.8
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
	for td in texture_data {fmt.println("Image:", td.size, len(td.data));assert(td.data != nil)}
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
	defer {{for &collision in collisions {newton.DestroyCollision(collision)}};delete(collisions)}
	{
		//append(&collisions, newton.CreateBox(world, 400, 2, 400, i32(len(collisions)), nil));shapeId += 1
		append(&collisions, newton.CreateBox(world, 400, 2, 400, shapeId, nil));shapeId += 1
		append(&collisions, newton.CreateSphere(world, 0.5, shapeId, nil));shapeId += 1
		append(&collisions, newton.CreateBox(world, 1.0, 1.0, 1.0, shapeId, nil));shapeId += 1
		append(&collisions, newton.CreateBox(world, 1.0, 0.5, 2.0, shapeId, nil));shapeId += 1
		append(&collisions, newton.CreateCylinder(world, 0.5, 0.5, 1.5, shapeId, nil));shapeId += 1
		append(&collisions, newton.CreateCylinder(world, 0.3, 0.6, 1.5, shapeId, nil));shapeId += 1
		append(&collisions, newton.CreateCapsule(world, 0.5, 0.5, 1.5, shapeId, nil));shapeId += 1
		append(&collisions, newton.CreateCapsule(world, 0.4, 0.6, 1.2, shapeId, nil));shapeId += 1
		append(&collisions, newton.CreateCone(world, 0.5, 2.0, shapeId, nil));shapeId += 1
		append(&collisions, newton.CreateChamferCylinder(world, 0.5, 0.6, shapeId, nil));shapeId += 1
	}
	for &collision in collisions {write_collision(collision)}

	// Create meshes

	meshes = make([dynamic]^newton.Mesh)
	defer {{for &mesh in meshes {newton.MeshDestroy(mesh)}};delete(meshes)}
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
	indices := make([dynamic]u16, 0, total_point_count)
	defer delete(indices)

	// Create reader items

	render_items = make([dynamic]Render_Item, 0)
	defer delete(render_items)

	{
		image_mask := i32(len(texture_data) - 1)
		for &mesh, idx in meshes {

			m_vertices := newton.get_vertices(mesh, Vertex, allocator = context.temp_allocator)
			m_indices := newton.get_indices(mesh, u16, allocator = context.temp_allocator)

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
	defer {{for &body in bodies {newton.DestroyBody(body)}};delete(bodies)}

	//u_transform = make([dynamic]float4x4, 0, 8);defer delete(u_transform)
	{
		mtx: newton.float4x4
		identity := linalg.identity(newton.float4x4)
		for &collision, i in collisions {
			body := newton.CreateDynamicBody(world, collision, &identity)

			newton.body_set_user_data(body, Body_User_Data(i))
			newton.BodySetTransformCallback(body, set_transform_callback)
			if i == 0 {
				mtx = linalg.matrix4_translate(newton.float3{0, -1, 0})
			} else {
				newton.BodySetForceAndTorqueCallback(body, force_and_torque_callback)
				mass: f32 = 50
				vector := float3{1, 1, 1}
				inertia := float3{(vector.y * vector.y + vector.z * vector.z), (vector.x * vector.x + vector.z * vector.z), (vector.x * vector.x + vector.y * vector.y)}
				inertia *= 4.16666651
				newton.BodySetMassMatrix(body, mass, inertia.x, inertia.y, inertia.z)
				// ixx: f32 = 4.16666651 * (vector.y * vector.y + vector.z * vector.z)
				// iyy: f32 = 4.16666651 * (vector.x * vector.x + vector.z * vector.z)
				// izz: f32 = 4.16666651 * (vector.x * vector.x + vector.y * vector.y)
				//newton.BodySetMassMatrix(body, 50, ixx, iyy, izz)

				mtx = linalg.matrix4_translate(float3{f32(i) * 0.5, 4, 0}) * linalg.matrix4_rotate(f32(i), float3{0, 1, 0})
			}

			newton.BodySetMatrix(body, &mtx)
			append(&bodies, body)
		}
	}
	for &body in bodies {write_body(body)}

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
	fragment_source := fragment_sources[1]

	program := gl.load_shaders_source(vertex_source, fragment_source) or_else panic("Failed to create GLSL program")
	defer gl.DeleteProgram(program)

	gl.UseProgram(program)

	uniforms: gl.Uniforms = gl.get_uniforms_from_program(program)
	defer gl.destroy_uniforms(uniforms)

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

	for !glfw.WindowShouldClose(window_handle) && running {

		start_tick = time.tick_now()
		delta = f32(time.duration_seconds(time.tick_diff(last_tick, start_tick)))
		last_tick = start_tick

		newton.Update(world, delta)
		//fmt.println("LastUpdateTime", newton.GetLastUpdateTime(world), delta)

		// Process all incoming events like keyboard press, window resize, and etc.
		glfw.PollEvents()

		//gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		view := glm.mat4LookAt({0, 10, 20}, {0, 0, 0}, {0, 1, 0})
		proj := glm.mat4Perspective(45, aspect, 0.1, 100.0)
		proj_view := proj * view

		ut: float4x4
		//for i in 0 ..< len(u_transform) {
		//	ri := &render_items[i]
		for &ri in render_items {
			//gl.ActiveTexture(gl.TEXTURE0)
			gl.BindTexture(gl.TEXTURE_2D, textures[ri.texture_index])
			//ut = proj_view * u_transform[i]
			ut = proj_view * ri.transform
			gl.UniformMatrix4fv(ui_transform.location, 1, false, &ut[0, 0])
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
