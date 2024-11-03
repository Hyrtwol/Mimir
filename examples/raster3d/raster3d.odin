//#+vet
package raster3d

import "base:intrinsics"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:os"
// import win32 "core:sys/windows"
import cv "libs:tlc/canvas"
import "shared:obug"
import model "../../data/models/cube"

L :: intrinsics.constant_utf16_cstring

TITLE :: "Mimir Hello"
WIDTH :: 320
HEIGHT :: WIDTH * 3 / 4
CENTER :: true

float4x4 :: cv.float4x4
float2 :: cv.float2
float3 :: cv.float3

inchToMm :: 25.4

FitResolutionGate :: enum {
	kFill = 0,
	kOverscan,
}

computeScreenCoordinates :: proc(
    filmApertureSize: [2]f32,
    imageSize: [2]u32,
    fitFilm: FitResolutionGate,
    nearClippingPlane: f32,
    focalLength: f32,
    top, bottom, left, right: ^f32,
) {
    filmAspectRatio := filmApertureSize.x / filmApertureSize.y
    deviceAspectRatio := (f32(imageSize.x) / f32(imageSize.y))

    top^ = ((filmApertureHeight * inchToMm / 2) / focalLength) * nearClippingPlane
    right^ = ((filmApertureWidth * inchToMm / 2) / focalLength) * nearClippingPlane

    // field of view (horizontal)
    fov := math.DEG_PER_RAD * math.atan((filmApertureWidth * inchToMm / 2) / focalLength)
	fmt.println("Field of view" , fov)

    xscale : f32 = 1
    yscale : f32 = 1

    switch (fitFilm) {
	case .kFill:
		if filmAspectRatio > deviceAspectRatio {
			xscale = deviceAspectRatio / filmAspectRatio
		} else {
			yscale = filmAspectRatio / deviceAspectRatio
		}
		break
	case .kOverscan:
		if filmAspectRatio > deviceAspectRatio {
			yscale = filmAspectRatio / deviceAspectRatio
		} else {
			xscale = deviceAspectRatio / filmAspectRatio
		}
		break
    }

    right^ *= xscale
    top^ *= yscale

    bottom^ = -top^
    left^ = -right^
}

multVecMatrix :: proc(x: ^float4x4, src, dst: ^float3) {
	a, b, c, w: f32

	a = src[0] * x[0][0] + src[1] * x[1][0] + src[2] * x[2][0] + x[3][0]
	b = src[0] * x[0][1] + src[1] * x[1][1] + src[2] * x[2][1] + x[3][1]
	c = src[0] * x[0][2] + src[1] * x[1][2] + src[2] * x[2][2] + x[3][2]
	w = src[0] * x[0][3] + src[1] * x[1][3] + src[2] * x[2][3] + x[3][3]

	dst.x = a / w
	dst.y = b / w
	dst.z = c / w
}

convertToRaster :: proc(
	vertexWorld: ^float3,
    worldToCamera: ^float4x4,
    l, r, t, b: f32,
    near: f32,
	imageSize: [2]f32,
    vertexRaster: ^float3,
) {
    vertexCamera: float3

    //worldToCamera.multVecMatrix(vertexWorld, vertexCamera)
	multVecMatrix(worldToCamera, vertexWorld, &vertexCamera)
	//vertexCamera = worldToCamera^ * vertexWorld^

    vertexScreen: float2
    vertexScreen.x = near * vertexCamera.x / -vertexCamera.z
    vertexScreen.y = near * vertexCamera.y / -vertexCamera.z

    vertexNDC: float2
    vertexNDC.x = 2 * vertexScreen.x / (r - l) - (r + l) / (r - l)
    vertexNDC.y = 2 * vertexScreen.y / (t - b) - (t + b) / (t - b)

    vertexRaster.x = (vertexNDC.x + 1) / 2 * imageSize.x
    vertexRaster.y = (1 - vertexNDC.y) / 2 * imageSize.y
    vertexRaster.z = -vertexCamera.z
}

edgeFunction :: proc(a, b, c: float3) -> f32 {
	return (c[0] - a[0]) * (b[1] - a[1]) - (c[1] - a[1]) * (b[0] - a[0])
}

imageWidth :: 640
imageHeight :: 480
worldToCamera: float4x4 : {0.707107, -0.331295, 0.624695, 0, 0, 0.883452, 0.468521, 0, -0.707107, -0.331295, 0.624695, 0, -1.63871, -5.747777, -40.400412, 1}

ntris: u32 : 3156
nearClippingPlane: f32 : 1
farClippingPLane: f32 : 1000
focalLength: f32 = 20 // in mm

// 35mm Full Aperture in inches
filmApertureWidth: f32 = 0.980
filmApertureHeight: f32 = 0.735

run :: proc() -> (exit_code: int) {
	fmt.println("hello world")

	vec := [3]i32{1,5,3}
	fmt.println("max:", max(vec.x, vec.y, vec.z))

	fmt.println("cameraToWorld:", worldToCamera)
	cameraToWorld:= linalg.inverse(worldToCamera)
	fmt.println("cameraToWorld:", cameraToWorld)

	t, b, l, r: f32
	computeScreenCoordinates(
        {filmApertureWidth, filmApertureHeight},
        {imageWidth, imageHeight},
        .kOverscan,
        nearClippingPlane,
        focalLength,
        &t, &b, &l, &r)
	fmt.println("t, b, l, r:", t, b, l, r)

	for v in model.vertices {
		fmt.printfln("v: %v", v)
	}

	return
}

main :: proc() {
    assert(len(model.vertices) == 24)
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}
