// Simplified Alpha Blended Particle shader. Differences from regular Alpha Blended Particle one:
// - no Smooth particle support
// - no AlphaTest
// - no ColorMask

Shader "TLStudio/Effect/AlphaBlended(UIPanelClip) 2" {
Properties {
	_TintColor("Tint Color", Color) = (1,1,1,1)
	_MainTex ("Particle Texture", 2D) = "white" {}
	_ClipRange0("_ClipRange0", Vector) = (0.0, 0.0, 1.0, 1.0)
	_ClipArgs0("_ClipArgs0", Vector) = (1000.0, 1000.0, 0.0, 1.0)
	_ClipRange1("_ClipRange1", Vector) = (0.0, 0.0, 1.0, 1.0)
	_ClipArgs1("_ClipArgs1", Vector) = (1000.0, 1000.0, 0.0, 1.0)
}

Category {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	Blend SrcAlpha OneMinusSrcAlpha
	Cull Off Lighting Off ZWrite Off
	
	BindChannels {
	    Bind "Color", color
		Bind "Vertex", vertex
		Bind "TexCoord", texcoord
	}

	SubShader {
		//Blend SrcAlpha One
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
				float4 worldPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			half4  _MainTex_ST;
			float4 _ClipRange0;
			float4 _ClipArgs0;
			float4 _ClipRange1;
			float4 _ClipArgs1;
			fixed4 _TintColor;

			float2 Rotate(float2 v, float2 rot)
			{
				float2 ret;
				ret.x = v.x * rot.y - v.y * rot.x;
				ret.y = v.x * rot.x + v.y * rot.y;
				return ret;
			}

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = v.texcoord;
				o.color = v.color;
				float2 clipSpace = o.vertex.xy / o.vertex.w;
				clipSpace = (clipSpace.xy + 1) * 0.5;
				o.worldPos.xy = clipSpace * _ClipRange0.zw + _ClipRange0.xy;
				o.worldPos.zw = Rotate(clipSpace, _ClipArgs1.zw) * _ClipRange1.zw + _ClipRange1.xy;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 finalCol = tex2D(_MainTex, i.texcoord) * i.color;
				finalCol.rgb = finalCol.rgb * _TintColor.rgb * 2;
				finalCol.a = finalCol.a * _TintColor.a;
				float2 factor = (float2(1.0, 1.0) - abs(i.worldPos.xy)) * _ClipArgs0.xy;
				float f = min(factor.x, factor.y);
				factor = (float2(1.0, 1.0) - abs(i.worldPos.zw)) * _ClipArgs1.xy;
				f = min(f, min(factor.x, factor.y));
				finalCol.a *= clamp(f, 0.0, 1.0);
				return  finalCol;
			}
			ENDCG
		}
	}

	SubShader {
		LOD 150
		Pass {
			SetTexture[_MainTex]{
			combine texture * Primary,texture*Primary
			}
			SetTexture[_MainTex]{
			constantColor[_TintColor]
			combine Previous  * constant  Double, Previous * constant
			}
		}
	}
}
}
