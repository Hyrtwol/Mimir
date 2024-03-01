package xatlas

foreign import xatlas "xatlas.lib"

USE_LINALG :: #config(FMOD_USE_LINALG, true)

import _c "core:c"
import "core:math/linalg"


uint32_t :: _c.uint32_t
int32_t :: _c.int32_t
float :: _c.float
_Bool :: bool

xatlasImageChartIndexMask :: 0x1FFFFFFF;
xatlasImageHasChartIndexBit :: 0x80000000;
xatlasImageIsBilinearBit :: 0x40000000;
xatlasImageIsPaddingBit :: 0x20000000;

xatlasParameterizeFunc :: #type proc(positions : ^_c.float, texcoords : ^_c.float, vertexCount : u32, indices : ^u32, indexCount : u32);
xatlasProgressFunc :: #type proc(category : xatlasProgressCategory, progress : _c.int, userData : rawptr) -> _Bool;
xatlasReallocFunc :: #type proc(unamed0 : rawptr, unamed1 : _c.size_t) -> rawptr;
xatlasFreeFunc :: #type proc(unamed0 : rawptr);
xatlasPrintFunc :: #type proc(unamed0 : cstring) -> _c.int;

xatlasChartType :: enum i32 {
    XATLAS_CHART_TYPE_PLANAR,
    XATLAS_CHART_TYPE_ORTHO,
    XATLAS_CHART_TYPE_LSCM,
    XATLAS_CHART_TYPE_PIECEWISE,
    XATLAS_CHART_TYPE_INVALID,
};

xatlasIndexFormat :: enum i32 {
    XATLAS_INDEX_FORMAT_UINT16,
    XATLAS_INDEX_FORMAT_UINT32,
};

xatlasAddMeshError :: enum i32 {
    XATLAS_ADD_MESH_ERROR_SUCCESS,
    XATLAS_ADD_MESH_ERROR_ERROR,
    XATLAS_ADD_MESH_ERROR_INDEXOUTOFRANGE,
    XATLAS_ADD_MESH_ERROR_INVALIDFACEVERTEXCOUNT,
    XATLAS_ADD_MESH_ERROR_INVALIDINDEXCOUNT,
};

xatlasProgressCategory :: enum i32 {
    XATLAS_PROGRESS_CATEGORY_ADDMESH,
    XATLAS_PROGRESS_CATEGORY_COMPUTECHARTS,
    XATLAS_PROGRESS_CATEGORY_PACKCHARTS,
    XATLAS_PROGRESS_CATEGORY_BUILDOUTPUTMESHES,
};

xatlasChart :: struct {
    faceArray : ^u32,
    atlasIndex : u32,
    faceCount : u32,
    type : xatlasChartType,
    material : u32,
};

xatlasVertex :: struct {
    atlasIndex : i32,
    chartIndex : i32,
    uv : [2]_c.float,
    xref : u32,
};

xatlasMesh :: struct {
    chartArray : ^xatlasChart,
    indexArray : ^u32,
    vertexArray : ^xatlasVertex,
    chartCount : u32,
    indexCount : u32,
    vertexCount : u32,
};

xatlasAtlas :: struct {
    image : ^u32,
    meshes : ^xatlasMesh,
    utilization : ^_c.float,
    width : u32,
    height : u32,
    atlasCount : u32,
    chartCount : u32,
    meshCount : u32,
    texelsPerUnit : _c.float,
};

xatlasMeshDecl :: struct {
    vertexPositionData : rawptr,
    vertexNormalData : rawptr,
    vertexUvData : rawptr,
    indexData : rawptr,
    faceIgnoreData : ^_Bool,
    faceMaterialData : ^u32,
    faceVertexCount : ^u8,
    vertexCount : u32,
    vertexPositionStride : u32,
    vertexNormalStride : u32,
    vertexUvStride : u32,
    indexCount : u32,
    indexOffset : i32,
    faceCount : u32,
    indexFormat : xatlasIndexFormat,
    epsilon : _c.float,
};

xatlasUvMeshDecl :: struct {
    vertexUvData : rawptr,
    indexData : rawptr,
    faceMaterialData : ^u32,
    vertexCount : u32,
    vertexStride : u32,
    indexCount : u32,
    indexOffset : i32,
    indexFormat : xatlasIndexFormat,
};

xatlasChartOptions :: struct {
    paramFunc : xatlasParameterizeFunc,
    maxChartArea : _c.float,
    maxBoundaryLength : _c.float,
    normalDeviationWeight : _c.float,
    roundnessWeight : _c.float,
    straightnessWeight : _c.float,
    normalSeamWeight : _c.float,
    textureSeamWeight : _c.float,
    maxCost : _c.float,
    maxIterations : u32,
    useInputMeshUvs : _Bool,
    fixWinding : _Bool,
};

xatlasPackOptions :: struct {
    maxChartSize : u32,
    padding : u32,
    texelsPerUnit : _c.float,
    resolution : u32,
    bilinear : _Bool,
    blockAlign : _Bool,
    bruteForce : _Bool,
    createImage : _Bool,
    rotateChartsToAxis : _Bool,
    rotateCharts : _Bool,
};

@(default_calling_convention="c")
foreign xatlas {

    @(link_name="xatlasCreate")
    xatlasCreate :: proc() -> ^xatlasAtlas ---;

    @(link_name="xatlasDestroy")
    xatlasDestroy :: proc(atlas : ^xatlasAtlas) ---;

    @(link_name="xatlasAddMesh")
    xatlasAddMesh :: proc(atlas : ^xatlasAtlas, meshDecl : ^xatlasMeshDecl, meshCountHint : u32) -> xatlasAddMeshError ---;

    @(link_name="xatlasAddMeshJoin")
    xatlasAddMeshJoin :: proc(atlas : ^xatlasAtlas) ---;

    @(link_name="xatlasAddUvMesh")
    xatlasAddUvMesh :: proc(atlas : ^xatlasAtlas, decl : ^xatlasUvMeshDecl) -> xatlasAddMeshError ---;

    @(link_name="xatlasComputeCharts")
    xatlasComputeCharts :: proc(atlas : ^xatlasAtlas, chartOptions : ^xatlasChartOptions) ---;

    @(link_name="xatlasPackCharts")
    xatlasPackCharts :: proc(atlas : ^xatlasAtlas, packOptions : ^xatlasPackOptions) ---;

    @(link_name="xatlasGenerate")
    xatlasGenerate :: proc(atlas : ^xatlasAtlas, chartOptions : ^xatlasChartOptions, packOptions : ^xatlasPackOptions) ---;

    @(link_name="xatlasSetProgressCallback")
    xatlasSetProgressCallback :: proc(atlas : ^xatlasAtlas, progressFunc : xatlasProgressFunc, progressUserData : rawptr) ---;

    @(link_name="xatlasSetAlloc")
    xatlasSetAlloc :: proc(reallocFunc : xatlasReallocFunc, freeFunc : xatlasFreeFunc) ---;

    @(link_name="xatlasSetPrint")
    xatlasSetPrint :: proc(print : xatlasPrintFunc, verbose : _Bool) ---;

    @(link_name="xatlasAddMeshErrorString")
    xatlasAddMeshErrorString :: proc(error : xatlasAddMeshError) -> cstring ---;

    @(link_name="xatlasProgressCategoryString")
    xatlasProgressCategoryString :: proc(category : xatlasProgressCategory) -> cstring ---;

    @(link_name="xatlasMeshDeclInit")
    xatlasMeshDeclInit :: proc(meshDecl : ^xatlasMeshDecl) ---;

    @(link_name="xatlasUvMeshDeclInit")
    xatlasUvMeshDeclInit :: proc(uvMeshDecl : ^xatlasUvMeshDecl) ---;

    @(link_name="xatlasChartOptionsInit")
    xatlasChartOptionsInit :: proc(chartOptions : ^xatlasChartOptions) ---;

    @(link_name="xatlasPackOptionsInit")
    xatlasPackOptionsInit :: proc(packOptions : ^xatlasPackOptions) ---;

}
