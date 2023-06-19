package main

import "core:fmt"
import win32 "core:sys/windows"
import win32app "../../shared/tlc/win32app"

TITLE :: "Mimir"

main :: proc() {
	title1 := "ABC"
	wtitle := win32.utf8_to_wstring(title1)
	title2, err2 := win32.wstring_to_utf8(wtitle, 256, context.allocator)
	fmt.printf("title1 \"%s\"\n", title1)
	fmt.printf("title2 \"%s\" %v\n", title2, err2)
	assert(title1 == title2)

	// app title
	wtitle2: win32.wstring = win32.utf8_to_wstring(TITLE)
	fmt.printf("wtitle %d\n", wtitle2)

	// win32.MessageBoxW(nil, win32.utf8_to_wstring("Title should be " + TITLE), wtitle, win32.MB_OK)
}
