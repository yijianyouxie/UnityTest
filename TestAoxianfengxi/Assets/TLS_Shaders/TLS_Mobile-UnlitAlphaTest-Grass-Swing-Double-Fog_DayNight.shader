﻿// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Unlit alpha-cutout shader.
// - no lighting
// - no lightmap support
// - no per-material color

Shader "TLStudio/Transparent/UnLit Cutout_Ani Double-Fog DayNight" {
Properties {
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
	_Range("Range" , Range(0,0.1)) = 0.05
//	_LightingScale("LightScale(fake)",Range(0.5,1.5)) = 1
}
SubShader {
	Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
	LOD 100
	Cull Off

	Lighting Off

	Pass {  
		CGPROGRAM
		#pragma skip_variants FOG_EXP SHADOWS_CUBE
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			
			#include "UnityCG.cginc"
			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
				UNITY_FOG_COORDS(1)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;
			// fixed _LightingScale;
			half	_Range;
			fixed4 _LightColorScale;
			v2f vert (appdata_full v)
			{
				half4	finalpos = mul(unity_ObjectToWorld,v.vertex);
				half3	dist =	_WorldSpaceCameraPos.xyz - finalpos.xyz;
				half4	mdlPos;
				if(length(dist) < 25)
				{
					float 	finalbias = fmod(finalpos.x*finalpos.x + finalpos.y*finalpos.y + finalpos.z*finalpos.z,4);
					if(v.color.r == 0)
					{
						mdlPos	= v.vertex;
					}
					else
					{
						half st = 0;
						if(finalbias < 1) st = max(_CosTime.w + 0.3, -0.5);
						else if(finalbias >= 1 && finalbias < 2) st = min(_SinTime.w, 0.8) * finalbias;
						else if(finalbias >= 2 && finalbias < 3) st = min(_CosTime.w, 0.9) * finalbias;
						else if(finalbias >= 3 && finalbias < 4) st = max(_SinTime.w + 0.8, -0.8) * finalbias;
						mdlPos.xyz = v.vertex.xyz + v.tangent * st * _Range ;
						mdlPos.w = v.vertex.w;
					}
				}
				else
				{
					mdlPos = v.vertex;
				}

				v2f o;
				o.vertex = UnityObjectToClipPos(mdlPos);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				if(UseHeightFog > 0)
				{
					TL_TRANSFER_FOG(o, o.vertex, v.vertex);
				}else
				{
					UNITY_TRANSFER_FOG(o, o.vertex);				
				}
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.texcoord);
				clip(col.a - _Cutoff);
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(i.fogCoord, col.rgb);
				}else
				{
					UNITY_APPLY_FOG(i.fogCoord, col);				
				}
				
				fixed3 finalColor = col*_LightColorScale;
				return fixed4(finalColor,col.a);
			}
		ENDCG
	}
		Pass
			{
				//??pass???? ??????fallBack??????? "LightMode" = "ShadowCaster" ?????????Pass
				Tags{ "LightMode" = "ShadowCaster" }

				CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#pragma multi_compile_shadowcaster
//#pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
#pragma shader_feature _RENDERING_CUTOUT
#pragma shader_feature _SMOOTHNESS_ALBEDO
#include "UnityCG.cginc"
				sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;
			struct v2f {
				V2F_SHADOW_CASTER;
				float2 uv : TEXCOORD1;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
					return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				fixed4 testColor = tex2D(_MainTex, i.uv);
				clip(testColor.a - _Cutoff);
				SHADOW_CASTER_FRAGMENT(i)
			}
				ENDCG

			}
}

}
