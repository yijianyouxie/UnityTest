// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/CharSkin_VF2" {
/////////////////Properties->////////////////////////////
    Properties {
		//_Yoffset("Y offset", float) = 0
		_Color("Color(整体染色用)", Color) = (1,1,1,1)
		_BodySkinColor("BodySkinColor(肤色用)", Color) = (1,1,1,1)
		//_SkinShadowColor("SkinShadow Color", Color) = (1,1,1,1)
		[NoScaleOffset]_MainTex("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset]_Emit("闪光控制图", 2D) = "black" {}
		[HDR]_EmitIntensity("闪光颜色",Color) = (1,1,1,1)
		_EmitDensity("闪光密度",Range(0.001,1)) = 1   
		_EmitSize("闪光大小",Range(0,10.0)) = 1
		[HDR]_EmissionColor("EmissionColor", Color) = (0,0,0,0)
		[NoScaleOffset] _Normal("Normal", 2D) = "bump" {}
		_DetailNormal("Detail Normal", 2D) = "bump" {}
		_DetailNormalScale("Detail Normal1 Scale", Range(0,2)) = 1
		_DetailNormal2("Detail Normal2", 2D) = "bump" {}
		_DetailNormal2Scale("Detail Normal2 Scale", Range(0,2)) = 1
		_DetailNormal3("Detail Normal3", 2D) = "bump" {}
		_DetailNormal3Scale("Detail Normal3 Scale", Range(0,2)) = 1
		[NoScaleOffset] _Metallic("MixeradConfigMap.R:Metal;G:Roughness;B:曲率，采样skinProfile用", 2D) = "white" {}
		_AO("AO", Range(0,1)) = 1
		[NoScaleOffset]_Mask("Mask", 2D) = "black" {}
		_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
		_SSSWrap("SSS Wrap", Range(-2,2)) = 0
		_ScatterColor("Scatter Color", Color) = (1,1,1,1)//默认为白色
		[HideInInspector]_ScatterProfileColor("Scatter Profile Color", Color) = (1,0,0,1)
		_SkinLightIntensity("SkinLightIntensity", Range(1,3)) = 1
		_SkinSI("SkinSpecularIntensity",Range(1,10)) = 1
		[Toggle] _gray("Gray", float) = 0
		[NoScaleOffset]_EnvCube("Environment Cube", Cube) = "evn" {}
		[HDR]_EnvColor("Environment Color", Color) = (1,1,1,1)
		[MaterialEnum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
		[HideInInspector] _Mode("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
		[HideInInspector] _ZWrite("__zw", Float) = 1.0
		[HDR]_GlitterColor("GlitterColor", Color) = (0,0,0,1)//闪白颜色
		_GlitterColorWidth("GlitterColorWidth",Range(2,10)) = 2
		
		_Aniso("Aniso(XY:主高光偏移方向 ZW:辅高光偏移方向)",vector) = (0,0,0,0)
        _MetallicAdjust ("Metallic", Range(0, 1)) = 1
        _GlossAdjust ("Smoothness", Range(0, 1)) = 1


    }
/////////////////////<-Properties/////////////////////////////
    SubShader {

        Tags {
			//"Queue"="Geometry+400" "RenderType"="Opaque"
			"Queue" = "AlphaTest+50"
			"RenderType" = "TransparentCutout"
			"ShadowProjector" = "true" 
		}
		LOD 300
		
		cull [_Cull]
		Blend[_SrcBlend][_DstBlend]
		ZWrite[_ZWrite]

        Pass {
            Name "FORWARD"
            Tags {"LightMode"="ForwardBase"}
            
            
            CGPROGRAM
            #pragma skip_variants _ALPHAPREMULTIPLY_ON DIRECTIONAL DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SHADOWS_SCREEN SHADOWS_SHADOWMASK VERTEXLIGHT_ON
            #pragma vertex vert
            #pragma fragment frag

			/*#define _DETAILNORMAL 1
			#undef _DETAILNORMAL*/
			#define UNITY_BRDF_GGX 1
			//#define UNITY_COLORSPACE_GAMMA 1
            #include "UnityCG.cginc"
			//#include "CGIncludes/AutoLight.cginc"
			//#include "CGIncludes/DynamicPointLight.cginc"
			//#include "CGIncludes/UnityStandardBRDF.cginc"
//#ifdef	_AVATARMESHHINT
			//#include "AvatarCommon.cginc"
//#endif
            //#pragma multi_compile_fwdbase_fullshadows
			#pragma multi_compile _ _ALPHATEST_ON _ALPHAPREMULTIPLY_ON
			//#pragma multi_compile _ _AVATARMESHHINT
			//#pragma multi_compile _ _SHADOWS_PCF
			#pragma multi_compile _ _UICHAR
			/*#pragma multi_compile __ PROJECTOR_DEPTH_MAP_ON
			#include "DepthMapShadow.cginc"*/
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
            #pragma exclude_renderers xbox360 ps3 flash d3d11_9x

///Color////////////////////
			fixed4 _Color;
			fixed4 _GlitterColor;
			float4 _EmissionColor;
			half3 _EnvColor;
			fixed3 _ScatterColor;
			fixed3 _ScatterProfileColor;
			float4 _AmbientTop;
			float4 _AmbinetDown;
			float4 _EmitIntensity;
			float4 _SkinShadowColor;
///Sampler//////////////
            sampler2D _MainTex; 
            sampler2D _Normal;
            sampler2D _Metallic;
			sampler2D _Mask;
			sampler2D _SkinProfile;
            sampler2D _Emit;
//#ifdef _DETAILNORMAL
//			sampler2D _DetailNormal;
//			half _DetailNormalScale;
//			sampler2D _DetailNormal2;
//			half _DetailNormal2Scale;
//			sampler2D _DetailNormal3;
//			half _DetailNormal3Scale;
//#endif
			samplerCUBE _EnvCube;

///float//////////////////
            fixed _MetallicAdjust;
            fixed _GlossAdjust;
			fixed _AO;
			fixed _gray;
			float _GlobalEnvIntensity;
			half _SSSWrap;
			fixed _ShadowAttenFactor;
			half _GlitterColorWidth;
			float _SkinLightIntensity;
			float _SkinSI;
			float _EmitDensity,_EmitSize;
			float _Yoffset;
			float _rainIntensity;
#ifdef _ALPHATEST_ON
			fixed _Cutoff;
#endif
			
///float4////////////////////
			half4 _CharLightDir;
			half4 _CharLightColor;
			half4 _CharFillLightDir;
			half4 _CharFillLightColor;

			half4 _UICharLightDir;
			half4 _UICharLightColor;
			half4 _UICharFillLightDir;
			half4 _UICharFillLightColor;

			float4 _MainTex_ST;
			float4 _DetailNormal_ST;
			float4 _DetailNormal2_ST;
			float4 _DetailNormal3_ST;

			float4 _Aniso;
			float3 _BodySkinColor;

///sparkle相关
			sampler2D _SparkleTex;
			sampler2D _SparkleMaskTex;

			float4 _SparkleEyeColor;
			float _SparkleEyeSpacing;
			float4 _SparkleLipColor;
			float _SparkleLipSpacing;
			float4 _SparkleCheekColor;
			float _SparkleCheekSpacing;

///////////Struct/////////////////////////////////
            struct VertexInput 
			{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput 
			{
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
				
//#ifdef _DETAILNORMAL
//				float2 uv1 : TEXCOORD5;				
//				float4 uv2 : TEXCOORD6;
//				//float2 uv3 : TEXCOORD7;
//#endif
                float4 viewPos : TEXCOORD5;
				float3 tangentDirVertical : TEXCOORD6;
				float3 bitangentDirVertical : TEXCOORD7;
				UNITY_FOG_COORDS(8)
            };
///////////Fuction/////////////////
			inline half3 DiffuseAndSpecularFromMetallic (half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
			{
				half4 unity_ColorSpaceDielectricSpecCus = half4(0.04, 0.04, 0.04, 1.0 - 0.04);
				specColor = lerp (unity_ColorSpaceDielectricSpecCus.rgb, albedo, metallic);
				half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpecCus.a;
				oneMinusReflectivity = oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
				return albedo * oneMinusReflectivity;
			}
			float hash(float2 p) 
			{
			    float h = dot(p, float2(127.1, 311.7));
			    return frac(sin(h)*43758.5453123);
			}
			float noise(float2 p) 
			{
			    float2 i = floor(p);
			    float2 f = frac(p);
			    float2 u = f*f*(3.0 - 2.0*f);
			    float n = lerp(lerp(hash(i),hash(i + float2(1.0, 0.0)), u.x),lerp(hash(i + float2(0.0, 1.0)),hash(i + 1), u.x), u.y);
			    return n;
			}
			half3 BlendNormals(half3 n1, half3 n2)
			{
				return normalize(half3(n1.xy + n2.xy, n1.z*n2.z));
			}
			inline half Pow5 (half x)
			{
				return x*x * x*x * x;
			}
			inline half3 FresnelTerm (half3 F0, half cosA)
			{
				half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
				return F0 + (1-F0) * t;
			}
			float PerceptualRoughnessToRoughness(float perceptualRoughness)
			{
				return perceptualRoughness * perceptualRoughness;
			}
			inline half PerceptualRoughnessToSpecPower (half perceptualRoughness)
			{
				half m = PerceptualRoughnessToRoughness(perceptualRoughness);   // m is the true academic roughness.
				half sq = max(1e-4f, m*m);
				half n = (2.0 / sq) - 2.0;                          // https://dl.dropboxusercontent.com/u/55891920/papers/mm_brdf.pdf
				n = max(n, 1e-4f);                                  // prevent possible cases of pow(0,0), which could happen when roughness is 1.0 and NdotH is zero
				return n;
			}

////反射球计算 
			float3 Reflection(float3 Normal,float Metallic,float Roughness,half3 worldViewDir)
			{
				half3 reflUVW   = reflect(-worldViewDir, Normal);
				half perceptualRoughness = Roughness /* perceptualRoughness */;
				perceptualRoughness = perceptualRoughness * (1.7 - 0.7*perceptualRoughness);
				half mip =perceptualRoughness*6;
				half3 R = reflUVW;
				half4 rgbm = texCUBElod(_EnvCube, half4(R, mip));
			#ifdef UNITY_COLORSPACE_GAMMA
				rgbm.rgb = pow(rgbm.rgb, 2.2);
			#endif
				//改用RGBM编码将亮度信息存储到A通道 默认rgbm.a*15，现在因为反射图都没有a信息所以先乘零。
				float3 indirectSpecular = rgbm.rgb*(1+rgbm.a*0)* _GlobalEnvIntensity* _EnvColor.rgb;
				return indirectSpecular;
			}

////细节法线
			float3 DetailNormal(float3 Normal_var, float2 uv1, float2 uv2, float2 uv3, float4 Mask_var)
			{
			//#ifdef _DETAILNORMAL
			//	float3 _DetailNormal_var  = UnpackNormal(tex2D(_DetailNormal, uv1));
			//	float3 _DetailNormal_var2 = UnpackNormal(tex2D(_DetailNormal2,uv2));
			//	float3 _DetailNormal_var3 = UnpackNormal(tex2D(_DetailNormal3,uv3));
			//    Normal_var= BlendNormals(Normal_var,lerp(float3(0,0,1),_DetailNormal_var, Mask_var.r*_DetailNormalScale));
			//	Normal_var= BlendNormals(Normal_var,lerp(float3(0,0,1),_DetailNormal_var2,Mask_var.g*_DetailNormal2Scale));
			//	Normal_var= BlendNormals(Normal_var,lerp(float3(0,0,1),_DetailNormal_var3,Mask_var.b*_DetailNormal3Scale));
			//#endif
				return Normal_var;
			}
			
////specularTerm
			float GetSpecularTerm(half roughness, half perceptualRoughness, half smoothness, half nh, half lh)
			{
				#if UNITY_BRDF_GGX

					// GGX Distribution multiplied by combined approximation of Visibility and Fresnel
					// See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
					// https://community.arm.com/events/1155
					float a = roughness;
					float a2 = a*a;

					float d = nh * nh * (a2 - 1.h) + 1.00001h;


					float specularTerm = a2 / (max(0.1f, lh * lh) * (roughness + 0.5f) * (d * d) * 4);
					// on mobiles (where half actually means something) denominator have risk of overflow
					// clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
					// sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
					#if defined (SHADER_API_MOBILE)
						specularTerm = specularTerm - 1e-4h;
					#endif

				#else

					// Legacy
					half specularPower = PerceptualRoughnessToSpecPower(perceptualRoughness);
					// Modified with approximate Visibility function that takes roughness into account
					// Original ((n+1)*N.H^n) / (8*Pi * L.H^3) didn't take into account roughness
					// and produced extremely bright specular at grazing angles

					half invV = lh * lh * smoothness + perceptualRoughness * perceptualRoughness; // approx ModifiedKelemenVisibilityTerm(lh, perceptualRoughness);
					half invF = lh;

					half specularTerm = ((specularPower + 1) * pow(nh, specularPower)) / (8 * invV * invF + 1e-4h);

				#ifdef UNITY_COLORSPACE_GAMMA
					specularTerm = sqrt(max(1e-4f, specularTerm));
				#endif

				#endif

				#if defined (SHADER_API_MOBILE)
					specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
				#endif
				#if defined(_SPECULARHIGHLIGHTS_OFF)
					specularTerm = 0.0;
				#endif

				return specularTerm;
			}

////皮肤KS高光
			float KS_Skin_Specular(half3 N, half3 L, half3 V, half m)
			{
				//m = m * 0.09 + 0.23;
				half3 h = L + V; // Unnormalized half-way vector
				half3 H = normalize( h );
				half ndoth = (dot( N, H ));
				//half4 profileUV = half4(ndoth, m, 0, 0);
				half PH = pow( 2.0 * tex2D( _SkinProfile, half2(ndoth, m)).a, 10);
				//float F = fresnelReflectance( H, V, 0.028 );
				half F = FresnelTerm(0.028, saturate(ndoth));
				return max( PH * F / dot( h, h ), 0 );
			}

////闪点
			float FlashPoint(float2 uv0, float4 _Emit_var, float NdotV, float3 specular)
			{
				///两套noiseUV，互相有偏移
				float2 scaleUV = uv0*200;
				float2 scaleUVoffset = (uv0 + float2(0.7,-0.5))*200;
				float2 floorUV =floor(scaleUV);
				float2 fractUV = frac(scaleUV);
				float2 floorUVoffset = floor(scaleUVoffset);
				float2 fractUVoffset = frac(scaleUVoffset);
				///四个dot放一起计算
				float4 append = float4(dot(floorUV, float2(127,311)),dot(floorUV, float2(269,183)),dot(floorUVoffset, float2(127,311)),dot(floorUVoffset, float2(269,183)));
				float4 append_random = frac(sin(append)*43758.55);
				float4 append_random_random = sin(append_random*5+float4(10,15,10,25))*0.25+0.5;
				float4 final_random = (append_random_random - float4(fractUV, fractUVoffset))*_EmitSize;
				//两套uv出两套闪点
				float pointA = 1-smoothstep(0,1,length(final_random.xy));
				float pointB = 1-smoothstep(0,1,length(final_random.zw));
				///随视角变动闪烁
				float3 transView = mul(UNITY_MATRIX_IT_MV, float4(0.01,0.01,0.01,0))*0.01;
				float2 shanAppend = float2(dot(append_random_random.xy*transView.xz,float2(100,200)),dot(append_random_random.zw*transView.xz,float2(100,200)));
				float2 shanshuo = saturate(_Emit_var.g*_EmitDensity -frac(sin(shanAppend)*500));
				float shanpoint = pointA * shanshuo.x + pointB * shanshuo.y;
				shanpoint = shanpoint *smoothstep(0.3,1,NdotV) + shanpoint * smoothstep(0.2,0.5,specular.r)*100;
				return shanpoint;
			}

////下雨
			inline void CharRain(float curvature, float4 viewPos, inout float3 _Normal_var, inout float Metallic, inout float Smoothness)
			{
			#ifndef _UICHAR
				float coefficient = _rainIntensity*(1-curvature);
				float4 RainNormal = float4(noise(viewPos.zw*float2(80,260)-(_Time.y*10)),noise(viewPos.zw*float2(70,300)-(_Time.y*5)),1,1);
				RainNormal.xy *= 0.1;
				_Normal_var = lerp(_Normal_var,BlendNormals(_Normal_var,RainNormal),coefficient);
				Metallic = lerp(Metallic, max(0.3, Metallic),coefficient);
				Smoothness = lerp(Smoothness, max(0.5,Smoothness), coefficient);
			#endif
			}


////////////VF///////////////
            VertexOutput vert (VertexInput v) 
			{
                VertexOutput o = (VertexOutput)0;
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _MainTex);
//#ifdef _DETAILNORMAL
//				o.uv1 = TRANSFORM_TEX(v.texcoord0, _DetailNormal);
//				o.uv2.xy = TRANSFORM_TEX(v.texcoord0, _DetailNormal2);
//				o.uv2.zw = TRANSFORM_TEX(v.texcoord0, _DetailNormal3);
//				//o.uv3 = TRANSFORM_TEX(v.texcoord0, _DetailNormal3);
//#endif
				float a = 90 / 180 * UNITY_PI;
				float3x3 tangent_roate = float3x3(cos(a), sin(a), 0,sin(a), cos(a),0,0,0,1);
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
				o.tangentDirVertical = normalize(mul(tangent_roate, o.tangentDir));
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				o.bitangentDirVertical = normalize(cross(o.normalDir, o.tangentDirVertical) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex );
				//o.viewPos.xy = mul(UNITY_MATRIX_MV, v.vertex).xy;
				o.viewPos.xy = UnityObjectToViewPos(v.vertex).xy;
				o.viewPos.zw = v.vertex.xz;
				if(UseHeightFog > 0)
				{
					TL_TRANSFER_FOG(o, o.pos, v.vertex);
				}else
				{
					UNITY_TRANSFER_FOG(o, o.pos);				
				}
                return o;
            }
////////////////FF////////////
            float4 frag(VertexOutput i) : COLOR 
			{
				float3 specularColor;
				float specularMonochrome;
				float SpecularTerm;
				float SpecularTerm2;
				float alpha = 1;

////tex2D:
				float4 _MainTex_var = tex2D(_MainTex,i.uv0);
#ifdef UNITY_COLORSPACE_GAMMA
				_MainTex_var.rgb = pow(_MainTex_var.rgb, 2.2);
#endif

#ifdef _ALPHATEST_ON
				clip(_MainTex_var.a - _Cutoff);
#endif
				float4 _Emit_var = tex2D(_Emit,i.uv0);
				float3 _Normal_var = UnpackNormal(tex2D(_Normal,i.uv0));
				float4 _Mask_var =tex2D(_Mask,i.uv0);
				float4 SilkNoise = tex2D(_Emit,i.uv0.xy*15);//闪点控制图的b通道用来给丝绸加一层noise
				float4 _Metallic_var = tex2D(_Metallic,i.uv0);
				float Metallic	 = _Metallic_var.r * _MetallicAdjust;
				float Smoothness = _Metallic_var.g * _GlossAdjust;
				float curvature  = _Metallic_var.b;
				float Ao = 1-_AO + _Metallic_var.a * _AO;

////加入细节法线
//#ifdef _DETAILNORMAL
//				_Normal_var = DetailNormal(_Normal_var, i.uv1, i.uv2.xy, i.uv2.zw, _Mask_var);
//#endif

////非UI角色下雨
				CharRain(curvature, i.viewPos, _Normal_var, Metallic, Smoothness);

////roughness
				half perceptualRoughness = 1-Smoothness;
				half roughness = perceptualRoughness * perceptualRoughness;
#ifdef UNITY_COLORSPACE_GAMMA
				half surfaceReduction = 0.28;
#else
				half surfaceReduction = (0.6 - 0.08 * perceptualRoughness);
#endif
				surfaceReduction = 1.0 - roughness*perceptualRoughness*surfaceReduction;
                surfaceReduction = lerp(surfaceReduction,1,ceil(curvature));

////最终normal:
                i.normalDir = normalize(i.normalDir);
				//切线坐标系到世界坐标系
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
				float3x3 tangentTransformVertical = float3x3( i.tangentDirVertical, i.bitangentDirVertical, i.normalDir);
                float3 normalDirection = normalize(mul(_Normal_var, tangentTransform));

////LightingData:
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				float attenuation = 1;
#ifdef _UICHAR
				float3 lightDirection =normalize( _UICharLightDir.xyz);
				float3 lightColor =  _UICharLightColor.xyz *= saturate(attenuation + _ShadowAttenFactor);
				float3 fillLightDir = normalize(_UICharFillLightDir.xyz);
				half3  fillLightColor = _UICharFillLightColor.rgb;
#else
				float3 lightDirection = normalize(_CharLightDir.xyz);
				float3 lightColor = _CharLightColor.xyz *= saturate(attenuation + _ShadowAttenFactor);
				float3 fillLightDir = normalize(_CharFillLightDir.xyz);
				half3  fillLightColor = _CharFillLightColor.rgb;
#endif
				lightColor	   = lerp(lightColor,    lightColor     *_SkinLightIntensity, ceil(curvature));
				fillLightColor = lerp(fillLightColor,fillLightColor *_SkinLightIntensity, ceil(curvature));

				float3 halfDirection = normalize(viewDirection+lightDirection);
				float NdotL =dot( normalDirection, lightDirection );
				float TopN = (dot(normalDirection, float3(0,1,0))+1)*0.5;
				float LdotH = saturate(dot(lightDirection, halfDirection));
				float NdotV = saturate(dot( normalDirection, viewDirection ));

////diffuseColor:
				float3 diffuseColor = (_MainTex_var.rgb*_Color.rgb);
				diffuseColor = lerp(diffuseColor, diffuseColor * _BodySkinColor, ceil(curvature));
				diffuseColor = DiffuseAndSpecularFromMetallic(diffuseColor, Metallic, specularColor, specularMonochrome);

#ifdef _ALPHAPREMULTIPLY_ON
				alpha =_MainTex_var.a*_Color.a;
	#ifdef UNITY_COLORSPACE_GAMMA
				alpha = pow(alpha, 2.2);
	#endif
				diffuseColor *=alpha;
				specularColor *=alpha;
#endif

////specularColor:
                specularMonochrome = 1.0-specularMonochrome;
                specularColor = lerp(specularColor,diffuseColor*0.3,_Mask_var.a);

////DirectDiffuse:
				half scaledNL = saturate( (NdotL + 1 + _SSSWrap * curvature) / (2.0 + _SSSWrap * curvature) );
				half3 profileColor = tex2D(_SkinProfile, half2(scaledNL, curvature)).rgb;
				half3 diffuseTerm = lerp(profileColor.rgb, profileColor.rrr, _ScatterProfileColor);
				half3 directDiffuse = lerp(lightColor * saturate(NdotL), _ScatterColor * diffuseTerm * lightColor, ceil(curvature));

////IndirectDiffuse:
				float4 ambientColor = lerp(_AmbinetDown,_AmbientTop,TopN);
				half fillLightFactor = saturate(dot(normalDirection, fillLightDir));
				float3 indirectDiffuse = ambientColor.rgb+fillLightColor * fillLightFactor;

////DirectSpecular:
				//主光源各向异性高光计算 kajiya-kay光照模型
				float3 kajiyaNormalDirection =normalize( normalDirection+mul( float3(_Aniso.xy,0), tangentTransform )*_Mask_var.a);
                float kajiyaNdotH  = max(0.0,lerp(dot(kajiyaNormalDirection, halfDirection), dot(kajiyaNormalDirection, viewDirection ), _Mask_var.a));//丝绸的主高光完全跟随视线以保证高光线平直
				kajiyaNdotH  = lerp(kajiyaNdotH, max(0,sin(radians(kajiyaNdotH +0)*180)),_Mask_var.a);
				if (curvature >0.05)
				{
					SpecularTerm = KS_Skin_Specular(normalDirection, lightDirection, viewDirection, max(perceptualRoughness,0.1));//max（x，0.1）是避免脸部绝对光滑。过于光滑的表面高光会变成一个点，比如瓷器。
				}
				else
				{
					SpecularTerm = GetSpecularTerm(roughness, perceptualRoughness, Smoothness,kajiyaNdotH, LdotH);
				}
                float3 directSpecularMainLight = SpecularTerm*lightColor * saturate(NdotL*0.7+0.3) * lerp(specularColor,float3(1,1,1)*_SkinSI,ceil(curvature));//高光不明显用这一行替换。因为KS皮肤不用s走非金属F0 为0.04的反射计算。

				//辅光源各向异性高光计算 kajiya-kay光照模型
				float3 kajiyaNormalDirection2 =normalize( normalDirection+mul( float3(_Aniso.zw,0), tangentTransformVertical )*_Mask_var.a);
				float kajiyaNdotH2 =max(0.0,dot(kajiyaNormalDirection2, viewDirection ));
				kajiyaNdotH2 = lerp(kajiyaNdotH2,max(0,sin(radians(kajiyaNdotH2+0)*180)),_Mask_var.a);
				half specularPower = PerceptualRoughnessToSpecPower(perceptualRoughness);
				SpecularTerm2 = specularPower * pow(kajiyaNdotH2,specularPower);
#ifdef UNITY_COLORSPACE_GAMMA
				SpecularTerm2 = specularPower/3 * pow(kajiyaNdotH2,specularPower);
#endif
                float3 directSpecularFillLight = SpecularTerm2 * specularColor * saturate(NdotL*0.5+0.5) * fillLightColor *(1-ceil(curvature));
				//主辅光源高光合并及钳制
                float3 directSpecular = clamp(directSpecularMainLight+directSpecularFillLight, 0.0, 100.0);// Prevent FP16 overflow on mobiles

////IndirectSpecular:
				float3 indirectSpecular = Reflection(normalDirection,Metallic,perceptualRoughness,viewDirection)*specularColor;

////specular
                float3 specular = (SilkNoise.b*3*directSpecular.r*_Mask_var.a+directSpecular + indirectSpecular*(1-ceil(curvature)))*surfaceReduction;///如果美术角色皮肤有一层白光去掉皮肤部分的反射就可以

////diffuse
				half GlitterFresnel = pow(1-NdotV,_GlitterColorWidth);//闪白
#ifdef _UICHAR
				float3 diffuse = (directDiffuse + indirectDiffuse) * diffuseColor * lerp(_SkinShadowColor, 1, attenuation);
#else
                float3 diffuse = (directDiffuse + indirectDiffuse) * diffuseColor * lerp(_SkinShadowColor, 1, attenuation) + _GlitterColor.rgb * GlitterFresnel;
#endif

////Final Color:
                float3 finalColor = (diffuse + specular)*Ao;
				
////闪点和自发光
				float shanpoint = FlashPoint(i.uv0, _Emit_var, NdotV, specular);
				finalColor = clamp(finalColor+shanpoint*_EmitIntensity,0,16);
				finalColor.rgb += _EmissionColor.rgb * _Emit_var.a;

////整体角色灰色显示
				finalColor = lerp(finalColor,Luminance(finalColor)*float3(1,1,1),_gray);

			
#ifdef UNITY_COLORSPACE_GAMMA
				finalColor = pow(finalColor, 0.45);
				alpha = pow(alpha, 0.45);
#endif
                fixed4 finalRGBA = fixed4(finalColor,alpha);
				//阴影
//				finalRGBA *= ShadowColorAtten(i.posWorld);
//#ifdef PROJECTOR_DEPTH_MAP_ON
//				finalRGBA *= ProjectorShadowColorAtten(i.posWorld);
//#endif
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(i.fogCoord, finalRGBA.rgb);
				}else
				{
					UNITY_APPLY_FOG(i.fogCoord, finalRGBA);				
				}
                return finalRGBA;
            }
            ENDCG
        }
    }

	FallBack "TLStudio/CharSkin_Middle"
	CustomEditor "CustomStandardShaderEditor"
}
