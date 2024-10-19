package main

import "base:intrinsics"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "libs:graphviz"
import "shared:obug"

generate_graph :: proc(dot, output: string) {
	dot_path := filepath.clean(dot, context.temp_allocator)
	output_file := filepath.clean(output, context.temp_allocator)
	graphviz.execute_dot(dot_path, output_file)
}

run :: proc() -> (exit_code: int) {
	fmt.println("Graphviz")
	generate_graph("../examples/graphviz/demo.dot", "demo.png")
	generate_graph("../examples/neural_network/nn342.dot", "../examples/neural_network/nn342.svg")
	return
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}
