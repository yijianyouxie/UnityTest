// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)


#ifndef UNITY_STANDARD_CORE_INCLUDED
#define UNITY_STANDARD_CORE_INCLUDED

#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"
#include "CGIncludes/UnityStandardBRDF.cginc"
#include "CGIncludes/UnityStandardConfig.cginc"
#include "CGIncludes/UnityStandardInput.cginc"
#include "CGIncludes/UnityPBSLighting.cginc"
#include "CGIncludes/UnityStandardUtils.cginc"
#include "UnityGBuffer.cginc"

#include "CGIncludes/TLVertexAnimation.cginc"

#include "CGIncludes/AutoLight.cginc"
#include "CGIncludes/TLStudioCG.cginc"
#include "CGIncludes/DynamicPointLight.cginc"

////////////////////
float Hash(float2 p)
{
	 return frac(sin(dot(p,float2(127.1,311.7)))*43758.5453);
}
float Noise(float2 p)
{
	 float2 i=floor(p);
	 float2 f=frac(p);
	 float2 u=((((f)*(f)))*(((3.0)-(((2.0)*(f))))));
	 return (((-(1.0)))+(((2.0)*(lerp(lerp(Hash(((i)+(float2(0.0,0.0)))),Hash(((i)+(float2(1.0,0.0)))),u.x),lerp(Hash(((i)+(float2(0.0,1.0)))),Hash(((i)+(float2(1.0,1.0)))),u.x),u.y)))));
}
float SeaOctave(float2 uv)
{
	 (uv)+=(Noise(uv));
	 float2 wv=((1.0)-(abs(sin(uv))));
	 float2 swv=abs(cos(uv));
	 (wv)=(lerp(wv,swv,wv));
	 return ((1.0)-(pow(((wv.x)*(wv.y)),0.65)));
}
float3 RippleNormal(in float3 N,in float2 uv,float4 cameraPos)
{
	 float4 jitterUV;
	 half worldscale=5;
	 worldscale=1;
	 (jitterUV)=(((((uv.xyxy)*(float4(1.5,5,5,1.5))))*(worldscale)));
	 float4 seed=((((clamp(((N.xzxz)*(10000)),(-(1)),1))*(float4(20,20,6,6))))*(cameraPos));
	 float R1=((SeaOctave(((((jitterUV.yx)*(10)))-(seed.x))))+(SeaOctave(float2(((((jitterUV.z)*(3)))-(seed.z)),((jitterUV.w)*(3))))));
	 float R3=((SeaOctave(float2(((((jitterUV.xy)*(4)))-(seed.w)))))+(SeaOctave(((((jitterUV.zw)*(8)))-(seed.y)))));
	 (R3)*=(0.5);
	 float R_D=((((((((((R1)*(N.x)))*(N.x)))+(((((R3)*(N.z)))*(N.z)))))*(5)))+(((((R1)+(R3)))*(0.1))));
	 (R_D)*=(((((step(0.5,1))*(1)))*(1.3)));
	 return normalize(lerp(((N)+(float3(0,0,R_D))),N,((0.5)-(((0.2)*(saturate(N.y)))))));
}
float hash(float2 p) 
{
    float h = dot(p, float2(127.1, 311.7));
    return frac(sin(h)*43758.5453123);
}
float GetNoise(float2 p) 
{
    float2 i = floor(p);
    float2 f = frac(p);
    float2 u = f*f*(3.0 - 2.0*f);
    float n = lerp(lerp(hash(i),hash(i + float2(1.0, 0.0)), u.x),lerp(hash(i + float2(0.0, 1.0)),hash(i + 1), u.x), u.y);
    //float2 k = 1 - abs(sin(n + p/3));
    return n;
    //return lerp(k.x + k.y, 0,n);
}
float2 Filpbook(float2 uv, float4 config)
{
    // *** BEGIN Flipbook UV Animation vars ***
	// Total tiles of Flipbook Texture
	float totalTiles = config.x * config.y;
	// Offsets for cols and rows of Flipbook Texture
	float colsOffset = 1.0f / config.x;
	float rowsOffset = 1.0f / config.y;
	// Speed of animation
	float speed = _Time.y * 20.0;
	// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
	// Calculate current tile linear index
	float currentTileIndex = round( fmod( speed, totalTiles) );
	currentTileIndex += ( currentTileIndex < 0) ? totalTiles : 0;
	// Obtain Offset X coordinate from current tile linear index
	float linearIndexToX = round ( fmod ( currentTileIndex, config.x ) );
	// Multiply Offset X by coloffset
	float offsetX = linearIndexToX * colsOffset;
	// Obtain Offset Y coordinate from current tile linear index
	float linearIndexToY = round( fmod( ( currentTileIndex - linearIndexToX ) / config.x, config.y ) );
	// Reverse Y to get tiles from Top to Bottom
	linearIndexToY = (int)(config.y-1) - linearIndexToY;
	// Multiply Offset Y by rowoffset
	float offsetY = linearIndexToY * rowsOffset;
	// UV Offset
	float2 offsetXY = float2(offsetX, offsetY);
	// Flipbook UV
	half2 finalUV = frac( uv ) * float2(colsOffset, rowsOffset) + offsetXY;
	// *** END Flipbook UV Animation vars ***
    return finalUV;
}
////////////////////
//-------------------------------------------------------------------------------------
// counterpart for NormalizePerPixelNormal
// skips normalization per-vertex and expects normalization to happen per-pixel
half3 NormalizePerVertexNormal (float3 n) // takes float to avoid overflow
{
    #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        return normalize(n);
    #else
        return n; // will normalize per-pixel instead
    #endif
}

float3 NormalizePerPixelNormal (float3 n)
{
    #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        return n;
    #else
        return normalize(n);
    #endif
}

//-------------------------------------------------------------------------------------
UnityLight MainLight ()
{
    UnityLight l;

    l.color = _LightColor0.rgb;
    l.dir = _WorldSpaceLightPos0.xyz;
    return l;
}

UnityLight AdditiveLight (half3 lightDir, half atten)
{
    UnityLight l;

    l.color = _LightColor0.rgb;
    l.dir = lightDir;
    #ifndef USING_DIRECTIONAL_LIGHT
        l.dir = NormalizePerPixelNormal(l.dir);
    #endif

    // shadow the light
    l.color *= atten;
    return l;
}

UnityLight DummyLight ()
{
    UnityLight l;
    l.color = 0;
    l.dir = half3 (0,1,0);
    return l;
}

UnityIndirect ZeroIndirect ()
{
    UnityIndirect ind;
    ind.diffuse = 0;
    ind.specular = 0;
    return ind;
}

//-------------------------------------------------------------------------------------
// Common fragment setup

// deprecated
half3 WorldNormal(half4 tan2world[3])
{
    return normalize(tan2world[2].xyz);
}

// deprecated
#ifdef _TANGENT_TO_WORLD
    half3x3 ExtractTangentToWorldPerPixel(half4 tan2world[3])
    {
        half3 t = tan2world[0].xyz;
        half3 b = tan2world[1].xyz;
        half3 n = tan2world[2].xyz;

    #if UNITY_TANGENT_ORTHONORMALIZE
        n = NormalizePerPixelNormal(n);

        // ortho-normalize Tangent
        t = normalize (t - n * dot(t, n));

        // recalculate Binormal
        half3 newB = cross(n, t);
        b = newB * sign (dot (newB, b));
    #endif

        return half3x3(t, b, n);
    }
#else
    half3x3 ExtractTangentToWorldPerPixel(half4 tan2world[3])
    {
        return half3x3(0,0,0,0,0,0,0,0,0);
    }
#endif

float3 PerPixelWorldNormal(float4 i_tex, float4 tangentToWorld[3], float4 i_secondTex, float3 i_posWorld, out float3 noRippleNormal)
{
    UNITY_INITIALIZE_OUTPUT(float3,noRippleNormal);
#ifdef _NORMALMAP
    half3 tangent = tangentToWorld[0].xyz;
    half3 binormal = tangentToWorld[1].xyz;
    half3 normal = tangentToWorld[2].xyz;

    #if UNITY_TANGENT_ORTHONORMALIZE
        normal = NormalizePerPixelNormal(normal);

        // ortho-normalize Tangent
        tangent = normalize (tangent - normal * dot(tangent, normal));

        // recalculate Binormal
        half3 newB = cross(normal, tangent);
        binormal = newB * sign (dot (newB, binormal));
    #endif

    half3 normalTangent = NormalInTangentSpace(i_tex, i_secondTex);
    float3 noRippleNormalT = normalTangent;
//Rain
	if (_rainIntensity > 0)
	{

		float signU = sign(dot(normal, normalize(float3(-1, 0, 0))));
		float signV = sign(dot(normal, normalize(float3(0, 0, -1))));
		float up = saturate(dot(normal, float3(0, 1, 0)));
		float2 speed = lerp(float2(signU, signV), float2(0.4, 0.4), floor(up + 0.01)) * 30;
		float normalScale = lerp(0.6, 0.3, floor(up + 0.01))*0.3;
		float mip = smoothstep(50, 30, length(i_posWorld - _WorldSpaceCameraPos));
		float intensity = _rainIntensity*up + float3(0, 0, 1);
		float noise1 = GetNoise(i_posWorld.xz*_rainTiling*float2(20, 40) + (speed*_Time.x*_flowRate));
		float noise2 = GetNoise(i_posWorld.xz*_rainTiling*float2(10, 20) + (speed*_Time.x*_flowRate));
		//float4 RainNormal = tex2D(_RainNormal, i_posWorld.xz*_rainTiling+frac(speed*_Time.x*_flowRate*_rainTiling));
		//RainNormal += tex2D(_RainNormal, i_posWorld.xz*_rainTiling+frac(speed*_Time.x*_flowRate*_rainTiling*0.5));
		//RainNormal = RainNormal/2;

#ifndef _DETAIL_ON
		float4 rippleConfig = float4(3, 3, 0.3, 0.5);
		float4 RainRippleA = tex2D(_rainRipple, Filpbook(i_posWorld.xz * rippleConfig.z, rippleConfig));
		float4 RainRippleB = tex2D(_rainRipple, Filpbook(i_posWorld.xz * rippleConfig.z + float2(0.3, 0.6), rippleConfig));
		RainRippleA.rgb = UnpackScaleNormal(RainRippleA, noise2*mip*rippleConfig.w);
		RainRippleB.rgb = UnpackScaleNormal(RainRippleB, noise2*mip*rippleConfig.w);
		float3 rippleNormal = BlendNormals(RainRippleA.rgb, RainRippleB.rgb);

		rippleNormal = BlendNormals(rippleNormal, normalTangent);

#endif

		float4 RainNormal = float4(noise1, noise2, 1, 1);
		float3 RainNormalBlend = UnpackScaleNormal(RainNormal, normalScale*mip);
		RainNormalBlend = BlendNormals(normalTangent, RainNormalBlend);

		//RainNormalBlend.xy =normalTangent.xy+RainNormalBlend.xy;
		//RainNormalBlend.z = normalTangent.z*RainNormalBlend.z;
#ifndef _DETAIL_ON
		RainNormalBlend = normalize(lerp(RainNormalBlend, rippleNormal, smoothstep(0.9, 1, up)));
#endif
		normalTangent = lerp(normalTangent, RainNormalBlend, intensity);

	}

//#ifdef _SNOW
//		float4 SnowNormal = tex2D(_SnowNormal, i_posWorld.xz*_SnowNormalTiling);
//		float SnowUp =saturate(dot(normal, float3(0,1,0)));
//		SnowUp = smoothstep(0.5, 0.7, SnowUp);
//		float3 SnowNormalBlend = UnpackScaleNormal(SnowNormal, 1);
//        float SnowIntensity = SnowUp * saturate(_snowCoverage*1.5);
//	    normalTangent = lerp(normalTangent,SnowNormalBlend,SnowIntensity);
//#endif

    float3 normalWorld = NormalizePerPixelNormal(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
    #ifndef _DETAIL_ON
        noRippleNormal = NormalizePerPixelNormal(tangent * noRippleNormalT.x + binormal * noRippleNormalT.y + normal * noRippleNormalT.z);
    #endif
#else
    float3 normalWorld = normalize(tangentToWorld[2].xyz);
#endif

    return normalWorld;
}
#ifdef _PARALLAXMAP
    #define IN_VIEWDIR4PARALLAX(i) NormalizePerPixelNormal(half3(i.tangentToWorldAndPackedData[0].w,i.tangentToWorldAndPackedData[1].w,i.tangentToWorldAndPackedData[2].w))
    #define IN_VIEWDIR4PARALLAX_FWDADD(i) NormalizePerPixelNormal(i.viewDirForParallax.xyz)
#else
    #define IN_VIEWDIR4PARALLAX(i) half3(0,0,0)
    #define IN_VIEWDIR4PARALLAX_FWDADD(i) half3(0,0,0)
#endif

#if UNITY_REQUIRE_FRAG_WORLDPOS
    #if UNITY_PACK_WORLDPOS_WITH_TANGENT
        #define IN_WORLDPOS(i) half3(i.tangentToWorldAndPackedData[0].w,i.tangentToWorldAndPackedData[1].w,i.tangentToWorldAndPackedData[2].w)
    #else
        #define IN_WORLDPOS(i) i.posWorld
    #endif
    #define IN_WORLDPOS_FWDADD(i) i.posWorld
#else
    #define IN_WORLDPOS(i) half3(0,0,0)
    #define IN_WORLDPOS_FWDADD(i) half3(0,0,0)
#endif

#define IN_LIGHTDIR_FWDADD(i) half3(i.tangentToWorldAndLightDir[0].w, i.tangentToWorldAndLightDir[1].w, i.tangentToWorldAndLightDir[2].w)

#ifndef _DETAIL_ON
#define FRAGMENT_SETUP(x) FragmentCommonData x = \
    FragmentSetup(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX(i), i.tangentToWorldAndPackedData, IN_WORLDPOS(i),  float4(0,0,0,0));


#define FRAGMENT_SETUP_FWDADD(x) FragmentCommonData x = \
    FragmentSetup(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX_FWDADD(i), i.tangentToWorldAndLightDir, IN_WORLDPOS_FWDADD(i), float4(0,0,0,0));
#else
#define FRAGMENT_SETUP(x) FragmentCommonData x = \
    FragmentSetup(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX(i), i.tangentToWorldAndPackedData, IN_WORLDPOS(i), i.secondTex);


#define FRAGMENT_SETUP_FWDADD(x) FragmentCommonData x = \
    FragmentSetup(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX_FWDADD(i), i.tangentToWorldAndLightDir, IN_WORLDPOS_FWDADD(i), i.secondTex);

#endif

struct FragmentCommonData
{
    half3 diffColor, specColor;
    // Note: smoothness & oneMinusReflectivity for optimization purposes, mostly for DX9 SM2.0 level.
    // Most of the math is being done on these (1-x) values, and that saves a few precious ALU slots.
    half oneMinusReflectivity, smoothness, occlusion;
    float3 normalWorld;
    float3 eyeVec;
    half alpha, smoothnessBase, snowConfig;
    float3 posWorld;

#if UNITY_STANDARD_SIMPLE
    half3 reflUVW;
#endif

#if UNITY_STANDARD_SIMPLE
    half3 tangentSpaceNormal;
#endif
};

inline FragmentCommonData MetallicSetup (float4 i_tex, float4 i_secondTex = float4(0,0,0,0))
{
	half smoothnessBase;
	float metallicBase;

	half metallic;
	half smoothness; // this is 1 minus the square root of real roughness m.
	float4 uv = float4(i_tex.xy, 0, _SampleBias);

#if defined(_ALPHATEST_ON )||(_ALPHABLEND_ON)
	metallic = _MetallicScale;
	smoothness = tex2Dbias(_ConfigMap, uv).a;
#else
	metallic = tex2Dbias(_MainTex, uv).a * _MetallicScale;
	smoothness = tex2Dbias(_ConfigMap, uv).a;
#endif

	metallicBase = metallic;//正常的金属度，给下雨时单独控制金属部分的光滑度用


#if _DETAIL_ON
	half detailSmoothness = tex2Dbias(_DetailAlbedoMap, uv).w;

	uv.xy = i_secondTex.xy;
	half secondDetailSmoothness = tex2Dbias(_SecondDetailAlbedoMap, uv).w;

	uv.xy = i_secondTex.zw;
	half thirdDetailSmoothness = tex2Dbias(_ThirdDetailAlbedoMap, uv).w;

	half4 mask = tex2D(_DetailMask, i_tex.xy);

	half smoothness1 = (detailSmoothness - 0.05) * mask.x + 0.05;
	half smoothness2 = (secondDetailSmoothness - smoothness1) * mask.y + smoothness1;
	half smoothness3 = (thirdDetailSmoothness - smoothness2) * mask.z + smoothness2;

	smoothness = smoothness3 * smoothness * _GlossScale;
#else
	smoothness *= _GlossScale;
#endif
	smoothnessBase = smoothness;//下雨遮挡用的原始smoothness


	////////////////////////
	half3 albedo = SRGBConvert(tex2D(_MainTex, i_tex.xy).rgb);

#if _DETAIL_ON
	half3 detailAlbedo = tex2D(_DetailAlbedoMap, i_tex.zw).rgb;
	half4 secondDetailAlbedo = tex2D(_SecondDetailAlbedoMap, i_secondTex.xy);
	half3 thirdDetailAlbedo = tex2D(_ThirdDetailAlbedoMap, i_secondTex.zw);
	  
	//half4 mask = tex2D(_DetailMask, i_tex.xy);

	//mask.x 部分体现出来的是detailAlbedo
	half3 color1 = detailAlbedo * mask.x;

	//mask.y 部分体现出来的是secondDetailAlbedo，其余部分为color1
	half3 color2 = (secondDetailAlbedo - color1) * mask.y + color1;

	//mask.z 部分体现出来的是thirdDetailAlbedo，其余部分为color2
	half3 color3 = (thirdDetailAlbedo - color2) * mask.z + color2;

	albedo = color3;
#else
	albedo *= _Color.rgb;
#endif
#if _DEBGU_M
	albedo = fixed4(0.18, 0.18, 0.18, 1);
#endif


    half oneMinusReflectivity;
    half3 specColor;
    half3 diffColor;

	if (_rainIntensity > 0)
	{
		metallic = lerp(metallic, min(0.8, metallic), _rainIntensity);
		smoothness = lerp(smoothness, lerp(1.0, 0.6, metallicBase), _rainSmoothness);
	}

	specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
	oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
	//if (_rainIntensity > 0)
	//{
	//	float specLevel = lerp(0.01, 1, metallic);
	//	specColor = lerp(specColor, specColor*specLevel, _rainIntensity);
	//}
	diffColor = albedo * oneMinusReflectivity;

	FragmentCommonData o = (FragmentCommonData)0;
    o.specColor = specColor;
	o.diffColor = diffColor;
	o.smoothnessBase = smoothnessBase;
    o.oneMinusReflectivity = oneMinusReflectivity;
	o.smoothness = smoothness; 
    return o;
}
// parallax transformed texcoord is used to sample occlusion
// 内部函数全展开
inline FragmentCommonData FragmentSetup (inout float4 i_tex, float3 i_eyeVec, half3 i_viewDirForParallax, float4 tangentToWorld[3], float3 i_posWorld,float4 i_secondTex)
{

	#if defined (SHADER_API_MOBILE)//移动端不用tex2Dbias
	half occ = tex2D(_ConfigMap, i_tex.xy).b;
	#else
	float4 occuv = i_tex;
	occuv.w = _SampleBias;
	half occ = tex2Dbias(_ConfigMap, occuv).b;
	#endif
#if TLSTUDIO_BRDF_HIGH ==0//最低画质节省贴图,ao是1
	occ = 1;
#endif
	half occlusion = LerpOneTo(occ, _OcclusionStrength);

	////////////////////////
	half4 mainTex = tex2D(_MainTex, i_tex.xy);
	half3 albedo = SRGBConvert(mainTex.rgb);
	half alpha;
	#if defined(_ALPHATEST_ON) || (_ALPHABLEND_ON)
		alpha = mainTex.a * _Color.a;
	#else
		alpha = _Color.a;
	#endif
    #if defined(_ALPHATEST_ON)
        clip (alpha - _Cutoff);
    #endif
	//把MetallicSetup算好的部分FragmentCommonData传进来，最后一起return
		FragmentCommonData o;// = UNITY_SETUP_BRDF_INPUT(i_tex, i_secondTex);

	///////////
	half smoothnessBase;
	half metallicBase;

	half metallic;
	half smoothness; // this is 1 minus the square root of real roughness m.
	float4 uv = float4(i_tex.xy, 0, _SampleBias);

#if defined(_ALPHATEST_ON )||(_ALPHABLEND_ON)
	metallic = _MetallicScale;
#else
	metallic = mainTex.a * _MetallicScale;
	//metallic = tex2Dbias(_MainTex, uv).a * _MetallicScale;原来是用图bias的
#endif
	
#if defined (SHADER_API_MOBILE)//移动端不用tex2Dbias
	smoothness = tex2D(_ConfigMap, i_tex.xy).a;
#else
	smoothness = tex2Dbias(_ConfigMap, uv).a;
#endif
#if TLSTUDIO_BRDF_HIGH ==0//最低画质节省贴图,光滑度不用采样而是金属度,越金属越光滑
	smoothness = metallic;
#endif
	metallicBase = metallic;//正常的金属度，给下雨时单独控制金属部分的光滑度用


#if _DETAIL_ON
	half detailSmoothness = tex2D(_DetailAlbedoMap, i_tex.zw).w;

	uv.xy = i_secondTex.xy;
	half secondDetailSmoothness = tex2D(_SecondDetailAlbedoMap, uv).w;

	uv.xy = i_secondTex.zw;
	half thirdDetailSmoothness = tex2D(_ThirdDetailAlbedoMap, uv).w;

	half4 mask = tex2D(_DetailMask, i_tex.xy);

	half smoothness1 = (detailSmoothness - 0.05) * mask.x + 0.05;
	half smoothness2 = (secondDetailSmoothness - smoothness1) * mask.y + smoothness1;
	half smoothness3 = (thirdDetailSmoothness - smoothness2) * mask.z + smoothness2;

	smoothness = smoothness3 * smoothness * _GlossScale;
#else
	smoothness *= _GlossScale;
#endif
	smoothnessBase = smoothness;//下雨遮挡用的原始smoothness
	o.smoothnessBase = smoothnessBase;




#if _DETAIL_ON
	half3 detailAlbedo = tex2D(_DetailAlbedoMap, i_tex.zw).rgb;
	half4 secondDetailAlbedo = tex2D(_SecondDetailAlbedoMap, i_secondTex.xy);
	half3 thirdDetailAlbedo = tex2D(_ThirdDetailAlbedoMap, i_secondTex.zw);
	
	half3 color1 = detailAlbedo * mask.x;//mask.x 部分体现出来的是detailAlbedo
	half3 color2 = (secondDetailAlbedo - color1) * mask.y + color1;//mask.y 部分体现出来的是secondDetailAlbedo，其余部分为color1
	half3 color3 = (thirdDetailAlbedo - color2) * mask.z + color2;//mask.z 部分体现出来的是thirdDetailAlbedo，其余部分为color2

	albedo = color3;
#else
	albedo *= _Color.rgb;
#endif
#if _DEBGU_M
	albedo = fixed4(0.18, 0.18, 0.18, 1);
#endif


	half oneMinusReflectivity;
	half3 specColor;
	half3 diffColor;


	////////////
	float3 noRippleNormal;
	float3 normalWorld;
    //o.normalWorld = PerPixelWorldNormal(i_tex, tangentToWorld, i_secondTex,i_posWorld, noRippleNormal);
	/////////////////////////////////////////
	UNITY_INITIALIZE_OUTPUT(float3, noRippleNormal);
	half3 tangent = tangentToWorld[0].xyz;
	half3 binormal = tangentToWorld[1].xyz;
	half3 normal = tangentToWorld[2].xyz;

	#if UNITY_TANGENT_ORTHONORMALIZE
	normal = NormalizePerPixelNormal(normal);
	tangent = normalize(tangent - normal * dot(tangent, normal));// ortho-normalize Tangent
	half3 newB = cross(normal, tangent);// recalculate Binormal
	binormal = newB * sign(dot(newB, binormal));
	#endif
	half3 normalTangent = NormalInTangentSpace(i_tex, i_secondTex);


	half3 noRippleNormalT = normalTangent;



	half noRippleConfig = 0;
	half4 noise;
	half snowCulling;
#if TLSTUDIO_BRDF_HIGH >0
	if ((_rainIntensity + _snowCoverage)>0)//有雨的情况下
	{
		/////////////////////////////////////////////
		metallic = lerp(metallic, min(0.8, metallic), _rainIntensity);//雨下金属度更强
		smoothness = lerp(smoothness, lerp(1.0, 0.6, metallicBase), _rainSmoothness);//雨下光滑度更高
		/////////////////////////////////////////////////////////////////不管是下雨下雪,都需要计算一个遮挡范围
		noise = tex2D(_SnowNoise, i_posWorld.xz*0.1);
		float snowDTSize = _snowCameraSet.y * 2;
		float2 snowDTOffset = float2((0.5 - frac(_snowCameraSet.x / snowDTSize)), (0.5 - frac(_snowCameraSet.z / snowDTSize)));
		float2 snowDepthUV = float2(i_posWorld.x, i_posWorld.z) / snowDTSize + snowDTOffset;// +(noise.b*0.002 - smoothness * 0.004);//?
#if TLSTUDIO_BRDF_HIGH == 2 //最高级别会多一张图的采样,让遮挡边缘乱一些
		snowDepthUV += (noise.b*0.002 - smoothness * 0.004);
#endif
		
		float4 depthRGBA = tex2D(_SnowDepth, snowDepthUV);

		half depthTex = depthRGBA.r * 255 + depthRGBA.g;//根据CaptureSnowDepth shader解码
		half pixeldepth = i_posWorld.y + _SnowTexConfig;//根据拍摄相机位置调整顶点位置

		snowCulling = (pixeldepth - depthTex);
		snowCulling = smoothstep(_SnowHeight, 0, snowCulling);//增加范围，可以模糊遮挡边界，但落差小的地方遮挡也会相应减弱
		/////////////////////////////////////////////////////////////////
		if (_rainIntensity>0)
		{
			////////////////////////////////////
			half signU = sign(dot(normal, normalize(half3(-1, 0, 0))));
			half signV = sign(dot(normal, normalize(half3(0, 0, -1))));
			half up = saturate(dot(normal, half3(0, 1, 0)));
			half2 speed = lerp(half2(signU, signV), half2(0.4, 0.4), floor(up + 0.01)) * 30;
			half normalScale = lerp(0.6, 0.3, floor(up + 0.01))*0.3;
			half mip = smoothstep(50, 30, length(i_posWorld - _WorldSpaceCameraPos));
			half intensity = _rainIntensity*up + half3(0, 0, 1);
			half noise1 = GetNoise(i_posWorld.xz*_rainTiling*half2(20, 40) + (speed*_Time.x*_flowRate));
			half noise2 = GetNoise(i_posWorld.xz*_rainTiling*half2(10, 20) + (speed*_Time.x*_flowRate));
			//float4 RainNormal = tex2D(_RainNormal, i_posWorld.xz*_rainTiling+frac(speed*_Time.x*_flowRate*_rainTiling));
			//RainNormal += tex2D(_RainNormal, i_posWorld.xz*_rainTiling+frac(speed*_Time.x*_flowRate*_rainTiling*0.5));
			//RainNormal = RainNormal/2;

#ifndef _DETAIL_ON
			half4 rippleConfig = half4(3, 3, 0.3, 0.5);
			half4 RainRippleA = tex2D(_rainRipple, Filpbook(i_posWorld.xz * rippleConfig.z, rippleConfig));
			half4 RainRippleB = tex2D(_rainRipple, Filpbook(i_posWorld.xz * rippleConfig.z + half2(0.3, 0.6), rippleConfig));
			RainRippleA.rgb = UnpackScaleNormal(RainRippleA, noise2*mip*rippleConfig.w);
			RainRippleB.rgb = UnpackScaleNormal(RainRippleB, noise2*mip*rippleConfig.w);
			half3 rippleNormal = RainRippleA.rgb;
#if TLSTUDIO_BRDF_HIGH == 2 //最高级别有2个法线波纹效果
			rippleNormal = BlendNormals(RainRippleA.rgb, RainRippleB.rgb);
#endif
			rippleNormal = BlendNormals(rippleNormal, normalTangent);
#endif

			half4 RainNormal = half4(noise2, noise2, 1, 1);
#if TLSTUDIO_BRDF_HIGH == 2 //最高级别会考虑第二个噪声,效果不是很明显
			RainNormal.x = noise1;
#endif
			half3 RainNormalBlend = UnpackScaleNormal(RainNormal, normalScale*mip);
			RainNormalBlend = BlendNormals(normalTangent, RainNormalBlend);

#ifndef _DETAIL_ON
			RainNormalBlend = normalize(lerp(RainNormalBlend, rippleNormal, smoothstep(0.9, 1, up)));
#endif
			normalTangent = lerp(normalTangent, RainNormalBlend, intensity);//下雨的时候要算一个新的normalTangent



			noRippleConfig = snowCulling;
			smoothness = lerp(o.smoothnessBase, smoothness, noRippleConfig);//遮挡部分光滑度往回走
		}
		specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);//float specLevel = lerp(0.01, 1, metallic);specColor = lerp(specColor, specColor*specLevel, _rainIntensity);
		oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
		diffColor = albedo * oneMinusReflectivity;

		normalWorld = NormalizePerPixelNormal(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
#ifndef _DETAIL_ON
		noRippleNormal = NormalizePerPixelNormal(tangent * noRippleNormalT.x + binormal * noRippleNormalT.y + normal * noRippleNormalT.z);
		normalWorld = lerp(noRippleNormal, normalWorld, noRippleConfig);
#endif
		
	if (_snowCoverage>0)
	{
		half coverage = dot(tangentToWorld[2].xyz, half3(0, 1, 0));
		half noCoverage = coverage;
#ifdef _LEAF_ON
		coverage = smoothstep(0.4, 0.6, coverage);
		noCoverage = smoothstep(0.5, 0.4, noCoverage);
#else
		coverage = saturate(coverage);
		coverage = smoothstep(0.4, 0.6, coverage);//模型法线的哪些部分盖雪
		noCoverage = smoothstep(0.4, 0.3, saturate(noCoverage));
#endif
		half up = saturate(coverage - 1 + _snowCoverage * 2);
		half noCoverageNormalSnow = smoothstep(0.2, 0.4, saturate(dot(normalWorld, half3(0, 1, 0))));
		half3 SnowNormal = UnpackScaleNormal(half4(noise.rg, 1, 1), 2);
		half3 SnowNormalWorld = NormalizePerPixelNormal(tangentToWorld[0] * SnowNormal.x + tangentToWorld[1] * SnowNormal.y + tangentToWorld[2] * SnowNormal.z);
		half3 SnowNormalWorldNew = normalize(lerp(SnowNormalWorld, normalWorld, 0.2));//雪地稍微混入一点原来的法线细节
		half3 SnowNormalWorldNew1 = normalize(lerp(SnowNormalWorld, normalWorld, 0.5));//增加阴影里的雪地细节用
		half SnowDiff = dot(SnowNormalWorldNew1, UnityWorldSpaceLightDir(i_posWorld))*0.6 + 0.6;
		o.snowConfig = up*snowCulling;

		half3 fillLightColorSnow = _SnowColor.rgb;
#if TLSTUDIO_BRDF_HIGH == 2
		normalWorld = lerp(normalWorld, SnowNormalWorldNew, o.snowConfig);
		smoothness = lerp(smoothness, noise.a, o.snowConfig);
		fillLightColorSnow = lerp(fillLightColor, _SnowColor.rgb, SnowDiff);
#endif
		diffColor = lerp(lerp(diffColor, _SnowColor.rgb, noCoverageNormalSnow*noCoverage*snowCulling), fillLightColorSnow, o.snowConfig);
	
		occlusion = lerp(occlusion, 1, o.snowConfig);
	}
	}
	else
#endif
	{
		specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);//float specLevel = lerp(0.01, 1, metallic);specColor = lerp(specColor, specColor*specLevel, _rainIntensity);
		oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
		diffColor = albedo * oneMinusReflectivity;

		normalWorld = NormalizePerPixelNormal(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well


	}
#ifndef _NORMALMAP
	normalWorld = normalize(tangentToWorld[2].xyz);
#endif
	o.normalWorld = normalWorld;
	o.occlusion = occlusion;
	o.specColor = specColor;
	o.diffColor = diffColor;
	o.oneMinusReflectivity = oneMinusReflectivity;
	o.smoothness = smoothness;

    o.eyeVec = NormalizePerPixelNormal(i_eyeVec);
    o.posWorld = i_posWorld;

    // NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
    o.diffColor = PreMultiplyAlpha (o.diffColor, alpha, o.oneMinusReflectivity, /*out*/ o.alpha);
    return o;
}

inline UnityGI FragmentGI (FragmentCommonData s, half occlusion, half4 i_ambientOrLightmapUV, half atten, UnityLight light, bool reflections)
{
    UnityGIInput d;
    d.light = light;
    d.worldPos = s.posWorld;
    d.worldViewDir = -s.eyeVec;
    d.atten = atten;
    #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
        d.ambient = 0;
        d.lightmapUV = i_ambientOrLightmapUV;
    #else
        d.ambient = i_ambientOrLightmapUV.rgb;
        d.lightmapUV = 0;
    #endif

    d.probeHDR[0] = unity_SpecCube0_HDR;
    d.probeHDR[1] = unity_SpecCube1_HDR;
    #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
      d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
    #endif
    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
      d.boxMax[0] = unity_SpecCube0_BoxMax;
      d.probePosition[0] = unity_SpecCube0_ProbePosition;
      d.boxMax[1] = unity_SpecCube1_BoxMax;
      d.boxMin[1] = unity_SpecCube1_BoxMin;
      d.probePosition[1] = unity_SpecCube1_ProbePosition;
    #endif

    if(reflections)
    {
        Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.smoothness, -s.eyeVec, s.normalWorld, s.specColor);
        // Replace the reflUVW if it has been compute in Vertex shader. Note: the compiler will optimize the calcul in UnityGlossyEnvironmentSetup itself
        #if UNITY_STANDARD_SIMPLE
            g.reflUVW = s.reflUVW;
        #endif

        return UnityGlobalIllumination (d, occlusion, s.normalWorld, g);
    }
    else
    {
        return UnityGlobalIllumination (d, occlusion, s.normalWorld);
    }
}

inline UnityGI FragmentGI (FragmentCommonData s, half occlusion, half4 i_ambientOrLightmapUV, half atten, UnityLight light)
{
    return FragmentGI(s, occlusion, i_ambientOrLightmapUV, atten, light, true);
}


//-------------------------------------------------------------------------------------
half4 OutputForward (half4 output, half alphaFromSurface)
{
    #if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
        output.a = alphaFromSurface;
    #else
        UNITY_OPAQUE_ALPHA(output.a);
    #endif
    return output;
}

inline half4 VertexGIForward(VertexInput v, float3 posWorld, half3 normalWorld)
{
    half4 ambientOrLightmapUV = 0;
    // Static lightmaps
    #ifdef LIGHTMAP_ON
        ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
        ambientOrLightmapUV.zw = 0;
    // Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
    #elif UNITY_SHOULD_SAMPLE_SH
        #ifdef VERTEXLIGHT_ON
            // Approximated illumination from non-important point lights
            ambientOrLightmapUV.rgb = Shade4PointLights (
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, posWorld, normalWorld);
        #endif

        ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, ambientOrLightmapUV.rgb);
    #endif

    #ifdef DYNAMICLIGHTMAP_ON
        ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    #endif

    return ambientOrLightmapUV;
}

// ------------------------------------------------------------------
//  Base forward pass (directional light, emission, lightmaps, ...)

struct VertexOutputForwardBase
{
    UNITY_POSITION(pos);
    float4 tex                            : TEXCOORD0;
    float3 eyeVec                         : TEXCOORD1;
    float4 tangentToWorldAndPackedData[3] : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
    half4 ambientOrLightmapUV             : TEXCOORD5;    // SH or Lightmap UV
#if !defined (UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
    UNITY_SHADOW_COORDS(6)
    UNITY_FOG_COORDS(7)
#else
    UNITY_LIGHTING_COORDS(6,7)
    UNITY_FOG_COORDS(8)
#endif
        // next ones would not fit into SM2.0 limits, but they are always for SM3.0+
    #if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
        float3 posWorld                 : TEXCOORD9;
    #endif
#if _DETAIL_ON
	half4 secondTex						: TEXCOORD10;
#endif
    float4 vertexColor : TEXCOORD11;	
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


VertexOutputForwardBase vertForwardBase (VertexInput v)
{
    UNITY_SETUP_INSTANCE_ID(v);
    VertexOutputForwardBase o;
    UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBase, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	#if defined(_LEAF_ON)
    float2 animParams = float2(v.color.y, v.color.z);
    v.vertex = AnimateVertex(v.vertex, v.normal, animParams);
	#endif
    float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
    #if UNITY_REQUIRE_FRAG_WORLDPOS
        #if UNITY_PACK_WORLDPOS_WITH_TANGENT
            o.tangentToWorldAndPackedData[0].w = posWorld.x;
            o.tangentToWorldAndPackedData[1].w = posWorld.y;
            o.tangentToWorldAndPackedData[2].w = posWorld.z;
        #else
            o.posWorld = posWorld.xyz;
        #endif
    #endif
    o.pos = UnityObjectToClipPos(v.vertex);
    o.tex = TexCoords(v);

#if _DETAIL_ON
	o.secondTex = SecondTexCoords(v);
#endif

	  #ifdef _LEAF_ON
				float3 worldSpaceLightDir = UnityWorldSpaceLightDir( posWorld.xyz);
               float3 lightDir = mul(unity_WorldToObject,normalize(worldSpaceLightDir.xyz*float3(-1,0,-1)));
			    float dir = (dot(normalize(lightDir), float3(0,0,-1))+1)/2;
                 int index =0;
                if(lightDir.x >0)
				     index =dir*15;
                else
                     index =31-dir*15;
                index =round(index);
                // 这里要强转为float，是因为在es3平台上编译shader会报这个错（ 'asint': no matching 1 parameter intrinsic function; Possible intrinsic functions are: asint(float|half|int|uint) ）
                int code = asint((float)v.color.a);
                // 根据光的方向来取出特定的位
                float ShadowMask = (fixed)(code >> index & 0x00000001);
               // o.vertexcolor.rgb = saturate(pow(distance(float3(0,0,0),v.vertex.xyz)/2.5,4));
                o.vertexColor.rgb =v.color.rgb;
	            o.vertexColor.a = saturate(ShadowMask);
      #else
	    o.vertexColor = fixed4(1,1,1,1);
	  #endif

    o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
    float3 normalWorld = UnityObjectToWorldNormal(v.normal);
    #ifdef _TANGENT_TO_WORLD
        float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

        float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
        o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
        o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
        o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
    #else
        o.tangentToWorldAndPackedData[0].xyz = 0;
        o.tangentToWorldAndPackedData[1].xyz = 0;
        o.tangentToWorldAndPackedData[2].xyz = normalWorld;
    #endif

    //We need this for shadow receving
    UNITY_TRANSFER_LIGHTING(o, v.uv1);

    o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);

    //UNITY_TRANSFER_FOG(o,o.pos);
	TL_TRANSFER_FOG(o,o.pos,v.vertex);
    return o;
}
half4 fragForwardBaseInternal (VertexOutputForwardBase i)
{
    UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

    FRAGMENT_SETUP(s)

    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    UnityLight mainLight = MainLight ();
#ifndef _LEAF_ON

	UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);

#else

	#if defined(LIGHTMAP_ON)
		fixed4 rawOcclusionMask = UNITY_SAMPLE_TEX2D(unity_ShadowMask, i.ambientOrLightmapUV.xy);
		fixed atten = saturate(dot(rawOcclusionMask, unity_OcclusionMaskSelector));
	#else
		UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);
	#endif
#endif
    
    #ifdef _LEAF_ON
        atten =saturate(min(atten,saturate(i.vertexColor.a+_ShadowIntensity+ max (0,dot (i.tangentToWorldAndPackedData[2],mainLight.dir))*_AOAdd)));
    #endif

    #ifdef _SHOW_ATTEN
      return half4(atten, 0, 0, 1);
    #endif

	// 由于在BRDF中已经把ao作用到最终的颜色，所以这里间接光的处理不需要加上ao，直接使用1
    UnityGI gi = FragmentGI (s, s.occlusion, i.ambientOrLightmapUV, atten, mainLight);
    half4 treeParam = half4(diffwrap, i.vertexColor.r, _AOIntensity, _AOAdd);

#ifdef _SHOW_DIFFUSE
	return half4(gi.indirect.diffuse, 1);
#endif



	half4 c = TLSTUDIO_BRDF_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity,
		s.smoothness, s.normalWorld, -s.eyeVec, TreeAmbientTop, TreeAmbientMiddle,
		TreeAmbientDown, gi.light, gi.indirect, treeParam);

#if TLSTUDIO_BRDF_HIGH == 2
	if (_DynamicPointLight == 1)
	{
		if (_GlobalOrLocalDynamicPointLight == 1)
		{
			for (int index = 0; index < _DynamicPointLightNum; index++)
			{

				unityShadowCoord3 lightCoord = mul(_GlobalWorldToLight[index], unityShadowCoord4(s.posWorld, 1)).xyz;
				fixed shadow = UNITY_SHADOW_ATTENUATION(i, s.posWorld);
				fixed attenpoint = tex2D(_DynamicLightTexture0, dot(lightCoord, lightCoord).rr).r;
				//int kkk = int(clamp(dot(lightCoord, lightCoord), 0, 1) * 1022);
				//float attenpoint = _DynamicLightAttenuationArray[kkk];

				float3 lightVector = _GlobalPointLightPos[index] - s.posWorld;
				float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);
				half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));

				float shakefactor = _GlobalPointLightShakeFactor[index];
				float3 shakeOffset = float3(0, 0, 0);
				shakeOffset.x = sin(_Time.z * shakefactor);
				shakeOffset.y = sin(_Time.z * shakefactor + 5);
				shakeOffset.z = cos(_Time.z * shakefactor + 7);
				lightDirection += shakeOffset * 0.07;

				UnityLight pointLight;
				pointLight.color = _GlobalPointLightColor[index];
				pointLight.dir = normalize(lightDirection);
				pointLight.color *= attenpoint;

				//c.rgb += fixed3(attenpoint, attenpoint, attenpoint);
				UnityIndirect noIndirect = ZeroIndirect();
				c.rgb += BRDF3_Unity_PBS_DPL(s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, pointLight, noIndirect).rgb;
				//c.rgb+= fixed3(0.1,0.1,0.1);
				//c.rgb += LightweightFragmentPBR(index, s.diffColor, _MetallicScale, s.specColor, s.smoothness, occlusion, gi.indirect.diffuse, s.normalWorld, -s.eyeVec,
				//	_PointLightPos[index], half4(_PointLightRange[index], _PointLightIntensity[index],1,1), _PointLightColor[index], s.posWorld, _PointLightShakeFactor[index]);

			}
		}
		else
		{
			for (int index = 0; index < _DynamicPointLightNum; index++)
			{

				unityShadowCoord3 lightCoord = mul(_WorldToLight[index], unityShadowCoord4(s.posWorld, 1)).xyz;
				fixed shadow = UNITY_SHADOW_ATTENUATION(i, s.posWorld);
				fixed attenpoint = tex2D(_DynamicLightTexture0, dot(lightCoord, lightCoord).rr).r;
				//int kkk = int(clamp(dot(lightCoord, lightCoord), 0, 1) * 1022);
				//float attenpoint = _DynamicLightAttenuationArray[kkk];

				float3 lightVector = _PointLightPos[index] - s.posWorld;
				float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);
				half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));

				float shakefactor = _PointLightShakeFactor[index];
				float3 shakeOffset = float3(0, 0, 0);
				shakeOffset.x = sin(_Time.z * shakefactor);
				shakeOffset.y = sin(_Time.z * shakefactor + 5);
				shakeOffset.z = cos(_Time.z * shakefactor + 7);
				lightDirection += shakeOffset * 0.07;

				UnityLight pointLight;
				pointLight.color = _PointLightColor[index];
				pointLight.dir = normalize(lightDirection);
				pointLight.color *= attenpoint;

				//c.rgb += fixed3(attenpoint, attenpoint, attenpoint);
				UnityIndirect noIndirect = ZeroIndirect();
				c.rgb += BRDF3_Unity_PBS_DPL(s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, pointLight, noIndirect).rgb;
				//c.rgb+= fixed3(0.1,0.1,0.1);
				//c.rgb += LightweightFragmentPBR(index, s.diffColor, _MetallicScale, s.specColor, s.smoothness, occlusion, gi.indirect.diffuse, s.normalWorld, -s.eyeVec,
				//	_PointLightPos[index], half4(_PointLightRange[index], _PointLightIntensity[index],1,1), _PointLightColor[index], s.posWorld, _PointLightShakeFactor[index]);

			}
		}

	}
#endif


    c.rgb += Emission(i.tex.xy);

    //UNITY_APPLY_FOG(i.fogCoord, c.rgb);
	TL_APPLY_FOG(i.fogCoord, c.rgb);

    return OutputForward (c, s.alpha);
}

half4 fragForwardBase (VertexOutputForwardBase i) : SV_Target   // backward compatibility (this used to be the fragment entry function)
{
    return fragForwardBaseInternal(i);
}

// ------------------------------------------------------------------
//  Additive forward pass (one light per pass)

struct VertexOutputForwardAdd
{
    UNITY_POSITION(pos);
    float4 tex                          : TEXCOORD0;
    float3 eyeVec                       : TEXCOORD1;
    float4 tangentToWorldAndLightDir[3] : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:lightDir]
    float3 posWorld                     : TEXCOORD5;
#if !defined (UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
    UNITY_SHADOW_COORDS(6)
    UNITY_FOG_COORDS(7)
#else
    UNITY_LIGHTING_COORDS(6, 7)
    UNITY_FOG_COORDS(8)
#endif

    // next ones would not fit into SM2.0 limits, but they are always for SM3.0+
#if defined(_PARALLAXMAP)
    half3 viewDirForParallax            : TEXCOORD8;
#endif

	half4 secondTex						: TEXCOORD9;
	float4 vertexColor					: TEXCOORD10;
    UNITY_VERTEX_OUTPUT_STEREO
};


VertexOutputForwardAdd vertForwardAdd (VertexInput v)
{
    UNITY_SETUP_INSTANCE_ID(v);
    VertexOutputForwardAdd o;
    UNITY_INITIALIZE_OUTPUT(VertexOutputForwardAdd, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	#if defined(_LEAF_ON)
    float2 animParams = float2(v.color.y, v.color.z);
    v.vertex = AnimateVertex(v.vertex, v.normal, animParams);
	#endif

    float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
    o.pos = UnityObjectToClipPos(v.vertex);

    o.tex = TexCoords(v);
    o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
    o.posWorld = posWorld.xyz;
    float3 normalWorld = UnityObjectToWorldNormal(v.normal);
    #ifdef _TANGENT_TO_WORLD
        float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

        float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
        o.tangentToWorldAndLightDir[0].xyz = tangentToWorld[0];
        o.tangentToWorldAndLightDir[1].xyz = tangentToWorld[1];
        o.tangentToWorldAndLightDir[2].xyz = tangentToWorld[2];
    #else
        o.tangentToWorldAndLightDir[0].xyz = 0;
        o.tangentToWorldAndLightDir[1].xyz = 0;
        o.tangentToWorldAndLightDir[2].xyz = normalWorld;
    #endif
    //We need this for shadow receiving and lighting
    UNITY_TRANSFER_LIGHTING(o, v.uv1);

    float3 lightDir = _WorldSpaceLightPos0.xyz - posWorld.xyz * _WorldSpaceLightPos0.w;
    #ifndef USING_DIRECTIONAL_LIGHT
        lightDir = NormalizePerVertexNormal(lightDir);
    #endif
    o.tangentToWorldAndLightDir[0].w = lightDir.x;
    o.tangentToWorldAndLightDir[1].w = lightDir.y;
    o.tangentToWorldAndLightDir[2].w = lightDir.z;

    #ifdef _PARALLAXMAP
        TANGENT_SPACE_ROTATION;
        o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
    #endif

    //UNITY_TRANSFER_FOG(o,o.pos);
	TL_TRANSFER_FOG(o,o.pos,v.vertex);
    return o;
}

half4 fragForwardAddInternal (VertexOutputForwardAdd i)
{
    UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

    FRAGMENT_SETUP_FWDADD(s)

    UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld)
    UnityLight light = AdditiveLight (IN_LIGHTDIR_FWDADD(i), atten);
    UnityIndirect noIndirect = ZeroIndirect ();
	//s.diffColor = atten;

	half4 treeParam = half4(diffwrap, i.vertexColor.r, _AOIntensity, _AOAdd);

	half4 c = BRDF1_Unity_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity,
		s.smoothness, s.normalWorld, -s.eyeVec, TreeAmbientTop, TreeAmbientMiddle,
		TreeAmbientDown, light, noIndirect, treeParam);


    //half4 c = BRDF1_Unity_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, light, noIndirect);

    //UNITY_APPLY_FOG_COLOR(i.fogCoord, c.rgb, half4(0,0,0,0)); // fog towards black in additive pass
	TL_APPLY_FOG(i.fogCoord, c.rgb);
    return OutputForward (c, s.alpha);
}

half4 fragForwardAdd (VertexOutputForwardAdd i) : SV_Target     // backward compatibility (this used to be the fragment entry function)
{
    return fragForwardAddInternal(i);
}

//
// Old FragmentGI signature. Kept only for backward compatibility and will be removed soon
//

inline UnityGI FragmentGI(
    float3 posWorld,
    half occlusion, half4 i_ambientOrLightmapUV, half atten, half smoothness, half3 normalWorld, half3 eyeVec,
    UnityLight light,
    bool reflections)
{
    // we init only fields actually used
    FragmentCommonData s = (FragmentCommonData)0;
    s.smoothness = smoothness;
    s.normalWorld = normalWorld;
    s.eyeVec = eyeVec;
    s.posWorld = posWorld;
    return FragmentGI(s, occlusion, i_ambientOrLightmapUV, atten, light, reflections);
}
inline UnityGI FragmentGI (
    float3 posWorld,
    half occlusion, half4 i_ambientOrLightmapUV, half atten, half smoothness, half3 normalWorld, half3 eyeVec,
    UnityLight light)
{
    return FragmentGI (posWorld, occlusion, i_ambientOrLightmapUV, atten, smoothness, normalWorld, eyeVec, light, true);
}

#endif // UNITY_STANDARD_CORE_INCLUDED
