// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Disturance" {
    Properties {
        _Disturbance ("Disturbance", 2D) = "bump" {}
        _MainTex ("MainTex", 2D) = "white" {}

    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        ZWrite Off
        ZTest Always
         blend SrcAlpha OneminusSrcAlpha
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

          

            uniform sampler2D _Disturbance;
            uniform sampler2D _MainTex;
            struct VertexInput {
                float4 vertex : POSITION;
                half2 texcoord0 : TEXCOORD0;
                fixed4 color : COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                half2 uv0 : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                fixed4 color : COLOR;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos(v.vertex );
                o.screenPos = o.pos;
                o.color = v.color;
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR {
//                #if UNITY_UV_STARTS_AT_TOP
//                    float grabSign = -_ProjectionParams.x;
//                #else
//                    float grabSign = _ProjectionParams.x;
//                #endif
                i.screenPos = float4( i.screenPos.xy / i.screenPos.w, 0, 0 );
                i.screenPos.y *= _ProjectionParams.x;
                fixed4 _Disturbance_var = tex2D(_Disturbance,i.uv0);
                half2 sceneUVs = i.screenPos.xy*0.5+0.5 + (_Disturbance_var.rg*0.02-0.01);
                fixed4 sceneColor = tex2D(_MainTex, sceneUVs);
                return fixed4(sceneColor.rgb,_Disturbance_var.a*i.color.a);
            }
            ENDCG
        }
    }
}
