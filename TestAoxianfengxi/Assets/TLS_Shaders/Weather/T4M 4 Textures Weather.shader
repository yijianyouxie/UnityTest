// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable
// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

Shader "TLStudio/Weather/T4M/T4M 4 Textures Weather"
{
	Properties
	{
		_SpecColor("地表反射光颜色", Color) = (0.4862, 0.4049, 0.2822, 0)

		_HaveAlphaL0("层1-是否开启反射，(只可填0或1，其中0代表不反射，1代表反射)", Int) = 0
		_ShininessL0("层1-反射强度", Range(0.03, 1)) = 0.078125
		_Splat0("层1-纹理贴图", 2D) = "white" {}
		
		_HaveAlphaL1("层2-是否开启反射，(只可填0或1，其中0代表不反射，1代表反射)", Int) = 0
		_ShininessL1("层2-反射强度", Range(0.03, 1)) = 0.078125
		_Splat1("层2-纹理贴图", 2D) = "white" {}
		
		_HaveAlphaL2("层3-是否开启反射，(只可填0或1，其中0代表不反射，1代表反射)", Int) = 0
		_ShininessL2("层3-反射强度", Range(0.03, 1)) = 0.078125
		_Splat2("层3-纹理贴图", 2D) = "white" {}
		
		_HaveAlphaL3("层4-是否开启反射，(只可填0或1，其中0代表不反射，1代表反射)", Int) = 0
		_ShininessL3("层4-反射强度", Range(0.03, 1)) = 0.078125
		_Splat3("层4-纹理贴图", 2D) = "white" {}
		
		_Control("层5-控制贴图", 2D) = "white" {} 
		
		_TintMask_SnowR_RainR("积雪在红通道 积水在绿通道", 2D) = "white" {}
		_RainMaskPower("积水纹理的Power",Range(0.0,2.0)) = 0.5
		   
		_TintTex("积雪部分替换纹理", 2D) = "white" {}  
		_TintTexTiling("积雪替换纹理的Tiling", Range(0.01, 100)) = 5  
		_TintPowerMaxRange("积雪强度上限",Range(0,2)) = 2 
		_TintNormalEx("模型边缘积雪范围",Range(-1,1)) = 0.05 
 
		//_NormalNoisePower("NormalNoisePower",Range(0,1)) = 0
		    
		_NormalNoiseMap("积水扰动法线的图 (RG) noise Normal",2D) = "Black" {}  		
		_NormalNoiseSpeed("法线扰动的速度",Range(0,1)) = 1
		_NormalNoiseMapPower("积水扰动法线图的Power",Range(0.001,2.0)) = 0.5 
		_NormalNoiseTiling("扰动法线图的Tiling",Range(0.01,10)) = 6 
		_AttenHigh("法线与Y轴夹角的dot值大于这个值时为完全的积水效果",Range(0.5,1)) = 0.95
		_AttenRange("法线与Y轴夹角的dot值在这范围内衰减",Range(0.01,0.45)) = 0.1
		_LowValue("根据法线朝向重新计算的雨水效果的最低输出值",Range(0,0.2)) = 0
		_RainLightDarkValue("雨天的光线变暗的值",Range(0,0.8)) = 0.385
		_RainSkyColor("雨天的整体颜色，Alpha通道为可以加强强度",Color) = (0.5,0.75,1, 0.8)
		
		_TexRollMap("下雨流水的图 ",2D) = "Black" {} 
		_TexRollMapTiling("下雨流水图的Tiling",Range(0.001,5)) = 0.13 
		_TexRollMapPower("下雨流水图的Power",Range(0,5)) = 1.4
		_TexRollMapSpeed("下雨流水图的速度",Range(0.1,5)) = 1.4
		_TexRollAttenHigh("法线与Y轴夹角的dot值大于这个值时为完全的积水效果",Range(0.5,1)) = 0.85
		_TexRollAttenRange("法线与Y轴夹角的dot值在这范围内衰减",Range(0.01,0.45)) = 0.2
		_TexRollLowValue("根据法线朝向重新计算的雨水效果的最低输出值",Range(0,0.2)) = 0
		
		_Decal2Tiling("两张扰动纹理和流水贴图叠加的程度",Range(1,2)) = 1.2 
		
		_LightPos("光源位置", Vector) = (100,100,100,100)
			_ambientColor("AmbientLight", Range(0.1, 2)) = 1
			_lambert("LambertLight",Range(0.1, 2)) = 1
	}
	//本身使用八张纹理
	SubShader
	{
		Tags
		{
			"Queue" = "Geometry+500"
			"SplatCount" = "4"
			"RenderType" = "Opaque"
		}
		LOD 200
		pass
		{
			Name "ForwardBase"
			Tags
			{
				"LightMode" = "ForwardBase"
			}
			
			CGPROGRAM
			#pragma skip_variants DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTPROBE_SH VERTEXLIGHT_ON
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			//#pragma multi_compile TINT_DISABLE TINT_ENABLE
			//#pragma multi_compile GLOBALSH_DISABLE GLOBALSH_ENABLE
			//#pragma multi_compile RAIN_DISABLE RAIN_ENABLE

			#ifndef VAR_TINT_TEX 
			#define VAR_TINT_TEX
			#endif
			
			#include "Assets/TLS_Shaders/UnityCG.cginc"
			#include "Assets/TLS_Shaders/CGIncludes/AutoLight.cginc"
			#include "Assets/TLS_Shaders/CGIncludes/Lighting.cginc"
			//在实际使用的时候路径需要改
			#include "../../TLS_Shaders/Weather/Include/CommonCal.cginc"  
			#include "../../TLS_Shaders/Weather/Include/TintColor.cginc"
			#include "../../TLS_Shaders/Weather/Include/NoiseAndDecal.cginc"
			#pragma multi_compile_fwdbase_fullshadows
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			
			uniform sampler2D _Splat0; uniform float4 _Splat0_ST;
			uniform sampler2D _Splat1; uniform float4 _Splat1_ST;
			uniform sampler2D _Splat2; uniform float4 _Splat2_ST;
			uniform sampler2D _Splat3; uniform float4 _Splat3_ST;
			uniform sampler2D _Control; uniform float4 _Control_ST;
			
			uniform fixed _ShininessL0;
			uniform fixed _ShininessL1;
			uniform fixed _ShininessL2;
			uniform fixed _ShininessL3;

			uniform fixed _HaveAlphaL0;
			uniform fixed _HaveAlphaL1;
			uniform fixed _HaveAlphaL2;
			uniform fixed _HaveAlphaL3;

			uniform float4 _LightPos;
			float _ambientColor;
			float _lambert;
			VAR_TINT_COLOR_NEED
			VAR_NOISE_DECAL_NEED 
			half _RainLightDarkValue;
			fixed4 _RainSkyColor;
#ifdef SHADOWS_SHADOWMASK
			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord0 : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
			};
			
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float4 uv0 : TEXCOORD0;	//xy : Splat0 | zw : LightMap  
				float4 uv1 : TEXCOORD1;	//xy : Splat1 | zw : Splat2
				float4 uv2 : TEXCOORD2;	//xy : Splat3 | zw : Control
				float3 worldpos : TEXCOORD3;
				float3 normalDir : TEXCOORD4;
#ifdef GLOBALSH_ENABLE
				float3 vlighting : TEXCOORD5;
				UNITY_SHADOW_COORDS(6)
					UNITY_FOG_COORDS(7)
#else
				UNITY_SHADOW_COORDS(5)
				UNITY_FOG_COORDS(6)
#endif
			};
			
			VertexOutput vert(VertexInput v) {
				VertexOutput o;
				UNITY_INITIALIZE_OUTPUT(VertexOutput, o);
				o.uv0.xy = TRANSFORM_TEX(v.texcoord0, _Splat0);
				o.uv1.xy = TRANSFORM_TEX(v.texcoord0, _Splat1);
				o.uv1.zw = TRANSFORM_TEX(v.texcoord0, _Splat2);
				o.uv2.xy = TRANSFORM_TEX(v.texcoord0, _Splat3);
				o.uv2.zw = TRANSFORM_TEX(v.texcoord0, _Control);
				
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldpos.xyz = mul(unity_ObjectToWorld, v.vertex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				
				#ifndef LIGHTMAP_OFF
					float2 lmuv = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw;
					o.uv0.z = lmuv.x;
					o.uv0.w = lmuv.y;
				#else
					float3 lightColor = _LightColor0.rgb;
					o.uv0.zw = float2(0,0);
				#endif 
				#ifdef GLOBALSH_ENABLE
				o.vlighting = ShadeSH9 (float4(o.normalDir, 1.0));
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

			fixed4 frag(VertexOutput i) : COLOR
			{  
				float3 worldpos = i.worldpos;

				fixed3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - worldpos);
				fixed3 normalDirection = normalize(i.normalDir.xyz);
				fixed3 lightDirection1 = normalize(_LightPos.xyz);
				fixed3 halfDirection = normalize(viewDirection + lightDirection1.xyz);
				UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldpos);
				
				float2 uvOffset = float2(0,0);
				if (RAIN_ENABLE > 0)
				{
					NOISE_TEX_4TERRAIN(worldpos, i.uv2.zw, normalDirection, uvOffset)
				}
				fixed4 _Control_var = tex2D(_Control,i.uv2.zw);
				fixed4 _Splat0_var = tex2D(_Splat0,i.uv0.xy + uvOffset);
				fixed4 _Splat1_var = tex2D(_Splat1,i.uv1.xy + uvOffset); 
				fixed4 _Splat2_var = tex2D(_Splat2,i.uv1.zw + uvOffset);
				fixed4 _Splat3_var = tex2D(_Splat3,i.uv2.xy + uvOffset);
				fixed3 f_c = ((_Control_var.r*_Splat0_var.rgb) + (_Control_var.g*_Splat1_var.rgb) + (_Control_var.b*_Splat2_var.rgb) + (_Control_var.a*_Splat3_var.rgb));
				 
				if(TINT_ENABLE > 0)			
				{
					TINT_TEX_MASKMAP_BASECOLOR_DOT_AUTO_UV(worldpos,normalDirection,i.uv2.zw,f_c)
					//TINT_CAL_COLOR_DOT_NOMASKMAP_FAKENOR_T4M_2PARAMS(i.uv2.zw,half3x3(i.tangentToWorldAndPackedData[0].xyz,i.tangentToWorldAndPackedData[1].xyz,i.tangentToWorldAndPackedData[2].xyz),f_c,normalDirection,f_c,normalDirection)
				}
				
				if (RAIN_ENABLE > 0)
				{
					//TWO_RECAL_SNOWMASK_4TERRAIN(worldpos,i.uv2.zw,normalDirection,f_c,f_c)
					
					#ifndef LIGHTMAP_OFF
						//开着LightMap的情况下，法线扰动目前不起作用
						RECAL_SNOWMASK_4TERRAIN(worldpos ,i.uv2.zw,normalDirection,f_c,f_c)
					#else					
						//扰动法线     
						float4 normal_water = float4(normalDirection,0);
						NOISE_NOR_RECAL_SNOWMASK_4TERRAIN(worldpos ,i.uv2.zw,normalDirection,f_c,normal_water,f_c) 
						//return fixed4(normalDirection,1);
						normalDirection = normalize(normal_water.xyz);
#endif
				}

				float2 lmuv = float2(i.uv0.z, i.uv0.w);
				#ifndef LIGHTMAP_OFF
					fixed4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap,lmuv);
					fixed3 lightmap = DecodeLightmap(lmtex);
					lightmap = BlendLightmap(lightmap, lmuv);
					fixed3 lightColor = _LightColor0.rgb*_ambientColor;
					fixed3 directDiffuse = lightmap.rgb*_lambert;
					
					//#ifdef RAIN_ENABLE 
					//	fixed3 lightDirection = normalize(_LightPos.xyz);
					//	fixed NdotL = max(0.0,dot(normalDirection, lightDirection));
					//	directDiffuse = directDiffuse * (1 - min(_RainLightDarkValue ,_NormalNoisePower)) + (_RainSkyColor.a + 1) * _RainSkyColor.rgb * NdotL * normal_water.w * min(_RainLightDarkValue,_NormalNoisePower);//normal_water.w;
					//#endif 
				#else
					fixed3 lightDirection = normalize(_LightPos.xyz); 
					fixed3 attenColor = attenuation * _LightColor0.xyz;
					fixed3 lightColor = _LightColor0.rgb;
					fixed NdotL = max(0.0,dot(normalDirection, lightDirection));
					fixed3 directDiffuse = max(0.0, NdotL) * attenColor;
				#endif
				half atten2 = UnityComputeForwardShadows(lmuv, i.worldpos, 0);
				directDiffuse += directDiffuse * atten2 * lightColor;
				fixed f_g = (_HaveAlphaL0 * _Control_var.r * _Splat0_var.a) + (_HaveAlphaL1 * _Control_var.g * _Splat1_var.a) + (_HaveAlphaL2 * _Control_var.b * _Splat2_var.a) + (_HaveAlphaL3 * _Control_var.a * _Splat3_var.a);
				fixed f_s = _ShininessL0 * _Control_var.r + _ShininessL1 * _Control_var.g + _ShininessL2 * _Control_var.b + _ShininessL3 * _Control_var.a;
				fixed nh = max(0, dot(halfDirection, normalDirection));
				fixed spec = max(0, pow(nh, f_s * 128)) * f_g;
				fixed3 fs = ((f_c * _SpecColor.w) + (_SpecColor.xyz * spec)) * 2.0;
				fixed3 fc = fs + (f_c * directDiffuse);
				#ifdef GLOBALSH_ENABLE
				fc = fc*max(fixed3(1.0,1.0,1.0),(i.vlighting - UNITY_LIGHTMODEL_AMBIENT.xyz)*2);
				#endif
				 // apply fog
												 //UNITY_APPLY_FOG_COLOR(i.fogCoord, fc, fixed4(0,0,0,0)); //custom fog color
				fc = (f_c * directDiffuse/**atten*/) + fs;
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(i.fogCoord, fc.rgb);
				}else
				{
					UNITY_APPLY_FOG(i.fogCoord, fc);				
				}
				return fixed4(fc,1);
			}
#else
struct VertexInput {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 texcoord0 : TEXCOORD0;
	float2 texcoord1 : TEXCOORD1;
};

struct VertexOutput {
	float4 pos : SV_POSITION;
	float4 uv0 : TEXCOORD0;	//xy : Splat0 | zw : LightMap  
	float4 uv1 : TEXCOORD1;	//xy : Splat1 | zw : Splat2
	float4 uv2 : TEXCOORD2;	//xy : Splat3 | zw : Control
	float3 worldpos : TEXCOORD3;
	float3 normalDir : TEXCOORD4;
#ifdef GLOBALSH_ENABLE
	float3 vlighting : TEXCOORD5;
	LIGHTING_COORDS(6, 7)
		UNITY_FOG_COORDS(8)
#else
	LIGHTING_COORDS(5, 6)
		UNITY_FOG_COORDS(7)
#endif
};

VertexOutput vert(VertexInput v) {
	VertexOutput o;
	UNITY_INITIALIZE_OUTPUT(VertexOutput, o);
	o.uv0.xy = TRANSFORM_TEX(v.texcoord0, _Splat0);
	o.uv1.xy = TRANSFORM_TEX(v.texcoord0, _Splat1);
	o.uv1.zw = TRANSFORM_TEX(v.texcoord0, _Splat2);
	o.uv2.xy = TRANSFORM_TEX(v.texcoord0, _Splat3);
	o.uv2.zw = TRANSFORM_TEX(v.texcoord0, _Control);

	o.pos = UnityObjectToClipPos(v.vertex);
	o.worldpos.xyz = mul(unity_ObjectToWorld, v.vertex);
	o.normalDir = UnityObjectToWorldNormal(v.normal);

#ifndef LIGHTMAP_OFF
	float2 lmuv = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw;
	o.uv0.z = lmuv.x;
	o.uv0.w = lmuv.y;
#else
	float3 lightColor = _LightColor0.rgb;
	o.uv0.zw = float2(0, 0);
#endif 
#ifdef GLOBALSH_ENABLE
	o.vlighting = ShadeSH9(float4(o.normalDir, 1.0));
#endif

	TRANSFER_VERTEX_TO_FRAGMENT(o)
		if(UseHeightFog > 0)
		{
			TL_TRANSFER_FOG(o, o.pos, v.vertex);
		}else
		{
			UNITY_TRANSFER_FOG(o, o.pos);		
		}
	return o;
}

fixed4 frag(VertexOutput i) : COLOR
{
	float3 worldpos = i.worldpos;

	fixed3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - worldpos);
	fixed3 normalDirection = normalize(i.normalDir.xyz);
	fixed3 lightDirection1 = normalize(_LightPos.xyz);
	fixed3 halfDirection = normalize(viewDirection + lightDirection1.xyz);
	fixed attenuation = LIGHT_ATTENUATION(i);

	float2 uvOffset = float2(0,0);
	if (RAIN_ENABLE > 0)
	{
		NOISE_TEX_4TERRAIN(worldpos, i.uv2.zw, normalDirection, uvOffset)
	}

		fixed4 _Control_var = tex2D(_Control,i.uv2.zw);
	fixed4 _Splat0_var = tex2D(_Splat0,i.uv0.xy + uvOffset);
	fixed4 _Splat1_var = tex2D(_Splat1,i.uv1.xy + uvOffset);
	fixed4 _Splat2_var = tex2D(_Splat2,i.uv1.zw + uvOffset);
	fixed4 _Splat3_var = tex2D(_Splat3,i.uv2.xy + uvOffset);
	fixed3 f_c = ((_Control_var.r*_Splat0_var.rgb) + (_Control_var.g*_Splat1_var.rgb) + (_Control_var.b*_Splat2_var.rgb) + (_Control_var.a*_Splat3_var.rgb));

	if (TINT_ENABLE > 0)
	{
		TINT_TEX_MASKMAP_BASECOLOR_DOT_AUTO_UV(worldpos,normalDirection,i.uv2.zw,f_c)
	}
		//TINT_CAL_COLOR_DOT_NOMASKMAP_FAKENOR_T4M_2PARAMS(i.uv2.zw,half3x3(i.tangentToWorldAndPackedData[0].xyz,i.tangentToWorldAndPackedData[1].xyz,i.tangentToWorldAndPackedData[2].xyz),f_c,normalDirection,f_c,normalDirection)

	if (RAIN_ENABLE > 0)
	{
		//TWO_RECAL_SNOWMASK_4TERRAIN(worldpos,i.uv2.zw,normalDirection,f_c,f_c)

#ifndef LIGHTMAP_OFF
		//开着LightMap的情况下，法线扰动目前不起作用
		RECAL_SNOWMASK_4TERRAIN(worldpos ,i.uv2.zw,normalDirection,f_c,f_c)
#else					
		//扰动法线     
		float4 normal_water = float4(normalDirection,0);
		NOISE_NOR_RECAL_SNOWMASK_4TERRAIN(worldpos ,i.uv2.zw,normalDirection,f_c,normal_water,f_c)
			//return fixed4(normalDirection,1);
			normalDirection = normalize(normal_water.xyz);
#endif
	}

#ifndef LIGHTMAP_OFF
		float2 lmuv = float2(i.uv0.z, i.uv0.w);
		fixed4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap,lmuv);
		fixed3 lightmap = DecodeLightmap(lmtex);
		lightmap = BlendLightmap(lightmap, lmuv);
		fixed3 directDiffuse = min(lightmap.rgb, attenuation*lightmap.rgb);

		//#ifdef RAIN_ENABLE 
		//	fixed3 lightDirection = normalize(_LightPos.xyz);
		//	fixed NdotL = max(0.0,dot(normalDirection, lightDirection));
		//	directDiffuse = directDiffuse * (1 - min(_RainLightDarkValue ,_NormalNoisePower)) + (_RainSkyColor.a + 1) * _RainSkyColor.rgb * NdotL * normal_water.w * min(_RainLightDarkValue,_NormalNoisePower);//normal_water.w;
		//#endif 
#else
		fixed3 lightDirection = normalize(_LightPos.xyz);
		fixed3 attenColor = attenuation * _LightColor0.xyz;
		fixed3 lightColor = _LightColor0.rgb;
		fixed NdotL = max(0.0,dot(normalDirection, lightDirection));
		fixed3 directDiffuse = max(0.0, NdotL) * attenColor;
#endif

		fixed f_g = (_HaveAlphaL0 * _Control_var.r * _Splat0_var.a) + (_HaveAlphaL1 * _Control_var.g * _Splat1_var.a) + (_HaveAlphaL2 * _Control_var.b * _Splat2_var.a) + (_HaveAlphaL3 * _Control_var.a * _Splat3_var.a);
		fixed f_s = _ShininessL0 * _Control_var.r + _ShininessL1 * _Control_var.g + _ShininessL2 * _Control_var.b + _ShininessL3 * _Control_var.a;
		fixed nh = max(0, dot(halfDirection, normalDirection));
		fixed spec = max(0, pow(nh, f_s * 128)) * f_g;
		fixed3 fs = ((f_c * _SpecColor.w) + (_SpecColor.xyz * spec)) * 2.0;
		fixed3 fc = fs + (f_c * directDiffuse);
#ifdef GLOBALSH_ENABLE
		fc = fc*max(fixed3(1.0,1.0,1.0),(i.vlighting - UNITY_LIGHTMODEL_AMBIENT.xyz) * 2);
#endif
		if(UseHeightFog > 0)
		{
			TL_APPLY_FOG(i.fogCoord, fc.rgb);
		}else
		{
			UNITY_APPLY_FOG(i.fogCoord, fc); // apply fog		
		}
										 //UNITY_APPLY_FOG_COLOR(i.fogCoord, fc, fixed4(0,0,0,0)); //custom fog color
		return fixed4(fc,1);
}
#endif
			ENDCG
		}
	}
	//本身使用六张纹理
	SubShader
	{
		Tags
		{
			"Queue" = "Geometry+500"
			"SplatCount" = "4"
			"RenderType" = "Opaque"
		}
		LOD 200
		pass
		{
			Name "ForwardBase"
			Tags
			{
				"LightMode" = "ForwardBase"
			}
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			//#pragma multi_compile TINT_DISABLE TINT_ENABLE
			//#pragma multi_compile GLOBALSH_DISABLE GLOBALSH_ENABLE

			#ifndef VAR_TINT_TEX 
			#define VAR_TINT_TEX
			#endif
			
			#include "Assets/TLS_Shaders/UnityCG.cginc"
			#include "Assets/TLS_Shaders/CGIncludes/AutoLight.cginc"
			#include "Assets/TLS_Shaders/CGIncludes/Lighting.cginc"
			//在实际使用的时候路径需要改
			#include "../../TLS_Shaders/Weather/Include/CommonCal.cginc"  
			#include "../../TLS_Shaders/Weather/Include/TintColor.cginc"
			#pragma multi_compile_fwdbase_fullshadows
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			
			uniform sampler2D _Splat0; uniform float4 _Splat0_ST;
			uniform sampler2D _Splat1; uniform float4 _Splat1_ST;
			uniform sampler2D _Splat2; uniform float4 _Splat2_ST;
			uniform sampler2D _Splat3; uniform float4 _Splat3_ST;
			uniform sampler2D _Control; uniform float4 _Control_ST;
			
			uniform fixed _ShininessL0;
			uniform fixed _ShininessL1;
			uniform fixed _ShininessL2;
			uniform fixed _ShininessL3;

			uniform fixed _HaveAlphaL0;
			uniform fixed _HaveAlphaL1;
			uniform fixed _HaveAlphaL2;
			uniform fixed _HaveAlphaL3;

			uniform float4 _LightPos;
			float _ambientColor;
			VAR_TINT_COLOR_NEED
			
			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord0 : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
			};
			
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float4 uv0 : TEXCOORD0;	//xy : Splat0 | zw : LightMap  
				float4 uv1 : TEXCOORD1;	//xy : Splat1 | zw : Splat2
				float4 uv2 : TEXCOORD2;	//xy : Splat3 | zw : Control
				float3 worldpos : TEXCOORD3;
				float3 normalDir : TEXCOORD4;
#ifdef GLOBALSH_ENABLE
				float3 vlighting : TEXCOORD5;
				UNITY_SHADOW_COORDS(6)
					UNITY_FOG_COORDS(7)
#else
				UNITY_SHADOW_COORDS(5)
					UNITY_FOG_COORDS(6)
#endif
			};
			
			VertexOutput vert(VertexInput v) {
				VertexOutput o;
				UNITY_INITIALIZE_OUTPUT(VertexOutput, o);
				o.uv0.xy = TRANSFORM_TEX(v.texcoord0, _Splat0);
				o.uv1.xy = TRANSFORM_TEX(v.texcoord0, _Splat1);
				o.uv1.zw = TRANSFORM_TEX(v.texcoord0, _Splat2);
				o.uv2.xy = TRANSFORM_TEX(v.texcoord0, _Splat3);
				o.uv2.zw = TRANSFORM_TEX(v.texcoord0, _Control);
				
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldpos.xyz = mul(unity_ObjectToWorld, v.vertex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				
				#ifndef LIGHTMAP_OFF
					float2 lmuv = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw;
					o.uv0.z = lmuv.x;
					o.uv0.w = lmuv.y;
				#else
					float3 lightColor = _LightColor0.rgb;
					o.uv0.zw = float2(0,0);
				#endif 
				#ifdef GLOBALSH_ENABLE
				o.vlighting = ShadeSH9 (float4(o.normalDir, 1.0));
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

			fixed4 frag(VertexOutput i) : COLOR
			{  
				float3 worldpos = i.worldpos;

				fixed3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - worldpos);
				fixed3 normalDirection = normalize(i.normalDir.xyz);
				fixed3 lightDirection1 = normalize(_LightPos.xyz);
				fixed3 halfDirection = normalize(viewDirection + lightDirection1.xyz);
				UNITY_LIGHT_ATTENUATION(attenuation,i,i.worldpos);
			 
				fixed4 _Control_var = tex2D(_Control,i.uv2.zw);
				fixed4 _Splat0_var = tex2D(_Splat0,i.uv0.xy);
				fixed4 _Splat1_var = tex2D(_Splat1,i.uv1.xy); 
				fixed4 _Splat2_var = tex2D(_Splat2,i.uv1.zw);
				fixed4 _Splat3_var = tex2D(_Splat3,i.uv2.xy);
				fixed3 f_c = ((_Control_var.r*_Splat0_var.rgb) + (_Control_var.g*_Splat1_var.rgb) + (_Control_var.b*_Splat2_var.rgb) + (_Control_var.a*_Splat3_var.rgb));
				
				if (TINT_ENABLE > 0)
				{
					TINT_TEX_NOMASK_BASECOLOR_DOT_AUTO_UV(worldpos,normalDirection,f_c)
				}
					//TINT_CAL_COLOR_DOT_FAKENOR_T4M_2PARAMS(i.uv2.zw,half3x3(i.tangentToWorldAndPackedData[0].xyz,i.tangentToWorldAndPackedData[1].xyz,i.tangentToWorldAndPackedData[2].xyz),f_c,normalDirection,f_c,normalDirection)
				float2 lmuv = float2(i.uv0.z, i.uv0.w);
				#ifndef LIGHTMAP_OFF
					fixed4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap,lmuv);
					fixed3 lightmap = DecodeLightmap(lmtex);
					lightmap = BlendLightmap(lightmap, lmuv);
					fixed3 directDiffuse = lightmap.rgb;
					fixed3 lightColor = _LightColor0.rgb*_ambientColor;
				#else
					fixed3 lightDirection = normalize(_LightPos.xyz); 
					fixed3 attenColor = attenuation * _LightColor0.xyz;
					fixed NdotL = max(0.0,dot(normalDirection, lightDirection));
					fixed3 directDiffuse = max(0.0, NdotL) * attenColor;
					fixed3 lightColor = _LightColor0.rgb;
				#endif
				half atten2 = UnityComputeForwardShadows(lmuv, i.worldpos, 0);
				directDiffuse += directDiffuse * atten2 * lightColor;
				fixed f_g = (_HaveAlphaL0 * _Control_var.r * _Splat0_var.a) + (_HaveAlphaL1 * _Control_var.g * _Splat1_var.a) + (_HaveAlphaL2 * _Control_var.b * _Splat2_var.a) + (_HaveAlphaL3 * _Control_var.a * _Splat3_var.a);
				fixed f_s = _ShininessL0 * _Control_var.r + _ShininessL1 * _Control_var.g + _ShininessL2 * _Control_var.b + _ShininessL3 * _Control_var.a;
				fixed nh = max(0, dot(halfDirection, normalDirection));
				fixed spec = max(0, pow(nh, f_s * 128)) * f_g;
				fixed3 fs = ((f_c * _SpecColor.w) + (_SpecColor.xyz * spec)) * 2.0;
				fixed3 fc = fs + (f_c * directDiffuse);
				#ifdef GLOBALSH_ENABLE
				fc = fc*max(fixed3(1.0,1.0,1.0),(i.vlighting - UNITY_LIGHTMODEL_AMBIENT.xyz)*2);
				#endif
												 //UNITY_APPLY_FOG_COLOR(i.fogCoord, fc, fixed4(0,0,0,0)); //custom fog color
				fc = (f_c * directDiffuse/**atten*/) + fs;
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(i.fogCoord, fc.rgb);
				}else
				{
					UNITY_APPLY_FOG(i.fogCoord, fc); // apply fog				
				}
				return fixed4(fc,1);
			}
			ENDCG
		}
	}
	
	FallBack "T4MShaders/ShaderModel2/Diffuse/T4M 4 Textures"
}
