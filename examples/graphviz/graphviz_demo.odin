package main

import "base:intrinsics"
import "core:fmt"
import "libs:graphviz"
import "libs:obug"

run :: proc() {
	fmt.println("Graphviz")
	//graphviz.execute_dot("-?")
	graphviz.execute_dot("D:\\dev\\odin\\Mimir\\examples\\graphviz\\nn342.dot", .png)
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		obug.tracked_run(run)
	} else {
		run()
	}
}
