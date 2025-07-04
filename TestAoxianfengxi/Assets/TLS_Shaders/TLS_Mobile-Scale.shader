// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Transparent/Scale"
{
	Properties
	{			
		_MainTex ("Main Texture" ,2D) = "" {}
		_Speed ("Speed", Vector) = (0,0,0,0)
		_BumpMap ("Normalmap ", 2D) = "bump" {}
	}

	SubShader
	{	
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		//Blend One One	
		Blend SrcAlpha OneMinusSrcAlpha 
		Cull Off Lighting Off ZWrite Off Fog {Mode Off}
		Pass
		{

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest	
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x

			#include "UnityCG.cginc"			
				
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float4  _Speed;
			
			float  _ScaleSpeed;			
			float  _BeginTimeY;
			float  _EndTimeY;
			float _OffsetTime;
				

			struct a2v {					
				float4 vertex : POSITION;					
				float4 texcoord : TEXCOORD0;
				float4 normal : NORMAL;
			};

			struct v2f {
				float4 vertex : SV_POSITION;					
				float2 uv : TEXCOORD0;					
			};

			float2 uvPanner(float2 uv, float x, float y)
			{
				float t = _Time.x;
				return float2(uv.x + x * t, uv.y + y * t);
			}

			v2f vert (a2v v)
			{
				v2f o;
				v.vertex.xyz -= v.normal*(min(_EndTimeY,_Time.y)-_BeginTimeY+_OffsetTime)*_ScaleSpeed;
				o.vertex = UnityObjectToClipPos(v.vertex);				
				o.uv = TRANSFORM_TEX ( v.texcoord, _MainTex );					
				return o;
			}

			float4 frag (v2f i) : COLOR
			{	
				float2 uv1 = i.uv+_Speed.xy*_Time.x;
				float2 uv2 = i.uv+_Speed.zw*_Time.x;
				float3 _UVOffset1 = UnpackNormal(tex2D(_BumpMap,TRANSFORM_TEX(uv1, _BumpMap)));
				float3 _UVOffset2 = UnpackNormal(tex2D(_BumpMap,TRANSFORM_TEX(uv2, _BumpMap)));
				float3 _UVOffset = (_UVOffset1+_UVOffset2)*0.5;
				float2  uv3 = i.uv+_UVOffset.rb;
				float4 tex = tex2D(_MainTex,TRANSFORM_TEX(uv3, _MainTex));
				return tex;
			}
			ENDCG 
		}	
	}	
	
}
