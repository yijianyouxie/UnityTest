// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Transparent/NormalNoise"
{
	Properties
	{
		_MainTex ("Texture(RGB)", 2D) = "white" {}
		_NormalNoiseMap("扰动法线(RGB) RG is noise B is Alpha",2D) = "Black" {}  		
		_NormalNoiseTiling("扰动法线图的Tiling",Range(0.01,10)) = 6 
		_NormalNoiseSpeed("法线扰动的Speed",Range(0,1)) = 1
		_NormalNoiseMapPower("法线扰动的Power",Range(0.001,2.0)) = 0.5 
	}
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		//Tags { "RenderType"="Opaque" }
		LOD 150

		Pass
		{
			//one                        1
			//zero                       0
			//SrcColor                   源的RGB值，例如（0.5,0.4,1）
			//SrcAlpha                   源的A值, 例如0.6
			//DstColor                   混合目标的RGB值例如（0.5，0.4,1）
			//DstAlpha                   混合目标的A值例如0.6
			//OneMinusSrcColor           (1,1,1) - SrcColor
			//OneMinusSrcAlpha           1- SrcAlpha
			//OneMinusDstColor           (1,1,1) - DstColor
			//OneMinusDstAlpha           1- DstAlpha
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			
			#include "Assets/TLS_Shaders/UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				//float4 color : COlOR;
			};

			struct v2f
			{
				float2 uv        : TEXCOORD0;
				float3 worldpos  : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				//float4 color	 : COlOR;
				UNITY_FOG_COORDS(3)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NormalNoiseMap;
			float4 _NormalNoiseMap_ST;
			half _NormalNoiseSpeed;
			half _NormalNoiseTiling;
			half _NormalNoiseMapPower;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldpos = mul(unity_ObjectToWorld, v.vertex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				//o.color = v.color;
				if(UseHeightFog > 0)
				{
					TL_TRANSFER_FOG(o,o.vertex, v.vertex);
				}else
				{
					UNITY_TRANSFER_FOG(o,o.vertex);				
				}
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float2 noiseNormal1 = tex2D(_NormalNoiseMap, i.uv * _NormalNoiseTiling + 0.1 * _Time.y * _NormalNoiseSpeed).rg;
				float2 noiseNormal2 = tex2D(_NormalNoiseMap, i.uv * _NormalNoiseTiling - 0.1 * _Time.y * _NormalNoiseSpeed).rg;
				noiseNormal1 = (noiseNormal1 - 0.5) * 2*_NormalNoiseMapPower;
				noiseNormal2 = (noiseNormal2 - 0.5) * 2*_NormalNoiseMapPower;
				float2 finalUV = noiseNormal1 + noiseNormal2;
				fixed4 col = tex2D(_MainTex, finalUV);
				col.a = tex2D(_NormalNoiseMap, i.uv).b;
				//col.a =  i.color.a;
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(i.fogCoord, col.rgb);
				}else
				{
					UNITY_APPLY_FOG(i.fogCoord, col);				
				}
				return col;
			}
			ENDCG
		}
	}
}
