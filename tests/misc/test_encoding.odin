package test_misc

import "core:os"
import "core:strings"
import "core:encoding/ini"

@test
parse_editorconfig :: proc(t: ^testing.T) {
	path := os.clean_path("../../.editorconfig", allocator = context.temp_allocator) or_else panic("os.clean_path")
	// path = os.get_absolute_path(path, allocator = context.temp_allocator) or_else panic("os.get_absolute_path")
	// fmt.printfln("reading %s", path)
	bytes := os.read_entire_file(path, allocator = context.temp_allocator) or_else panic("os.read_entire_file")
	ini_data := strings.clone_from_bytes(bytes, allocator = context.temp_allocator) or_else panic("strings.clone_from_bytes")
	data := ini.load_map_from_string(ini_data, context.allocator) or_else panic("ini.load_map_from_string")
	defer ini.delete_map(data)

	testing.expect_value(t, data["*.odin"]["max_line_length"], "off")
	testing.expect_value(t, data["*.odin"]["indent_style"], "tab")
	testing.expect_value(t, data[""]["root"], "true")
}
