// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Transparent/Scroll"
{
	Properties
	{
		_MainTex ("Texture RGB", 2D) = "white" {}
		_CutOff ("Base Alpha CutOff", Range(0,1)) = 0.5
		_TimeScale("TimeScale",Range(1,10)) = 5 
	}
	SubShader
	{
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 150

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off  
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
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _CutOff;
			fixed _TimeScale;
			float _BeginTimeX = 0;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
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
				fixed4 col = tex2D(_MainTex, i.uv);
				clip (col.a - _CutOff -(_Time.x - _BeginTimeX)*_TimeScale);
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
