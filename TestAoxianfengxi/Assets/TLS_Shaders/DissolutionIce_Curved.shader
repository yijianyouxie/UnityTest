// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/FX/DissolutionIce_Curved"
{
	//适用于那种非直线的模型，比如弯曲的桥
	//需要定义圆心和圆的起始点
	//外部传入一个位置点，将此点转换为圆上的某点，按照弧度进行比较
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
		/*_ModelSize("ModelSize", Range(0,100)) = 15
		_Progress("Progress", Range(0,1)) = 0.0*/
		_Center("Center", vector) = (0,0,0,0)
		_Start("Start", vector) = (0,0,0,0)
		_TargetPosition("TargetPosition", vector) = (0, 0, 0 ,1)
		_DissoveRange("DissoveRange", Range(0,15)) = 5
	}
	SubShader
	{
		Tags{ "RenderType" = "TransparentCutout" "LightMode" = "ForwardBase" "Queue" = "Transparent-100" }
		LOD 200

		Pass{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			// compile directives
	#pragma vertex vert_surf
	#pragma fragment frag_surf
	//#pragma multi_compile GLOBALSH_DISABLE GLOBALSH_ENABLE
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
			fixed4 _Color;
			/*float _ModelSize;
			float _Progress;*/
			float4 _Center;
			float4 _Start;
			float4 _TargetPosition;
			float _DissoveRange;

			struct Input {
				half2 uv_MainTex;
			};

			void surf(Input IN, inout SurfaceOutput o) {
				fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
				o.Albedo = c.rgb*_Color.rgb;
				//o.Alpha = c.a*_Color.a;
			}


		// vertex-to-fragment interpolation data
		// no lightmaps:
	#ifdef LIGHTMAP_OFF
			struct v2f_surf {
				float4 pos : SV_POSITION;
				half4 pack0 : TEXCOORD0; // _MainTex
				half3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
	#if UNITY_SHOULD_SAMPLE_SH
				half3 sh : TEXCOORD3; // SH
	#endif
				SHADOW_COORDS(4)
				UNITY_FOG_COORDS(5)
	#if SHADER_TARGET >= 30
				float4 lmap : TEXCOORD6;
	#endif
	#ifdef GLOBALSH_ENABLE
				float3 vlighting : TEXCOORD7;
	#else
	#endif
		};
	#endif
		// with lightmaps:
	#ifndef LIGHTMAP_OFF
			struct v2f_surf {
				float4 pos : SV_POSITION;
				half4 pack0 : TEXCOORD0; // _MainTex
				half3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float4 lmap : TEXCOORD3;
				SHADOW_COORDS(4)
				UNITY_FOG_COORDS(5)
	#ifdef GLOBALSH_ENABLE
				float3 vlighting : TEXCOORD6;
	#else
	#endif
		};
	#endif
			float4 _MainTex_ST;

			// vertex shader
			v2f_surf vert_surf(appdata_full v) {
				v2f_surf o;
				UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

				float3 center = mul(unity_WorldToObject, float4(_Center.xyz, 1));
				float3 start = mul(unity_WorldToObject, float4(_Start.xyz, 1));
				float3 startVector = normalize(start - center);
				float3 vertexVector = normalize(v.vertex - center);
				half sv = dot(startVector, vertexVector);
				o.pack0.z = sv;

				float3 target = mul(unity_WorldToObject, float4(_TargetPosition.xyz, 1));
				float3 targetVector = normalize(target - center);
				half tv = dot(startVector, targetVector);
				o.pack0.w = tv;

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = worldPos;
				o.worldNormal = worldNormal;
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
				clip(IN.pack0.w - IN.pack0.z);
				// prepare and unpack data
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT(Input,surfIN);
				surfIN.uv_MainTex.x = 1.0;
				surfIN.uv_MainTex = IN.pack0.xy;
				float3 worldPos = IN.worldPos;
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
				o.Normal = IN.worldNormal;
				normalWorldVertex = IN.worldNormal;


				// call surface function
				surf(surfIN, o);

				// compute lighting & shadowing factor
				UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
				fixed4 c = 0;

				// Setup lighting environment
				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
	#if !defined(LIGHTMAP_ON)
				gi.light.color = _LightColor0.rgb;
				gi.light.dir = lightDir;
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
	#if UNITY_SHOULD_SAMPLE_SH
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

	#ifdef GLOBALSH_ENABLE
				c.xyz = c.xyz*max(fixed3(1.0,1.0,1.0),(IN.vlighting - UNITY_LIGHTMODEL_AMBIENT.xyz) * 2);
	#endif
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(IN.fogCoord, c.rgb);
				}else
				{
					UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog				
				}
				UNITY_OPAQUE_ALPHA(c.a);
				return c;
			}

			ENDCG

		}

		Pass
		{

			CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma multi_compile FOG_EXP2 FOG_LINEAR
	#pragma multi_compile_fwdbase

	#include "UnityCG.cginc"
	#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 worldPos : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
				float3 worldTangent : TEXCOORD4;
				float3 worldBitangent : TEXCOORD5;
			};

			float4 _DiffuseColor;
			sampler2D _GrabTexture;
			sampler2D _IceTexture;
			sampler2D _NoiseTexture;
			sampler2D _NormalTex;
			samplerCUBE _Cube;
			float4 _IceTexture_ST;
			float4 _NoiseTexture_ST;
			float4 _NormalTex_ST;
			float _RefrectionNoise;
			float _TexOffset;
			float _IceBlendNoiseDegree;
			float _NDotLDrgree;
			float _SpecularDrgree;
			float _SpecularScatterArea;
			float _Specular2Drgree;
			float _Lerp;
			float _LerpAlpha;

			/*float _ModelSize;
			float _Progress;*/
			float4 _Center;
			float4 _Start;
			float4 _TargetPosition;
			float _DissoveRange;


			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _IceTexture);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.screenPos = o.vertex;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);// mul(v.normal, (float3x3)_World2Object);
				o.worldTangent = mul(unity_ObjectToWorld, v.tangent);
				o.worldBitangent = cross(normalize(o.worldNormal), normalize(o.worldTangent));

				float3 center = mul(unity_WorldToObject, float4(_Center.xyz, 1));
				float3 start = mul(unity_WorldToObject, float4(_Start.xyz, 1));
				float3 startVector = normalize(start - center);
				float3 vertexVector = normalize(v.vertex - center);
				half sv = dot(startVector, vertexVector);
				o.uv.z = sv;

				float3 target = mul(unity_WorldToObject, float4(_TargetPosition.xyz, 1));
				float3 targetVector = normalize(target - center);
				half tv = dot(startVector, targetVector);
				o.uv.w = tv;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float delta = i.uv.z - i.uv.w;
				clip(delta + _DissoveRange);

				i.worldPos = normalize(i.worldPos);
				i.worldNormal = normalize(i.worldNormal);
				i.worldTangent = normalize(i.worldTangent);
				i.worldBitangent = normalize(i.worldBitangent);
				/*
				注意:
				UNITY_MATRIX_MVP 只是到裁剪完后的齐次裁剪空间 xy分量范围是-w,w 要想知道屏幕位置  需要
				screenPosX = ((x / w) * 0.5 + 0.5) * width
				screenPosY = ((y / w) * 0.5 + 0.5) * height
				*/
				float4 realScreenPos = float4(((i.screenPos.x / i.screenPos.w) *0.5 + 0.5)*_ProjectionParams.x,
					((i.screenPos.y / i.screenPos.w) *0.5 + 0.5)*_ProjectionParams.y, 0, 0);
				//法线贴图数值读取
				float3 normalMap = UnpackNormal(tex2D(_NormalTex, i.uv));
				float2 screenUV = realScreenPos + ((normalMap.rgb.rg + mul(UNITY_MATRIX_V, float4(i.worldNormal, 0)).xy)*_RefrectionNoise);
				//float4 screenColor = tex2D(_GrabTexture, screenUV);

				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

				//构造切空间-世界矩阵
				float3x3 tangent2World = float3x3(i.worldTangent, i.worldBitangent, i.worldNormal);
				//法线贴图(切空间)转世界
				float3 normalMapWorld = normalize(mul(normalMap, tangent2World));
				//根据法线贴图计算反射
				float3 viewReflectDir = reflect(-viewDir, normalMapWorld);
				//取主贴图颜色
				float4 iceTexColor = tex2D(_IceTexture, TRANSFORM_TEX(i.uv, _IceTexture));
				//取明暗图颜色
				float4 noiseTexColor = tex2D(_NoiseTexture, TRANSFORM_TEX(i.uv, _NoiseTexture));

				float4 screenColor = texCUBE(_Cube, realScreenPos + ((normalMap.rgb + mul(UNITY_MATRIX_V, float4(i.worldNormal, 0)).xyz)*_RefrectionNoise));

				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 lightColor = _LightColor0.rgb;

				float3 emissive = _IceBlendNoiseDegree * iceTexColor * noiseTexColor;
				//与光源夹角 这里乘平方为了让暗色更亮些
				float nDotL = pow(dot(normalMapWorld, lightDir) + _NDotLDrgree, 2);
				float3 diffuse = _DiffuseColor.rgb * nDotL;
				float3 specular1 = _SpecularDrgree * pow(max(0, dot(lightDir, viewReflectDir)), exp(_SpecularScatterArea));
				float3 specular2 = pow(1.0 - max(0, dot(normalMapWorld, viewDir)), _Specular2Drgree) * nDotL;

				float3 col = emissive + ((diffuse + specular1 + specular2) * lightColor);
				fixed4 finalColor = fixed4(lerp(screenColor.rgb, col, _Lerp), 1);
				finalColor = fixed4(lerp(screenColor.rgb, col, _Lerp), 1);
				finalColor = fixed4(lerp(fixed4(0.0,0.0,0.0,0.0), finalColor, _LerpAlpha));

				//显示溶解部分
				/*if (delta <= 0)
				{*/
				clip(noiseTexColor.r*_DissoveRange + delta);
				//}
				return finalColor;
				//return fixed4(i.uv.z, 0, 0, 1);
			}
			ENDCG
		}
	}
}
