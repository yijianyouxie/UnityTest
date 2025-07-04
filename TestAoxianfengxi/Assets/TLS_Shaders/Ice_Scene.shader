Shader "TLStudio/FX/Ice_Scene"
{
	//适用于整个场景的情况
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Base (RGB)", 2D) = "white" {}

		[Header(oooooooooooooooooooooooooooooICE)]
		//Ice
		_DiffuseColor("DiffuseColor", Color) = (0.25,0.25,0.25,1)
		_NormalTex("NormalTex", 2D) = "bump" {}
		_IceTexture("IceTexture", 2D) = "white"{}
		_NoiseTexture("NoiseTexture", 2D) = "white"{}
		_Cube("Reflection Cubemap", Cube) = "" {}
		_RefrectionNoise("RefrectionNoise", Range(-0.5, 0.5)) = -0.232
		_TexOffset("TexOffset", float) = 0.0
		_IceBlendNoiseDegree("IceBlendNoiseDegree", float) = 5.0
		_NDotLDrgree("NDotLDrgree", float) = 0.5
		_SpecularDrgree("SpecularDrgree", float) = 0.7
		_SpecularScatterArea("SpecularScatterArea", float) = 2.02
		_Specular2Drgree("Specular2Drgree", Range(0, 1)) = 0.882
		_Lerp("Lerp", Range(0, 1)) = 0.73
		_LerpAlpha("LerpAlpha", Range(0, 1)) = 1.0
		_Intensity("Intensity", Range(0, 5)) = 1.0

		_Reflection("Reflection", 2D) = "white" {}
		_RimColor("RimColor", Color) = (1,1,1,1)
		_ReflectionIntension("Reflection Intensity",Range(0,1)) = 0.5
	}
	SubShader
	{
		Tags{ "Queue" = "AlphaTest+150" "RenderType" = "Opaque" }
		LOD 200

		Pass{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma skip_variants FOG_EXP GLOBALSH_ENABLE DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN VERTEXLIGHT_ON
			// compile directives
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma multi_compile GLOBALSH_DISABLE GLOBALSH_ENABLE
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbase
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#define UNITY_PASS_FORWARDBASE
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			#define INTERNAL_DATA
			#define WorldReflectionVector(data,normal) data.worldRefl
			#define WorldNormalVector(data,normal) normal

			// Original surface shader snippet:
			#line 12 ""
			#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
			#endif

			//#pragma surface surf Lambert noforwardadd
			sampler2D _MainTex;
			half4 _MainTex_ST;
			fixed4 _Color;

			//冰
			fixed4 _DiffuseColor;
			sampler2D _GrabTexture;
			sampler2D _IceTexture;
			sampler2D _NoiseTexture;
			sampler2D _NormalTex;
			samplerCUBE _Cube;
			half4 _IceTexture_ST;
			half4 _NoiseTexture_ST;
			half4 _NormalTex_ST;
			half _RefrectionNoise;
			half _TexOffset;
			half _IceBlendNoiseDegree;
			half _NDotLDrgree;
			half _SpecularDrgree;
			half _SpecularScatterArea;
			half _Specular2Drgree;
			half _Lerp;
			half _LerpAlpha;
			half _Intensity;

			sampler2D _Reflection; half4 _Reflection_ST;
			fixed4 _RimColor;
			fixed _ReflectionIntension;

			struct Input {
				half2 uv_MainTex;
			};

			// vertex-to-fragment interpolation data
			// no lightmaps:
		#ifdef LIGHTMAP_OFF
			struct v2f_surf {
				float4 pos : SV_POSITION;
				half2 pack0 : TEXCOORD0; // _MainTex
				half3 worldNormal : TEXCOORD1;
				float4 worldPos : TEXCOORD2;
				float4 screenPos : TEXCOORD3;
				float3 worldTangent : TEXCOORD4;
				float3 worldBitangent : TEXCOORD5;
		#if UNITY_SHOULD_SAMPLE_SH
				half3 sh : TEXCOORD6; // SH
		#endif
				SHADOW_COORDS(7)
				UNITY_FOG_COORDS(8)
		#if SHADER_TARGET >= 30
				float4 lmap : TEXCOORD9;
		#endif
		#ifdef GLOBALSH_ENABLE
				float3 vlighting : TEXCOORD10;
		#else
		#endif
			};
		#endif
			// with lightmaps:
		#ifndef LIGHTMAP_OFF
			struct v2f_surf {
				float4 pos : SV_POSITION;
				half2 pack0 : TEXCOORD0; // _MainTex
				half3 worldNormal : TEXCOORD1;
				float4 worldPos : TEXCOORD2;
				float4 lmap : TEXCOORD3;
				float4 screenPos : TEXCOORD4;
				float3 worldTangent : TEXCOORD5;
				float3 worldBitangent : TEXCOORD6;
				SHADOW_COORDS(7)
				UNITY_FOG_COORDS(8)
		#ifdef GLOBALSH_ENABLE
				float3 vlighting : TEXCOORD9;
		#else
		#endif
			};
		#endif

			// vertex shader
			v2f_surf vert_surf(appdata_full v) {
				v2f_surf o;
				UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.pack0 = TRANSFORM_TEX(v.texcoord, _MainTex);

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos.xyz = worldPos;
				o.worldNormal = worldNormal;

				o.worldPos.w = 1;

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
				o.vlighting = ShadeSH9(float4(o.worldNormal, 1.0));
		#endif

				o.screenPos = o.pos;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldTangent = mul(unity_ObjectToWorld, v.tangent);
				o.worldBitangent = cross(normalize(o.worldNormal), normalize(o.worldTangent));

				TRANSFER_SHADOW(o); // pass shadow coordinates to pixel shader
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
				float3 worldPos = IN.worldPos;
			#ifndef USING_DIRECTIONAL_LIGHT
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
			#else
				fixed3 lightDir = _WorldSpaceLightPos0.xyz;
			#endif
				
				fixed4 finalColor = 0;

				IN.worldPos = normalize(IN.worldPos);
				IN.worldNormal = normalize(IN.worldNormal);
				IN.worldTangent = normalize(IN.worldTangent);
				IN.worldBitangent = normalize(IN.worldBitangent);
				
				float4 realScreenPos = float4(((IN.screenPos.x / IN.screenPos.w) *0.5 + 0.5)*_ProjectionParams.x,
					((IN.screenPos.y / IN.screenPos.w) *0.5 + 0.5)*_ProjectionParams.y, 0, 0);
				//法线贴图数值读取
				float3 normalMap = UnpackNormal(tex2D(_NormalTex, IN.pack0));
				float2 screenUV = realScreenPos + ((normalMap.rgb.rg + mul(UNITY_MATRIX_V, float4(IN.worldNormal, 0)).xy)*_RefrectionNoise);
				//float4 screenColor = tex2D(_GrabTexture, screenUV);

				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.worldPos);

				//构造切空间-世界矩阵
				float3x3 tangent2World = float3x3(IN.worldTangent, IN.worldBitangent, IN.worldNormal);
				//法线贴图(切空间)转世界
				float3 normalMapWorld = normalize(mul(normalMap, tangent2World));
				//根据法线贴图计算反射
				float3 viewReflectDir = reflect(-viewDir, normalMapWorld);
				//取主贴图颜色
				fixed4 iceTexColor = tex2D(_IceTexture, TRANSFORM_TEX(IN.pack0, _IceTexture));
				//取明暗图颜色
				fixed4 noiseTexColor = tex2D(_NoiseTexture, TRANSFORM_TEX(IN.pack0, _NoiseTexture));

				fixed4 screenColor = texCUBE(_Cube, realScreenPos + ((normalMap.rgb + mul(UNITY_MATRIX_V, float4(IN.worldNormal, 0)).xyz)*_RefrectionNoise));

				fixed attenuation = LIGHT_ATTENUATION(IN);
			#ifndef LIGHTMAP_OFF
				fixed4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.lmap.xy);
				fixed3 lightmap = DecodeLightmap(lmtex);
				fixed3 directDiffuse = min(lightmap.rgb, attenuation*lightmap.rgb);
			#endif

				lightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 lightColor = _LightColor0.rgb;

				fixed3 emissive = _IceBlendNoiseDegree * iceTexColor * noiseTexColor;
				//与光源夹角 这里乘平方为了让暗色更亮些
				float nDotL = saturate(pow(dot(normalMapWorld, lightDir) + _NDotLDrgree, 2));
				fixed3 diffuse = _DiffuseColor.rgb * nDotL;
				fixed3 specular1 = _SpecularDrgree * pow(max(0, dot(lightDir, viewReflectDir)), exp(_SpecularScatterArea));
				fixed3 specular2 = pow(1.0 - max(0, dot(normalMapWorld, viewDir)), _Specular2Drgree) * nDotL;

			#ifndef LIGHTMAP_OFF
				emissive *= directDiffuse * _Intensity;
			#endif
				fixed3 col = emissive + ((diffuse + specular1 + specular2) * lightColor);
				finalColor = fixed4(lerp(screenColor.rgb, col, _Lerp), 1);
				finalColor = fixed4(lerp(fixed4(0.0, 0.0, 0.0, 0.0), finalColor, _LerpAlpha));

				finalColor = finalColor * _Color;
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(IN.fogCoord, finalColor.rgb);
				}else
				{
					UNITY_APPLY_FOG(IN.fogCoord, finalColor);				
				}

				////// RimEmissive:
				half3 normalDirection = IN.worldNormal;
				fixed rimRange = 1 - abs(dot(viewDir, normalDirection));
				half2 ReflUV = mul(UNITY_MATRIX_V, float4(normalDirection, 0)).rg*0.5 + 0.5;
				fixed4 _Reflection_var = tex2D(_Reflection, TRANSFORM_TEX(ReflUV, _Reflection));
				fixed3 rimEmissive =  _Reflection_var.rgb*_ReflectionIntension + rimRange * rimRange * _RimColor;
				finalColor.rgb += rimEmissive;

				finalColor.a = _Color.a;
				return finalColor;
			}
			ENDCG
		}
		Pass{

			Tags{ "LightMode" = "ShadowCaster" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#include "UnityCG.cginc"
			struct v2f {
				V2F_SHADOW_CASTER;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
	FallBack "TLStudio/Opaque/UnLit"
}
