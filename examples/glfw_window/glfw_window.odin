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
import "core:time"
import "shared:obug"
import gl "vendor:OpenGL"
import "vendor:glfw"

// cow, cube, gazebo, crisscross
import model "../../data/models/cube"
SCALE :: 0.2
// import model "../../data/models/platonic/icosahedron"
// SCALE :: 1.0

_ :: png

// odinfmt: disable
image_file_bytes: [2][]u8 = {
	#load("../../data/images/uv_checker_x.png"),
	#load("../../data/images/uv_checker_y.png"),
}

vertex_sources: []string = {
	string(#load("shaders/pos.vs")),
	string(#load("shaders/pos_tex.vs")),
	string(#load("shaders/pos_nml.vs")),
	string(#load("shaders/pos_tex_nml.vs")),
}

fragment_sources: []string = {
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

	vertex_source := vertex_sources[model.vertex_flags]
	fragment_source := fragment_sources[1]
	// useful utility procedures that are part of vendor:OpenGl
	program := gl.load_shaders_source(vertex_source, fragment_source) or_else panic("Failed to create GLSL program")
	defer gl.DeleteProgram(program)

	gl.UseProgram(program)

	uniforms := gl.get_uniforms_from_program(program)
	defer gl.destroy_uniforms(uniforms)

	image_w, image_h: i32
	texture_data: [2][]u8
	{
		img: ^image.Image
		err: image.Error
		options := image.Options{.alpha_add_if_missing}

		img, err = png.load_from_bytes(image_file_bytes[0], options)
		if err != nil {
			fmt.println("ERROR: Image:", "failed to load.")
			return
		}
		defer png.destroy(img)
		image_w = i32(img.width)
		image_h = i32(img.height)

		// Copy bytes from icon buffer into slice.
		data := make([]u8, len(img.pixels.buf))
		for b, i in img.pixels.buf {
			data[i] = b
		}
		texture_data[0] = data

		fmt.println("Image:", image_w, image_h)
	}
	{
		img: ^image.Image
		err: image.Error
		options := image.Options{.alpha_add_if_missing}

		img, err = png.load_from_bytes(image_file_bytes[1], options)
		if err != nil {
			fmt.println("ERROR: Image:", "failed to load.")
			return
		}
		defer png.destroy(img)
		image_w = i32(img.width)
		image_h = i32(img.height)

		// Copy bytes from icon buffer into slice.
		data := make([]u8, len(img.pixels.buf))
		for b, i in img.pixels.buf {
			data[i] = b
		}
		texture_data[1] = data

		fmt.println("Image:", image_w, image_h)
	}

	for td in texture_data {assert(td != nil)}
	defer for td in texture_data {delete(td)}

	vao: u32
	gl.GenVertexArrays(1, &vao);defer gl.DeleteVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	// initialization of OpenGL buffers
	vbo, ebo: u32
	gl.GenBuffers(1, &vbo);defer gl.DeleteBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo);defer gl.DeleteBuffers(1, &ebo)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(model.vertices) * size_of(model.vertices[0]), raw_data(model.vertices), gl.STATIC_DRAW)

	fmt.printfln("vertex_flags: 0b%8b", model.vertex_flags)

	size_of_vertex := i32(size_of(model.vertex))
	when model.vertex_flags == 0b01 {
		gl.EnableVertexAttribArray(0)
		gl.EnableVertexAttribArray(1)
		gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of_vertex, offset_of(model.vertex, pos))
		gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of_vertex, offset_of(model.vertex, texcoord))
		// gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of_vertex, offset_of_by_string(model.vertex, "pos"))
		// gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of_vertex, offset_of_by_string(model.vertex, "texcoord"))
	} else when model.vertex_flags == 0b10 {
		gl.EnableVertexAttribArray(0)
		gl.EnableVertexAttribArray(1)
		gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of_vertex, offset_of(model.vertex, pos))
		gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of_vertex, offset_of(model.vertex, normal))
	} else when model.vertex_flags == 0b11 {
		gl.EnableVertexAttribArray(0)
		gl.EnableVertexAttribArray(1)
		gl.EnableVertexAttribArray(2)
		gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of_vertex, offset_of(model.vertex, pos))
		gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of_vertex, offset_of(model.vertex, texcoord))
		gl.VertexAttribPointer(2, 3, gl.FLOAT, false, size_of_vertex, offset_of(model.vertex, normal))
	} else {
		gl.EnableVertexAttribArray(0)
		gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of_vertex, offset_of(model.vertex, pos))
	}

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(model.indices) * size_of(model.indices[0]), raw_data(model.indices), gl.STATIC_DRAW)


	textures: [2]Texture
	gl.GenTextures(len(textures), &textures[0])
	defer gl.DeleteTextures(len(textures), &textures[0])

	for ti in 0 ..< len(textures) {
		//gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, textures[ti])
		// Describe texture.
		gl.TexImage2D(
			gl.TEXTURE_2D, // texture type
			0, // level of detail number (default = 0)
			gl.RGBA, // texture format
			image_w, // width
			image_h, // height
			0, // border, must be 0
			gl.RGBA, // pixel data format
			gl.UNSIGNED_BYTE, // data type of pixel data
			&texture_data[ti][0], // image data
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
