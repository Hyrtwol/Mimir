// #pragma target 6.1

struct PSInput {
    float4 position : SV_POSITION;
    float2 uv : TEXCOORD;
};

Texture2D g_texture : register(t0);
SamplerState g_sampler : register(s0);

PSInput VSMain(float4 position : POSITION, float2 uv : TEXCOORD, float3 normal : NORMAL) {
    PSInput result;

    result.position = position;
    result.uv = uv;

    return result;
}

//float4 PSMain(PSInput input, float3 baryWeights : SV_Barycentrics) : SV_TARGET
float4 PSMain(PSInput input) : SV_TARGET {
    //return g_texture.Sample(g_sampler, input.uv);
    return float4(input.uv.xy,0,1);
}
