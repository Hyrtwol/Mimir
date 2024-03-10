package test_misc

import "core:fmt"
import "core:os"
import "core:testing"
import "shared:ounit"

@(test)
write_hello_txt :: proc(t: ^testing.T) {
	path := "hello.txt"
	fmt.printf("writing %s\n", path)
	//data: []byte = {65, 66, 67, 68} // "ABCD"
	data := "ABCD"
	ok := os.write_entire_file(path, transmute([]byte)data)
	testing.expect(t, ok)
	testing.expect(t, os.exists("hello.txt"))
}
