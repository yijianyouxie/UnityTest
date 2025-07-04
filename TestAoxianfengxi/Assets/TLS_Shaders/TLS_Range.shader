// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Transparent/Range"
{
	Properties
	{		
		_Color("Color", Color) = (0,0,0,1)
		_MainTex ("Main Texture" ,2D) = "" {}
		_Length("Length", Float) = 1
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
			float _Length;
			float4 _Color;

			struct a2v {					
				float4 vertex : POSITION;					
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;					
				float2 uv : TEXCOORD0;					
			};

			v2f vert (a2v v)
			{
				v2f o;
				v.vertex.xyz += normalize(-v.vertex.xyz)*(_Length-1);
				o.vertex = UnityObjectToClipPos(v.vertex);				
				o.uv = TRANSFORM_TEX (v.texcoord, _MainTex );					
				return o;
			}

			float4 frag (v2f i) : COLOR
			{	
				return tex2D(_MainTex, i.uv)*_Color;
			}
			ENDCG 
		}	
	}	
	
}
