// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Character/Character1\4Blend" {
    Properties {
		_Color("AddColor", Color) = (0,0,0,1)
        _MainTex ("MainTex", 2D) = "white" {}
        _Reflection ("Reflection", 2D) = "white" {}
        _RimColor ("RimColor", Color) = (1,1,1,1)
        _ShadeColor ("Shade Color", Color) = (0.7, 0.3, 0.6, 1)
    }
    SubShader {
        Tags {
            "Queue"="Transparent"
            "RenderType"="Transparent"
             "ShadowProjector" = "true"
        }
		LOD 150
		//Pass
		//{
		//   Blend One One
  //         Lighting Off   
		//   ZTest Greater 
		//   ZWrite Off
		//   CGPROGRAM
		//   #pragma skip_variants FOG_EXP INSTANCING_ON DIRECTIONAL DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SHADOWS_SCREEN SHADOWS_SHADOWMASK VERTEXLIGHT_ON SHADOWS_CUBE POINT SPOT UNITY_HDR_ON
		//   #pragma vertex vert
		//   #pragma fragment frag
		//   #pragma fragmentoption ARB_precision_hint_fastest   
   
		//   float4 _ShadeColor;
		//   struct appdata
		//   {
		//		float4 vertex : POSITION;
		//		float3 _normal : NORMAL;
		//		half2 uv0 : TEXCOORD0;
		//   };

		//   struct v2f
		//   {
		//		float4 pos : POSITION; 
		//		float2 uv0 : TEXCOORD0;  
		//   };

		//   v2f vert(appdata v)
		//   {
		//		v2f o;
		//		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		//		o.uv0 = v.uv0;
		//		return o;
		//   }
		//   float4 frag(v2f i) : COLOR
		//   {
		//		return _ShadeColor;
		//   }
		//   ENDCG
		//} 
        Pass {
            Name "ForwardBase"
            Tags {
                "LightMode"="ForwardBase"
            }
            ColorMask RGBA
            Blend SrcAlpha OneMinusSrcAlpha  
			Stencil
			{
				Ref 2         // 写入Stencil的值为1
				Comp always   // 总是写入
				Pass replace  // 替换现有Stencil值
			}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            /*#pragma multi_compile __ PROJECTOR_DEPTH_MAP_ON
            #include "DepthMapShadow.cginc"*/
            uniform fixed4 _LightColor0;
            uniform sampler2D _Reflection; uniform half4 _Reflection_ST;
            uniform sampler2D _MainTex; uniform half4 _MainTex_ST;
            uniform fixed4 _Color;
            uniform fixed4 _RimColor;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                half2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                half2 uv0 : TEXCOORD0;
                half2 uv1: TEXCOORD6;
                fixed3 viewDirection : TEXCOORD1;
                fixed3 normalDir : TEXCOORD2;
                LIGHTING_COORDS(3,4)
                float3 shLight : TEXCOORD5;
                float4 posWorld:TEXCOORD7;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.uv1 =  (( v.texcoord0*0.4375)+0.53135);
                o.normalDir = UnityObjectToWorldNormal(v.normal);// mul(_Object2World, float4(v.normal,0)).xyz;
                o.shLight = ShadeSH9(float4(o.normalDir * 1.0,1));
                o.posWorld = mul(unity_ObjectToWorld , v.vertex);
                o.viewDirection = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR {
                i.normalDir = normalize(i.normalDir);
/////// Vectors:
                fixed3 normalDirection = i.normalDir;
                fixed4 CtrlTex = tex2D(_MainTex,TRANSFORM_TEX(i.uv1, _MainTex));
				fixed4 _MainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
                clip(_Color.a-CtrlTex.g);
                fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
////// Lighting:
                fixed attenuation = LIGHT_ATTENUATION(i)*0.9;
                fixed3 attenColor = attenuation * _LightColor0.xyz;
/////// Diffuse:
                fixed NdotL = max(0.2,dot( normalDirection, lightDirection ));
                fixed3 directDiffuse =NdotL* attenColor*(1-CtrlTex.b);
                fixed3 indirectDiffuse = i.shLight;
                fixed3 diffuse = (directDiffuse + indirectDiffuse) * _MainTexColor.rgb;
////// Emissive:
				fixed rimRange = 1-abs(dot(i.viewDirection,normalDirection));
                fixed2 ReflUV = mul( UNITY_MATRIX_V, float4(normalDirection,0)).rg*0.5+0.5;
                fixed4 _Reflection_var = tex2D(_Reflection,TRANSFORM_TEX(ReflUV, _Reflection));
				//fixed ReflectionRange = tex2D(_Reflection, TRANSFORM_TEX(i.uv0, _MainTex));
                fixed3 emissive = _Color.rgb+_Reflection_var.rgb*CtrlTex.r+rimRange*rimRange*_RimColor+ _MainTexColor.rgb * CtrlTex.b*0.5;
;
				//float3 emissive = _Color.rgb + _Reflection_var.rgb*ReflectionRange;
/// Final Color:
                fixed3 finalColor = diffuse + emissive;
                /*finalColor *= ShadowColorAtten(i.posWorld);
                #ifdef PROJECTOR_DEPTH_MAP_ON
                finalColor *= ProjectorShadowColorAtten(i.posWorld);
                #endif*/
                return fixed4(finalColor,1-CtrlTex.g);
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

uniform float4 _MainTex_ST;

v2f vert( appdata_base v )
{
	v2f o;
	TRANSFER_SHADOW_CASTER(o)
	
	 half2 uvTemp = ((v.texcoord*0.4375)+0.53135);
	o.uv = TRANSFORM_TEX(uvTemp, _MainTex);
	return o;
}

uniform sampler2D _MainTex;
uniform fixed _Cutoff;
uniform fixed4 _Color;

float4 frag( v2f i ) : SV_Target
{
	fixed4 texcol = tex2D( _MainTex, i.uv );
	clip(_Color.a-texcol.g);
	
	SHADOW_CASTER_FRAGMENT(i)
}
ENDCG
	}
    }
	FallBack "Mobile/Diffuse"
}