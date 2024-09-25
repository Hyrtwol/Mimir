#+build windows
#+vet
package win32app

import "core:fmt"
import "core:mem"
import "core:strings"
import win32 "core:sys/windows"

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
	case sa == 0:  return false
	case sb == 0:  return false
	case sa != sb: return false
	}
	return mem.compare_byte_ptrs((^u8)(&a[0]), (^u8)(&b[0]), sa) == 0
}

/*
	gb_internal int convert_multibyte_to_widechar(char const *multibyte_input, int input_length, wchar_t *output, int output_size) {
		return MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, multibyte_input, input_length, output, output_size);
	}
*/
convert_multibyte_to_widechar :: proc(multibyte_input: string, output: wstring, output_size: i32) -> i32 {
	input_length := i32(len(multibyte_input))
	if input_length < 1 {
		return 0
	}

	b := transmute([]byte)multibyte_input
	cstr := raw_data(b)

	n := win32.MultiByteToWideChar(win32.CP_UTF8, win32.MB_ERR_INVALID_CHARS, cstr, input_length, nil, 0)
	if n == 0 {
		return 0
	}
	if n > input_length {
		return 0
	}

	n1 := win32.MultiByteToWideChar(win32.CP_UTF8, win32.MB_ERR_INVALID_CHARS, cstr, input_length, output, output_size)
	if n1 == 0 {
		return 0
	}

	output[n] = 0
	for n >= 1 && output[n-1] == 0 {
		n -= 1
	}
	return n
}

/*
	gb_internal int convert_widechar_to_multibyte(wchar_t const *widechar_input, int input_length, char *output, int output_size) {
		return WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, widechar_input, input_length, output, output_size, nullptr, nullptr);
	}
*/
// convert_widechar_to_multibyte :: proc(wchar_t const *widechar_input, input_length: i32, char *output, output_size: i32) -> i32 {
// 	n := win32.WideCharToMultiByte(win32.CP_UTF8, win32.WC_ERR_INVALID_CHARS, widechar_input, input_length, output, output_size, nullptr, nullptr)
// 	return n
// }
