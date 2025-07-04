// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Unlit shader. Simplest possible textured shader.
// - no lighting
// - no lightmap support
// - no per-material color

Shader "TLStudio/Transparent/UnLitColor" {
	Properties{
		[MaterialEnum(UnityEngine.Rendering.CullMode)] _Cull("裁剪模式", Int) = 2
		[Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 0
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

		SubShader{
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		LOD 100

		Cull[_Cull]
		ZWrite[_ZWrite]
		Blend SrcAlpha OneMinusSrcAlpha
		Pass{
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"

	struct appdata_t {
		float4 vertex : POSITION;
		half2 texcoord : TEXCOORD0;
	};

	struct v2f {
		float4 vertex : SV_POSITION;
		half2 texcoord : TEXCOORD0;
	};

	sampler2D _MainTex;
	half4 _MainTex_ST;
	fixed4 _Color;

	v2f vert(appdata_t v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
		return o;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		fixed4 col = tex2D(_MainTex, i.texcoord)*_Color;
	return col;
	}
		ENDCG
	}
	}

}
