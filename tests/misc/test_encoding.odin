package test_misc

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:os"
import "core:slice"
import "core:strings"
import "core:testing"
import "core:encoding/ini"
import "shared:ounit"

@test
parse_editorconfig :: proc(t: ^testing.T) {

	path := os.clean_path("../../.editorconfig", allocator = context.temp_allocator) or_else panic("os.clean_path")
	// path = os.get_absolute_path(path, allocator = context.temp_allocator) or_else panic("os.get_absolute_path")
	// fmt.printfln("reading %s", path)
	bytes := os.read_entire_file(path, allocator = context.temp_allocator) or_else panic("os.read_entire_file")
	ini_data := strings.clone_from_bytes(bytes, allocator = context.temp_allocator) or_else panic("strings.clone_from_bytes")
	data := ini.load_map_from_string(ini_data, context.allocator) or_else panic("ini.load_map_from_string")
	defer ini.delete_map(data)
	//testing.expect_value(t, err2, runtime.Allocator_Error.None)

	// iterator := ini.iterator_from_string(ini_data)
	// for key, value in ini.iterate(&iterator) {
	// 	fmt.println(key, ", ", value)
	// }

	// str := ini.save_map_to_string(data, context.allocator)
	// defer delete(str)
	// fmt.println(str)

	testing.expect_value(t, data["*.odin"]["max_line_length"], "off")
	testing.expect_value(t, data["*.odin"]["indent_style"], "tab")
	testing.expect_value(t, data[""]["root"], "true")
}
