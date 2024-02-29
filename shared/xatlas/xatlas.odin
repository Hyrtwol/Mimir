package xatlas

USE_LINALG :: #config(FMOD_USE_LINALG, true)

import _c "core:c"
import "core:math/linalg"

foreign import "xatlas.lib"

uint32_t :: _c.uint32_t
int32_t :: _c.int32_t
float :: _c.float

xatlasChartType :: enum {
	Planar,
	Ortho,
	LSCM,
	Piecewise,
	Invalid,
}

xatlasChart :: struct {
	faceArray:  ^uint32_t,
	atlasIndex: uint32_t,
	faceCount:  uint32_t,
	type:       xatlasChartType,
	material:   uint32_t,
}

xatlasVertex :: struct {
	atlasIndex: int32_t,
	chartIndex: int32_t,
	uv:         [2]float,
	xref:       uint32_t,
}

xatlasMesh :: struct {
	chartArray:  ^xatlasChart,
	indexArray:  ^uint32_t,
	vertexArray: ^xatlasVertex,
	chartCount:  uint32_t,
	indexCount:  uint32_t,
	vertexCount: uint32_t,
}

xatlasImageChartIndexMask :: 0x1FFFFFFF;
xatlasImageHasChartIndexBit :: 0x80000000;
xatlasImageIsBilinearBit :: 0x40000000;
xatlasImageIsPaddingBit :: 0x20000000;
