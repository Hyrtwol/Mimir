package lightwave

import _c "core:c"
import la "core:math/linalg"

// D:\dev\lightwave\lwsdk\include\lwtypes.h

LWImageID :: rawptr
LWBufferValue :: f32
LWPixmapID :: rawptr
LWTextureID :: rawptr
NodeEditorID :: rawptr

LWFrame :: i32
LWTime :: f64

LWFVector :: la.Vector3f32 // [3]f32
LWDVector :: la.Vector3f64 // [3]f64;
LWFMatrix3 :: la.Matrix3x3f32 // [3][3]
LWFMatrix4 :: la.Matrix4x4f32 // [4][4];
LWDMatrix3 :: la.Matrix3x3f64 // [3][3]
LWDMatrix4 :: la.Matrix4x4f64 // [4][4];

LWID :: u32
//#define LWID_(a,b,c,d) ((((unsigned int)a)<<24)|(((unsigned int)b)<<16)|(((unsigned int)c)<<8)|((unsigned int)d))
LWID_ :: #force_inline proc(a, b, c, d: u32) -> LWID {return (u32(a) << 24) | (u32(b) << 16) | (u32(c) << 8) | u32(d)}


LWCommandCode :: i32

LWChannelID :: rawptr

/*
 * Persistent instances are just some opaque data object referenced
 * by void pointer.  Errors from handler functions are human-readable
 * strings, where a null string pointer indicates no error.
 */
LWInstance :: rawptr
LWError :: ^u8
