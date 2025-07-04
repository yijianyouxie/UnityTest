// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Effect/ScreenWave" {
    Properties {
        _MainTex("MainTexture", 2D) = "white" {}
        _OffsetTexture ("NoiseTexture", 2D) = "bump" {}
        _Offset ("Intensity", Range(0, 1)) = 0
        _horizontal("HorizontalSpeed",float) = 1
       _color("Color",Color) = (1,1,1,1)
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        Pass {
			Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            //uniform float4 _TimeEditor;
            uniform float  _horizontal;
            uniform sampler2D _MainTex; uniform half4 _MainTex_ST;
            uniform sampler2D _OffsetTexture; uniform half4 _OffsetTexture_ST;
            uniform fixed _Offset;
            uniform float myTime;
            uniform fixed4 _color;
            struct VertexInput {
                float4 vertex : POSITION;
                half2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                half2 uv0 : TEXCOORD0;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR {
                float4 timer = myTime *_horizontal;
                half2 offsetTextureUV = float2(0,0);
                offsetTextureUV.x =i.uv0.x/(0.1+timer) +0.5-0.5/(0.1+timer);
                offsetTextureUV.y =i.uv0.y/(0.1+timer) +0.5-0.5/(0.1+timer);
//half2 offsetTextureUV =i.uv0;
                fixed3 _OffsetTexture_var = tex2D(_OffsetTexture,TRANSFORM_TEX(offsetTextureUV, _OffsetTexture))*2-1;
                half2 mainTextureUV = (i.uv0+_OffsetTexture_var.rg*_Offset);
                fixed4 _MainTexture_var = tex2D(_MainTex,TRANSFORM_TEX(mainTextureUV, _MainTex));
				half2 mainTextureUV1 =mainTextureUV*0.99 + 0.005;
                fixed4 _MainTexture_var1 = tex2D(_MainTex,TRANSFORM_TEX(mainTextureUV1, _MainTex));
				half2 mainTextureUV2 =mainTextureUV*0.98 + 0.01;
                fixed4 _MainTexture_var2 = tex2D(_MainTex,TRANSFORM_TEX(mainTextureUV2, _MainTex));
				half2 mainTextureUV3 =mainTextureUV*0.97 + 0.015;
                fixed4 _MainTexture_var3 = tex2D(_MainTex,TRANSFORM_TEX(mainTextureUV3, _MainTex));
                //_MainTexture_var.rgb = _MainTexture_var.rgb*_MainTexture_var.a;
				fixed4 finalColor = (_MainTexture_var*0.4+_MainTexture_var1*0.3+_MainTexture_var2*0.2+_MainTexture_var3*0.1)*_color;
                return finalColor;
                
            }
            ENDCG
        }
    }
}
