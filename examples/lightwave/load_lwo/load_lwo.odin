package main

import "base:intrinsics"
import "core:fmt"
import "core:os"
import lw "shared:newtek_lightwave"
import "shared:obug"

output_path :: "lightwave.txt"

wln :: proc(fd: os.Handle, args: ..any) {
	os.write_string(fd, fmt.tprintln(..args))
}

w :: proc(fd: os.Handle, args: ..any) {
	os.write_string(fd, fmt.tprint(..args))
}

wfln :: proc(fd: os.Handle, format: string, args: ..any) {
	os.write_string(fd, fmt.tprintfln(format, ..args))
}

wf :: proc(fd: os.Handle, format: string, args: ..any) {
	os.write_string(fd, fmt.tprintf(format, ..args))
}

run :: proc() -> (exit_code: int) {
	fmt.println("LightWave Object Reader")

	lwo_files: []cstring = {
		// lwo test files
		"../data/models/box.lwo",
		"../data/models/boxs.lwo",
		"../data/models/boxuv.lwo",
		"../data/models/multi_layer.lwo",
	}

	fmt.printfln("writing %s", output_path)
	fd, fe := os.open(output_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0)
	if fe != os.ERROR_NONE {return}
	defer os.close(fd)

	for lwo_file in lwo_files {
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

			points: []lw.lwPoint = lw.get_points(&layer.point)
			for &point, i in points {
				pols: []lw.lwint = lw.get_pols(&point)
				vmaps: []lw.lwVMapPt = lw.get_vmaps(&point)

				wf(fd, "  point[%d]: ", i)
				wln(fd, "pos:", point.pos, "pols:", pols, "nvmaps:", vmaps)
			}

			polys: []lw.lwPolygon = lw.get_polys(&layer.polygon)
			for &poly, i in polys {
				wfln(fd, "  polygon[%d]:", i)
				wfln(fd, "    part: %d", poly.part)
				wfln(fd, "    smoothgrp: %d", poly.smoothgrp)
				wfln(fd, "    flags: 0x%8X", poly.flags)
				wfln(fd, "    type: %v", poly.type)
				wfln(fd, "    norm: %v", poly.norm)
				wfln(fd, "    nverts: %d", poly.nverts)

				verts: []lw.lwPolVert = lw.get_polverts(&poly)
				for &vert, j in verts {
					vmaps: []lw.lwVMapPt = lw.get_polvert_vmaps(&vert)
					w(fd, "      ")
					wf(fd, "vert[%d]: ", j)
					w(fd, "index:", vert.index, "norm:", vert.norm, "vmaps:", vmaps)
					wln(fd)
				}
			}
		}
		wln(fd)
	}

	fmt.println("Done.")
	return
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}
