Shader "TLStudio/CharCrystal_Low" 
{
	Properties
	{
		[MaterialEnum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
		_Cutoff("Alpha Cutoff", Range(0,1)) = 0.5

		[HideInInspector] _Mode("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
		[HideInInspector] _ZWrite("__zw", Float) = 1.0


		//[Header(Ambient)]
		//_AmbientIntensity("Ambient Intensity", Range(0, 1)) = 0.8
		//_ShadowAttenFactorTest("_ShadowAttenFactorTest", Range(0,1)) = 0.3
		

		[Header( Color)]
		[HDR]_Color("Color(整体染色用)", Color) = (1,1,1,1)
		_MainTex("Main Tex", 2D) = "white" {}
		_MainTexUV_A("MainTexTilingOffset_A", vector) = (1, 1, 0, 0)
		_Distortion3("MainTex Distortion", Range(-5, 5)) = 0
		_MainTexUVOffsetSpeed("MainTex UV Offset Speed",Range(0,1)) = 0
		_MainTexScale("MainTex Scale", Range(0,10)) = 1.0
		_MainTexPower("MainTex Power", Range(0.01,10)) = 1.0


		[Header(Normal)]
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Normal Scale", Range(-2,2)) = 1.0
		_BumpDetailMap("Detail Normal Map", 2D) = "bump" {}
		_BumpDetailScale("Detail Normal Scale",  Range(-2,2)) = 0.0


		[Header(Mixed Map)]
		[NoScaleOffset]_EmitMask("Mixed Mask(R:Emit  G:FlashPoint)", 2D) = "black" {}
		_EmitMaskUV("Emit Mask Tiling Offset", vector) = (1, 1, 0, 0)
		_FlashPointMaskUV("Flash Point Mask Tiling Offset", vector) = (1, 1, 0, 0)


		[Header(Emission)]
		[HDR]_EmitColor("Emit Color", Color) = (1, 1, 1, 1)
		_Distortion4("EmitTex Distortion", Range(-5, 5)) = 0
		_EmitTexUVOffsetSpeed("EmitTex UV Offset Speed",Range(-1,1)) = 0
		_EmissionMaskPower("Emission Mask Power",Range(0.001,100)) = 1


		[Header(Flash Point)]
		_FlashPointNormal("Flash Point Normal", 2D) = "bump" {}
		_FlashPointNormalScale("Flash Point Normal Scale",  Range(-2,2)) = 0.0


		[HDR]_SpecularK2("FP SpecularK Color", Color) = (0, 0, 0, 1)
		_SpecularFrequency2("FP SpecularK Frequency", Range(0,100)) = 44
		_SpecularPower2("FP SpecularK Power", Range(1,100)) = 2


		[Header(Specular)]
		[HDR]_Specular("Specular Color", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(1, 1000)) = 20

			
		[Header(SpecularK)]
		[HDR]_SpecularK("SpecularK Color", Color) = (1, 1, 1, 1)
		_SpecularFrequency("SpecularK Frequency", Range(0,100)) = 44
		_SpecularPower("SpecularK Power", Range(1,100)) = 2


		[Header(Fresnel)]
		[HDR]_FresnelColor("Fresnel Color", Color) = (1, 1, 1, 1)
		_FresnelPower1("Fresnel Power", Range(0.01, 50)) = 8


		[Header(Cubemap)]
		[HDR]_ReflectColor("Reflection Color", Color) = (1, 1, 1, 1)
		[NoScaleOffset]_Cubemap("Reflection Cubemap", Cube) = "_Skybox" {}
		_CubemapMaskPower("Cubemap Mask Power", Range(0.01,100)) = 10
		_CubemapMaskIntensity("Cubemap Mask Intensity", Range(0,1)) = 0


		[Header(Colorful)]
		[HDR]_Colorful("Colorful Color", Color) = (1, 1, 1, 1)
		_ColorfulTex("Colorful Tex", 2D) = "black" {}
		_ColorfulFrequency("Colorful Speed", Range(0, 2)) = 0.2
		_ColorfulDistortion("Colorful Distortion", Range(0, 10)) = 0
		_ColorfulTexPower("ColorfulTex Power", Range(0.001, 10)) = 1


		[Header(Glitter)]
		[HDR]_GlitterColor("Glitter Color", Color) = (0,0,0,1)//闪白颜色
		_GlitterColorWidth("Glitter Color Width", Range(2,10)) = 2
	}

	SubShader
	{
		Tags {"Queue" = "Geometry+400" "RenderType" = "Opaque"}
		LOD 200
		Stencil{
			Ref 1
			Comp always
			Pass replace
		}//ssao剔除

		Cull[_Cull]
		Blend[_SrcBlend][_DstBlend]
		ZWrite[_ZWrite]

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#define _SHADOWS_PCF

			//#include "Assets/TLStudio/Shaders/CGIncludes/TLStudioCG.cginc"
			#include "UnityCG.cginc"
			#include "CGIncludes/AutoLight.cginc"

			#pragma multi_compile_fwdbase_fullshadows
			#pragma multi_compile _ _UICHAR
			#pragma multi_compile _ _ALPHATEST_ON _ALPHAPREMULTIPLY_ON
			#pragma target 3.0
			#pragma skip_variants LIGHTMAP_ON DYNAMICLIGHTMAP_ON VERTEXLIGHT_ON LIGHTMAP_SHADOW_MIXING SHADOWS_SHADOWMASK 

			
			half _SpecularFrequency, _SpecularPower, _SpecularFrequency2, _SpecularPower2, _CubemapMaskPower, _CubemapMaskIntensity;
			half4 _Color, _EmitColor, _Colorful, _ReflectColor, _FresnelColor, _Specular, _SpecularK, _SpecularK2;
			sampler2D _MainTex, _EmitMask, _ColorfulTex, _BumpMap, _BumpDetailMap, _FlashPointNormal;
			float4 _MainTexUV_A, _FlashPointMaskUV, _EmitMaskUV;
			float4 _ColorfulTex_ST, _BumpMap_ST, _BumpDetailMap_ST, _FlashPointNormal_ST, _MainTex_ST;
			half _BumpScale, _Cutoff, _BumpDetailScale, _FlashPointNormalScale, _Gloss, _FresnelPower1;
			half _MainTexScale, _MainTexPower, _MainTexUVOffsetSpeed, _EmitTexUVOffsetSpeed, _EmissionMaskPower;
			half _Distortion3, _Distortion4, _ColorfulFrequency, _ColorfulDistortion, _ColorfulTexPower;
			samplerCUBE _Cubemap;


			half _ShadowAttenFactor;//0-1
			//half _ShadowAttenFactorTest;
			//half _AmbientIntensity;

			half4 _CharLightDir;
			half4 _CharLightColor;
			//half4 _CharFillLightDir;
			//half4 _CharFillLightColor;
			half4 _CharMainLightSpecularDirection;
			half4 _UICharLightDir;
			half4 _UICharLightColor;
			//half4 _UICharFillLightDir;
			//half4 _UICharFillLightColor;

			half4 _AmbientTop;//hdr
			half4 _AmbinetDown;//hdr
			half4 _UICharAmbientTop;//hdr
			half4 _UICharAmbinetDown;//hdr

			half4 _SkinShadowColor;

			half4 _GlitterColor;//hdr
			half _GlitterColorWidth;//2-10

			

			half3 BlendNormals(half3 n1, half3 n2)
			{
				return normalize(half3(n1.xy + n2.xy, n1.z * n2.z));
			}

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos   : SV_POSITION;
				float4 uv    : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
				float4 uv1   : TEXCOORD4;
				float4 uv2   : TEXCOORD5;
				float4 uv3   : TEXCOORD6;
				LIGHTING_COORDS(7, 8)
				
			};


			v2f vert(a2v v)
			{
				v2f o = (v2f)0;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv.xy  = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw  = v.texcoord.xy * _MainTexUV_A.xy + _MainTexUV_A.zw;
				o.uv1.xy = v.texcoord.xy * _EmitMaskUV.xy + _EmitMaskUV.zw;
				o.uv1.zw = v.texcoord.xy * _FlashPointMaskUV.xy + _FlashPointMaskUV.zw;
				o.uv2.xy = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
				o.uv2.zw = v.texcoord.xy * _BumpDetailMap_ST.xy + _BumpDetailMap_ST.zw;
				o.uv3.xy = v.texcoord.xy * _FlashPointNormal_ST.xy + _FlashPointNormal_ST.zw;
				o.uv3.zw = v.texcoord.xy * _ColorfulTex_ST.xy + _ColorfulTex_ST.zw;

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				TRANSFER_VERTEX_TO_FRAGMENT(o)

				return o;
			}


			half4 frag(v2f i, half facing : VFACE) : COLOR
			{
				half alpha = 1;
				half alphaCut = tex2D(_MainTex, i.uv.zw).a;


#ifdef _ALPHATEST_ON
				clip(alphaCut - _Cutoff);
#endif

				//attenuation
				//float attenuation = LIGHT_ATTENUATION_HUMAN(i);
				float attenuation = LIGHT_ATTENUATION(i);
				attenuation = saturate(attenuation + _ShadowAttenFactor  + /*_ShadowAttenFactorTest*/+ 0.3);

#ifdef _UICHAR
				float3 lightDirection = normalize(_UICharLightDir.xyz);
				float3 lightSpecularDirection = normalize(_UICharLightDir.xyz);
				half3 lightColor = _UICharLightColor.xyz * attenuation;
#else
				float3 lightDirection = normalize(_CharLightDir.xyz);
				float3 lightSpecularDirection = normalize(_CharMainLightSpecularDirection.xyz);
				half3 lightColor = _CharLightColor.xyz * attenuation;
#endif


				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float3 viewSpaceView = normalize(mul(UNITY_MATRIX_V, float4(viewDir, 0.0)).xyz);//将世界空间 的视线 转到 观察空间
				half3 halfDir = normalize(lightDirection + viewDir);
				half3 halfDir_Specular = normalize(lightSpecularDirection + viewDir);


				half flashPointMask = tex2D(_EmitMask, i.uv1.zw).g;
				

				//细节法线
				/*half3 bumpDetail = UnpackNormal(tex2D(_BumpDetailMap, i.uv2.zw));
				bumpDetail.xy *= _BumpDetailScale;
				bumpDetail.z = sqrt(1.0 - saturate(dot(bumpDetail.xy, bumpDetail.xy)));*/
				//主法线
				half3 bump = UnpackNormal(tex2D(_BumpMap, i.uv2.xy));
				bump.xy *= _BumpScale;
				bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
				//闪点法线
				//half3 flashPointNormal = UnpackNormal(tex2D(_FlashPointNormal, i.uv3.xy));
				//flashPointNormal.xy *= _FlashPointNormalScale;
				//flashPointNormal.z = sqrt(1.0 - saturate(dot(flashPointNormal.xy, flashPointNormal.xy)));

				//bumpDetail = lerp(bumpDetail, flashPointNormal, flashPointMask);
				//bump = BlendNormals(bump, bumpDetail);

				half3 flashPointNormal = UnpackNormal(tex2D(_FlashPointNormal, i.uv3.xy));
				flashPointNormal.xy *= _FlashPointNormalScale;
				flashPointNormal.z = sqrt(1.0 - saturate(dot(flashPointNormal.xy, flashPointNormal.xy)));

				half3 bumpDetail = lerp(half3(0, 0, 1), flashPointNormal, flashPointMask);
				bump = BlendNormals(bump, bumpDetail);

				bump = facing > 0 ? bump : -bump;
				

				half3 modelWorldNormal = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				half3 viewSpaceNormal = normalize(mul(UNITY_MATRIX_V, float4(modelWorldNormal, 0.0)).xyz);//将世界空间 的法线 转到 观察空间
				

				//模拟折射
				//世界空间的贴图法线转到观察空间（效果好）
				float2 offset = -viewSpaceNormal.xy * 0.5;

				float TopN = (dot(modelWorldNormal, float3(0, 1, 0)) + 1) * 0.5;

				
				//钻石高光
				float ndotv = dot(viewDir, modelWorldNormal);//nv
				float sinValue = (sin(ndotv * lerp(_SpecularFrequency, _SpecularFrequency2, flashPointMask))  + 1.0) * 0.5;//0-1
				sinValue = pow(sinValue, lerp(_SpecularPower, _SpecularPower2, flashPointMask));
				half3 specularK = lightColor * sinValue * lerp(_SpecularK, _SpecularK2, flashPointMask);


				//主高光
				//half3 specular = lightColor * _Specular.rgb * pow(max(0, dot(modelWorldNormal, halfDir_Specular)), _Gloss);


				//色散 多彩色
				half3 colorfulTex = tex2D(_ColorfulTex, i.uv3.zw + frac(_Time.y * _ColorfulFrequency) - viewSpaceNormal.xy * _ColorfulDistortion) * _Colorful;


				//反射 天空盒
				//float3 worldRefl = reflect(-viewDir, modelWorldNormal);
				//half3 cubeMap = texCUBE(_Cubemap, worldRefl);
				half3 reflection = /*cubeMap **/ _ReflectColor;//为达到宝石效果而添加此项
				

				//菲涅尔反射
				//half3 fresnel = saturate(pow(1 - saturate(ndotv /** 0.5 + 0.5*/), _FresnelPower1)) * _FresnelColor.rgb;
				//half3 reflectionFresnel = cubeMap * fresnel * (1 - flashPointMask);


				half3 mainTex = tex2D(_MainTex, i.uv.xy + offset * _Distortion3 + frac(_Time.y * _MainTexUVOffsetSpeed)).rgb;
				half3 albedo = pow(mainTex, _MainTexPower) * _MainTexScale;


				//自发光
				half3 emissionTex = tex2D(_EmitMask, i.uv1.xy  + offset * _Distortion4 + frac(_Time.y * _EmitTexUVOffsetSpeed)).r;
				emissionTex = saturate(pow(emissionTex, _EmissionMaskPower));
				half3 emission = albedo * lerp(0, _EmitColor.rgb, emissionTex);


				albedo = albedo * _Color.rgb;
				
				half3 diffuse = lightColor * max(0.0, dot(modelWorldNormal, lightDirection) * 1);
					 

				//闪白
				half GlitterFresnel = pow(1 - ndotv, _GlitterColorWidth);

			
				//环境光
#ifdef _UICHAR
				half4 ambientColor = lerp(_UICharAmbinetDown, _UICharAmbientTop, TopN);
#else
				half4 ambientColor = lerp(_AmbinetDown, _AmbientTop, TopN);
#endif
				float ndotNegativeL = (-dot(modelWorldNormal, lightDirection)) * 0.5 + 0.5;//与主光反向的光
				ambientColor.rgb = ambientColor.rgb * max(0.2, ndotNegativeL);


				diffuse = diffuse + ambientColor.rgb * 0.8/*_AmbientIntensity*/;
				

#ifdef _UICHAR
				diffuse = diffuse * albedo * lerp(_SkinShadowColor, 1, attenuation);
#else
				diffuse = diffuse * albedo * lerp(_SkinShadowColor, 1, attenuation) + _GlitterColor.rgb * GlitterFresnel;
#endif

#ifdef _ALPHAPREMULTIPLY_ON
				alpha = alphaCut * _Color.a;
				diffuse *= alpha;
				//specular *= alpha;
				specularK *= alpha;
				//reflectionFresnel *= alpha;
				reflection *= alpha;
				colorfulTex *= alpha;
				emission *= alpha;
#endif


				return half4(
					clamp
					(
						(lerp(saturate(diffuse), saturate(reflection), saturate(pow(saturate(ndotv), _CubemapMaskPower) * _CubemapMaskIntensity)))
						//+
						//reflectionFresnel
						+
						emission
						//+
						//specular
						+
						specularK
						+
						saturate(pow(colorfulTex, _ColorfulTexPower) * pow(1 - saturate(ndotv), 1) * 2)
						, 0, 16
					),
					alpha);
			}
			ENDCG
		}

		Pass
		{
			Name "Caster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On
			ZTest LEqual
			cull back

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
			#pragma multi_compile _ _ALPHATEST_ON _ALPHAPREMULTIPLY_ON
			#include "UnityCG.cginc"

			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2  uv : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			//uniform float4 _MainTex_ST;
			float4 _MainTexUV_A;

			v2f vert(appdata_base v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
			#if defined(_ALPHATEST_ON) || defined(_ALPHAPREMULTIPLY_ON)
				//o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv = v.texcoord.xy * _MainTexUV_A.xy + _MainTexUV_A.zw;

			#endif
				return o;
			}

			uniform sampler2D _MainTex;

			float4 frag(v2f i) : SV_Target
			{
			#if defined(_ALPHATEST_ON) || defined(_ALPHAPREMULTIPLY_ON)
				fixed4 texcol = tex2D(_MainTex, i.uv);
				clip(texcol.a - 0.5);
			#endif
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
	CustomEditor "CustomStandardShaderEditor"
}
