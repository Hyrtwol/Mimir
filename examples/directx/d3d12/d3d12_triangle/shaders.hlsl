struct PSInput {
	float4 position : SV_POSITION;
	float4 color : COLOR;
};

PSInput VSMain(float4 position : POSITION0, float2 texcoord : TEXCOORD, float3 normal : NORMAL) {
	PSInput result;
	result.position = position;
    //result.uv = texcoord;
	//result.color = float4(normal, 1);
	result.color = float4(0,0,0,1);
	result.color.xy = texcoord;
	//result.color.xyz = normal;
	return result;
}

float4 PSMain(PSInput input) : SV_TARGET {
	return input.color;
}
