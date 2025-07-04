// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Effect/BreathLight(UIPanelClip)"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
        _Color("Color",Color) = (1,1,1,1)
      	_frequency("Frequency",float) = 1
      	_ClipRange0 ("_ClipRange0", Vector) = (0.0, 0.0, 1.0, 1.0)
    	_ClipArgs0 ("_ClipArgs0", Vector) = (1000.0, 1000.0, 1.0, 1.0)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
		LOD 100
		ZWrite Off
		Cull Off
		Blend SrcAlpha One
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float2 worldPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
            fixed4 _Color;
			float _frequency;
			float4 _ClipRange0;
			float2 _ClipArgs0;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				float2 clipSpace = o.vertex.xy / o.vertex.w;
				clipSpace = (clipSpace.xy + 1) * 0.5;
				o.worldPos = clipSpace * _ClipRange0.zw + _ClipRange0.xy;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
                col = col*((sin(_Time.w*_frequency)+3)*0.5)*col.a*_Color;
                float2 factor = (float2(1.0, 1.0) - abs(i.worldPos)) * _ClipArgs0;
                col.a *= clamp( min(factor.x, factor.y), 0.0, 1.0);
				return col;
			}
			ENDCG
		}
	}
}
