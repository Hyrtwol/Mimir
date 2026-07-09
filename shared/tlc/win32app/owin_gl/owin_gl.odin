// https://wikis.khronos.org/opengl/Creating_an_OpenGL_Context_(WGL)
package owin_gl

// import "core:fmt"
import win32 "core:sys/windows"
import gl "vendor:OpenGL"
import "vendor:glfw"

_ :: gl
_ :: glfw

PIXELFORMATDESCRIPTOR :: win32.PIXELFORMATDESCRIPTOR

wglCreateContext :: win32.wglCreateContext
// wglCreateContextAttribsARB :: win32.wglCreateContextAttribsARB
wglMakeCurrent :: win32.wglMakeCurrent
wglDeleteContext :: win32.wglDeleteContext
wglGetProcAddress :: win32.wglGetProcAddress

ChoosePixelFormat :: win32.ChoosePixelFormat
SetPixelFormat :: win32.SetPixelFormat
SwapBuffers :: win32.SwapBuffers

glGetString :: gl.GetString

gl_set_proc_address :: win32.gl_set_proc_address

load_up_to :: proc(major: int = 4, minor: int = 6) {
	gl.load_up_to(major, minor, gl_set_proc_address)
}

choose_and_set_pixel_format :: proc(hdc: win32.HDC) -> (pixelFormat: win32.INT, ok: win32.BOOL) {
	// odinfmt: disable
	pfd: win32.PIXELFORMATDESCRIPTOR = {
		nSize = size_of(win32.PIXELFORMATDESCRIPTOR),
		nVersion = 1,
		dwFlags = win32.PFD_DRAW_TO_WINDOW | win32.PFD_SUPPORT_OPENGL | win32.PFD_DOUBLEBUFFER,
		iPixelType = win32.PFD_TYPE_RGBA, // The kind of framebuffer. RGBA or palette.
		cColorBits = 32,                  // Colordepth of the framebuffer.
		cRedBits = 0, cRedShift = 0, cGreenBits = 0, cGreenShift = 0, cBlueBits = 0, cBlueShift = 0, cAlphaBits = 0, cAlphaShift = 0,
		cAccumBits = 0, cAccumRedBits = 0, cAccumGreenBits = 0, cAccumBlueBits = 0, cAccumAlphaBits = 0,
		cDepthBits = 24,                  // Number of bits for the depthbuffer
		cStencilBits = 8,                 // Number of bits for the stencilbuffer
		cAuxBuffers = 0,                  // Number of Aux buffers in the framebuffer.
		iLayerType = win32.PFD_MAIN_PLANE,
		bReserved = 0,
		dwLayerMask = 0, dwVisibleMask = 0, dwDamageMask = 0
	}
	// odinfmt: enable
	pixelFormat = win32.ChoosePixelFormat(hdc, &pfd)
	ok = pixelFormat > 0
	if ok {
		ok = win32.SetPixelFormat(hdc, pixelFormat, &pfd)
	}
	return
}
