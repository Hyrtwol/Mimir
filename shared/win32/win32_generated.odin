// +build windows
package sys_windows

// Windows.Win32.UI.WindowsAndMessaging (Public, SequentialLayout, Sealed, BeforeFieldInit) TypeReference ValueType
WNDCLASSEXW :: struct {
	cbSize: u32, // OdinWin32.PrimitiveTypeHandleInfo Public
	style: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public
	lpfnWndProc: WNDPROC, // OdinWin32.HandleTypeHandleInfo Public
	cbClsExtra: i32, // OdinWin32.PrimitiveTypeHandleInfo Public
	cbWndExtra: i32, // OdinWin32.PrimitiveTypeHandleInfo Public
	hInstance: HINSTANCE, // OdinWin32.HandleTypeHandleInfo Public
	hIcon: HICON, // OdinWin32.HandleTypeHandleInfo Public
	hCursor: HCURSOR, // OdinWin32.HandleTypeHandleInfo Public
	hbrBackground: HBRUSH, // OdinWin32.HandleTypeHandleInfo Public
	lpszMenuName: PWSTR, // OdinWin32.HandleTypeHandleInfo Public
	lpszClassName: PWSTR, // OdinWin32.HandleTypeHandleInfo Public
	hIconSm: HICON, // OdinWin32.HandleTypeHandleInfo Public
}

// Windows.Win32.UI.WindowsAndMessaging (Public, Sealed) TypeReference Enum
WNDCLASS_STYLES :: enum {
	CS_VREDRAW: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public, Static, Literal, HasDefault
	CS_HREDRAW: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public, Static, Literal, HasDefault
	CS_DBLCLKS: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public, Static, Literal, HasDefault
	CS_OWNDC: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public, Static, Literal, HasDefault
	CS_CLASSDC: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public, Static, Literal, HasDefault
	CS_PARENTDC: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public, Static, Literal, HasDefault
	CS_NOCLOSE: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public, Static, Literal, HasDefault
	CS_SAVEBITS: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public, Static, Literal, HasDefault
	CS_BYTEALIGNCLIENT: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public, Static, Literal, HasDefault
	CS_BYTEALIGNWINDOW: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public, Static, Literal, HasDefault
	CS_GLOBALCLASS: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public, Static, Literal, HasDefault
	CS_IME: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public, Static, Literal, HasDefault
	CS_DROPSHADOW: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public, Static, Literal, HasDefault
}

// Windows.Win32.UI.WindowsAndMessaging (Public, Sealed, AutoClass, BeforeFieldInit) TypeReference MulticastDelegate
WNDPROC :: struct {
}

// Windows.Win32.Foundation (Public, SequentialLayout, Sealed, BeforeFieldInit) TypeReference ValueType
HINSTANCE :: struct {
	Value: ^i32, // OdinWin32.PrimitiveTypeHandleInfo Public
}

// Windows.Win32.UI.WindowsAndMessaging (Public, SequentialLayout, Sealed, BeforeFieldInit) TypeReference ValueType
HICON :: struct {
	Value: ^i32, // OdinWin32.PrimitiveTypeHandleInfo Public
}

// Windows.Win32.UI.WindowsAndMessaging (Public, SequentialLayout, Sealed, BeforeFieldInit) TypeReference ValueType
HCURSOR :: struct {
	Value: ^i32, // OdinWin32.PrimitiveTypeHandleInfo Public
}

// Windows.Win32.Graphics.Gdi (Public, SequentialLayout, Sealed, BeforeFieldInit) TypeReference ValueType
HBRUSH :: struct {
	Value: ^i32, // OdinWin32.PrimitiveTypeHandleInfo Public
}

// Windows.Win32.Foundation (Public, SequentialLayout, Sealed, BeforeFieldInit) TypeReference ValueType
PWSTR :: struct {
	Value: ^u8, // OdinWin32.PointerTypeHandleInfo Public
}
