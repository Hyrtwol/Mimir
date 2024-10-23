//#+vet
package raster3d

import "base:intrinsics"
// import "base:runtime"
import "core:fmt"
// import "core:os"
// import win32 "core:sys/windows"
import cv "libs:tlc/canvas"

L :: intrinsics.constant_utf16_cstring

TITLE :: "Mimir Hello"
WIDTH :: 320
HEIGHT :: WIDTH * 3 / 4
CENTER :: true

float4x4 :: cv.float4x4

inchToMm :: 25.4

FitResolutionGate :: enum {
	kFill = 0,
	kOverscan,
}

computeScreenCoordinates :: proc() {}
convertToRaster :: proc() {}
edgeFunction :: proc() {}

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

main :: proc() {
	fmt.println("hello world")
}
