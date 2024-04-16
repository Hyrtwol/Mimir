// +build windows
// +vet
package win32app

import "core:fmt"
import "core:strings"

// similar to strings.to_string
to_wstring :: #force_inline proc(b: strings.Builder, allocator := context.temp_allocator) -> (res: wstring) {
	return utf8_to_wstring(string(b.buf[:]), allocator)
}

// similar to fmt.caprintf
waprintf :: #force_inline proc(format: string, args: ..any, allocator := context.allocator, newline := false) -> wstring {
	return utf8_to_wstring(fmt.tprintf(format, ..args), allocator)
}

// similar to fmt.caprintfln
waprintfln :: #force_inline proc(format: string, args: ..any, allocator := context.allocator) -> wstring {
	return waprintf(format, ..args, allocator = allocator, newline = true)
}

// similar to fmt.ctprintf
wtprintf :: #force_inline proc(format: string, args: ..any, allocator := context.temp_allocator, newline := false) -> wstring {
	return utf8_to_wstring(fmt.tprintf(format, ..args), allocator)
}

// similar to fmt.ctprintfln
wtprintfln :: #force_inline proc(format: string, args: ..any, allocator := context.temp_allocator) -> wstring {
	return wtprintf(format, ..args, allocator = allocator, newline = true)
}
