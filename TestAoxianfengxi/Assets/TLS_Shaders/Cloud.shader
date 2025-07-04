Shader "TLStudio/Transparent/Cloud"
{
	Properties
	{
		texCloudMask("Cloud Mask Map", 2D) = "white" {}
		texClouds("Cloud Map 1", 2D) = "white" {}
		texClouds2("Cloud Map 2", 2D) = "white" {}
		texLayer("Cloud Layer Map", 2D) = "white" {}
		
		_DistortionMap ("Distortion Map", 2D) = "" {}    //扭曲
		
        _DistortionScrollX ("X Offset", float) = 0    
        _DistortionScrollY ("Y Offset", float) = 0    
        _DistortionScaleX ("X Scale", float) = 1.0
        _DistortionScaleY ("Y Scale", float) = 1.0
        _DistortionPower ("Distortion Power", float) = 0.08
		_Refraction ("Refraction", float) = 1.0        //折射值
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

			CGPROGRAM
			#pragma skip_variants FOG_EXP DIRLIGHTMAP_COMBINED VERTEXLIGHT_ON
			#pragma multi_compile_fog

			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fwdbase	
			#pragma multi_compile_fog
			
			
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#define UNITY_PASS_FORWARDBASE
			#include "UnityCG.cginc"
			#include "Assets/TLS_Shaders/CGIncludes/Lighting.cginc"
			#include "Assets/TLS_Shaders/CGIncludes/AutoLight.cginc"
			#include "Assets/TLS_Shaders/CGIncludes/WeatherLibrary.cginc"

			///Weather Effect
			#pragma multi_compile __ CYWEATHER_RAIN CYWEATHER_SNOW
			#include "CYWeatherEffect.cginc"

			#define INTERNAL_DATA
			#define WorldReflectionVector(data,normal) data.worldRefl
			#define WorldNormalVector(data,normal) normal
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float2 PSDiffuseUV : TEXCOORD2;
				float2 PSLayerUV : TEXCOORD3;
				float2 PSCloudUV : TEXCOORD4;
				float2 PSCloudUV2 : TEXCOORD5;
				float2 PSCloud2UV : TEXCOORD6;
				float2 PSCloud2UV2 : TEXCOORD7;
				float2 PSBlendFactors : TEXCOORD8;
			};

			sampler2D texCloudMask;
			float4 texCloudMask_ST;
			sampler2D texClouds;
			float4 texClouds_ST;
			sampler2D texClouds2;
			float4 texClouds2_ST;
			sampler2D texLayer;
			float4 texLayer_ST;
			
			

			uniform sampler2D _DistortionMap;
			uniform float _DistortionScrollX;
            uniform float _DistortionScrollY; 
            uniform float _DistortionPower;
            uniform float _BackgroundScaleX;
            uniform float _BackgroundScaleY;
            uniform float _DistortionScaleX;
            uniform float _DistortionScaleY;
			uniform float _Refraction;
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.uv;
				
				o.uv.zw = v.normal.xy;
				
				//UNITY_TRANSFER_FOG(o,o.vertex);
					if(UseHeightFog > 0)
				{
					TL_TRANSFER_FOG( o ,o.vertex, v.vertex);
				}else
				{
					UNITY_TRANSFER_FOG(o,o.vertex); // pass fog coordinates to pixel shader				
				}

				// Calc PSDiffuseUV &  PSLayerUV
				o.PSDiffuseUV = (v.uv + float2(0.001, 0.001));
				o.PSLayerUV = (v.uv * 3.0);

				// Calc PSBlendFactors
				float tmpvar_7 = fmod((_Time.y * 0.01), 1.0);
				float tmpvar_8 = cos((6.282 * tmpvar_7));
				o.PSBlendFactors.x = ((-(tmpvar_8)+1.0) * 0.5);
				o.PSBlendFactors.y = (1.0 - o.PSBlendFactors.x);

				// Calc PSCloudUV etc.
				float2 tmpvar_9 = (v.normal.xy * 0.3);
				float2 tmpvar_12 = (v.normal.xy * 0.5);
				float2 tmpvar_10 = (v.uv * 3.0);
				o.PSCloudUV = (tmpvar_10 + (tmpvar_9 * (tmpvar_7 - 0.5)));
				o.PSCloudUV2 = (tmpvar_10 + (tmpvar_9 * (((fmod((tmpvar_7 + 0.5), 1.0))) - 0.5)));
				o.PSCloud2UV = (tmpvar_10 + (tmpvar_12 * (tmpvar_7 - 0.5)));
				o.PSCloud2UV2 = (tmpvar_10 + (tmpvar_12 * (((fmod((tmpvar_7 + 0.5), 1.0))) - 0.5)));

				

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				 float2 disOffset = float2(_DistortionScrollX*_Time.y,_DistortionScrollY*_Time.y);
                 float2 disScale = float2(_DistortionScaleX,_DistortionScaleY);
				 float4 disTex = tex2D(_DistortionMap, disScale * i.uv+disOffset);
				 float2 offsetUV = (-_Refraction*(disTex * _DistortionPower - (_DistortionPower*0.5)));
				// apply fog
		//		UNITY_APPLY_FOG(i.fogCoord, col);
				fixed4 tmpvar_1 = tex2D(texCloudMask, i.PSDiffuseUV* texCloudMask_ST.xy + texCloudMask_ST.zw);
				
				float4 cloudColor1 = (tex2D(texClouds, ((i.PSCloudUV*texClouds_ST.xy+texClouds_ST.zw) + offsetUV)) * i.PSBlendFactors.x + tex2D(texClouds, ((i.PSCloudUV2*texClouds_ST.xy+texClouds_ST.zw) +  offsetUV)) * i.PSBlendFactors.y);
				float4 cloudColor2 = (tex2D(texClouds2, ((i.PSCloud2UV*texClouds2_ST.xy+texClouds2_ST.zw)  + offsetUV)) * i.PSBlendFactors.x + tex2D(texClouds2, ((i.PSCloud2UV2*texClouds2_ST.xy+texClouds2_ST.zw) + offsetUV)) * i.PSBlendFactors.y);
				fixed4 col = lerp(cloudColor1, cloudColor2, tex2D(texLayer, i.PSLayerUV* texLayer_ST.xy + texLayer_ST.zw).x);
				
				//col.w = ((col.x + 1.0) - ((1.0 - tmpvar_1.x) * 2.0));
				col.w = tmpvar_1.x;
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(i.fogCoord, col.rgb);
				}else
				{
					UNITY_APPLY_FOG(i.fogCoord, col); // apply fog				
				}
				return col;
			}
			ENDCG
		}
	}
}
