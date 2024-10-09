cbuffer constants : register(b0) {
	float4x4 transform;
	float4x4 projection;
	float3   light_vector;
}

struct vs_in {
	float3 position : POS;
	float3 normal   : NOR;
	float2 texcoord : TEX;
	float3 color    : COL;
};

struct vs_out {
	float4 position : SV_POSITION;
	float2 texcoord : TEX;
	float4 color    : COL;
};

Texture2D    mytexture : register(t0);
SamplerState mysampler : register(s0);

vs_out vs_main(vs_in input) {
	float light = clamp(dot(normalize(mul(transform, float4(input.normal, 0.0f)).xyz), normalize(-light_vector)), 0.0f, 1.0f) * 0.8f + 0.2f;
	vs_out output;
	output.position = mul(projection, mul(transform, float4(input.position, 1.0f)));
	output.texcoord = input.texcoord;
	output.color    = float4(input.color * light, 1.0f);
	return output;
}

float4 ps_main(vs_out input) : SV_TARGET {
	return mytexture.Sample(mysampler, input.texcoord) * input.color;
}

////////

vs_out debug_vs(uint vI : SV_VERTEXID)
{
    float2 texcoord = float2(vI&1,vI>>1);
	vs_out output;
	output.position = float4(texcoord.x * 0.5 + 0.5, texcoord.y * -0.5 - 0.5, 0, 1);
	output.texcoord = texcoord;
	output.color    = float4(1,1,1,1);
	return output;
}

float4 debug_ps(vs_out input) : SV_TARGET
{
	return mytexture.Sample(mysampler, input.texcoord);
}
