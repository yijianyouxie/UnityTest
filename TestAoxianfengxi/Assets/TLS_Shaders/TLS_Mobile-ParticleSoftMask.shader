// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Effect/AdditiveMask (Soft)" {
Properties {
     _TintColor("TintColor",Color) = (1,1,1,1)
	_MainTex ("Particle Texture", 2D) = "white" {}
	_Mask ("Mask", 2D) = "white" {}
}

Category {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	Blend One OneMinusSrcColor
	ColorMask RGBA
	Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }

	SubShader {
    LOD 150
		Pass {
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_particles

			#include "UnityCG.cginc"
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x

			sampler2D _MainTex;
			sampler2D _Mask;
			fixed4 _TintColor;
			
			struct appdata_t {
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				#ifdef SOFTPARTICLES_ON
				float4 projPos : TEXCOORD1;
				#endif
			};

			float4 _MainTex_ST;
			float4 _Mask_ST;
			
			v2f vert (appdata_t v)
			{
				v2f o = (v2f)0;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				o.texcoord = v.texcoord;
				return o;
			}

			sampler2D_float _CameraDepthTexture;
			float _InvFade;
			
			fixed4 frag (v2f i) : SV_Target
			{
			    fixed3 MainTex_Var = tex2D(_MainTex, TRANSFORM_TEX(i.texcoord, _MainTex));
				fixed4 Mask_Var = tex2D(_Mask, TRANSFORM_TEX(i.texcoord, _Mask));
				fixed4 col = fixed4(MainTex_Var,Mask_Var.r);
				half4 prev = i.color * col *_TintColor;
				prev.rgb *= prev.a;
				prev.a = prev.a;
				return prev;
			}
			ENDCG 
		}
	} 
}
}