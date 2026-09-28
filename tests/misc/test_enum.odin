package test_misc

import "core:fmt"
import "core:os"
import "core:reflect"
import "core:strings"
import "core:testing"
import "shared:ounit"

@(test)
string_to_enum :: proc(t: ^T) {

	output_formats :: enum {
		png,
		svg,
	}

	ext := "png"
	output_format, ok := reflect.enum_from_name(output_formats, ext)
	expect_value(t, ok, true)
	expect_value(t, output_format, output_formats.png)

	ext = "xxx"
	output_format, ok = reflect.enum_from_name(output_formats, ext)
	expect_value(t, ok, false)
	expect_value(t, output_format, output_formats.png)

	ext = "svg"
	output_format, ok = reflect.enum_from_name(output_formats, ext)
	expect_value(t, ok, true)
	expect_value(t, output_format, output_formats.svg)
}
