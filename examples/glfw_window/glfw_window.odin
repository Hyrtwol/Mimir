// https://github.com/bg-thompson/OpenGL-Tutorials-In-Odin/blob/main/Rotating-Cube/rotating-cube.odin
// https://github.com/damdoy/opengl_examples/blob/master/texture_plane/main.cpp
//
package glfw_window

import "base:intrinsics"
import "core:fmt"
import "core:image"
import "core:image/png"
import glm "core:math/linalg/glsl"
import "core:os"
import "core:reflect"
import "core:time"
import "shared:obug"
import gl "vendor:OpenGL"
import "vendor:glfw"

// cow, cube, gazebo, crisscross
// import model "../../data/models/cube"
import model "../../data/models/gazebo"
SCALE :: 0.2
//import model "../../data/models/platonic/icosahedron"
//SCALE :: 1.0

_ :: png

vertex_flags :: 0b00000010

// odinfmt: disable
image_file_bytes:= [?][]u8 {
	#load("../../data/images/uv_checker_x.png"),
	#load("../../data/images/uv_checker_y.png"),
}
image_count :: len(image_file_bytes)

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
Texture :: u32
running: b32 = true
aspect: f32 = 1

texture_def :: struct {
	size: [2]i32,
	data: []u8,
}

vertex :: model.vertex

run :: proc() -> (exit_code: int) {
	when #defined(model.material) {
		fmt.println("size_of(model.material)=", size_of(model.material))
	}

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
			texture_data[ti].size = {i32(img.width), i32(img.height)}

			// Copy bytes from icon buffer into slice.
			data := make([]u8, len(img.pixels.buf))
			for b, i in img.pixels.buf {
				data[i] = b
			}
			texture_data[ti].data = data

			fmt.println("Image:", texture_data[ti].size)
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
	gl.BufferData(gl.ARRAY_BUFFER, len(model.vertices) * size_of(model.vertices[0]), raw_data(model.vertices), gl.STATIC_DRAW)

	fmt.printfln("vertex_flags: 0b%8b", vertex_flags)

	stride := i32(size_of(model.vertex))

	fields := reflect.struct_fields_zipped(model.vertex)
	for field, i in fields {
		//fmt.printfln("%d :: %v", i, field)
		fmt.printfln("%d :: %v %v tag=%v %v %v", i, field.name, field.type, field.tag, field.offset, field.is_using)

		index := u32(i)
		size: i32 = 0
		type: u32 = 0

		if reflect.is_array(field.type) {
			y := field.type.variant.(reflect.Type_Info_Array)
			fmt.printfln("%d :: type=%d type.size=%d %d %d elem=%v", index, field.type, field.type.size, y.count, y.elem_size, y.elem)
			size = i32(y.count)

			#partial switch info in y.elem.variant {
			case reflect.Type_Info_Integer:
				if info.signed {
					type = gl.INT
				} else {
					type = gl.UNSIGNED_INT
				}
			case reflect.Type_Info_Float:
				type = gl.FLOAT
			}
		}

		offset: uintptr = field.offset
		fmt.printfln("index=%d size=%d type=0x%x offset=%d", index, size, type, offset)
		assert(size > 0)
		assert(type > 0)
		gl.EnableVertexAttribArray(index)
		gl.VertexAttribPointer(index, size, type, false, stride, offset)
	}

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(model.indices) * size_of(model.indices[0]), raw_data(model.indices), gl.STATIC_DRAW)


	textures: [image_count]Texture
	gl.GenTextures(len(textures), &textures[0])
	defer gl.DeleteTextures(len(textures), &textures[0])

	for ti in 0 ..< image_count {
		//gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, textures[ti])
		// Describe texture.
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
	//gl.DepthFunc(gl.GREATER)

	// high precision timer
	start_tick := time.tick_now()

	ui_transform := &uniforms["u_transform"]
	u_transform: [2]glm.mat4

	for !glfw.WindowShouldClose(window_handle) && running {
		duration := time.tick_since(start_tick)
		t := f32(time.duration_seconds(duration))

		// Process all incoming events like keyboard press, window resize, and etc.
		glfw.PollEvents()

		//gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		pos := glm.vec3{glm.cos(t * 2), glm.sin(t * 2), 0}
		pos *= 1.3

		model_transform := glm.identity(glm.mat4)
		model_transform *= glm.mat4Translate(pos)
		model_transform *= glm.mat4Scale({SCALE, SCALE, SCALE})

		view := glm.mat4LookAt({0, -1, 4}, {0, 0, 0}, {0, 0, 1})
		proj := glm.mat4Perspective(45, aspect, 0.1, 100.0)
		proj_view := proj * view

		u_transform[0] = proj_view * model_transform * glm.mat4Rotate({0, 1, 1}, t)
		u_transform[1] = proj_view * glm.mat4Rotate({1, 1, 1}, t * 1.47) * model_transform

		for ti in 0 ..< len(textures) {
			//gl.ActiveTexture(gl.TEXTURE0)
			gl.BindTexture(gl.TEXTURE_2D, textures[ti])
			gl.UniformMatrix4fv(ui_transform.location, 1, false, &u_transform[ti][0, 0])
			gl.DrawElements(gl.TRIANGLES, i32(len(model.indices) * size_of(model.indices[0])), gl.UNSIGNED_SHORT, nil)
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
