// +build windows
// +vet
package win32app

import "core:fmt"
import "core:strings"
import "core:mem"

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

WCHAR_SIZE :: size_of(WCHAR)

wstring_byte_size :: proc "contextless" (s: wstring) -> int {
	if s == nil {return 0}
	p0 := uintptr((^WCHAR)(s))
	p := p0
	for p != 0 && (^WCHAR)(p)^ != 0 {
		p += WCHAR_SIZE
	}
	return int(p - p0)
}

wstring_len :: #force_inline proc "contextless" (s: wstring) -> int {
	return wstring_byte_size(s) / WCHAR_SIZE
}

wstring_equal :: proc "contextless" (a, b: wstring) -> bool {
	switch {
		case a == b:   return true
		case a == nil: return false
		case b == nil: return false
		}
	sa, sb := wstring_byte_size(a), wstring_byte_size(b)
	switch {
		case sa == 0: return false
		case sb == 0: return false
		case sa != sb: return false
	}
	return mem.compare_byte_ptrs((^u8)(&a[0]), (^u8)(&b[0]), sa) == 0
}
