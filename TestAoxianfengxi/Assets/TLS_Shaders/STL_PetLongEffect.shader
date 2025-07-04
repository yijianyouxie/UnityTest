// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/STL_PetLongEffect" {
    Properties {
        _MainTex ("MainTex", 2D) = "white" {}
        _RimColor ("RimColor", Color) = (0.5,0.5,0.5,1)
        _RimPower ("RimPower", Range(1, 5)) = 2.538461
        _FllowingLight ("FllowingLight", 2D) = "black" {}
        _FllowingLightColorRGBA ("FllowingLightColor(RGBA)", Color) = (0.5,0.5,0.5,1)
		[HideInInspector]_Color("_Color无用变透明用", Color) = (0.5,0.5,0.5,1)
        _XSpeed ("XSpeed", Float ) = 1
        _YSpeed ("YSpeed", Float ) = 1
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
pass {
Zwrite On
ColorMask 0
}
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
           // Blend One OneMinusSrcColor
           Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            CGPROGRAM
            #pragma skip_variants FOG_EXP INSTANCING_ON DIRECTIONAL DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SHADOWS_SCREEN SHADOWS_SHADOWMASK VERTEXLIGHT_ON SHADOWS_CUBE SHADOWS_DEPTH POINT SPOT UNITY_HDR_ON
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma exclude_renderers xbox360 ps3 flash d3d11_9x
            /*#pragma multi_compile __ PROJECTOR_DEPTH_MAP_ON
            #include "DepthMapShadow.cginc"*/
            uniform float4 _TimeEditor;
            uniform sampler2D _MainTex; uniform half4 _MainTex_ST;
            uniform fixed4 _RimColor;
            uniform float _RimPower;
            uniform sampler2D _FllowingLight; uniform half4 _FllowingLight_ST;
            uniform half _XSpeed;
            uniform half _YSpeed;
            uniform fixed4 _FllowingLightColorRGBA;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                half2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                half2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                //UNITY_FOG_COORDS(3)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex );
                /*if(UseHeightFog > 0)
                {
                	TL_TRANSFER_FOG(o,o.pos, v.vertex);
                }else
                {
	                UNITY_TRANSFER_FOG(o,o.pos);                
                }*/
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                fixed3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 normalDirection = i.normalDir;
                fixed4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                //clip(_MainTex_var.a*2-0.5);
////// Lighting:
////// Emissive:
                float4 time = _Time + _TimeEditor;
                half2 UVTemp = (i.uv0+frac((time.g*half2(_XSpeed,_YSpeed))));
                fixed4 _FllowingLight_var = tex2D(_FllowingLight,TRANSFORM_TEX(UVTemp, _FllowingLight))*2;
                float rim = pow(1.0-max(0,dot(i.normalDir, viewDirection)),_RimPower);
                fixed3 finalColor = (_MainTex_var.rgb+(((_FllowingLight_var.rgb*_FllowingLight_var.a)*_FllowingLightColorRGBA.a*_FllowingLightColorRGBA.rgb)+(_RimColor.rgb*rim)));
                fixed4 finalRGBA = fixed4(finalColor,max(_MainTex_var.a*_RimColor.a,rim));
               /* finalRGBA *= ShadowColorAtten(i.posWorld);
                #ifdef PROJECTOR_DEPTH_MAP_ON
                finalRGBA *= ProjectorShadowColorAtten(i.posWorld);
                #endif*/
                
                /*if(UseHeightFog > 0)
                {
                	TL_APPLY_FOG(i.fogCoord, finalRGBA.rgb);
                }else
                {
	                UNITY_APPLY_FOG(i.fogCoord, finalRGBA);                
                }*/
                return finalRGBA;
            }
            ENDCG
        }
        //Pass {
        //    Name "ShadowCaster"
        //    Tags {
        //        "LightMode"="ShadowCaster"
        //    }
        //    Offset 1, 1
            
        //    CGPROGRAM
        //    #pragma vertex vert
        //    #pragma fragment frag
        //    #define UNITY_PASS_SHADOWCASTER
        //    #include "UnityCG.cginc"
        //    #include "Lighting.cginc"
        //    #pragma fragmentoption ARB_precision_hint_fastest
        //    #pragma multi_compile_shadowcaster
        //    #pragma multi_compile FOG_EXP2 FOG_LINEAR
        //    #pragma exclude_renderers d3d11_9x xbox360 xboxone ps3 ps4 psp2 
        //    #pragma exclude_renderers xbox360 ps3 flash d3d11_9x
        //    uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
        //    struct VertexInput {
        //        float4 vertex : POSITION;
        //        float2 texcoord0 : TEXCOORD0;
        //    };
        //    struct VertexOutput {
        //        V2F_SHADOW_CASTER;
        //        float2 uv0 : TEXCOORD1;
        //    };
        //    VertexOutput vert (VertexInput v) {
        //        VertexOutput o = (VertexOutput)0;
        //        o.uv0 = v.texcoord0;
        //        o.pos = mul(UNITY_MATRIX_MVP, v.vertex );
        //        TRANSFER_SHADOW_CASTER(o)
        //        return o;
        //    }
        //    float4 frag(VertexOutput i) : COLOR {
        //        fixed4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
        //        //clip((_MainTex_var.a*2) - 0.5);
        //        SHADOW_CASTER_FRAGMENT(i)
        //    }
        //    ENDCG
        //}
    }
	FallBack "Mobile/Diffuse"
}
