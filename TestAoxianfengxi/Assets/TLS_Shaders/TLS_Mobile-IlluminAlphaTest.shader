// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_LightmapInd', a built-in variable
// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D
// Upgrade NOTE: replaced tex2D unity_LightmapInd with UNITY_SAMPLE_TEX2D_SAMPLER

// Simplified Diffuse shader. Differences from regular Diffuse one:
// - no Main Color
// - fully supports only 1 directional light. Other lights can affect it, but it will be per-vertex/SH.

Shader "TLStudio/Transparent/IlluminCutout" {
Properties {
	_Color("Color",Color) = (1.0, 1.0, 1.0, 1.0)
	_MainTex ("Base (RGB)", 2D) = "white" {}
	_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
	_Mask ("Mask (R)", 2D) = "white" {}
	_MaskSpecular("_MaskSpecular", 2D) = "white" {}
	Illumin("Illumin",float) = 0
	_IlluminColor("IlluminColor", Color) = (1,1,1,1)
	
	[Space(20)]
//	_SnowIntensity("Snow Intensity", Range(0, 1)) = 1
//	_SnowColorNew("Snow Color", Color) = (1,1,1,1)
	_SnowCoverage("Snow Coverage", Range(0, 1)) = 1
//	[NoScaleOffset] _SnowTex ("Snow Tex", 2D) = "white" {}
	[NoScaleOffset] _SnowMask ("Snow Mask", 2D) = "white" {}
	[NoScaleOffset] _SnowNormalEx ("Snow NormalEx", Range(0, 1)) = 0.05
	SpecularIntensity("高光强度",Range(0, 3)) = 1

	[HideInInspector]
	_DeltaScale("_DeltaScale", Range(0, 3)) = 1.5
	[HideInInspector]
	_HeightScale("_HeightScale ", Range(0, 1)) = 0.025
	[HideInInspector]
	_NoramlScale("_NoramlScale", Range(0, 3)) = 0.3
	[HideInInspector]
	_BumpDir("_BumpDir", Range(0, 1)) = 0
}
SubShader {
	Tags { "Queue"="AlphaTest+50" "IgnoreProjector"="False" "RenderType"="TransparentCutout" }
	LOD 200
	Cull Off


	// ------------------------------------------------------------
	// Surface shader code generated out of a CGPROGRAM block:
	

	// ---- forward rendering base pass:
	Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		ColorMask RGBA

CGPROGRAM
#pragma skip_variants SHADOWS_CUBE FOG_EXP POINT SPOT
#pragma target 3.0
#pragma skip_variants SHADOWS_CUBE FOG_EXP DIRLIGHTMAP_COMBINED LIGHTMAP_SHADOW_MIXING VERTEXLIGHT_ON POINT SPOT
// compile directives
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma multi_compile_fwdbase
#pragma multi_compile FOG_EXP2 FOG_LINEAR
#include "HLSLSupport.cginc"
#include "UnityShaderVariables.cginc"
#define UNITY_PASS_FORWARDBASE
#include "UnityCG.cginc"
#include "DynamicLight.cginc"
#include "Assets/TLS_Shaders/CGIncludes/Lighting.cginc"
#include "Assets/TLS_Shaders/CGIncludes/AutoLight.cginc"
#include "Assets/TLS_Shaders/CGIncludes/WeatherLibrary.cginc"

#define INTERNAL_DATA
#define WorldReflectionVector(data,normal) data.worldRefl
#define WorldNormalVector(data,normal) normal

// Original surface shader snippet:
#line 14 ""
#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
#endif

//#pragma surface surf Lambert noforwardadd alphatest:_Cutoff

sampler2D _MainTex,_Mask,_MaskSpecular;
	fixed4 _Color,_IlluminColor;
	float Illumin;
	float SpecularIntensity;

	uniform float EnableGlobalSpecular;
	uniform float4 GlobalSpecularLightPos;
	uniform fixed4 GlobalSpecularColor;
	uniform float GlobalSpecularIntensity;
	float4 _MainTex_TexelSize;

struct Input {
	float2 uv_MainTex;
	float3 worldPosition;
	float3 worldNormal;
};

float _EmissionIntensity;

void surf (Input IN, inout SurfaceOutput o) {
	fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
	fixed4 e = tex2D(_Mask, IN.uv_MainTex);
	fixed4 s = tex2D(_MaskSpecular, IN.uv_MainTex);
    float intensity = lerp(0, Illumin, _EmissionIntensity);
	o.Albedo = c.rgb*_Color.rgb+intensity*e.rgb*c.rgb*_IlluminColor.rgb;
	if (_SnowIntensity > 0)
	{
		o.Albedo = BlendSnow(o.Albedo, IN.worldPosition, IN.worldNormal, IN.uv_MainTex);
	}
	o.Alpha = c.a*_Color.a;
	o.Specular = s.r;
}


// vertex-to-fragment interpolation data
		#ifdef LIGHTMAP_OFF
			struct v2f_surf {
				float4 pos : SV_POSITION;
				half2 pack0 : TEXCOORD0;
				// half3 worldNormal : TEXCOORD1;
				// float3 worldPos : TEXCOORD2;
				float4 worldNormal : TEXCOORD1;
				float4 worldTangent : TEXCOORD2;
				float4 worldBinormal : TEXCOORD3;
		#if UNITY_SHOULD_SAMPLE_SH
				half3 sh : TEXCOORD4; // SH
		#endif
				UNITY_SHADOW_COORDS(5)
				UNITY_FOG_COORDS(6)
		#if SHADER_TARGET >= 30
				float4 lmap : TEXCOORD7;
		#endif
		#ifdef GLOBALSH_ENABLE
				float3 vlighting : TEXCOORD8;
		#else
		#endif
			};
		#endif

			// with lightmaps:
		#ifndef LIGHTMAP_OFF
			struct v2f_surf {
			float4 pos : SV_POSITION;
			half2 pack0 : TEXCOORD0;
			// half3 worldNormal : TEXCOORD1;
			// float3 worldPos : TEXCOORD2;
			float4 worldNormal : TEXCOORD1;
			float4 worldTangent : TEXCOORD2;
			float4 worldBinormal : TEXCOORD3;
			float4 lmap : TEXCOORD4;
			UNITY_SHADOW_COORDS(5)
			UNITY_FOG_COORDS(6)
		#ifdef GLOBALSH_ENABLE
			float3 vlighting : TEXCOORD7;
		#else
		#endif
			};
		#endif

			float4 _MainTex_ST;
			fixed _Cutoff;

			// vertex shader
			v2f_surf vert_surf(appdata_full v) {
				v2f_surf o;
				UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				// o.worldPos = worldPos;
				// o.worldNormal = worldNormal;

				float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
		        float3x3 tangentToWorld = CreateTangentToWorldPerVertex(worldNormal, tangentWorld.xyz, tangentWorld.w);
		        o.worldTangent.xyz = tangentToWorld[0];
		        o.worldBinormal.xyz = tangentToWorld[1];
		        o.worldNormal.xyz = tangentToWorld[2];
				o.worldTangent.w = worldPos.x;
		        o.worldBinormal.w = worldPos.y;
		        o.worldNormal.w = worldPos.z;
				
		#ifndef DYNAMICLIGHTMAP_OFF
				o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
		#endif
		#ifndef LIGHTMAP_OFF
				o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		#endif

				// SH/ambient and vertex lights
		#ifdef LIGHTMAP_OFF
		#if UNITY_SHOULD_SAMPLE_SH
				o.sh = 0;
				// Approximated illumination from non-important point lights
		#ifdef VERTEXLIGHT_ON
				o.sh += Shade4PointLights(
					unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
					unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
					unity_4LightAtten0, worldPos, worldNormal);
		#endif
				o.sh = ShadeSHPerVertex(worldNormal, o.sh);
		#endif
		#endif // LIGHTMAP_OFF
		#ifdef GLOBALSH_ENABLE
				o.vlighting = ShadeSH9(float4(worldNormal, 1.0));
		#endif
				UNITY_TRANSFER_SHADOW(o, v.texcoord1); // pass shadow coordinates to pixel shader
				if(UseHeightFog > 0)
				{
					TL_TRANSFER_FOG(o,o.pos, v.vertex);
				}else
				{
					UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader				
				}
				return o;
			}

			// fragment shader
			fixed4 frag_surf(v2f_surf IN) : SV_Target{
				// prepare and unpack data
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT(Input,surfIN);
				surfIN.uv_MainTex.x = 1.0;
				surfIN.uv_MainTex = IN.pack0.xy;
				float3 worldPos = float3(IN.worldTangent.w, IN.worldBinormal.w, IN.worldNormal.w);
				float3 worldNormal = IN.worldNormal.xyz;
				surfIN.worldPosition = worldPos;
				surfIN.worldNormal = worldNormal;
				// return fixed4((normalize(worldNormal)+1)/2,1);
			#ifndef USING_DIRECTIONAL_LIGHT
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
			#else
				fixed3 lightDir = _WorldSpaceLightPos0.xyz;
			#endif
			#ifdef UNITY_COMPILER_HLSL
				SurfaceOutput o = (SurfaceOutput)0;
			#else
				SurfaceOutput o;
			#endif
				o.Albedo = 0.0;
				o.Emission = 0.0;
				o.Specular = 0.0;
				o.Alpha = 0.0;
				o.Gloss = 0.0;
				fixed3 normalWorldVertex = fixed3(0,0,1);
				o.Normal = worldNormal;
				normalWorldVertex = worldNormal;
				if (_RainIntensity > 0)
				{
					o.Normal = RainBubbleNormal(worldPos, IN.worldNormal.xyz, IN.worldTangent.xyz, IN.worldBinormal.xyz, _RainRipple_GI);
				}


				// call surface function
				surf(surfIN, o);

				// alpha test
				clip(o.Alpha - _Cutoff);

				// compute lighting & shadowing factor
				UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
				//atten = 0.5;
				fixed4 c = 0;

				// Setup lighting environment
				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
			#if defined(LIGHTMAP_ON)
				gi.light.color = _LightColor0.rgb;
				gi.light.dir = lightDir*1.5;
				gi.light.ndotl = LambertTerm(o.Normal, gi.light.dir);
			#endif
				// Call GI (lightmaps/SH/reflections) lighting function
				UnityGIInput giInput;
				UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
				giInput.light = gi.light;
				giInput.worldPos = worldPos;
				giInput.atten = atten;
			#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
				giInput.lightmapUV = IN.lmap;
			#else
				giInput.lightmapUV = 0.0;
			#endif
			#if UNITY_SHOULD_SAMPLE_SH && LIGHTMAP_OFF
				giInput.ambient = IN.sh;
			#else
				giInput.ambient.rgb = 0.0;
			#endif
				giInput.probeHDR[0] = unity_SpecCube0_HDR;
				giInput.probeHDR[1] = unity_SpecCube1_HDR;
			#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
				giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
			#endif
			#if UNITY_SPECCUBE_BOX_PROJECTION
				giInput.boxMax[0] = unity_SpecCube0_BoxMax;
				giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
				giInput.boxMax[1] = unity_SpecCube1_BoxMax;
				giInput.boxMin[1] = unity_SpecCube1_BoxMin;
				giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
			#endif
				LightingLambert_GI(o, giInput, gi);

				c += LightingLambert(o, gi);

				if (EnableGlobalSpecular > 0)
				{
					//half atten2 = UnityComputeForwardShadows(IN.lmap, worldPos, 0);
					/*float3 tNormal = UnpackNormal(fixed4(GetNormalByGray(_MainTex, IN.pack0.xy, _MainTex_TexelSize.xy), 1));
					tNormal.xy *= _NoramlScale;
					tNormal.z = sqrt(1.0 - saturate(dot(tNormal.xy, tNormal.xy)));
					float3 worldNormal2 = float3(dot(float3(IN.worldTangent.x, IN.worldBinormal.x, IN.worldNormal.x), tNormal),
						dot(float3(IN.worldTangent.y, IN.worldBinormal.y, IN.worldNormal.y), tNormal),
						dot(float3(IN.worldTangent.z, IN.worldBinormal.z, IN.worldNormal.z), tNormal));*/
					float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - worldPos.xyz);
					float3 lightDirectionCustom = normalize(GlobalSpecularLightPos.xyz);
					float3 halfDirectionCus = normalize(viewDirection + lightDirectionCustom);
					float lhCustom = saturate(dot(lightDirectionCustom, halfDirectionCus));
					float nv = saturate(dot(viewDirection, worldNormal));
					float3 globalSpecular = pow(max(0, dot(halfDirectionCus, worldNormal)), GlobalSpecularLightPos.w);
					//globalSpecular *= lightmap;
					float3 finalGlobalSpecular = /*_MainTex_var.a * */globalSpecular * GlobalSpecularIntensity * FresnelTerm(GlobalSpecularColor.xyz, lhCustom) * pow((1 - nv), 2);
					c.rgb = c.rgb + finalGlobalSpecular * 0.6f * SpecularIntensity * o.Specular;
				}

				//#ifdef GLOBALSH_ENABLE
				//  c.xyz = c.xyz*max(fixed3(1.0,1.0,1.0),(IN.vlighting - UNITY_LIGHTMODEL_AMBIENT.xyz)*2);
				//#endif
				c.rgb = GetDynamicPointLightColor(c.rgb, worldPos, worldNormal);
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(IN.fogCoord, c.rgb);
				}else
				{
					UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog				
				}
				//UNITY_OPAQUE_ALPHA(c.a);
				return c;
			}

			ENDCG

		}
	}
	Fallback "Transparent/Cutout/VertexLit"
}
