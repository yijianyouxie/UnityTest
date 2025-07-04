// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable
// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

Shader "TLStudio/Opaque/LightMapSpecular" {
	Properties{
		_MainColor("Main Color", Color) = (0.5,0.5,0.5,1)
		_SpecularColor("SpecularColor", Color) = (0.5,0.5,0.5,1)
		_Shine("Shine", Range(1, 128)) = 1
		_MainTex("MainTex", 2D) = "white" {}
		_BumpMap("法线贴图",2D) = "bump"{}
		_NormalScale("_NoramlScale", Range(0, 5)) = 1.0
		_ambientColor("AmbientLight", Range(0.1, 1)) = 1
		_lambert("LambertLight",Range(0.1, 1)) = 1
		_LightPos("主光源位置", Vector) = (100,100,100,100)

		[Space(20)]
		[Header(Extra Light)]
		[Toggle]
		_LightPos2Enable("光源2开启", float) = 0
		_LightPos2("光源2位置", Vector) = (100,100,100,100)
		_SpecularIntensity2("光源2强度", Range(0,1)) = 0.5

		[Space(20)]
		[Toggle]
		_LightPos3Enable("光源3开启", float) = 0
		_LightPos3("光源3位置", Vector) = (100,100,100,100)
		_SpecularIntensity3("光源3强度", Range(0,1)) = 0.5
		_SpecularBackPow("额外光Shine", Range(1, 128)) = 1
		
		[Space(20)]
//		_SnowIntensity("Snow Intensity", Range(0, 1)) = 1
//		_SnowColorNew("Snow Color", Color) = (1,1,1,1)
		_SnowCoverage("Snow Coverage", Range(0, 1)) = 1
//		[NoScaleOffset] _SnowTex ("Snow Tex", 2D) = "white" {}
		[NoScaleOffset] _SnowMask ("Snow Mask", 2D) = "white" {}
		[NoScaleOffset] _SnowNormalEx ("Snow NormalEx", Range(0, 1)) = 0.05
	}
	SubShader{
		Tags{
		"RenderType" = "Opaque"
		}
		LOD 200
		Pass{
			Name "ForwardBase"
			Tags{
			"LightMode" = "ForwardBase"
			}
			ColorMask RGBA

			CGPROGRAM
			#pragma skip_variants DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING VERTEXLIGHT_ON SHADOWS_CUBE
	#pragma vertex vert
	#pragma fragment frag
	//#pragma multi_compile GLOBALSH_DISABLE GLOBALSH_ENABLE
	#pragma multi_compile FOG_EXP2 FOG_LINEAR
	//#pragma multi_compile_instancing

	//#pragma multi_compile _ INSTANCE_ENABLE
	#if defined(INSTANCE_ENABLE) && defined(LIGHTMAP_ON)
		#if defined(LIGHTPROBE_SH)
			#undef LIGHTPROBE_SH
		#endif
	#endif
			
	#define UNITY_PASS_FORWARDBASE
	#include "UnityCG.cginc"
	#include "DynamicLight.cginc"
	#include "Assets/TLS_Shaders/CGIncludes/AutoLight.cginc"
	#include "Assets/TLS_Shaders/CGIncludes/Lighting.cginc"
	#define SNOW_COLOR_TYPE 1
	#include "Assets/TLS_Shaders/CGIncludes/WeatherLibrary.cginc"

		//#pragma multi_compile_fwdbase	
	#pragma multi_compile_fwdbase_fullshadows
	#pragma exclude_renderers xbox360 ps3 flash d3d11_9x 
	//#pragma target 3.0
	#ifndef LIGHTMAP_OFF
	#ifndef DIRLIGHTMAP_OFF
	#endif
	#endif
			uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
			uniform float EanbleNormalMap;
			//定义法线贴图变量
			sampler2D _BumpMap;
			float _NormalScale;
			// uniform sampler2D unity_Lightmap;
			// uniform float4 unity_LightmapST;
			uniform fixed4 _MainColor;
			uniform fixed4 _SpecularColor;
			uniform fixed _Shine;
			uniform fixed4 _LightPos;

			uniform float EnableGlobalSpecular;
			uniform float4 GlobalSpecularLightPos;
			uniform fixed4 GlobalSpecularColor;
			uniform float GlobalSpecularIntensity;

			uniform fixed _LightPos2Enable;
			uniform fixed4 _LightPos2;
			fixed _SpecularIntensity2;
			half _SpecularBackPow;

			uniform fixed _LightPos3Enable;
			uniform fixed4 _LightPos3;
			fixed _SpecularIntensity3;
			float _ambientColor;
			float _lambert;
			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 texcoord0 : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float4 uv0 : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float4 worldNormal : TEXCOORD2;
				float4 worldTangent : TEXCOORD3;
				float4 worldBinormal : TEXCOORD4;
				//LIGHTING_COORDS(5,6)
				UNITY_SHADOW_COORDS(5)
		#ifdef GLOBALSH_ENABLE
				float3 vlighting : TEXCOORD6;
		#else
		#endif
				UNITY_FOG_COORDS(7)
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

		#if defined(INSTANCE_ENABLE) && defined(UNITY_INSTANCING_ENABLED) && defined(LIGHTMAP_ON)
			UNITY_INSTANCING_BUFFER_START(Props)
				UNITY_DEFINE_INSTANCED_PROP(fixed4, unity_LightmapST)
			UNITY_INSTANCING_BUFFER_END(Props)
		#endif

			VertexOutput vert(VertexInput v) {
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.uv0.xy = v.texcoord0;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);

				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
		        float3x3 tangentToWorld = CreateTangentToWorldPerVertex(worldNormal, tangentWorld.xyz, tangentWorld.w);
		        o.worldTangent.xyz = tangentToWorld[0];
		        o.worldBinormal.xyz = tangentToWorld[1];
		        o.worldNormal.xyz = tangentToWorld[2];
				o.worldTangent.w = o.posWorld.x;
		        o.worldBinormal.w = o.posWorld.y;
		        o.worldNormal.w = o.posWorld.z;

				
				float3 lightColor = _LightColor0.rgb;
				o.pos = UnityObjectToClipPos(v.vertex);
		#ifndef LIGHTMAP_OFF
				#if defined(INSTANCE_ENABLE) && defined(UNITY_INSTANCING_ENABLED)
						unity_LightmapST = UNITY_ACCESS_INSTANCED_PROP(Props, unity_LightmapST);
				#endif
				o.uv0.zw = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw;
		#endif
		#ifdef GLOBALSH_ENABLE
				o.vlighting = ShadeSH9(float4(worldNormal, 1.0));
		#endif

				UNITY_TRANSFER_SHADOW(o, v.texcoord1);
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				if(UseHeightFog > 0)
				{
					TL_TRANSFER_FOG(o,o.pos, v.vertex);
				}else
				{
					UNITY_TRANSFER_FOG(o,o.pos);				
				}
				return o;
			}
			fixed4 frag(VertexOutput i) : COLOR{
				UNITY_SETUP_INSTANCE_ID(i);
				/////// Vectors:
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				if (EanbleNormalMap > 0)
				{
					float3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv0.xy));
					tangentNormal.xy *= _NormalScale;
					tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
					i.worldNormal.xyz = float3(dot(float3(i.worldTangent.x, i.worldBinormal.x, i.worldNormal.x), tangentNormal),
											   dot(float3(i.worldTangent.y, i.worldBinormal.y, i.worldNormal.y), tangentNormal),
											   dot(float3(i.worldTangent.z, i.worldBinormal.z, i.worldNormal.z), tangentNormal));
				}

				float3 normalDirection = normalize(i.worldNormal.xyz);
				// return fixed4((normalize(normalDirection)+1)/2,1);
				if (_RainIntensity > 0)
				{
					normalDirection = RainBubbleNormal(i.posWorld.xyz, i.worldNormal.xyz, i.worldTangent.xyz, i.worldBinormal.xyz, _RainRipple_LightMapSpecular);
				}
				float4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap,i.uv0.zw);
				float3 lightmap = DecodeLightmap(lmtex);
				lightmap = BlendLightmap(lightmap, i.uv0.zw);
				float3 directDiffuse = lightmap.rgb;
				float3 lightDirection = normalize(_LightPos.xyz);

				float3 lightColor = _LightColor0.rgb*_ambientColor;
				float3 halfDirection = normalize(viewDirection + lightDirection);
				////// Lighting:
				//float attenuation = LIGHT_ATTENUATION(i);
				UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld)
				float3 attenColor = attenuation;
				///////// Gloss:
				float gloss = _Shine;
				float specPow = gloss;
				////// Specular:
				float3 specularColor = _SpecularColor.rgb;
				float3 directSpecular = pow(max(0,dot(halfDirection,normalDirection)),specPow);

				float3 halfDirection2 = normalize(viewDirection + normalize(_LightPos2.xyz));
				float3 directSpecular2 = pow(max(0, dot(halfDirection2, normalDirection)), _SpecularBackPow);

				float3 halfDirection3 = normalize(viewDirection + normalize(_LightPos3.xyz));
				float3 directSpecular3 = pow(max(0, dot(halfDirection3, normalDirection)), _SpecularBackPow);

				float3 specular = (directSpecular + directSpecular2*_LightPos2Enable*_SpecularIntensity2 + directSpecular3*_LightPos3Enable*_SpecularIntensity3) * specularColor;

				specular *= lightmap;
				/////// Diffuse:
				float NdotL = max(0.0,dot(normalDirection, lightDirection));
				float3 indirectDiffuse = float3(0,0,0);
#ifdef SHADOWS_SHADOWMASK
				directDiffuse = lightmap.rgb*_lambert + max(0.0, NdotL)/* * attenColor*/;
#endif
		//#ifndef LIGHTMAP_OFF
		//		/*#ifdef SHADOWS_SCREEN
		//		    #if (defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)) && defined(SHADER_API_MOBILE)
		//		        directDiffuse += min(lightmap.rgb, attenuation);
		//		    #else
		//		        directDiffuse += max(min(lightmap.rgb,attenuation*2), lightmap.rgb*attenuation);
		//		    #endif
		//		#else*/
		//		directDiffuse += lightmap.rgb*0.7;
		//		/*#endif*/
		//#endif
		#ifdef LIGHTMAP_OFF
				indirectDiffuse += UNITY_LIGHTMODEL_AMBIENT.rgb; // Ambient Light
		#endif
				float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0.xy, _MainTex));

				float3 diffuseColor = _MainTex_var.rgb*_MainColor.rgb;
				if (_SnowIntensity > 0)
				{
					diffuseColor = BlendSnow(diffuseColor, i.posWorld, normalDirection, i.uv0.xy);
				}
				float3 diffuse = directDiffuse * diffuseColor;
#ifdef SHADOWS_SHADOWMASK
				half atten2 = UnityComputeForwardShadows(i.uv0.zw, i.posWorld, 0);
				diffuse += diffuse * atten2 * lightColor;
#endif
				
				float3 finalColor = diffuse;// +specular*_MainTex_var.a;
				if (EnableGlobalSpecular > 0)
				{
					float3 lightDirectionCustom = normalize(GlobalSpecularLightPos.xyz);
					float3 halfDirectionCus = normalize(viewDirection + lightDirectionCustom);
					float lhCustom = saturate(dot(lightDirectionCustom, halfDirectionCus));
					float nv = saturate(dot(viewDirection, normalDirection));
					float3 globalSpecular = pow(max(0, dot(halfDirectionCus, normalDirection)), GlobalSpecularLightPos.w);
					//globalSpecular *= lightmap;
					float3 finalGlobalSpecular = globalSpecular * GlobalSpecularIntensity * GlobalSpecularColor.xyz * FresnelTerm(GlobalSpecularColor.xyz, lhCustom) * pow((1 - nv), 1);
					//return fixed4(pow((1 - nv), 1), 0, 0, 1);
					finalColor = finalColor + finalGlobalSpecular * 1.4 * _MainTex_var.a;
					//finalColor = finalColor + finalGlobalSpecular*0.5;
				}
				else
				{
					finalColor = finalColor + specular*_MainTex_var.a;
				}
		#ifdef GLOBALSH_ENABLE
				finalColor.xyz = finalColor.xyz*max(fixed3(1.0,1.0,1.0),(i.vlighting - UNITY_LIGHTMODEL_AMBIENT.xyz) * 2);
		#endif
				finalColor.rgb = GetDynamicPointLightColor(finalColor.rgb, i.posWorld, normalDirection);
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(i.fogCoord,finalColor.rgb);
				}else
				{
					UNITY_APPLY_FOG(i.fogCoord,finalColor);				
				}
				return fixed4(finalColor,1);
			}
		ENDCG
	}

	Pass
		{
			//此pass就是 从默认的fallBack中找到的 "LightMode" = "ShadowCaster" 产生阴影的Pass
			Tags{ "LightMode" = "ShadowCaster" }

			CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#pragma multi_compile_shadowcaster
//#pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
#pragma shader_feature _RENDERING_CUTOUT
#pragma shader_feature _SMOOTHNESS_ALBEDO
#include "UnityCG.cginc"
			sampler2D _MainTex;
		float4 _MainTex_ST;
		fixed _Cutoff;
		struct v2f {
			V2F_SHADOW_CASTER;
			float2 uv : TEXCOORD1;
			UNITY_VERTEX_OUTPUT_STEREO
		};

		v2f vert(appdata_base v)
		{
			v2f o;
			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
			o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
			TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
		}

		float4 frag(v2f i) : SV_Target
		{
			fixed4 testColor = tex2D(_MainTex, i.uv);
			SHADOW_CASTER_FRAGMENT(i)
		}
			ENDCG

		}

	}
	FallBack "TLStudio/Opaque/UnLit"
}
