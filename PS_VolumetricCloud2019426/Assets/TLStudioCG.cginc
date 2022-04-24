#ifndef TLSTUDIO_CG_INCLUDED
#define TLSTUDIO_CG_INCLUDED

#include "UnityCG.cginc"

// fog stuff
float4 FogInfo;
float4 FogColor;
float4 FogColor2;
float4 FogColor3;
float4 FogInfo2;
float  HeightMinFactor;
half3 _FogRefLight;

void HeightTransferFog(inout float4 fogCoord, float4 pos, float4 objPos)
{
	UNITY_INITIALIZE_OUTPUT(float4, fogCoord);
	float4 worldPos = mul(unity_ObjectToWorld, objPos);
	float3 worldToCamDir =  _WorldSpaceCameraPos - worldPos;
	fogCoord.xyz = normalize(worldToCamDir);

	half distToStart = max(0,(length(worldToCamDir)-FogInfo.x));
	half heightFactor=saturate(worldPos.y * FogInfo.z + FogInfo.w);
	heightFactor *= heightFactor;
	heightFactor *= heightFactor;
	fogCoord.w = 1.0- (exp(((-distToStart) * (max(FogInfo.y * heightFactor, 0.1 * FogInfo.y)))));
	fogCoord.w *= fogCoord.w;
}

#if defined(UNITY_FOG_COORDS)
	#undef UNITY_FOG_COORDS
	#define UNITY_FOG_COORDS(idx) UNITY_FOG_COORDS_PACKED(idx, float4)
#endif
#define TL_TRANSFER_FOG(o, outpos, objPos)	HeightTransferFog(o.fogCoord, outpos, objPos)

void HeightApplyFog(float4 fogCoord,inout float3 color)
{
	#ifdef UNITY_PASS_FORWARDADD
		// forwardadd里暂不用雾效对光照颜色进行修正，现实世界里一个火球进了雾之后应该还能看到火光的，所以不做处理应该更贴近现实
	#else

		float3 worldToCameraDir = fogCoord.xyz;

		half3 lightDir = normalize(-_FogRefLight);
		float dirFactor = clamp(dot(-worldToCameraDir, lightDir), 0.0, 1.0); 
		dirFactor = dirFactor * dirFactor; 
		half3 dirColor = dirFactor * FogColor3.xyz;

		float3 fogColor=FogColor2.rgb * saturate(worldToCameraDir.y * 5 + 1)  + FogColor + dirColor;

		color = (lerp(color,((color * (1- fogCoord.w))+ fogColor), fogCoord.w));

	#endif
}

#define TL_APPLY_FOG(coord,col)	HeightApplyFog(coord,col)	
void WaterHeightApplyFog(float4 fogCoord,inout float3 color)
{
		float3 worldToCameraDir = fogCoord.xyz;
				half3 lightDir = normalize(-_FogRefLight);
		float dirFactor = clamp(dot(-worldToCameraDir, lightDir), 0.0, 1.0); 
		dirFactor = dirFactor * dirFactor; 
		half3 dirColor = dirFactor * FogColor3.xyz; 

		float3 fogColor=(FogColor2.rgb ) * saturate(worldToCameraDir.y * 5 + 1) ;
		color = (lerp(color,(FogColor + fogColor + dirColor), fogCoord.w));

}

#define TL_APPLY_WATER_FOG(coord,col)	WaterHeightApplyFog(coord,col)	

// gamma linear stuff
#define SRGBConvertSimple 0

float3 SRGBConvert(float3 srgbColor)
{
#ifdef UNITY_COLORSPACE_GAMMA
	#if SRGBConvertSimple
		return srgbColor * srgbColor;
	#else
		return pow(srgbColor, 2.2);
	#endif
#else
	return srgbColor;
#endif
}

float3 LinearToGamma(float3 linearColor)
{
#ifdef UNITY_COLORSPACE_GAMMA
	#if SRGBConvertSimple
		return sqrt(linearColor);
	#else
		//return pow(linearColor, 0.4545);
		return float3(LinearToGammaSpaceExact(linearColor.r), LinearToGammaSpaceExact(linearColor.g), LinearToGammaSpaceExact(linearColor.b));
	#endif
#else
	return linearColor;
#endif
}

sampler2D_float _SceneDepthTex, _CameraDepthTexture;

float TL_SAMPLE_DEPTH_TEXTURE(float2 coord)
{
#if defined (USE_UNITY_DEPTH_TEX)
	return SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, coord);
#else
	return SAMPLE_DEPTH_TEXTURE(_SceneDepthTex, coord);
#endif
}

fixed _CharToneMapping;

half3 CharTonemapping(half3 color)
{
    const half A = 2.51f;
    const half B = 0.03f;
    const half C = 2.43f;
    const half D = 0.59f;
    const half E = 0.14f;

    half3 toneMappingColor = (color * (A * color + B)) / (color * (C * color + D) + E);
	
    return lerp(color, max(toneMappingColor, 0), _CharToneMapping);
}
#endif // TLSTUDIO_CG_INCLUDED
