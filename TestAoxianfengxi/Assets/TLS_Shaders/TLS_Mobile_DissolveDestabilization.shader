// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Effect/ DissolveDestabilization" {
    Properties {
        _TintColor ("TintColor", Color) = (0.5,0.5,0.5,1)
        _MainTexture ("MainTexture", 2D) = "white" {}
        _Noise ("DestabilizationTexture", 2D) = "bump" {} 
        _mask ("mask", 2D) = "white" {}
        _RJ ("Dissolve", Range(0.0, 1.0)) = 0
		_colorWidth("ColorWidth", Range(0, 1)) = 0
        _Color ("Color", Color) = (0.5,0.5,0.5,1)
    }
    SubShader {
        Tags {
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
LOD 150
Blend SrcAlpha OneMinusSrcAlpha
ZWrite Off
        Pass {         
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            uniform sampler2D _MainTexture; uniform half4 _MainTexture_ST;
            uniform sampler2D _Noise; uniform half4 _Noise_ST;
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
				//_RJ = (_RJ - 0.5) * 2;
                float2 noiseUV = TRANSFORM_TEX(i.uv0, _Noise)+_Time.x*float2(3,3);
                fixed4 _Noise_var =( tex2D(_Noise,noiseUV)*2- 1)*((1-_TintColor.a)*0.02);
				fixed4 _MainTexture_var = tex2D(_MainTexture,TRANSFORM_TEX(i.uv0, _MainTexture)+fixed2(0,_Noise_var.y));

                fixed4 _mask_var = tex2D(_mask,TRANSFORM_TEX(i.uv0, _mask));
				//fixed cut = min(1, max(0,_mask_var.r- _RJ))/(1-max(0,_RJ));
                fixed cut = _mask_var.r- _RJ;
                clip(cut);
				int blend = step(_colorWidth, cut);
                fixed3 finalColor = (_MainTexture_var.rgb*_TintColor+ lerp(_Color.rgb, fixed3(0.0, 0.0, 0.0), blend))*i.color;
                return fixed4(finalColor,_MainTexture_var.a*_TintColor.a);
            }
            ENDCG
        }
    }
    FallBack "Unlit/Texture"
}
