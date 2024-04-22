package main

import "core:fmt"
import lw "shared:newtek_lightwave"

box :: "../data/models/box.lwo"
multi_layer :: "../models/multi_layer.lwo"

main :: proc() {
	fmt.println("LightWave Object Reader")

	lwo_file: cstring = box

	fail_id: u32 = 0
	fail_pos: i32 = 0
	obj := lw.lwGetObject(lwo_file, &fail_id, &fail_pos)
	defer if obj != nil {lw.lwFreeObject(obj)}

	fmt.println("lwo:", obj)

	for layer := obj.layer; layer != nil; layer = layer.next {
		fmt.println("layer:", layer)

		fmt.println("  name:", layer.name)

		fmt.println("  point.count:", layer.point.count)
		fmt.println("  point.offset:", layer.point.offset)

		point_cnt := layer.point.count
		points := ([^]lw.lwPoint)(layer.point.pt)
		for i in 0 ..< point_cnt {
			//fmt.printfln("  point[%d]: %v", i, points[i])
			point := &points[i]
			fmt.printfln("  point[%d]:", i)
			fmt.println("    pos:   ", point^.pos)
			fmt.println("    npols: ", point^.npols)
			fmt.println("    nvmaps:", point^.nvmaps)

		}

		poly_cnt := layer.polygon.count
		polys := ([^]lw.lwPolygon)(layer.polygon.pol)
		for i in 0 ..< poly_cnt {
			poly := &polys[i]
			fmt.printfln("  polygon[%d]:", i)
			fmt.printfln("    part: %d", poly^.part)
			fmt.printfln("    smoothgrp: %d", poly^.smoothgrp)
			fmt.printfln("    flags: 0x%8X", poly^.flags)
			fmt.printfln("    type: 0x%8X", poly^.type)
			fmt.printfln("    norm: %v", poly^.norm)
			fmt.printfln("    nverts: %d", poly^.nverts)
		}
	}

	fmt.println("Done.")
}
