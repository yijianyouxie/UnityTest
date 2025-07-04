// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Effect/ Dissolve" {
    Properties {
        _TintColor ("TintColor", Color) = (0.5,0.5,0.5,1)
        _MainTexture ("MainTexture", 2D) = "white" {}
        _mask ("mask", 2D) = "white" {}
        _RJ ("Dissolve", Range(0.01, 1.1)) = 0
		_colorWidth("ColorWidth", Range(0, 0.05)) = 0
        _Color ("Color", Color) = (0.5,0.5,0.5,1)
    }
    SubShader {
        Tags {
            "Queue"="AlphaTest"
            "RenderType"="TransparentCutout"
        }
        Pass {         
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            uniform sampler2D _MainTexture; uniform half4 _MainTexture_ST;
            uniform sampler2D _mask; uniform half4 _mask_ST;
            uniform fixed _RJ;
            uniform fixed4 _Color;
			uniform fixed _colorWidth;
			uniform fixed4 _TintColor;
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
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = v.color;
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR {
                fixed4 _MainTexture_var = tex2D(_MainTexture,TRANSFORM_TEX(i.uv0, _MainTexture));
				fixed4 _mask_var = tex2D(_mask,TRANSFORM_TEX(i.uv0, _mask));
				fixed cut = _mask_var.r*_MainTexture_var.a- _RJ;
                clip(cut);
				int blend = step(_colorWidth, cut);
                fixed3 finalColor = (_MainTexture_var.rgb*_TintColor+ lerp(_Color.rgb, fixed3(0.0, 0.0, 0.0), blend))*i.color;
                return fixed4(finalColor,1);
            }
            ENDCG
        }
    }
    FallBack "Unlit/Texture"
}
