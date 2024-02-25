
cbuffer constants : register(b0)
{
    float4x4 projection;
    float3   lightvector;
    float3   rotate;
    float3   scale;
    float3   translate;
}

struct vs_in
{
    float3 position : POS;
    float3 normal   : NOR;
    float2 texcoord : TEX;
    uint3  rotation : ROT; // instance rotation
    float3 color    : COL; // instance color
};

struct vs_out
{
    float4 position : SV_POSITION;
    float2 texcoord : TEX;
    float4 color    : COL;
};

Texture2D    mytexture : register(t0);
SamplerState mysampler : register(s0);

float4x4 get_rotation_matrix(float3 r)
{
    float4x4 x = { 1, 0, 0, 0, 0, cos(r.x), -sin(r.x), 0, 0, sin(r.x), cos(r.x), 0, 0, 0, 0, 1 };
    float4x4 y = { cos(r.y), 0, sin(r.y), 0, 0, 1, 0, 0, -sin(r.y), 0, cos(r.y), 0, 0, 0, 0, 1 };
    float4x4 z = { cos(r.z), -sin(r.z), 0, 0, sin(r.z), cos(r.z), 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };

    return mul(mul(x, y), z);
}

vs_out vs_main(vs_in input)
{
    float4x4 scalematrix     = { scale.x, 0, 0, 0, 0, scale.y, 0, 0, 0, 0, scale.z, 0, 0, 0, 0, 1 };
    float4x4 translatematrix = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, translate.x, translate.y, translate.z, 1 };

    float4x4 transform = mul(mul(mul(get_rotation_matrix(1.5708f * input.rotation), get_rotation_matrix(rotate)), scalematrix), translatematrix);

    float light = clamp(dot(mul(input.normal, transform), normalize(-lightvector)), 0.0f, 1.0f) * 0.8f + 0.2f;

    vs_out output;

    output.position = mul(float4(input.position, 1.0f), mul(transform, projection));
    output.texcoord = input.texcoord;
    output.color    = float4(input.color * light, 1.0f);

    return output;
}

float4 ps_main(vs_out input) : SV_TARGET
{
    return mytexture.Sample(mysampler, input.texcoord) * input.color;
}
