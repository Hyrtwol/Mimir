package test_misc

import "core:fmt"
import "core:os"
import fp "core:path/filepath"
import "core:slice"
import "core:strings"
import "core:testing"
import "shared:ounit"

@(test)
write_hello_txt :: proc(t: ^testing.T) {
	path := "hello.log"
	// fmt.printfln("writing %s", path)
	data := "ABCD"
	ok := os.write_entire_file(path, transmute([]byte)data)
	testing.expect(t, ok)
	testing.expect(t, os.exists(path))
	err := os.remove(path)
	testing.expect(t, err == 0)
	testing.expect(t, !os.exists(path))
}

EXPECTED_FILE_SIZE :: 2893

@(test)
read_some_bytes :: proc(t: ^testing.T) {
	path := fp.join({ODIN_ROOT, "README.md"}, allocator = context.temp_allocator)
	//fmt.printfln("reading %s", path)

	data, ok := os.read_entire_file_from_filename(path, allocator = context.temp_allocator)
	testing.expect(t, ok)
	testing.expectf(t, len(data) == EXPECTED_FILE_SIZE, "len=%d", len(data))
	//data: []byte = {65, 66, 67, 68} // "ABCD"
	// data := "ABCD"
	// ok := os.write_entire_file(path, transmute([]byte)data)
	// testing.expect(t, ok)
	// testing.expect(t, os.exists("hello.txt"))
}

@(test)
file_io :: proc(t: ^testing.T) {
	path := fp.join({ODIN_ROOT, "README.md"}, allocator = context.temp_allocator)

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
	testing.expectf(t, length == EXPECTED_FILE_SIZE, "%d != %d", length, EXPECTED_FILE_SIZE)

	data := make([]byte, int(length))
	testing.expect(t, data != nil)
	if data == nil {return}
	defer delete(data)

	bytes_read: int
	bytes_read, err = os.read_full(fd, data)
	testing.expect(t, err == os.ERROR_NONE)
	if err != os.ERROR_NONE {return}

	// data[:bytes_read], true

	testing.expect(t, bytes_read == EXPECTED_FILE_SIZE)

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

@(test)
lowercase_dictionary :: proc(t: ^testing.T) {
	path := fp.join({"..", "doc", "odin-dictionary.txt"}, allocator = context.temp_allocator)

	// fmt.printfln("reading %s", path)
	data, ok := os.read_entire_file_from_filename(path, allocator = context.temp_allocator)
	testing.expect(t, ok)
	if !ok {return}

	newline :: "\r\n"

	words, err := strings.split(string(data), newline, allocator = context.temp_allocator)
	testing.expect(t, err == .None)
	if err != .None {return}

	new_words := make([dynamic]string, 0, len(words), context.temp_allocator)

	for w in words {
		if len(w) == 0 {continue}
		if w[0] == '#' {continue}
		append(&new_words, strings.to_lower(w, allocator = context.temp_allocator))
	}

	slice.sort(new_words[:])

	// fmt.printfln("writing %s", path)
	fd, fe := os.open(path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0)
	testing.expect(t, fe == 0)
	if fe != 0 {return}
	defer os.close(fd)
	os.write_string(fd, "# Odin Dictionary Words" + newline)
	for w in new_words {
		os.write_string(fd, w)
		os.write_string(fd, newline)
	}
}
