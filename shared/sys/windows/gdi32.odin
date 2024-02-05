// +build windows
package sys_windows_ex

// https://learn.microsoft.com/en-us/windows/win32/api/wingdi/
/*
foreign import gdi32 "system:Gdi32.lib"

@(default_calling_convention="system")
foreign gdi32 {
	// https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-createcompatibledc
	CreateCompatibleDC :: proc(hdc: HDC) -> HDC ---

	// https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-deletedc
	DeleteDC :: proc(hdc: HDC) -> BOOL ---
}
*/
