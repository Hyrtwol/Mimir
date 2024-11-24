#+build windows
#+vet
package owin

import "core:path/filepath"
import win32 "core:sys/windows"

expand_environment_strings :: proc(path: string, allocator := context.temp_allocator) -> (res: string, err: int) {
	wpath := win32.utf8_to_wstring(path, context.temp_allocator)

	INFO_BUFFER_SIZE :: 0x4000
	infoBuf: [INFO_BUFFER_SIZE]win32.WCHAR
	bufCharCount := win32.ExpandEnvironmentStringsW(wpath, &infoBuf[0], INFO_BUFFER_SIZE)
	if (bufCharCount > INFO_BUFFER_SIZE) {
		err = -1
		return
	}
	if bufCharCount == 0 {
		err = -2
		return
	}
	expanded_path, aerr := win32.wstring_to_utf8(&infoBuf[0], int(bufCharCount), context.temp_allocator)
	if aerr != .None {
		err = int(aerr)
		return
	}
	res, aerr = filepath.clean(expanded_path, allocator)
	err = int(aerr)
	return
}
