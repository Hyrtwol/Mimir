package canvas

import "core:math"

sbyte    :: i8
byte     :: u8
short    :: i16
ushort   :: u16
integer  :: i32
cardinal :: u32

half     :: f16
float    :: f32
double   :: f64

byte4    :: [4]byte
int2     :: [2]integer
int3     :: [3]integer
uint2    :: [2]cardinal
uint3    :: [3]cardinal
float2   :: [2]float
float3   :: [3]float
float4   :: [4]float
double2  :: [2]double
double3  :: [3]double

float2x2 :: matrix[2, 2]float
float2x3 :: matrix[2, 3]float
float3x2 :: matrix[3, 2]float
float3x3 :: matrix[3, 3]float
float3x4 :: matrix[3, 4]float
float4x3 :: matrix[4, 3]float
float4x4 :: matrix[4, 4]float

color           :: byte4
color_byte_size :: size_of(color)
color_bit_count :: color_byte_size * 8


ray2i: struct {
	pos, dir: int2,
}

ray2f: struct {
	pos, dir: float2,
}

ray3i: struct {
	pos, dir: int3,
}

ray3f: struct {
	pos, dir: float3,
}

circle2f :: struct {
	center: float2,
	radius: float,
}

circle2i :: struct {
	center: int2,
	radius: integer,
}

float2_zero :: float2{0, 0}
float2_one :: float2{1, 1}
float2_xunit :: float2{1, 0}
float2_yunit :: float2{0, 1}

float3_zero :: float3{0, 0, 0}
float3_one :: float3{1, 1, 1}
float3_xunit :: float3{1, 0, 0}
float3_yunit :: float3{0, 1, 0}
float3_zunit :: float3{0, 0, 1}

float4_zero :: float4{0, 0, 0, 0}
float4_one :: float4{1, 1, 1, 1}
float4_xunit :: float4{1, 0, 0, 0}
float4_yunit :: float4{0, 1, 0, 0}
float4_zunit :: float4{0, 0, 1, 0}
float4_wunit :: float4{0, 0, 0, 1}

int2_zero  :: int2{0, 0}
int2_one   :: int2{1, 1}
int2_xunit :: int2{1, 0}
int2_yunit :: int2{0, 1}

PI :: math.PI
TwoPI :: math.PI * 2
HalfPI :: math.PI / 2
