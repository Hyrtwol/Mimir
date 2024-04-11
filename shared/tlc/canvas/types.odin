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
double2	:: [2]double
double3	:: [3]double

color           :: byte4
color_byte_size :: size_of(color)
color_bit_count	:: color_byte_size * 8
