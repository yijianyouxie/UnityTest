// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "TLStudio/FX/RimLight" {
    Properties {
        _MainColor ("MainColor", Color) = (0.55,0.7,1,1)
        _Texture ("Texture", 2D) = "bump" {}
        _Inlinecolor ("RimColor", Color) = (0.55,0.7,1,1)
        _Inlineslider ("RimPower", Range(0, 3)) = 0.5
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha One
            ZWrite off
			Stencil
			{
				Ref 2         // 写入Stencil的值为1
				Comp always   // 总是写入
				Pass replace  // 替换现有Stencil值
			}
            CGPROGRAM
            #pragma skip_variants SHADOWS_CUBE SHADOWS_DEPTH FOG_EXP INSTANCING_ON DIRECTIONAL DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SHADOWS_SCREEN SHADOWS_SHADOWMASK VERTEXLIGHT_ON DIRECTIONAL_COOKIE POINT POINT_COOKIE SPOT UNITY_HDR_ON
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            uniform sampler2D _Texture; uniform float4 _Texture_ST;
            uniform float4 _Inlinecolor;
            uniform float _Inlineslider;
            float4 _MainColor;
            
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
                float4 color : COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float4 color : COLOR;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = normalize(mul(unity_ObjectToWorld,float4(v.normal, 0.0)).xyz);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex );
                o.color = v.color;
                return o;
            }
            
            float4 frag(VertexOutput i) : COLOR {
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 normalDirection = normalize(i.normalDir);
                fixed rim = pow((1.0-max(0,dot(normalDirection, viewDirection))),_Inlineslider)*2;
                fixed4 _Texture_var = tex2D(_Texture,TRANSFORM_TEX(i.uv0, _Texture));
                fixed3 finalTexCol =_Texture_var.rgb;
                
                fixed3 finalColor =_Texture_var*_MainColor + rim *_Inlinecolor.rgb;
                return fixed4(finalColor,_Texture_var.a*max(_MainColor.a,rim*_Inlinecolor.a))*i.color;
            }
            
            
            ENDCG
        }
    }
    FallBack "Diffuse"
}
