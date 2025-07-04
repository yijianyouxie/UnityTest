// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Effect/AlphaBlendedMask" {
    Properties {
	    _TintColor("Tint Color", Color) = (1,1,1,1)
		_MainTex("Particle Texture", 2D) = "white" {}
        _Mask ("Mask", 2D) = "white" {}
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        LOD 150
        Pass {
            Blend SrcAlpha OneMinusSrcAlpha
			Cull Off Lighting Off ZWrite Off Fog{ Color(0,0,0,0) }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
			sampler2D _Mask; sampler2D _MainTex; half4 _MainTex_ST; half4 _Mask_ST;
			fixed4 _TintColor;
            struct VertexInput {
                float4 vertex : POSITION;
                half2 texcoord0 : TEXCOORD0;
			    fixed4 color :COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                half2 uv0 : TEXCOORD0;
				fixed4 color :COLOR;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.pos = UnityObjectToClipPos(v.vertex);
				o.uv0 = v.texcoord0;
				o.color = v.color;
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR {
                fixed3 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                fixed3 _Mask_var = tex2D(_Mask,TRANSFORM_TEX(i.uv0, _Mask));
				fixed4 finalRGBA = fixed4(_MainTex_var, _Mask_var.r);
				fixed4 finalColor = fixed4(finalRGBA.rgb * i.color.rgb, finalRGBA.a * i.color.a);
				finalColor = fixed4(finalColor.rgb * _TintColor.rgb * 2.0, finalColor.a * _TintColor.a);
                return finalColor;
            }
            ENDCG
    }
    }
}
