package lightwave

foreign import lightwave "lightwave.lib"

import _c "core:c"

FILE :: struct {}

BEH_RESET :: 0
BEH_CONSTANT :: 1
BEH_REPEAT :: 2
BEH_OSCILLATE :: 3
BEH_OFFSET :: 4
BEH_LINEAR :: 5

PROJ_PLANAR :: 0
PROJ_CYLINDRICAL :: 1
PROJ_SPHERICAL :: 2
PROJ_CUBIC :: 3
PROJ_FRONT :: 4

WRAP_NONE :: 0
WRAP_EDGE :: 1
WRAP_REPEAT :: 2
WRAP_MIRROR :: 3

lwNode :: st_lwNode
lwPlugin :: st_lwPlugin
lwKey :: st_lwKey
lwEnvelope :: st_lwEnvelope
lwEParam :: st_lwEParam
lwVParam :: st_lwVParam
lwClipStill :: st_lwClipStill
lwClipSeq :: st_lwClipSeq
lwClipAnim :: st_lwClipAnim
lwClipXRef :: st_lwClipXRef
lwClipCycle :: st_lwClipCycle
lwClip :: st_lwClip
lwTMap :: st_lwTMap
lwImageMap :: st_lwImageMap
lwProcedural :: st_lwProcedural
lwGradKey :: st_lwGradKey
lwGradient :: st_lwGradient
lwTexture :: st_lwTexture
lwTParam :: st_lwTParam
lwCParam :: st_lwCParam
Glow :: st_lwGlow
lwRMap :: st_lwRMap
lwLine :: st_lwLine
lwSurface :: st_lwSurface
lwVMap :: st_lwVMap
lwVMapPt :: st_lwVMapPt
lwPoint :: st_lwPoint
lwPolVert :: st_lwPolVert
lwPolygon :: st_lwPolygon
lwPointList :: st_lwPointList
lwPolygonList :: st_lwPolygonList
lwLayer :: st_lwLayer
lwTagList :: st_lwTagList
lwObject :: st_lwObject

st_lwNode :: struct {
	next: ^st_lwNode,
	prev: ^st_lwNode,
	data: rawptr,
}

st_lwPlugin :: struct {
	next:  ^st_lwPlugin,
	prev:  ^st_lwPlugin,
	ord:   cstring,
	name:  cstring,
	flags: _c.int,
	data:  rawptr,
}

st_lwKey :: struct {
	next:       ^st_lwKey,
	prev:       ^st_lwKey,
	value:      _c.float,
	time:       _c.float,
	shape:      _c.uint,
	tension:    _c.float,
	continuity: _c.float,
	bias:       _c.float,
	param:      [4]_c.float,
}

st_lwEnvelope :: struct {
	next:      ^st_lwEnvelope,
	prev:      ^st_lwEnvelope,
	index:     _c.int,
	type:      _c.int,
	name:      cstring,
	key:       ^lwKey,
	nkeys:     _c.int,
	behavior:  [2]_c.int,
	cfilter:   ^lwPlugin,
	ncfilters: _c.int,
}

st_lwEParam :: struct {
	val:    _c.float,
	eindex: _c.int,
}

st_lwVParam :: struct {
	val:    [3]_c.float,
	eindex: _c.int,
}

st_lwClipStill :: struct {
	name: cstring,
}

st_lwClipSeq :: struct {
	prefix: cstring,
	suffix: cstring,
	digits: _c.int,
	flags:  _c.int,
	offset: _c.int,
	start:  _c.int,
	end:    _c.int,
}

st_lwClipAnim :: struct {
	name:   cstring,
	server: cstring,
	data:   rawptr,
}

st_lwClip :: struct {
	next:       ^st_lwClip,
	prev:       ^st_lwClip,
	index:      _c.int,
	type:       _c.uint,
	source:     AnonymousUnion0,
	start_time: _c.float,
	duration:   _c.float,
	frame_rate: _c.float,
	contrast:   lwEParam,
	brightness: lwEParam,
	saturation: lwEParam,
	hue:        lwEParam,
	gamma:      lwEParam,
	negative:   _c.int,
	ifilter:    ^lwPlugin,
	nifilters:  _c.int,
	pfilter:    ^lwPlugin,
	npfilters:  _c.int,
}

st_lwClipXRef :: struct {
	string: cstring,
	index:  _c.int,
	clip:   ^st_lwClip,
}

st_lwClipCycle :: struct {
	name: cstring,
	lo:   _c.int,
	hi:   _c.int,
}

st_lwTMap :: struct {
	size:       lwVParam,
	center:     lwVParam,
	rotate:     lwVParam,
	falloff:    lwVParam,
	fall_type:  _c.int,
	ref_object: cstring,
	coord_sys:  _c.int,
}

st_lwImageMap :: struct {
	cindex:      _c.int,
	projection:  _c.int,
	vmap_name:   cstring,
	axis:        _c.int,
	wrapw_type:  _c.int,
	wraph_type:  _c.int,
	wrapw:       lwEParam,
	wraph:       lwEParam,
	aa_strength: _c.float,
	aas_flags:   _c.int,
	pblend:      _c.int,
	stck:        lwEParam,
	amplitude:   lwEParam,
}

st_lwProcedural :: struct {
	axis:  _c.int,
	value: [3]_c.float,
	name:  cstring,
	data:  rawptr,
}

st_lwGradKey :: struct {
	next:  ^st_lwGradKey,
	prev:  ^st_lwGradKey,
	value: _c.float,
	rgba:  [4]_c.float,
}

st_lwGradient :: struct {
	paramname: cstring,
	itemname:  cstring,
	start:     _c.float,
	end:       _c.float,
	repeat:    _c.int,
	key:       ^lwGradKey,
	ikey:      ^_c.short,
}

st_lwTexture :: struct {
	next:      ^st_lwTexture,
	prev:      ^st_lwTexture,
	ord:       cstring,
	type:      _c.uint,
	chan:      _c.uint,
	opacity:   lwEParam,
	opac_type: _c.short,
	enabled:   _c.short,
	negative:  _c.short,
	axis:      _c.short,
	param:     AnonymousUnion1,
	tmap:      lwTMap,
}

st_lwTParam :: struct {
	val:    _c.float,
	eindex: _c.int,
	tex:    ^lwTexture,
}

st_lwCParam :: struct {
	rgb:    [3]_c.float,
	eindex: _c.int,
	tex:    ^lwTexture,
}

st_lwGlow :: struct {
	enabled:   _c.short,
	type:      _c.short,
	intensity: lwEParam,
	size:      lwEParam,
}

st_lwRMap :: struct {
	val:        lwTParam,
	options:    _c.int,
	cindex:     _c.int,
	seam_angle: _c.float,
}

st_lwLine :: struct {
	enabled: _c.short,
	flags:   _c.ushort,
	size:    lwEParam,
}

st_lwSurface :: struct {
	next:         ^st_lwSurface,
	prev:         ^st_lwSurface,
	name:         cstring,
	srcname:      cstring,
	color:        lwCParam,
	luminosity:   lwTParam,
	diffuse:      lwTParam,
	specularity:  lwTParam,
	glossiness:   lwTParam,
	reflection:   lwRMap,
	transparency: lwRMap,
	eta:          lwTParam,
	translucency: lwTParam,
	bump:         lwTParam,
	smooth:       _c.float,
	sideflags:    _c.int,
	alpha:        _c.float,
	alpha_mode:   _c.int,
	color_hilite: lwEParam,
	color_filter: lwEParam,
	add_trans:    lwEParam,
	dif_sharp:    lwEParam,
	glow:         lwEParam,
	line:         lwLine,
	shader:       ^lwPlugin,
	nshaders:     _c.int,
}

st_lwVMap :: struct {
	next:    ^st_lwVMap,
	prev:    ^st_lwVMap,
	name:    cstring,
	type:    _c.uint,
	dim:     _c.int,
	nverts:  _c.int,
	perpoly: _c.int,
	vindex:  ^_c.int,
	pindex:  ^_c.int,
	val:     ^^_c.float,
}

st_lwVMapPt :: struct {
	vmap:  ^lwVMap,
	index: _c.int,
}

st_lwPoint :: struct {
	pos:    [3]_c.float,
	npols:  _c.int,
	pol:    ^_c.int,
	nvmaps: _c.int,
	vm:     ^lwVMapPt,
}

st_lwPolVert :: struct {
	index:  _c.int,
	norm:   [3]_c.float,
	nvmaps: _c.int,
	vm:     ^lwVMapPt,
}

st_lwPolygon :: struct {
	surf:      ^lwSurface,
	part:      _c.int,
	smoothgrp: _c.int,
	flags:     _c.int,
	type:      _c.uint,
	norm:      [3]_c.float,
	nverts:    _c.int,
	v:         ^lwPolVert,
}

st_lwPointList :: struct {
	count:  _c.int,
	offset: _c.int,
	pt:     ^lwPoint,
}

st_lwPolygonList :: struct {
	count:   _c.int,
	offset:  _c.int,
	vcount:  _c.int,
	voffset: _c.int,
	pol:     ^lwPolygon,
}

st_lwLayer :: struct {
	next:    ^st_lwLayer,
	prev:    ^st_lwLayer,
	name:    cstring,
	index:   _c.int,
	parent:  _c.int,
	flags:   _c.int,
	pivot:   [3]_c.float,
	bbox:    [6]_c.float,
	point:   lwPointList,
	polygon: lwPolygonList,
	nvmaps:  _c.int,
	vmap:    ^lwVMap,
}

st_lwTagList :: struct {
	count:  _c.int,
	offset: _c.int,
	tag:    ^cstring,
}

st_lwObject :: struct {
	layer:   ^lwLayer,
	env:     ^lwEnvelope,
	clip:    ^lwClip,
	surf:    ^lwSurface,
	taglist: lwTagList,
	nlayers: _c.int,
	nenvs:   _c.int,
	nclips:  _c.int,
	nsurfs:  _c.int,
}

AnonymousUnion0 :: struct #raw_union {
	still: lwClipStill,
	seq:   lwClipSeq,
	anim:  lwClipAnim,
	xref:  lwClipXRef,
	cycle: lwClipCycle,
}

AnonymousUnion1 :: struct #raw_union {
	imap:  lwImageMap,
	_proc: lwProcedural,
	grad:  lwGradient,
}

@(default_calling_convention = "c")
foreign lightwave {

	@(link_name = "lwFreeLayer")
	lwFreeLayer :: proc(layer: ^lwLayer) ---

	@(link_name = "lwFreeObject")
	lwFreeObject :: proc(object: ^lwObject) ---

	@(link_name = "lwGetObject")
	lwGetObject :: proc(filename: cstring, failID: ^_c.uint, failpos: ^_c.int) -> ^lwObject ---

	@(link_name = "lwFreePoints")
	lwFreePoints :: proc(point: ^lwPointList) ---

	@(link_name = "lwFreePolygons")
	lwFreePolygons :: proc(plist: ^lwPolygonList) ---

	@(link_name = "lwGetPoints")
	lwGetPoints :: proc(fp: ^FILE, cksize: _c.int, point: ^lwPointList) -> _c.int ---

	@(link_name = "lwGetBoundingBox")
	lwGetBoundingBox :: proc(point: ^lwPointList, bbox: ^_c.float) ---

	@(link_name = "lwAllocPolygons")
	lwAllocPolygons :: proc(plist: ^lwPolygonList, npols: _c.int, nverts: _c.int) -> _c.int ---

	@(link_name = "lwGetPolygons")
	lwGetPolygons :: proc(fp: ^FILE, cksize: _c.int, plist: ^lwPolygonList, ptoffset: _c.int) -> _c.int ---

	@(link_name = "lwGetPolyNormals")
	lwGetPolyNormals :: proc(point: ^lwPointList, polygon: ^lwPolygonList) ---

	@(link_name = "lwGetPointPolygons")
	lwGetPointPolygons :: proc(point: ^lwPointList, polygon: ^lwPolygonList) -> _c.int ---

	@(link_name = "lwResolvePolySurfaces")
	lwResolvePolySurfaces :: proc(polygon: ^lwPolygonList, tlist: ^lwTagList, surf: ^^lwSurface, nsurfs: ^_c.int) -> _c.int ---

	@(link_name = "lwGetVertNormals")
	lwGetVertNormals :: proc(point: ^lwPointList, polygon: ^lwPolygonList) ---

	@(link_name = "lwFreeTags")
	lwFreeTags :: proc(tlist: ^lwTagList) ---

	@(link_name = "lwGetTags")
	lwGetTags :: proc(fp: ^FILE, cksize: _c.int, tlist: ^lwTagList) -> _c.int ---

	@(link_name = "lwGetPolygonTags")
	lwGetPolygonTags :: proc(fp: ^FILE, cksize: _c.int, tlist: ^lwTagList, plist: ^lwPolygonList) -> _c.int ---

	@(link_name = "lwFreeVMap")
	lwFreeVMap :: proc(vmap: ^lwVMap) ---

	@(link_name = "lwGetVMap")
	lwGetVMap :: proc(fp: ^FILE, cksize: _c.int, ptoffset: _c.int, poloffset: _c.int, perpoly: _c.int) -> ^lwVMap ---

	@(link_name = "lwGetPointVMaps")
	lwGetPointVMaps :: proc(point: ^lwPointList, vmap: ^lwVMap) -> _c.int ---

	@(link_name = "lwGetPolyVMaps")
	lwGetPolyVMaps :: proc(polygon: ^lwPolygonList, vmap: ^lwVMap) -> _c.int ---

	@(link_name = "lwFreeClip")
	lwFreeClip :: proc(clip: ^lwClip) ---

	@(link_name = "lwGetClip")
	lwGetClip :: proc(fp: ^FILE, cksize: _c.int) -> ^lwClip ---

	@(link_name = "lwFindClip")
	lwFindClip :: proc(list: ^lwClip, index: _c.int) -> ^lwClip ---

	@(link_name = "lwFreeEnvelope")
	lwFreeEnvelope :: proc(env: ^lwEnvelope) ---

	@(link_name = "lwGetEnvelope")
	lwGetEnvelope :: proc(fp: ^FILE, cksize: _c.int) -> ^lwEnvelope ---

	@(link_name = "lwFindEnvelope")
	lwFindEnvelope :: proc(list: ^lwEnvelope, index: _c.int) -> ^lwEnvelope ---

	@(link_name = "lwEvalEnvelope")
	lwEvalEnvelope :: proc(env: ^lwEnvelope, time: _c.float) -> _c.float ---

	@(link_name = "lwFreePlugin")
	lwFreePlugin :: proc(p: ^lwPlugin) ---

	@(link_name = "lwFreeTexture")
	lwFreeTexture :: proc(t: ^lwTexture) ---

	@(link_name = "lwFreeSurface")
	lwFreeSurface :: proc(surf: ^lwSurface) ---

	@(link_name = "lwGetTHeader")
	lwGetTHeader :: proc(fp: ^FILE, hsz: _c.int, tex: ^lwTexture) -> _c.int ---

	@(link_name = "lwGetTMap")
	lwGetTMap :: proc(fp: ^FILE, tmapsz: _c.int, tmap: ^lwTMap) -> _c.int ---

	@(link_name = "lwGetImageMap")
	lwGetImageMap :: proc(fp: ^FILE, rsz: _c.int, tex: ^lwTexture) -> _c.int ---

	@(link_name = "lwGetProcedural")
	lwGetProcedural :: proc(fp: ^FILE, rsz: _c.int, tex: ^lwTexture) -> _c.int ---

	@(link_name = "lwGetGradient")
	lwGetGradient :: proc(fp: ^FILE, rsz: _c.int, tex: ^lwTexture) -> _c.int ---

	@(link_name = "lwGetTexture")
	lwGetTexture :: proc(fp: ^FILE, bloksz: _c.int, type: _c.uint) -> ^lwTexture ---

	@(link_name = "lwGetShader")
	lwGetShader :: proc(fp: ^FILE, bloksz: _c.int) -> ^lwPlugin ---

	@(link_name = "lwGetSurface")
	lwGetSurface :: proc(fp: ^FILE, cksize: _c.int) -> ^lwSurface ---

	@(link_name = "lwDefaultSurface")
	lwDefaultSurface :: proc() -> ^lwSurface ---

	@(link_name = "lwGetSurface5")
	lwGetSurface5 :: proc(fp: ^FILE, cksize: _c.int, obj: ^lwObject) -> ^lwSurface ---

	@(link_name = "lwGetPolygons5")
	lwGetPolygons5 :: proc(fp: ^FILE, cksize: _c.int, plist: ^lwPolygonList, ptoffset: _c.int) -> _c.int ---

	@(link_name = "lwGetObject5")
	lwGetObject5 :: proc(filename: cstring, failID: ^_c.uint, failpos: ^_c.int) -> ^lwObject ---

	@(link_name = "lwListFree")
	lwListFree :: proc(list: rawptr, unamed0: #type proc(unamed0: rawptr)) ---

	@(link_name = "lwListAdd")
	lwListAdd :: proc(list: ^rawptr, node: rawptr) ---

	@(link_name = "lwListInsert")
	lwListInsert :: proc(vlist: ^rawptr, vitem: rawptr, unamed0: #type proc(unamed0: rawptr, unamed1: rawptr) -> _c.int) ---

	@(link_name = "dot")
	dot :: proc(a: ^_c.float, b: ^_c.float) -> _c.float ---

	@(link_name = "cross")
	cross :: proc(a: ^_c.float, b: ^_c.float, c: ^_c.float) ---

	@(link_name = "normalize")
	normalize :: proc(v: ^_c.float) ---

	@(link_name = "set_flen")
	set_flen :: proc(i: _c.int) ---

	@(link_name = "get_flen")
	get_flen :: proc() -> _c.int ---

	@(link_name = "getbytes")
	getbytes :: proc(fp: ^FILE, size: _c.int) -> rawptr ---

	@(link_name = "skipbytes")
	skipbytes :: proc(fp: ^FILE, n: _c.int) ---

	@(link_name = "getI1")
	getI1 :: proc(fp: ^FILE) -> _c.int ---

	@(link_name = "getI2")
	getI2 :: proc(fp: ^FILE) -> _c.short ---

	@(link_name = "getI4")
	getI4 :: proc(fp: ^FILE) -> _c.int ---

	@(link_name = "getU1")
	getU1 :: proc(fp: ^FILE) -> _c.uchar ---

	@(link_name = "getU2")
	getU2 :: proc(fp: ^FILE) -> _c.ushort ---

	@(link_name = "getU4")
	getU4 :: proc(fp: ^FILE) -> _c.uint ---

	@(link_name = "getVX")
	getVX :: proc(fp: ^FILE) -> _c.int ---

	@(link_name = "getF4")
	getF4 :: proc(fp: ^FILE) -> _c.float ---

	@(link_name = "getS0")
	getS0 :: proc(fp: ^FILE) -> cstring ---

	@(link_name = "sgetI1")
	sgetI1 :: proc(bp: ^^_c.uchar) -> _c.int ---

	@(link_name = "sgetI2")
	sgetI2 :: proc(bp: ^^_c.uchar) -> _c.short ---

	@(link_name = "sgetI4")
	sgetI4 :: proc(bp: ^^_c.uchar) -> _c.int ---

	@(link_name = "sgetU1")
	sgetU1 :: proc(bp: ^^_c.uchar) -> _c.uchar ---

	@(link_name = "sgetU2")
	sgetU2 :: proc(bp: ^^_c.uchar) -> _c.ushort ---

	@(link_name = "sgetU4")
	sgetU4 :: proc(bp: ^^_c.uchar) -> _c.uint ---

	@(link_name = "sgetVX")
	sgetVX :: proc(bp: ^^_c.uchar) -> _c.int ---

	@(link_name = "sgetF4")
	sgetF4 :: proc(bp: ^^_c.uchar) -> _c.float ---

	@(link_name = "sgetS0")
	sgetS0 :: proc(bp: ^^_c.uchar) -> cstring ---

}
