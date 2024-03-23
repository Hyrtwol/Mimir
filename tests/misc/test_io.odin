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

@(test)
read_some_bytes :: proc(t: ^testing.T) {
	path := "readme.md"
	fmt.printf("reading %s\n", path)

	data, ok := os.read_entire_file_from_filename(path)
	testing.expect(t, ok)
	testing.expectf(t, len(data) == 125, "len=%d", len(data))
	//data: []byte = {65, 66, 67, 68} // "ABCD"
	// data := "ABCD"
	// ok := os.write_entire_file(path, transmute([]byte)data)
	// testing.expect(t, ok)
	// testing.expect(t, os.exists("hello.txt"))
}

@(test)
file_io :: proc(t: ^testing.T) {
	path := "readme.md"
	fmt.printf("path %s\n", path)

	fd: os.Handle
	err: os.Errno

	fd, err = os.open(path, os.O_RDONLY, 0)
	testing.expect(t, err == 0)
	if err != 0 {return}

	defer os.close(fd)

	length: i64
	if length, err = os.file_size(fd); err != 0 {
		testing.expect(t, err == 0)
		return
	}
	testing.expectf(t, length == 125, "%d != 125", length)

	fmt.printf("length %d\n", length)

	data := make([]byte, int(length))
	testing.expect(t, data != nil)
	if data == nil {return}
	defer delete(data)

	bytes_read: int
	bytes_read, err = os.read_full(fd, data)
	testing.expect(t, err == os.ERROR_NONE)
	if err != os.ERROR_NONE {return}

	// data[:bytes_read], true

	testing.expect(t, bytes_read == 125)

	/*
	if len(buf) < min {
		return 0, -1
	}
	nn := max(int)
	for nn > 0 && n < min && err == 0 {
		nn, err = read(fd, buf[n:])
		n += nn
	}
	if n >= min {
		err = 0
	}
	*/
}
