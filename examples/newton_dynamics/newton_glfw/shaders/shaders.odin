package shaders

// odinfmt: disable
vertex_sources:= [?]string {
	string(#load("pos.vs")),
	string(#load("pos_tex.vs")),
	string(#load("pos_nml.vs")),
	string(#load("pos_tex_nml.vs")),
}

fragment_sources:= [?]string {
	string(#load("col.fs")),
	string(#load("tex.fs")),
	string(#load("lit.fs")),
}
// odinfmt: enable
