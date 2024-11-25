package owin_gl

// import "core:fmt"
import win32 "core:sys/windows"
import gl "vendor:OpenGL"
import "vendor:glfw"

_ :: gl
_ :: glfw
wglCreateContext :: win32.wglCreateContext
