// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef UNITY_STANDARD_INPUT_INCLUDED
	#define UNITY_STANDARD_INPUT_INCLUDED

	#include "CGIncludes/TLStudioCG.cginc"
	#include "UnityCG.cginc"

	#include "CGIncludes/UnityStandardConfig.cginc"
	//#include "CGIncludes/UnityPBSLighting.cginc" // TBD: remove
	#include "CGIncludes/UnityStandardUtils.cginc"

	//---------------------------------------
	// Directional lightmaps & Parallax require tangent space too
	#if (_NORMALMAP || DIRLIGHTMAP_COMBINED || _PARALLAXMAP)
		#define _TANGENT_TO_WORLD 1
	#endif

	//---------------------------------------
	half4       _Color;
	half        _Cutoff;

	sampler2D   _MainTex;
	float4      _MainTex_ST;

	sampler2D   _DetailAlbedoMap;
	float4      _DetailAlbedoMap_ST;

	sampler2D   _SecondDetailAlbedoMap;
	float4      _SecondDetailAlbedoMap_ST;

	sampler2D   _ThirdDetailAlbedoMap;
	float4      _ThirdDetailAlbedoMap_ST;

	sampler2D   _DetailMask;

	sampler2D   _ConfigMap;

	half        _BumpScale;

	sampler2D   _DetailNormalMap;
	half        _DetailNormalMapScale;

	sampler2D   _SecondDetailNormalMap;
	half        _SecondDetailNormalMapScale;

	half        _SampleBias;

	half       _MetallicScale;
	half       _GlossScale;
	half       _OcclusionStrength;

	half4       _EmissionColor;
	sampler2D   _EmissionMap;
	//sampler2D _RainNormal;
	half _rainIntensity;
	half _rainSmoothness;
	#ifndef _DETAIL_ON
		sampler2D _rainRipple;
		//float4 _rippleConfig;
	#endif
	half _snowCoverage;
	half3 _SnowColor;
	half3 _snowCameraSet;
	float  _SnowHeight;
	sampler2D _SnowDepth;
	sampler2D _SnowNoise;
	half _SnowTexConfig;
	half _flowRate;
	half _rainTiling;
	float _EmissionIntensity;
	float _EmissionIntensityMax;

	float _AOAdd;
	float _AOIntensity;
	float _ShadowIntensity;
	half4 TreeAmbientTop;
	half4 TreeAmbientMiddle;
	half4 TreeAmbientDown;
	float diffwrap;

	//-------------------------------------------------------------------------------------
	// Input functions

	struct VertexInput
	{
		float4 vertex   : POSITION;
		half3 normal    : NORMAL;
		float2 uv0      : TEXCOORD0;
		float2 uv1      : TEXCOORD1;
		fixed4 color    : COLOR;
		#if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
			float2 uv2      : TEXCOORD2;
		#endif
		#ifdef _TANGENT_TO_WORLD
			half4 tangent   : TANGENT;
		#endif
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	float4 TexCoords(VertexInput v)
	{
		float4 texcoord = float4(0, 0, 0, 0);
		texcoord.xy = TRANSFORM_TEX(v.uv0, _MainTex); // Always source from uv0

#if _DETAIL_ON
		texcoord.zw = TRANSFORM_TEX(v.uv0, _DetailAlbedoMap);
#endif
		return texcoord;
	}

	float4 SecondTexCoords(VertexInput v)
	{
		float4 texcoord = float4(0,0,0,0);
#if _DETAIL_ON
		texcoord.xy = TRANSFORM_TEX(v.uv0, _SecondDetailAlbedoMap); // Always source from uv0
		texcoord.zw = TRANSFORM_TEX(v.uv0, _ThirdDetailAlbedoMap);
#endif
		return texcoord;
	}

	half3 Albedo(float4 texcoords, float4 secondTexCoords)
	{
		half3 albedo = SRGBConvert(tex2D(_MainTex, texcoords.xy).rgb);

		#if _DETAIL_ON
			half3 detailAlbedo = tex2D(_DetailAlbedoMap, texcoords.zw).rgb;
			half4 secondDetailAlbedo = tex2D(_SecondDetailAlbedoMap, secondTexCoords.xy);
			half3 thirdDetailAlbedo = tex2D(_ThirdDetailAlbedoMap, secondTexCoords.zw);

			half4 mask = tex2D(_DetailMask, texcoords.xy);

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
			albedo = fixed4(0.18,0.18,0.18,1);
		#endif
		return albedo;
	}

	half Alpha(float2 uv)
	{
		#if defined(_ALPHATEST_ON )||(_ALPHABLEND_ON)
		return tex2D(_MainTex, uv).a * _Color.a;
		#else
		return _Color.a;
		#endif
	}

	half Occlusion(float4 uv)
	{
		uv.w =  _SampleBias;
		half occ = tex2Dbias(_ConfigMap, uv).b;
	//#ifdef _SNOW
	//	occ = lerp(occ, 1, saturate(_snowCoverage*10));
	//#endif
		return LerpOneTo (occ, _OcclusionStrength);
	}

	half2 MetallicGloss(float4 texcoords, float4 secondTexCoords, out float smoothnessBase)
	{
		half2 mg;

		float4 uv = float4(texcoords.xy,0,_SampleBias);

		#if defined(_ALPHATEST_ON )||(_ALPHABLEND_ON)
		mg.r = _MetallicScale;
		mg.g = tex2Dbias(_ConfigMap, uv).a;
		#else
		mg.r = tex2Dbias(_MainTex, uv).a * _MetallicScale;
		mg.g = tex2Dbias(_ConfigMap, uv).a;
		#endif

		float metallicBase = mg.r;//正常的金属度，给下雨时单独控制金属部分的光滑度用

		
		#if _DETAIL_ON
			half detailSmoothness = tex2Dbias(_DetailAlbedoMap, uv).w;

			uv.xy = secondTexCoords.xy;
			half secondDetailSmoothness = tex2Dbias(_SecondDetailAlbedoMap, uv).w;

			uv.xy = secondTexCoords.zw;
			half thirdDetailSmoothness = tex2Dbias(_ThirdDetailAlbedoMap, uv).w;

			half4 mask = tex2D(_DetailMask, texcoords.xy);

			half smoothness1 = (detailSmoothness - 0.05) * mask.x + 0.05;
			half smoothness2 = (secondDetailSmoothness - smoothness1) * mask.y + smoothness1;
			half smoothness3 = (thirdDetailSmoothness - smoothness2) * mask.z + smoothness2;

			mg.g = smoothness3 * mg.g * _GlossScale;
		#else
			mg.g *= _GlossScale;
		#endif

			if (_rainIntensity > 0)
			{
				mg.r = lerp(mg.r, min(0.8, mg.r), _rainIntensity);

				smoothnessBase = mg.g;//下雨遮挡用的原始smoothness
				mg.g = lerp(mg.g, lerp(1.0, 0.6, metallicBase), _rainSmoothness);;
			}
		
		return mg;
	}

	half3 Emission(float2 uv)
	{
		#ifndef _EMISSION
			return 0;
		#else
			return SRGBConvert(tex2D(_EmissionMap, uv).rgb) * _EmissionColor.rgb*max(_EmissionIntensityMax,_EmissionIntensity);
		#endif
	}

		half3 NormalInTangentSpace(float4 texcoords, float4 secondTexCoords)
		{
			half4 uv = half4(texcoords.xy, 0, _SampleBias);
#if defined (SHADER_API_MOBILE)//移动端不用tex2Dbias //最低画质undef_normal.这里的法线也不会生效
			float2 tempuv2 = tex2D(_ConfigMap, uv).rg;
#else
			float2 tempuv2 = tex2Dbias(_ConfigMap, uv).rg;
#endif
			float4 tempuv4 = float4(tempuv2, 1, 1);
			//half3 normalTangent = UnpackScaleNormal(tex2Dbias (_NormalMapAG, uv), _BumpScale);
			half3 normalTangent = UnpackScaleNormal(tempuv4, _BumpScale);
			//half3 normalTangent = UnpackScaleNormal(tempuv114, _BumpScale);
			#if _DETAIL_ON
				uv.xy = texcoords.zw;
			#if TLSTUDIO_BRDF_HIGH < 2
				half3 detailNormalTangent = half3(0,0,1);
			#else
				half3 detailNormalTangent = UnpackScaleNormal(tex2Dbias (_DetailNormalMap, uv), _DetailNormalMapScale);
			#endif

				uv.xy = secondTexCoords.xy;
			#if TLSTUDIO_BRDF_HIGH < 2//最低画质undef_normal.这里的法线也不会生效
				half3 secondDetailNormalTangent = half3(0,0,1);
			#else
				half3 secondDetailNormalTangent = UnpackScaleNormal(tex2Dbias (_SecondDetailNormalMap, uv), _SecondDetailNormalMapScale);
			#endif

				half4 mask = tex2D(_DetailMask, texcoords.xy);

				//若mask.x = 1则保留detailNormalTangent，否则设置为(0,0,1)
				half3 normal1 = (detailNormalTangent - half3(0,0,1)) * mask.x + half3(0,0,1);

				//若mask.y = 1则保留secondDetailNormalTangent，否则设置为normal1
				half3 normal2 = (secondDetailNormalTangent - normal1) * mask.y + normal1;
				
				//将两层detail的法线细节叠加到底层法线上
				normalTangent.z = normal2.z * normalTangent.z;
				normalTangent.xy = normal2.xy + normalTangent.xy;

				normalTangent = normalize(normalTangent);

			#endif
			return normalTangent;
		}

#endif // UNITY_STANDARD_INPUT_INCLUDED
