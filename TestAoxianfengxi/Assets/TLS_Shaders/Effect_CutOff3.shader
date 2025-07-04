// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Unlit alpha-blended shader.
// - no lighting
// - no lightmap support
// - no per-material color

Shader "FXEffect/CutOff3" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
		_CutTex ("Cutoff Tex", 2D) = "white" {}
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
	}

	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha
		Lighting Off	
		cull off 
		ZWrite on

		Pass {  
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile FOG_EXP2 FOG_LINEAR
			
				#include "UnityCG.cginc"

				struct appdata_t {
					float4 vertex : POSITION;
					float2 texcoord : TEXCOORD0;
					fixed4 color : COLOR;
				};

				struct v2f {
					float4 vertex : SV_POSITION;
					half2 texcoord : TEXCOORD0;
					fixed4 color : COLOR;
				};

				fixed4 _Color;
				sampler2D _MainTex;
				sampler2D _CutTex;
				float4 _MainTex_ST;
				float4 _CutTex_ST;
				fixed _Cutoff;
			
				v2f vert (appdata_t v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
					o.color = v.color;
					return o;
				}
			
				fixed4 frag (v2f i) : SV_Target
				{
					fixed4 col = tex2D(_MainTex, i.texcoord) * _Color;
					col.rgb *= i.color.rgb;

					fixed4 cut = tex2D(_CutTex, i.texcoord);
					//col.a *= i.color.a;
					clip(i.color.a - cut.r);
					clip(col.a - _Cutoff);
					return col;
				}
			ENDCG
		}
	}
}
