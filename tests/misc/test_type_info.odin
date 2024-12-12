package test_misc

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:os"
import "core:reflect"
import "core:testing"

@(test)
get_type_info :: proc(t: ^testing.T) {

	vertex :: struct {
		pos: [3]f32 `POSITION`,
		nml: [3]f32 `NORMAL`,
	}

	v := vertex{{1, 2, 3}, {0.1, 0.2, 0.3}}

	type_info: ^runtime.Type_Info = type_info_of(typeid_of(vertex))
	testing.expect(t, type_info != nil)

	#partial switch info in type_info.variant {
	case runtime.Type_Info_Named:
		testing.expect_value(t, info.name, "vertex")
		#partial switch b in info.base.variant {
		case runtime.Type_Info_Struct:
			testing.expect_value(t, b.field_count, 2)
			testing.expect_value(t, b.tags[0], "POSITION")
			testing.expect_value(t, b.tags[1], "NORMAL")
		case:
			//testing.fail(t)
			testing.expectf(t, false, "info.base.variant %v", info.base.variant)
		}
	case:
		testing.fail(t)
		testing.expectf(t, false, "type_info.variant %v", type_info.variant)
	}
}

@(test)
struct_tags :: proc(t: ^testing.T) {

	vertex :: struct {
		pos: [3]f32 `POSITION:"0"`,
		nml: [3]f32 `NORMAL:"1"`,
		uv0: [2]f32 `TEXCOORD:"2"`,
	}

	fd, fe := os.open("struct_fields_zipped.log", os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0)
	testing.expect(t, fe == 0)
	if fe != 0 {return}
	defer os.close(fd)
	w := io.to_writer(os.stream_from_handle(fd))

	vt: string
	ok: bool
	for field in reflect.struct_fields_zipped(vertex) {
		fmt.wprintfln(w, "%v", field)

		if vt, ok = reflect.struct_tag_lookup(reflect.Struct_Tag(field.tag), "POSITION"); ok {
			fmt.wprintfln(w, "POSITION: %v", vt)
		}
		if vt, ok = reflect.struct_tag_lookup(reflect.Struct_Tag(field.tag), "NORMAL"); ok {
			fmt.wprintfln(w, "NORMAL: %v", vt)
		}
		if vt, ok = reflect.struct_tag_lookup(reflect.Struct_Tag(field.tag), "TEXCOORD"); ok {
			fmt.wprintfln(w, "TEXCOORD: %v", vt)
		}
	}

}

@(test)
name_of_arg :: proc(t: ^testing.T) {
	get_name :: proc($name: string, allocator := context.allocator) -> string {
		return fmt.aprintf("$name=%s", name, allocator = allocator)
	}

	name : string
	name = get_name("odd")
	delete(name)

	testing.expect_value(t, name, "$name=odd")
}
