package user32ex

import "core:fmt"
import "core:intrinsics"
import "core:math/linalg"
import "core:runtime"
import "core:strings"
import win32 "core:sys/windows"

show_error_and_panic :: proc (msg: string) {
    errormsg := win32.utf8_to_wstring(fmt.tprintf("%s\nLast error: %x\n", msg, win32.GetLastError()))
    win32.MessageBoxW(nil, errormsg, L("Panic"), win32.MB_ICONSTOP | win32.MB_OK)
    panic(msg)
}

adjust_window_size :: proc (size: [2]i32, dwStyle, dwExStyle: u32) -> [2]i32 {
    rect := win32.RECT{0, 0, size.x, size.y}
    if win32.AdjustWindowRectEx(&rect, dwStyle, false, dwExStyle) {
        return {rect.right - rect.left, rect.bottom - rect.top}
    }
    return size
}

get_window_position :: proc (size: [2]i32, center: bool) -> [2]i32 {
    if center {
        if deviceMode:win32.DEVMODEW; win32.EnumDisplaySettingsW(nil, win32.ENUM_CURRENT_SETTINGS, &deviceMode) == win32.TRUE {
            dmsize := [2]i32{i32(deviceMode.dmPelsWidth), i32(deviceMode.dmPelsHeight)} // is there an easier way to describe this?
            return (dmsize - size) / 2
        }
    }
    return [2]i32{i32(win32.CW_USEDEFAULT), i32(win32.CW_USEDEFAULT)}
}
