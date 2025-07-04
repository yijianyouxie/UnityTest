// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Simplified Additive Particle shader. Differences from regular Additive Particle one:
// - no Smooth particle support
// - no AlphaTest
// - no ColorMask

Shader "Hidden/Effect/AdditiveMask" {
Properties {
	_TintColor("TintColor", Color) = (1,1,1,1)
	_MainTex ("Particle Texture", 2D) = "white" {}
	_Mask ("Mask", 2D) = "white" {}
}
Subshader{
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	Blend SrcAlpha One
	Cull Off 
	Lighting Off 
	ZWrite Off 
	Fog { Color (0,0,0,0) }
	ColorMask RGBA
	LOD 150
	Pass {

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			struct appdata_t {
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
				fixed4 color :COLOR;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
				fixed4 color :COLOR;
			};
			sampler2D _MainTex;
			half4  _MainTex_ST;
			sampler2D _Mask;
			half4  _Mask_ST;
			fixed4 _TintColor;
			
			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = v.texcoord;
				o.color = v.color;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 MainTex_Var = tex2D(_MainTex, TRANSFORM_TEX(i.texcoord, _MainTex));
				fixed3 Mask_Var = tex2D(_Mask, TRANSFORM_TEX(i.texcoord, _Mask));
				fixed4 col = fixed4(MainTex_Var,Mask_Var.r);
				fixed4 finalCol = col*i.color*_TintColor;
				return  finalCol;
			}
			ENDCG
		}
		}
}