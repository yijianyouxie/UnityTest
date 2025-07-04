// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Character/Character1\2" {
    Properties {
		_Color("AddColor", Color) = (0,0,0,1)
        _MainTex ("MainTex", 2D) = "white" {}
        _Reflection ("Reflection", 2D) = "white" {}
        _RimColor ("RimColor", Color) = (1,1,1,1)
		[HideInInspector]_Cutoff ("",float) = 0.5
    }
    SubShader {
        Tags {
            "Queue"="AlphaTest+150"
            "RenderType"="TransparentCutout"
            "ShadowProjector" = "true"
        }
		LOD 150
        Pass {
            Name "ForwardBase"
            Tags {
                "LightMode"="ForwardBase"
            }
            ColorMask RGBA
			Stencil
			{
				Ref 2         // 写入Stencil的值为1
				Comp always   // 总是写入
				Pass replace  // 替换现有Stencil值
			}
            
            CGPROGRAM
            #pragma skip_variants FOG_EXP INSTANCING_ON DIRECTIONAL DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SHADOWS_SCREEN SHADOWS_SHADOWMASK VERTEXLIGHT_ON SHADOWS_CUBE SHADOWS_DEPTH POINT SPOT UNITY_HDR_ON
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            //#define SHOULD_SAMPLE_SH_PROBE ( defined (LIGHTMAP_OFF) )
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            /*#pragma multi_compile __ PROJECTOR_DEPTH_MAP_ON
            #include "DepthMapShadow.cginc"*/
            uniform fixed4 _LightColor0;
            uniform sampler2D _Reflection; uniform half4 _Reflection_ST;
            uniform sampler2D _MainTex; uniform half4 _MainTex_ST;
            uniform fixed4 _Color;
            uniform fixed4 _RimColor;
            //uniform fixed _Cutout;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                half2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                half2 uv0 : TEXCOORD0;
                fixed3 viewDirection : TEXCOORD1;
                fixed3 normalDir : TEXCOORD2;
                half2 uvHalf  : TEXCOORD6;
                LIGHTING_COORDS(3,4)
                float3 shLight : TEXCOORD5;
                float4 posWorld:TEXCOORD7;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0.x = v.texcoord0.x;
                o.uv0.y = v.texcoord0.y;
                o.uvHalf.x = v.texcoord0.x+0.5;
                o.uvHalf.y =v.texcoord0.y;
                o.normalDir = UnityObjectToWorldNormal(v.normal);// mul(_Object2World, float4(v.normal,0)).xyz;
                o.posWorld = mul(unity_ObjectToWorld , v.vertex);
                //#if SHOULD_SAMPLE_SH_PROBE
                    o.shLight = ShadeSH9(float4(o.normalDir * 1.0,1));
                //#endif
                o.viewDirection = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR {
                i.normalDir = normalize(i.normalDir);
/////// Vectors:
                fixed3 normalDirection = i.normalDir;
                fixed4 CtrlTex = tex2D(_MainTex,TRANSFORM_TEX(i.uvHalf, _MainTex));
				fixed4 _MainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
                clip((1-CtrlTex.g)-(1-_Color.a));
                fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
////// Lighting:
                fixed attenuation = LIGHT_ATTENUATION(i)*0.9;
                fixed3 attenColor = attenuation * _LightColor0.xyz;
/////// Diffuse:
                fixed NdotL = max(0.2,dot( normalDirection, lightDirection ));
				//fixed3 indirectDiffuse = UNITY_LIGHTMODEL_AMBIENT.rgb;
                fixed3 directDiffuse = NdotL * attenColor;
                //#if SHOULD_SAMPLE_SH_PROBE
				fixed3 indirectDiffuse = i.shLight;
                //#endif
                fixed3 diffuse = (directDiffuse + indirectDiffuse) * _MainTexColor.rgb;
////// Emissive:
				fixed rimRange = 1-abs(dot(i.viewDirection,normalDirection));
                half2 ReflUV = mul( UNITY_MATRIX_V, float4(normalDirection,0)).rg*0.5+0.5;
                fixed4 _Reflection_var = tex2D(_Reflection,TRANSFORM_TEX(ReflUV, _Reflection));
				//fixed ReflectionRange = tex2D(_Reflection, TRANSFORM_TEX(i.uv0, _MainTex));
                fixed3 emissive = _Color.rgb+_Reflection_var.rgb*CtrlTex.r+rimRange*rimRange*_RimColor+_MainTexColor*CtrlTex.b*0.5;
				//float3 emissive = _Color.rgb + _Reflection_var.rgb*ReflectionRange;
/// Final Color:
                fixed3 finalColor = diffuse + emissive;
                /*finalColor *= ShadowColorAtten(i.posWorld);
                #ifdef PROJECTOR_DEPTH_MAP_ON
                finalColor *= ProjectorShadowColorAtten(i.posWorld);
                #endif*/
                return fixed4(finalColor,1);
            }
            ENDCG
        }
    }
			FallBack "Mobile/Diffuse"
}
