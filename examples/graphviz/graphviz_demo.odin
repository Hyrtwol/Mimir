package main

import "core:fmt"
import "libs:graphviz"

main :: proc() {
	fmt.println("Graphviz")
	graphviz.execute_dot()
}
