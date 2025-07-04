// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Character/CharacterMask" {
    Properties {
		_Color("AddColor", Color) = (0,0,0,1)
        _MainTex ("MainTex", 2D) = "white" {}
		_Mask("Mask", 2D) = "white" {}
        _Reflection ("Reflection", 2D) = "white" {}
        _RimColor ("RimColor", Color) = (1,1,1,1)
		_ReflectionIntension("Reflection Intensity",Range(0,1)) = 0.5
		[HideInInspector]_Cutoff ("",float) = 0.5
    }
    SubShader {
        Tags {
            "Queue"="AlphaTest+150"
            "RenderType"="TransparentCutout"
        }
		LOD 150
        Pass {
            Name "ForwardBase"
            Tags {
                "LightMode"="ForwardBase"
            }
            ColorMask RGBA
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #define SHOULD_SAMPLE_SH_PROBE ( defined (LIGHTMAP_OFF) )
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            uniform float4 _LightColor0;
            uniform sampler2D _Reflection; uniform float4 _Reflection_ST;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST; 
            uniform sampler2D _Mask; uniform float4 _Mask_ST;
            uniform fixed4 _Color;
            uniform fixed4 _RimColor;
            uniform fixed _ReflectionIntension;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                half2 uv0 : TEXCOORD0;
                fixed3 viewDirection : TEXCOORD1;
                fixed3 normalDir : TEXCOORD2;
                LIGHTING_COORDS(3,4)
                float3 shLight : TEXCOORD5;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);// mul(_Object2World, float4(v.normal,0)).xyz;
                #if SHOULD_SAMPLE_SH_PROBE
                    o.shLight = ShadeSH9(float4(o.normalDir * 1.0,1));
                #endif
                o.viewDirection = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR {
                i.normalDir = normalize(i.normalDir);
/////// Vectors:
                fixed3 normalDirection = i.normalDir;
				fixed3 _MainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
				fixed4 _MaskCol = tex2D(_Mask, TRANSFORM_TEX(i.uv0, _Mask));
				fixed4 _finalRGBA = fixed4(_MainTexColor, _MaskCol.r);

                clip(_finalRGBA.a-(1-_Color.a));
                fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
////// Lighting:
                fixed attenuation = LIGHT_ATTENUATION(i)*0.9;
                fixed3 attenColor = attenuation*_LightColor0.xyz;
/////// Diffuse:
                fixed NdotL = max(0.2,dot( normalDirection, lightDirection ));
                fixed3 indirectDiffuse = UNITY_LIGHTMODEL_AMBIENT.rgb;
                fixed3 directDiffuse = NdotL* attenColor;
                #if SHOULD_SAMPLE_SH_PROBE
                    indirectDiffuse += i.shLight;
                #endif
                fixed3 diffuse = (directDiffuse + indirectDiffuse) * _finalRGBA.rgb;
////// Emissive:
				fixed rimRange = 1-abs(dot(i.viewDirection,normalDirection));
                half2 ReflUV = mul( UNITY_MATRIX_V, float4(normalDirection,0)).rg*0.5+0.5;
                fixed4 _Reflection_var = tex2D(_Reflection,TRANSFORM_TEX(ReflUV, _Reflection));
				//fixed ReflectionRange = tex2D(_Reflection, TRANSFORM_TEX(i.uv0, _MainTex));
                fixed3 emissive = _Color.rgb+_Reflection_var.rgb*_ReflectionIntension+rimRange*rimRange*_RimColor;
				//float3 emissive = _Color.rgb + _Reflection_var.rgb*ReflectionRange;
/// Final Color:
                fixed3 finalColor = diffuse + emissive;
                return fixed4(finalColor,1);
            }
            ENDCG
        }
                	Pass {
		Name "Caster"
		Tags { "LightMode" = "ShadowCaster" }
		Offset 1, 1
		
		Fog {Mode Off}
		ZWrite On ZTest LEqual Cull Off

CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_shadowcaster
#include "UnityCG.cginc"

struct v2f { 
	V2F_SHADOW_CASTER;
	float2  uv : TEXCOORD1;
};

uniform sampler2D _MainTex;
uniform float4 _MainTex_ST; 
uniform sampler2D _Mask; 
uniform float4 _Mask_ST;

v2f vert( appdata_base v )
{
	v2f o;
	TRANSFER_SHADOW_CASTER(o)
	
	o.uv = v.texcoord;
	return o;
}

uniform fixed _Cutoff;
uniform fixed4 _Color;

float4 frag( v2f i ) : SV_Target
{
	fixed3 _MainTexColor = tex2D(_MainTex,TRANSFORM_TEX(i.uv, _MainTex));
	fixed4 _MaskCol = tex2D(_Mask,TRANSFORM_TEX(i.uv, _Mask));
	fixed4 _finalRGBA = fixed4(_MainTexColor, _MaskCol.r);
	clip(_finalRGBA.a-(1-_Color.a));
	
	SHADOW_CASTER_FRAGMENT(i)
}
ENDCG
	}
    }
    FallBack "Mobile/Diffuse"
}
