// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Effect/BreathLight"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
        _Color("Color",Color) = (1,1,1,1)
      _frequency("Frequency",float) =1
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
		LOD 100
ZWrite Off
Cull Off
Blend One One
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				half2 uv : TEXCOORD0;
			};

			struct v2f
			{
				half2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			half4 _MainTex_ST;
            fixed4 _Color;
float _frequency;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
                 col = col*((sin(_Time.w*_frequency)+3)*0.5)*col.a*_Color;
				return col;
			}
			ENDCG
		}
	}
}
