package main

import "base:intrinsics"
import "core:fmt"
import "core:path/filepath"
import "libs:graphviz"
import "libs:obug"

run :: proc() {
	fmt.println("Graphviz")

	dot_path := filepath.clean("../examples/neural_network/nn342.dot", context.temp_allocator)
	output_file := filepath.clean("../examples/neural_network/nn342.svg", context.temp_allocator)
	graphviz.execute_dot(dot_path, .svg, output_file)
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		obug.tracked_run(run)
	} else {
		run()
	}
}
