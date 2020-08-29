// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/TestFallBack"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		//Pass
		//{
		//	CGPROGRAM
		//	#pragma vertex vert
		//	#pragma fragment frag
		//	// make fog work
		//	#pragma multi_compile_fog
		//	
		//	#include "UnityCG.cginc"

		//	struct appdata
		//	{
		//		float4 vertex : POSITION;
		//		float2 uv : TEXCOORD0;
		//	};

		//	struct v2f
		//	{
		//		float2 uv : TEXCOORD0;
		//		UNITY_FOG_COORDS(1)
		//		float4 vertex : SV_POSITION;
		//	};

		//	sampler2D _MainTex;
		//	float4 _MainTex_ST;
		//	
		//	v2f vert (appdata v)
		//	{
		//		v2f o;
		//		o.vertex = UnityObjectToClipPos(v.vertex);
		//		o.uv = TRANSFORM_TEX(v.uv, _MainTex);
		//		UNITY_TRANSFER_FOG(o,o.vertex);
		//		return o;
		//	}
		//	
		//	fixed4 frag (v2f i) : SV_Target
		//	{
		//		// sample the texture
		//		fixed4 col = tex2D(_MainTex, i.uv);
		//		// apply fog
		//		UNITY_APPLY_FOG(i.fogCoord, col);
		//		return col;
		//	}
		//	ENDCG
		//}
		Pass
		{
		Name "ShadowCaster"
		Tags{ "LightMode" = "ShadowCaster" }

		//ZWrite On ZTest LEqual Cull Off

		//CGPROGRAM
		//#pragma vertex vert
		//#pragma fragment frag
		//#pragma multi_compile_shadowcaster
		//#include "UnityCG.cginc"

		//struct v2f {
		//V2F_SHADOW_CASTER;
		//};

		//v2f vert(appdata_base v)
		//{
		//v2f o;
		////TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
		//	TRANSFER_SHADOW_CASTER(o)
		//return o;
		//}

		//float4 frag(v2f i) : SV_Target
		//{
		//SHADOW_CASTER_FRAGMENT(i)
		//}
		//ENDCG
		}
		/*		Pass
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
	}
}
