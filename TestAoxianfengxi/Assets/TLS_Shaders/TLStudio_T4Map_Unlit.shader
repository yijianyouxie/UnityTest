﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable

Shader "TLStudio/T4Map_Unlit" {
    Properties {
        _Splat0 ("Layer1", 2D) = "white" {}
        _Splat1 ("Layer2", 2D) = "white" {}
        _Splat2 ("Layer3", 2D) = "white" {}
        _Splat3 ("Layer4", 2D) = "white" {}
        _Control ("Control", 2D) = "white" {}
    }
    SubShader {
        Tags {
            "Queue" = "Geometry+500"
            "SplatCount" = "4"
            "RenderType"="Opaque"
        }
        LOD 100
        Pass {
            Name "ForwardBase"
            Tags {
                "LightMode"="ForwardBase"
            } 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma multi_compile FOG_EXP2 FOG_LINEAR

            uniform sampler2D _Splat0; uniform float4 _Splat0_ST;
            uniform sampler2D _Splat1; uniform float4 _Splat1_ST;
            uniform sampler2D _Splat2; uniform float4 _Splat2_ST;
            uniform sampler2D _Splat3; uniform float4 _Splat3_ST;
            // uniform sampler2D unity_Lightmap; // uniform float4 unity_LightmapST;
            uniform sampler2D _Control; uniform float4 _Control_ST;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float2 uv4 : TEXCOORD4;
                UNITY_FOG_COORDS(5)

            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _Splat0);
                o.uv1 = TRANSFORM_TEX(v.texcoord0, _Splat1);
                o.uv2 = TRANSFORM_TEX(v.texcoord0, _Splat2);
                o.uv3 = TRANSFORM_TEX(v.texcoord0, _Splat3);
                o.uv4 =TRANSFORM_TEX(v.texcoord0, _Control);
                o.pos = UnityObjectToClipPos(v.vertex);
                if(UseHeightFog > 0)
                {
                	TL_TRANSFER_FOG(o,o.pos, v.vertex);
                }else
                {
	                UNITY_TRANSFER_FOG(o,o.pos);                
                }
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR {
                
                float4 _Control_var = tex2D(_Control,i.uv4);
                float4 _Splat0_var = tex2D(_Splat0,i.uv0);
                float4 _Splat1_var = tex2D(_Splat1,i.uv1);
                float4 _Splat2_var = tex2D(_Splat2,i.uv2);
                float4 _Splat3_var = tex2D(_Splat3,i.uv3);
                float3 baseColor =  ((_Control_var.r*_Splat0_var.rgb)+(_Control_var.g*_Splat1_var.rgb)+(_Splat2_var.rgb*_Control_var.b)+(_Control_var.a*_Splat3_var.rgb));
                fixed4 finalColor = fixed4 (baseColor,1);
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(i.fogCoord, finalColor.rgb);
				}else
				{
					UNITY_APPLY_FOG(i.fogCoord, finalColor);				
				}
				UNITY_OPAQUE_ALPHA(finalColor.a);
                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "TLStudio/Opaque/UnLit"
}
