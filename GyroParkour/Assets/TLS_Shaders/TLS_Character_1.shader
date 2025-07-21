// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Character/Character" {
    Properties {
		_Color("AddColor", Color) = (0,0,0,1)
        _MainTex ("MainTex", 2D) = "white" {}

		_TailorTex("裁剪控制图TailorTex", 2D) = "white" {}
		_TailorGradientTex("裁剪渐变图", 2D) = "white" {}
		_TailorMaskChannel1("裁剪使用的通道rgba(值是0或1)", vector) = (1, 0, 0 ,0)
		_TailorValue1("裁剪比例", Range(0,0.99)) = 0
		_TailorGradientDis1("裁剪渐变距离", Range(0,0.5)) = 0.1

        _Reflection ("Reflection", 2D) = "white" {}
        _RimColor ("RimColor", Color) = (1,1,1,1)
		_ReflectionIntension("Reflection Intensity",Range(0,1)) = 0.5
		[HideInInspector]_Cutoff ("",float) = 0.5
		FogSwitch("FogSwitch", float) = 0
    }
    SubShader {
        Tags {
            "Queue"="AlphaTest+50"
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
			Blend SrcAlpha OneMinusSrcAlpha
			//Cull Back
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
            #pragma multi_compile FOG_EXP2 FOG_LINEAR
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
			#include "DynamicLight.cginc"
            #include "AutoLight.cginc"
            #define INTERNAL_DATA
            /*#pragma multi_compile __ PROJECTOR_DEPTH_MAP_ON
            #include "DepthMapShadow.cginc"*/

            uniform fixed4 _LightColor0;
            uniform sampler2D _Reflection; uniform half4 _Reflection_ST;
            uniform sampler2D _MainTex; uniform half4 _MainTex_ST;

			sampler2D _TailorTex;
			sampler2D _TailorGradientTex;
			float4 _TailorGradientTex_ST;
			float4 _TailorMaskChannel1;//第一层裁剪使用的通道
			float _TailorValue1;
			float _TailorGradientDis1;
			float _TalorGap;

            uniform fixed4 _Color;
            uniform fixed4 _RimColor;
            uniform fixed _ReflectionIntension;
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
                LIGHTING_COORDS(3,4)
                float3 shLight : TEXCOORD5;
                UNITY_FOG_COORDS(6)
                float4 posWorld:TEXCOORD7;
            };

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);//  mul(_Object2World, float4(v.normal,0)).xyz;
                o.shLight = ShadeSH9(float4(o.normalDir * 1.0,1));
                o.posWorld = mul(unity_ObjectToWorld , v.vertex);
                o.viewDirection = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
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

				float tailorAlpha = 1.0;
				fixed4 tailorTexCol = tex2D(_TailorTex, i.uv0);
				float texValue = _TailorMaskChannel1.r * tailorTexCol.r + _TailorMaskChannel1.g * tailorTexCol.g + _TailorMaskChannel1.b * tailorTexCol.b + _TailorMaskChannel1.a * tailorTexCol.a;
				if (texValue < _TailorValue1)
				{
					if (texValue < _TailorValue1 - _TailorGradientDis1)
					{
						discard;
					}
					else
					{
						tailorAlpha = 1 - (_TailorValue1 - texValue) / _TailorGradientDis1;
						//tailorAlpha = clamp(tailorAlpha, 0, 0.97);//消除接缝
						fixed4 tailorGradientTexCol = 0;
						if (_TalorGap > 0)
						{
							tailorGradientTexCol = tex2D(_TailorGradientTex, TRANSFORM_TEX(float2(0.1 / _TailorGradientDis1 * i.uv0.x, tailorAlpha), _TailorGradientTex));
						}
						else
						{
							tailorGradientTexCol = tex2D(_TailorGradientTex, TRANSFORM_TEX(float2(i.uv0.x + _TailorValue1 / 5, tailorAlpha), _TailorGradientTex));
						}
						tailorAlpha = tailorGradientTexCol.r;
					}
				}

				if (tailorAlpha <= 0.1)
				{
					discard;
				}

                i.normalDir = normalize(i.normalDir);
/////// Vectors:
                fixed3 normalDirection = i.normalDir;
				fixed4 _MainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
                clip(_MainTexColor.a-(1-_Color.a));
                fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
////// Lighting:
                fixed attenuation = LIGHT_ATTENUATION(i)*0.9;
                fixed3 attenColor = attenuation*_LightColor0.xyz;
/////// Diffuse:
                fixed NdotL = max(0.2,dot( normalDirection, lightDirection ));
                //fixed3 indirectDiffuse = UNITY_LIGHTMODEL_AMBIENT.rgb;
                fixed3 directDiffuse = NdotL* attenColor;
                fixed3 indirectDiffuse = i.shLight;
                fixed3 diffuse = (directDiffuse + indirectDiffuse) * _MainTexColor.rgb;
////// Emissive:
				fixed rimRange = 1-abs(dot(i.viewDirection,normalDirection));
                half2 ReflUV = mul( UNITY_MATRIX_V, float4(normalDirection,0)).rg*0.5+0.5;
                fixed4 _Reflection_var = tex2D(_Reflection,TRANSFORM_TEX(ReflUV, _Reflection));
				//fixed ReflectionRange = tex2D(_Reflection, TRANSFORM_TEX(i.uv0, _MainTex));
                fixed3 emissive = _Color.rgb+_Reflection_var.rgb*_ReflectionIntension+rimRange*rimRange*_RimColor;
				//float3 emissive = _Color.rgb + _Reflection_var.rgb*ReflectionRange;
/// Final Color:
                fixed3 finalColor = diffuse + emissive;
                /*finalColor *= ShadowColorAtten(i.posWorld);
                #ifdef PROJECTOR_DEPTH_MAP_ON
                finalColor *= ProjectorShadowColorAtten(i.posWorld);
                #endif*/
				finalColor.rgb = GetDynamicPointLightColor(finalColor.rgb, i.posWorld, normalDirection);
                if(UseHeightFog > 0)
                {
                	TL_APPLY_FOG(i.fogCoord,finalColor.rgb);
                }else
                {
	                UNITY_APPLY_FOG(i.fogCoord,finalColor);                
                }
                return fixed4(finalColor, tailorAlpha);
            }
            ENDCG
        }

    }
			FallBack "Mobile/Diffuse"
}
