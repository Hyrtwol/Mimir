package test_misc

import _t "core:testing"

@(test)
use_define :: proc(t: ^_t.T) {

	vertex :: struct {
		pos: [3]f32,
		nml: [3]f32,
	}

	vertex_attrib := 0
	when #defined(vertex) {
		vertex_attrib += 1
	}
	when #defined(vertex.pos) {
		vertex_attrib += 2
	}
	when #defined(vertex.nml) {
		vertex_attrib += 4
	}
	when #defined(vertex.uv0) {
		vertex_attrib += 8
	}

	_t.expect_value(t, vertex_attrib, 1) // fails with: expected vertex_attrib to be 7, got 1
}
