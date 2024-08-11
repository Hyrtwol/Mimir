package main

import "core:fmt"
import "core:os"
import lw "shared:newtek_lightwave"

box :: "../data/models/box.lwo"
multi_layer :: "../models/multi_layer.lwo"

newline :: "\r\n"
output_path :: "lightwave.txt"

ws :: os.write_string

wln :: proc(fd: os.Handle, args: ..any) {
	os.write_string(fd, fmt.tprintln(..args))
}

wr :: proc(fd: os.Handle, args: ..any) {
	os.write_string(fd, fmt.tprint(..args))
}

wfln :: proc(fd: os.Handle, fmtstr: string, args: ..any) {
	os.write_string(fd, fmt.tprintf(fmtstr, ..args, newline = true))
}

wrf :: proc(fd: os.Handle, fmtstr: string, args: ..any) {
	os.write_string(fd, fmt.tprintf(fmtstr, ..args))
}

main :: proc() {
	fmt.println("LightWave Object Reader")

	lwo_file: cstring = box

	fmt.printfln("writing %s", output_path)
	fd, fe := os.open(output_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0)
	//testing.expect(t, fe == 0)
	if fe != 0 {return}
	defer os.close(fd)

	wfln(fd, "LightWave Object %s", lwo_file)

	fmt.printfln("reading %s", lwo_file)

	fail_id: u32 = 0
	fail_pos: i32 = 0
	obj := lw.lwGetObject(lwo_file, &fail_id, &fail_pos)
	if obj == nil {
		fmt.println("error:", "lwo_file=", lwo_file, "fail_id=", fail_id, "fail_pos=", fail_pos)
		return
	}
	defer lw.lwFreeObject(obj)

	fmt.println("lwo:", obj)

	for layer := obj.layer; layer != nil; layer = layer.next {
		wln(fd, "layer:", layer)

		wln(fd, "  name:", layer.name)
		wln(fd, "  flags:", layer.flags)

		wln(fd, "  point.count:", layer.point.count)
		wln(fd, "  point.offset:", layer.point.offset)

		point_cnt := layer.point.count
		points := ([^]lw.lwPoint)(layer.point.pt)
		for i in 0 ..< point_cnt {
			//wfln(fd,"  point[%d]: %v", i, points[i])
			point := &points[i]
			// wfln(fd,"  point[%d]:", i)
			// wln(fd, "    pos:   ", point^.pos)
			// wln(fd, "    npols: ", point^.npols)
			// wln(fd, "    nvmaps:", point^.nvmaps)
			wfln(fd, "  point[%d]: ", i)
			wr(fd, "    pos:", point^.pos)

			//fmt.print("npols:", point^.npols)
			wr(fd, " pols:")
			pol := ([^]lw.lwint)(point^.pol)
			for i in 0 ..< point^.npols {
				wrf(fd, " %d", pol[i])
			}
			wr(fd, " ")

			wr(fd, "nvmaps:", point^.nvmaps)
			wln(fd)
		}

		poly_cnt := layer.polygon.count
		polys := ([^]lw.lwPolygon)(layer.polygon.pol)
		for i in 0 ..< poly_cnt {
			poly := &polys[i]
			wfln(fd, "  polygon[%d]:", i)
			wfln(fd, "    part: %d", poly^.part)
			wfln(fd, "    smoothgrp: %d", poly^.smoothgrp)
			wfln(fd, "    flags: 0x%8X", poly^.flags)
			wfln(fd, "    type: %v", poly^.type)
			wfln(fd, "    norm: %v", poly^.norm)
			wfln(fd, "    nverts: %d", poly^.nverts)

			verts_cnt := poly^.nverts
			verts := ([^]lw.lwPolVert)(poly^.v)
			for j in 0 ..< verts_cnt {
				//wfln(fd,"  point[%d]: %v", i, points[i])
				vert := &verts[j]
				wrf(fd, "      vert[%d]: ", j)
				wln(fd, "index:", vert^.index, "norm:", vert^.norm, "nvmaps:", vert^.nvmaps)

			}
		}
	}

	fmt.println("Done.")
}
