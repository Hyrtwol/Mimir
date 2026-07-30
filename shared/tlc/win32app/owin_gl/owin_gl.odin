// https://wikis.khronos.org/opengl/Creating_an_OpenGL_Context_(WGL)
package owin_gl

import "core:fmt"
import win32 "core:sys/windows"
import gl "vendor:OpenGL"

int2 :: [2]i32

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
	fmt.println(#procedure, major, minor)
	gl.load_up_to(major, minor, gl_set_proc_address)
	init_wgl_extensions()
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

init_wgl_extensions :: proc() {

	assert(win32.wglCreateContextAttribsARB == nil)
	assert(win32.wglChoosePixelFormatARB == nil)
	assert(win32.wglSwapIntervalEXT == nil)
	assert(win32.wglGetExtensionsStringARB == nil)

	gl_set_proc_address(&win32.wglCreateContextAttribsARB, "wglCreateContextAttribsARB")
	gl_set_proc_address(&win32.wglChoosePixelFormatARB, "wglChoosePixelFormatARB")
	gl_set_proc_address(&win32.wglSwapIntervalEXT, "wglSwapIntervalEXT")
	gl_set_proc_address(&win32.wglGetExtensionsStringARB, "wglGetExtensionsStringARB")

	assert(win32.wglCreateContextAttribsARB != nil)
	assert(win32.wglChoosePixelFormatARB != nil)
	assert(win32.wglSwapIntervalEXT != nil)
	assert(win32.wglGetExtensionsStringARB != nil)
}

set_swap_interval :: proc(interval: i32) -> (ok: bool) {
	ok = win32.wglSwapIntervalEXT != nil
	if ok {
		ok = win32.wglSwapIntervalEXT(interval)
	}
	return
}

set_viewport_size :: proc(size: int2) {
	gl.Viewport(0, 0, expand_values(size))
}

set_viewport :: proc {
	gl.Viewport,
	set_viewport_size,
}

delete_context_and_clear :: proc(hglrc: ^win32.HGLRC) {
	// wglMakeCurrent(hdc, NULL); Unnecessary; wglDeleteContext will make the context not current
	ok := win32.wglDeleteContext(hglrc^)
	if ok {
		hglrc^ = nil
	}
}

delete_context :: proc {
	win32.wglDeleteContext,
	delete_context_and_clear,
}
