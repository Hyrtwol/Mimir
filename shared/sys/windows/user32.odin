// +build windows
package sys_windows_ex

// https://learn.microsoft.com/en-us/windows/win32/api/winuser/
// https://github.com/tpn/winsdk-7/blob/master/v7.1A/Include/WinUser.h
foreign import user32 "system:User32.lib"

@(default_calling_convention="system")
foreign user32 {
	// https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-drawtext
	DrawTextW :: proc(hdc: HDC, lpchText: LPCWSTR, cchText: INT, lprc: LPRECT, format: DrawTextFormat) -> INT ---
	// https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-redrawwindow
	RedrawWindow :: proc(hwnd: HWND, lprcUpdate: LPRECT, hrgnUpdate: HRGN, flags: RedrawWindowFlags) -> BOOL ---
}

DrawTextFormat :: enum u32 {
	DT_TOP                  = 0x00000000,
	DT_LEFT                 = 0x00000000,
	DT_CENTER               = 0x00000001,
	DT_RIGHT                = 0x00000002,
	DT_VCENTER              = 0x00000004,
	DT_BOTTOM               = 0x00000008,
	DT_WORDBREAK            = 0x00000010,
	DT_SINGLELINE           = 0x00000020,
	DT_EXPANDTABS           = 0x00000040,
	DT_TABSTOP              = 0x00000080,
	DT_NOCLIP               = 0x00000100,
	DT_EXTERNALLEADING      = 0x00000200,
	DT_CALCRECT             = 0x00000400,
	DT_NOPREFIX             = 0x00000800,
	DT_INTERNAL             = 0x00001000,
	DT_EDITCONTROL          = 0x00002000,
	DT_PATH_ELLIPSIS        = 0x00004000,
	DT_END_ELLIPSIS         = 0x00008000,
	DT_MODIFYSTRING         = 0x00010000,
	DT_RTLREADING           = 0x00020000,
	DT_WORD_ELLIPSIS        = 0x00040000,
	DT_NOFULLWIDTHCHARBREAK = 0x00080000,
	DT_HIDEPREFIX           = 0x00100000,
	DT_PREFIXONLY           = 0x00200000,
}

RedrawWindowFlags :: enum UINT {
	RDW_INVALIDATE      = 0x0001,
	RDW_INTERNALPAINT   = 0x0002,
	RDW_ERASE           = 0x0004,
	RDW_VALIDATE        = 0x0008,
	RDW_NOINTERNALPAINT = 0x0010,
	RDW_NOERASE         = 0x0020,
	RDW_NOCHILDREN      = 0x0040,
	RDW_ALLCHILDREN     = 0x0080,
	RDW_UPDATENOW       = 0x0100,
	RDW_ERASENOW        = 0x0200,
	RDW_FRAME           = 0x0400,
	RDW_NOFRAME         = 0x0800,
}
