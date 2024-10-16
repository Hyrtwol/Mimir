struct PSInput {
	float4 position : SV_POSITION;
	float4 color : COLOR;
};

PSInput VSMain(float4 position : POSITION0, float4 color : COLOR0) {
	PSInput result;
	result.position = position;
	result.color = color;
	return result;
}

float4 PSMain(PSInput input) : SV_TARGET {
	return input.color;
};
