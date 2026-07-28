package main

import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:glfw"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 6

WINDOW_WIDTH :: 1920 / 2
WINDOW_HEIGHT :: WINDOW_WIDTH * 9 / 16
ASPECT :: WINDOW_WIDTH / WINDOW_HEIGHT
UI_SCALE :: 1.0 // todo compute this dynamically based on window and display dimensions

SDL_Window_Context :: struct {
    //window :     ^SDL.Window,
    //gl_context : SDL.GLContext,
	window :     glfw.WindowHandle
}

init_sdl_opengl_context :: proc() -> (SDL_Window_Context, bool) {

	glfw.WindowHint(glfw.RESIZABLE, 1)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    window_context : SDL_Window_Context
    //SDL.Init({.VIDEO})
	if (!glfw.Init()) {
		fmt.eprintln("Failed to initialize GLFW")
		return window_context, false
	}

    // window := SDL.CreateWindow(
    //     "Odin SDL2 Demo",
    //     SDL.WINDOWPOS_UNDEFINED,
    //     SDL.WINDOWPOS_UNDEFINED,
    //     WINDOW_WIDTH,
    //     WINDOW_HEIGHT,
    //     {.OPENGL},
    // )
	window := glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Odin GLFW Demo", nil, nil)

    if window == nil {
        fmt.eprintln("Failed to create window")
        return window_context, false
    }

    // SDL.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(SDL.GLprofile.CORE))
    // SDL.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
    // SDL.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

    //gl_context := SDL.GL_CreateContext(window)
	glfw.MakeContextCurrent(window)
    //gl_context := glfw.GetCurrentContext()

    // vsync
    //SDL.GL_SetSwapInterval(1)
	glfw.SwapInterval(1)

	glfw.SetKeyCallback(window, key_callback)
	glfw.SetFramebufferSizeCallback(window, size_callback)

    //gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, SDL.gl_set_proc_address)
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
    window_context.window = window
    // window_context.gl_context = gl_context
    return window_context, true
}

sdl_opengl_cleanup :: proc(window_context : SDL_Window_Context) {
    // SDL.Quit()
    // SDL.DestroyWindow(window_context.window)
    // SDL.GL_DeleteContext(window_context.gl_context)
	glfw.DestroyWindow(window_context.window)
	glfw.Terminate()
}
