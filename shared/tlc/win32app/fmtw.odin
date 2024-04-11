// +build windows
// +vet
package win32app

import "core:fmt"
import "core:strings"

// similar to strings.to_string
to_wstring :: proc(b: strings.Builder, allocator := context.temp_allocator) -> (res: wstring) {
	return utf8_to_wstring(string(b.buf[:]), allocator)
}

// similar to fmt.caprintf
waprintf :: proc(format: string, args: ..any, allocator := context.allocator, newline := false) -> wstring {
	s := fmt.tprintf(format, ..args)
	return utf8_to_wstring(s, allocator)
}

// similar to fmt.caprintfln
waprintfln :: proc(format: string, args: ..any, allocator := context.allocator) -> wstring {
	return waprintf(format, ..args, allocator = allocator, newline = true)
}

// similar to fmt.ctprintf
wtprintf :: proc(format: string, args: ..any, allocator := context.temp_allocator, newline := false) -> wstring {
	s := fmt.tprintf(format, ..args)
	return utf8_to_wstring(s, allocator)
}

// similar to fmt.ctprintfln
wtprintfln :: proc(format: string, args: ..any, allocator := context.temp_allocator) -> wstring {
	return wtprintf(format, ..args, allocator = allocator, newline = true)
}
