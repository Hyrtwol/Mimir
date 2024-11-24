#+build windows
#+vet
package owin

import win32 "core:sys/windows"
import "core:time"

IDT_TIMER1: win32.UINT_PTR : 10001
IDT_TIMER2: win32.UINT_PTR : 10002
IDT_TIMER3: win32.UINT_PTR : 10003
IDT_TIMER4: win32.UINT_PTR : 10004

IDI_ICON1 :: 101

default_window_position: int2 : {win32.CW_USEDEFAULT, win32.CW_USEDEFAULT}
default_dwStyle :: win32.WS_OVERLAPPED | win32.WS_CAPTION | win32.WS_SYSMENU
default_dwExStyle :: win32.WS_EX_OVERLAPPEDWINDOW
default_sleep :: time.Millisecond * 10

HPEN_NULL :: win32.HPEN(uintptr(win32.PS_NULL))
HBRUSH_NULL :: win32.HBRUSH(uintptr(win32.BS_NULL))

LANGID_NEUTRAL_DEFAULT :: DWORD(win32.SUBLANG_DEFAULT) << 10 | DWORD(win32.LANG_NEUTRAL) & 0x3FF
