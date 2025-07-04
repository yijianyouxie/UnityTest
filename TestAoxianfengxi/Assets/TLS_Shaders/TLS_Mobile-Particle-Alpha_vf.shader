// Simplified Alpha Blended Particle shader. Differences from regular Alpha Blended Particle one:
// - no Smooth particle support
// - no AlphaTest
// - no ColorMask

Shader "TLStudio/Effect/AlphaBlended_vf" {
	Properties {
		_TintColor("Tint Color", Color) = (1,1,1,1)
		_MainTex ("Particle Texture", 2D) = "white" {}
	}

	SubShader{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }

		LOD 150
		Pass{
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off Lighting Off ZWrite Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			sampler2D _MainTex; half4 _MainTex_ST;
			fixed4 _TintColor;
			struct VertexInput {
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
				fixed4 color : COLOR;
			};
			struct VertexOutput {
				float4 pos : SV_POSITION;
				half2 uv0 : TEXCOORD0;
				fixed4 color : COLOR;
			};
			VertexOutput vert(VertexInput v) {
				VertexOutput o = (VertexOutput)0;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv0 = v.texcoord;
				o.color = v.color;
				return o;
			}
			fixed4 frag(VertexOutput i) : COLOR{
				fixed4 finalRGBA = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
				fixed4 finalColor = finalRGBA * i.color;
				//按照理论来说，原来的固定管线的实现是color和alpha是分开的，alpha部分并没有2倍
				//但是实际上，alpha分量是也被2倍了的
				//finalColor = fixed4(finalColor.rgb * _TintColor.rgb * 2.0, finalColor.a * _TintColor.a * 2.0);
				finalColor = clamp(finalColor * _TintColor * 2.0, 0, 1);
				return finalColor;
			}
			ENDCG
		}
	}
}