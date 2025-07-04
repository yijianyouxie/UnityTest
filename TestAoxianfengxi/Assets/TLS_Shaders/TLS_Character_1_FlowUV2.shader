// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Character/Character_FlowUV2" {
    Properties {
		_Color("AddColor", Color) = (0,0,0,1)
        _MainTex ("MainTex", 2D) = "white" {}
		_Flow_Texture("Flow_Texture", 2D) = "white" {}
        _Reflection ("Reflection", 2D) = "white" {}
        _RimColor ("RimColor", Color) = (1,1,1,1)
		_ReflectionIntension("Reflection Intensity",Range(0,1)) = 0.5
		[HideInInspector]_Cutoff ("",float) = 0.5
		_SpeedX("SpeedX", Float) = 1
		_SpeedY("SpeedY", Float) = 1
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
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile FOG_EXP2 FOG_LINEAR
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
			#define INTERNAL_DATA

            uniform fixed4 _LightColor0;
            uniform sampler2D _Reflection; uniform half4 _Reflection_ST;
            uniform sampler2D _MainTex; uniform half4 _MainTex_ST;
			uniform sampler2D _Flow_Texture;uniform fixed4 _Flow_Texture_ST;
			uniform fixed	_SpeedX;
			uniform fixed	_SpeedY;
            uniform fixed4 _Color;
            uniform fixed4 _RimColor;
            uniform fixed _ReflectionIntension;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                half2 texcoord0 : TEXCOORD0;
				half2 texcoord1 : TEXCOORD1;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                half2 uv0 : TEXCOORD0;
				half2 uv1 : TEXCOORD1;
                fixed3 viewDirection : TEXCOORD2;
                fixed3 normalDir : TEXCOORD3;
                LIGHTING_COORDS(4,5)
                float3 shLight : TEXCOORD6;
                UNITY_FOG_COORDS(7)
            };

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _MainTex);
				o.uv1 = TRANSFORM_TEX(v.texcoord1, _Flow_Texture);
				fixed modtime = fmod(_Time.x,60) ; 
				o.uv1.x = o.uv1.x + modtime * _SpeedX;
				o.uv1.y = o.uv1.y + modtime * _SpeedY;
                o.normalDir = UnityObjectToWorldNormal(v.normal);// mul(_Object2World, float4(v.normal,0)).xyz;
                o.shLight = ShadeSH9(float4(o.normalDir * 1.0,1));
                o.viewDirection = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
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
                i.normalDir = normalize(i.normalDir);
/////// Vectors:
                fixed3 normalDirection = i.normalDir;
				fixed4 _MainTexColor = tex2D(_MainTex, i.uv0);
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
				fixed4 Tex2D1 = tex2D(_Flow_Texture, i.uv1);
				fixed4 Add0 = Tex2D1*Tex2D1.a + fixed4(finalColor,1);
                if(UseHeightFog > 0)
                {
                	TL_APPLY_FOG(i.fogCoord,finalColor.rgb);
                }else
                {
	                UNITY_APPLY_FOG(i.fogCoord,finalColor);                
                }
                return fixed4(Add0.rgb,1);
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
	half2  uv : TEXCOORD1;
};

uniform float4 _MainTex_ST;

v2f vert( appdata_base v )
{
	v2f o;
	TRANSFER_SHADOW_CASTER(o)
	
	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
	return o;
}

uniform sampler2D _MainTex;
uniform fixed _Cutoff;
uniform fixed4 _Color;

fixed4 frag( v2f i ) : SV_Target
{
	fixed4 _MainTexColor = tex2D(_MainTex,i.uv);
	clip(_MainTexColor.a-(1-_Color.a));
	
	SHADOW_CASTER_FRAGMENT(i)
}
ENDCG
	}
    }
			FallBack "Mobile/Diffuse"
}
