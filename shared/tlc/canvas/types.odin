package canvas

byte	:: u8
float	:: f32
double	:: f64
int		:: i32
uint	:: u32

byte4	:: [4]byte
int2	:: [2]int
int3	:: [3]int
uint2	:: [2]uint
uint3	:: [3]uint
float2	:: [2]float
float3	:: [3]float
float4	:: [4]float
double2	:: [2]double
double3	:: [3]double

float2x3 :: matrix[2, 3]float
float3x3 :: matrix[3, 3]float
float4x4 :: matrix[4, 4]float

color           :: byte4
color_byte_size :: size_of(color)
color_bit_count	:: color_byte_size * 8


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
	radius: int,
}
