package newton_glfw

import "core:fmt"
import "vendor:glfw"
// import "core:c"
// import "core:math/linalg"
// import gl "vendor:OpenGL"
// import newton "shared:newton_dynamics"

@(private = "file")
GetFirstMonitor :: proc() -> (monitor_handle: glfw.MonitorHandle) {
	monitors := glfw.GetMonitors()
	if len(monitors) > 0 {
		monitor_handle = monitors[0]
	}
	return
}

@(private = "file")
GetMonitorPosAndSize :: proc(monitor_handle: glfw.MonitorHandle) -> (monitor_pos, monitor_size: [2]i32) {
	monitor_pos.x, monitor_pos.y = glfw.GetMonitorPos(monitor_handle)
	videoMode := glfw.GetVideoMode(monitor_handle)
	monitor_size = {videoMode.width, videoMode.height}
	return
}

@(private = "file")
GetWindowPosAndSize :: proc(monitor_handle: glfw.MonitorHandle) -> (window_pos, window_size: [2]i32) {
	monitor_pos, monitor_size := GetMonitorPosAndSize(monitor_handle)
	window_size = monitor_size * 8 / 10
	window_pos = monitor_pos + (monitor_size - window_size) / 2
	return
}

CreateWindowCentered :: proc() -> (window_handle: glfw.WindowHandle) {


	glfw.WindowHint(glfw.VISIBLE, glfw.FALSE)

	window_pos, window_size := GetWindowPosAndSize(GetFirstMonitor())
	window_handle = glfw.CreateWindow(window_size.x, window_size.y, "Mimir", nil, nil)
	if window_handle == nil {
		fmt.eprintln("Failed to create GLFW window")
		return
	}

	glfw.DefaultWindowHints()
	glfw.SetWindowPos(window_handle, window_pos.x, window_pos.y)
	glfw.ShowWindow(window_handle)
	return
}
