// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Ground"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 pos : SV_POSITION;
				//LIGHTING_COORDS(2, 3) // NEEDED FOR SHADOWS.
					SHADOW_COORDS(2)
						float4 lmap : TEXCOORD3;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.pos);
				//TRANSFER_VERTEX_TO_FRAGMENT(o); // NEEDED FOR SHADOWS.
#ifndef LIGHTMAP_OFF
				o.lmap.xy = v.uv * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
				TRANSFER_SHADOW(o);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				fixed atten = LIGHT_ATTENUATION(i);// NEEDED FOR SHADOWS.
				//fixed shadow = SHADOW_ATTENUATION(i);
#ifndef LIGHTMAP_OFF
				fixed4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lmap.xy);
				fixed3 lightmap = DecodeLightmap(lmtex);
				fixed3 directDiffuse = min(lightmap.rgb, atten*lightmap.rgb);
				return fixed4(col.rgb * atten * directDiffuse, 1) /** _LightColor0*/;
#endif
				return col * atten;
			}
			ENDCG
		}
		/*Pass
		{
		Name "ShadowCollector"
		Tags{ "LightMode" = "ShadowCollector" }

		Fog{ Mode Off }
		ZWrite On ZTest LEqual

		CGPROGRAM
		#line 36 ""
		#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
		#endif

		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_shadowcollector

		#define SHADOW_COLLECTOR_PASS
		#include "UnityCG.cginc"

		struct appdata {
		float4 vertex : POSITION;
		};

		struct v2f {
		V2F_SHADOW_COLLECTOR;
		};

		v2f vert(appdata v)
		{
		v2f o;
		TRANSFER_SHADOW_COLLECTOR(o)
		return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
		SHADOW_COLLECTOR_FRAGMENT(i)
		}
		ENDCG

		#LINE 65

		}*/
//				Pass
//			{
//				Name "ShadowCaster"
//				Tags{ "LightMode" = "ShadowCaster" }
//
//				ZWrite On ZTest LEqual Cull Off
//
//				CGPROGRAM
//#pragma vertex vert
//#pragma fragment frag
//#pragma multi_compile_shadowcaster
//#include "UnityCG.cginc"
//
//				struct v2f {
//				V2F_SHADOW_CASTER;
//			};
//
//			v2f vert(appdata_base v)
//			{
//				v2f o;
//				//TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
//				TRANSFER_SHADOW_CASTER(o)
//					return o;
//			}
//
//			float4 frag(v2f i) : SV_Target
//			{
//				SHADOW_CASTER_FRAGMENT(i)
//			}
//				ENDCG
//			}
		
	}
		//Fallback "VertexLit"
	Fallback "Custom/TestFallBack"
}
