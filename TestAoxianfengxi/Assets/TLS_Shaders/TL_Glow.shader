Shader "TLStudio/Effect/Glow"{
	Properties{
		_MainTex("Main tex",2D) = "black" {}
		_GlowColor("Glow Color", Color) = (1,0,0,1)
		_Outline("Outline width", Range(0.0, 1.0)) = 0.225
		_Opacity("Glow Opacity", Range(0.5, 2.0)) = 1.0
		//_RenderTex("Render tex",2D) = "black" {}
		_MaskTex("Mask tex",2D) = "white" {}
		/*_Factor("Factor",Range (0.0, 1.0)) = 1.0
		_TintColor ("Tint Color", Color) = (1,0,0,1)*/
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	struct vinGlow {
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		half2 texcoord0 : TEXCOORD0;
	};
	struct voutGlow {
		float4 pos : POSITION;
		float4 color : COLOR;
		half2 uv : TEXCOORD0;
	};

	uniform fixed4 _Color;

	uniform sampler2D _MainTex;
	uniform half4 _MainTex_ST;
	/*uniform sampler2D _RenderTex;
	uniform half4 _RenderTex_ST;*/
	uniform sampler2D _MaskTex;
	uniform half4 _MaskTex_ST;

	uniform fixed4 _GlowColor;
	uniform fixed _Outline;
	uniform fixed _Opacity;
	/*uniform fixed _Factor;
	uniform fixed4 _TintColor;*/

	voutGlow vertPassGlobal(vinGlow v, fixed Occlusion)
	{
		voutGlow o;
		//float4 view_vertex = mul(UNITY_MATRIX_MV, v.vertex);
		float4 view_vertex = float4(UnityObjectToViewPos(v.vertex), 1.0);
		float3 view_normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
		view_vertex.xy += normalize(view_normal) * view_vertex.w * 2.0 * _Outline * Occlusion / 10.0;
		o.pos = mul(UNITY_MATRIX_P, view_vertex);
		o.color = fixed4(_GlowColor.r, _GlowColor.g, _GlowColor.b, _Opacity / 5.0);

		o.uv = v.texcoord0;

		return o;
	}
	fixed4 fragPass(voutGlow i) : COLOR
	{
		fixed mask = tex2D(_MaskTex, i.uv).r;
		fixed4 finalColor = i.color;
		finalColor.a *= mask;
		return finalColor;
	}

	ENDCG

	SubShader {
		Tags{ "Queue" = "Transparent" }

		Pass{
			Name "OUTLINE1" Tags{ "LightMode" = "Always" }
			Cull Front ZWrite Off Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
			voutGlow vertPass(vinGlow v) {
				return vertPassGlobal(v, 0.2);
			}
			ENDCG
		}

		Pass{
			Name "OUTLINE2" Tags{ "LightMode" = "Always" }
			Cull Front ZWrite Off Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
				voutGlow vertPass(vinGlow v) {
				return vertPassGlobal(v, 0.4);
			}
			ENDCG
		}

		Pass{
			Name "OUTLINE3" Tags{ "LightMode" = "Always" }
			Cull Front ZWrite Off Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
				voutGlow vertPass(vinGlow v) {
				return vertPassGlobal(v, 0.6);
			}
			ENDCG
		}

		Pass{
			Name "OUTLINE3" Tags{ "LightMode" = "Always" }
			Cull Front ZWrite Off Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
				voutGlow vertPass(vinGlow v) {
				return vertPassGlobal(v, 0.8);
			}
			ENDCG
		}

		Pass{
			Name "OUTLINE5" Tags{ "LightMode" = "Always" }
			Cull Front ZWrite Off Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
				voutGlow vertPass(vinGlow v) {
				return vertPassGlobal(v, 1.0);
			}
			ENDCG
		}

		//Pass{
		//	Name "BACKGR" Tags{ "LightMode" = "Always" }
		//	Blend SrcAlpha OneMinusSrcAlpha
		//    Cull Back //剔除后面
		//    CGPROGRAM
		//    #pragma vertex vert
		//    #pragma fragment frag
		//    #include "UnityCG.cginc"

		//    struct v2f
		//    {
		//        float4 vertex :POSITION;
		//        float4 uv:TEXCOORD0;
		//    };
		//
		//    v2f vert(appdata_full v)
		//    {
		//        v2f o;
		//        o.vertex = mul(UNITY_MATRIX_MVP,v.vertex);
		//        o.uv = v.texcoord;
		//        return o;
		//    }

		//    fixed4 frag(v2f IN) :COLOR
		//    {
		//        fixed4 _MainTex_Var = tex2D(_MainTex,IN.uv);
		//        //fixed4 _RenderTex_Var = tex2D(_RenderTex, IN.uv);
		//		//fixed Area = tex2D(_AreaTex, IN.uv).r;
		//		fixed4 finalColor = _MainTex_Var /*+ _TintColor * _Factor*/;
		//        return finalColor;
		//    }
		//    ENDCG
		//}
	}
	Fallback "Diffuse"
}