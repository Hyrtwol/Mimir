// +build windows
package owin

// 1 / 33972

// WNDCLASSEXW TypeDefinition
// TypeReference ; Windows.Win32.UI.WindowsAndMessaging ; Public, SequentialLayout, Sealed, BeforeFieldInit
// ValueType
WNDCLASSEXW :: struct {
	cbSize: UInt32, // OdinWin32.PrimitiveTypeHandleInfo Public
	style: WNDCLASS_STYLES, // OdinWin32.HandleTypeHandleInfo Public
	lpfnWndProc: WNDPROC, // OdinWin32.HandleTypeHandleInfo Public
	cbClsExtra: Int32, // OdinWin32.PrimitiveTypeHandleInfo Public
	cbWndExtra: Int32, // OdinWin32.PrimitiveTypeHandleInfo Public
	hInstance: HINSTANCE, // OdinWin32.HandleTypeHandleInfo Public
	hIcon: HICON, // OdinWin32.HandleTypeHandleInfo Public
	hCursor: HCURSOR, // OdinWin32.HandleTypeHandleInfo Public
	hbrBackground: HBRUSH, // OdinWin32.HandleTypeHandleInfo Public
	lpszMenuName: PWSTR, // OdinWin32.HandleTypeHandleInfo Public
	lpszClassName: PWSTR, // OdinWin32.HandleTypeHandleInfo Public
	hIconSm: HICON, // OdinWin32.HandleTypeHandleInfo Public
}

// WNDCLASS_STYLES TypeDefinition
// TypeReference ; Windows.Win32.UI.WindowsAndMessaging ; Public, Sealed
// Enum
WNDCLASS_STYLES :: enum UInt32 {
	CS_VREDRAW = 1,
	CS_HREDRAW = 2,
	CS_DBLCLKS = 8,
	CS_OWNDC = 32,
	CS_CLASSDC = 64,
	CS_PARENTDC = 128,
	CS_NOCLOSE = 512,
	CS_SAVEBITS = 2048,
	CS_BYTEALIGNCLIENT = 4096,
	CS_BYTEALIGNWINDOW = 8192,
	CS_GLOBALCLASS = 16384,
	CS_IME = 65536,
	CS_DROPSHADOW = 131072,
}

// WNDPROC TypeDefinition
// TypeReference ; Windows.Win32.UI.WindowsAndMessaging ; Public, Sealed, AutoClass, BeforeFieldInit
// MulticastDelegate
// WNDPROC :: #type proc "system" () -> LRESULT

// HINSTANCE TypeDefinition
// TypeReference ; Windows.Win32.Foundation ; Public, SequentialLayout, Sealed, BeforeFieldInit
// ValueType
HINSTANCE :: struct {
	Value: IntPtr, // OdinWin32.PrimitiveTypeHandleInfo Public
}

// HICON TypeDefinition
// TypeReference ; Windows.Win32.UI.WindowsAndMessaging ; Public, SequentialLayout, Sealed, BeforeFieldInit
// ValueType
HICON :: struct {
	Value: IntPtr, // OdinWin32.PrimitiveTypeHandleInfo Public
}

// HCURSOR TypeDefinition
// TypeReference ; Windows.Win32.UI.WindowsAndMessaging ; Public, SequentialLayout, Sealed, BeforeFieldInit
// ValueType
HCURSOR :: struct {
	Value: IntPtr, // OdinWin32.PrimitiveTypeHandleInfo Public
}

// HBRUSH TypeDefinition
// TypeReference ; Windows.Win32.Graphics.Gdi ; Public, SequentialLayout, Sealed, BeforeFieldInit
// ValueType
HBRUSH :: struct {
	Value: IntPtr, // OdinWin32.PrimitiveTypeHandleInfo Public
}

// PWSTR TypeDefinition
// TypeReference ; Windows.Win32.Foundation ; Public, SequentialLayout, Sealed, BeforeFieldInit
// ValueType
PWSTR :: struct {
	Value: ^Char, // OdinWin32.PointerTypeHandleInfo Public
}
