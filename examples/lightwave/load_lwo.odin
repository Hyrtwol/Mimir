package main

import "core:fmt"
import lw "libs:lightwave"

box :: "../data/models/box.lwo"
multi_layer :: "../models/multi_layer.lwo"

main :: proc() {
	fmt.println("LightWave Object Reader")

	lwo_file: cstring = box

	fail_id: u32 = 0
	fail_pos: i32 = 0
	obj := lw.lwGetObject(lwo_file, &fail_id, &fail_pos)
	defer if obj != nil {lw.lwFreeObject(obj)}

	fmt.printf("lwo %v\n", obj)

	for layer := obj.layer; layer != nil; layer = layer.next {
		fmt.printf("layer %v\n", layer)

		fmt.printf("  name %v\n", layer.name)

		fmt.printf("  point.count:  %d\n", layer.point.count)
		fmt.printf("  point.offset: %d\n", layer.point.offset)

		point_cnt := layer.point.count
		points := ([^]lw.lwPoint)(layer.point.pt)
		for i in 0 ..< point_cnt {
			//fmt.printf("  point[%d]: %v\n", i, points[i])
			point := &points[i]
			fmt.printf("  point[%d]:\n", i)
			fmt.printf("    pos: %v\n", point^.pos)
			fmt.printf("    npols: %d\n", point^.npols)
			fmt.printf("    nvmaps: %d\n", point^.nvmaps)

		}

		poly_cnt := layer.polygon.count
		polys := ([^]lw.lwPolygon)(layer.polygon.pol)
		for i in 0 ..< poly_cnt {
			poly := &polys[i]
			fmt.printf("  polygon[%d]:\n", i)
			fmt.printf("    part: %d\n", poly^.part)
			fmt.printf("    smoothgrp: %d\n", poly^.smoothgrp)
			fmt.printf("    flags: 0x%8X\n", poly^.flags)
			fmt.printf("    type: 0x%8X\n", poly^.type)
			fmt.printf("    norm: %v\n", poly^.norm)
			fmt.printf("    nverts: %d\n", poly^.nverts)
		}
	}

	fmt.println("Done.")
}
