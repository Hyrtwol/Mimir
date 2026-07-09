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
