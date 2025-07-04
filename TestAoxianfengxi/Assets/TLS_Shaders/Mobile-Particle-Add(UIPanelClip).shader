// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Simplified Additive Particle shader. Differences from regular Additive Particle one:
// - no Tint color
// - no Smooth particle support
// - no AlphaTest
// - no ColorMask

Shader "Mobile/Particles/Additive(UIPanelClip)" {
Properties {
	_MainTex ("Particle Texture", 2D) = "white" {}
	_ClipRange0("_ClipRange0", Vector) = (0.0, 0.0, 1.0, 1.0)
	_ClipArgs0("_ClipArgs0", Vector) = (1000.0, 1000.0, 1.0, 1.0)
}

Category {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	Blend SrcAlpha One
	Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }
	
	BindChannels {
		Bind "Color", color
		Bind "Vertex", vertex
		Bind "TexCoord", texcoord
	}
	SubShader {
		Pass {
			CGPROGRAM
			#pragma skip_variants FOG_EXP
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			struct appdata_t {
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
				fixed4 color : COLOR;
			};
			struct v2f {
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
				fixed4 color : COLOR;
				float2 worldPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			half4  _MainTex_ST;
			float4 _ClipRange0;
			float2 _ClipArgs0;

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = v.texcoord;
				o.color = v.color;
				float2 clipSpace = o.vertex.xy / o.vertex.w;
				clipSpace = (clipSpace.xy + 1) * 0.5;
				o.worldPos = clipSpace * _ClipRange0.zw + _ClipRange0.xy;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 finalCol = tex2D(_MainTex, i.texcoord) * i.color;
				float2 factor = (float2(1.0, 1.0) - abs(i.worldPos)) * _ClipArgs0;
				finalCol.a *= clamp(min(factor.x, factor.y), 0.0, 1.0);
				return  finalCol;
			}
			ENDCG
		}
	}

	SubShader {
		Pass {
			SetTexture [_MainTex] {
				combine texture * primary
			}
		}
	}
}
}
