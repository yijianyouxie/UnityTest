// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Community contribution: http://www.tasharen.com/forum/index.php?topic=9268.0
Shader "Hidden/Unlit/Transparent Colored Gray (TextureClip)"
{
	Properties
	{
		_MainTex ("Base (RGB), Alpha (A)", 2D) = "black" {}
	}

	SubShader
	{
		LOD 100

		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
		}

		Pass
		{
			Cull Off
			Lighting Off
			ZWrite Off
			Offset -1, -1
			Fog { Mode Off }
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _ClipTex;
			float4 _ClipRange0 = float4(0.0, 0.0, 1.0, 1.0);
			float2 _ClipArgs0 = float2(1000.0, 1000.0);
			float4 _ClipRange1 = float4(0.0, 0.0, 1.0, 1.0);
			float2 _ClipArgs1 = float2(1000.0, 1000.0);

			struct appdata_t
			{
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
				fixed4 color : COLOR;
			};

			struct v2f
			{
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
				half2 clipUV : TEXCOORD2;
				float2 worldPos : TEXCOORD1;
				fixed4 color : COLOR;
			};

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				o.texcoord = v.texcoord;
				o.clipUV = (v.vertex.xy * _ClipRange0.zw + _ClipRange0.xy) * 0.5 + half2(0.5, 0.5);
				o.worldPos = v.vertex.xy * _ClipRange1.zw + _ClipRange1.xy;
				return o;
			}

			fixed4 frag (v2f IN) : COLOR
			{
				// Softness factor
				float2 factor = (float2(1.0, 1.0) - abs(IN.worldPos)) * _ClipArgs1;


				fixed4 texColor = tex2D(_MainTex, IN.texcoord);
				fixed4 col = texColor * IN.color;
				col.a *= tex2D(_ClipTex, IN.clipUV).a;

				col.a *= clamp(min(factor.x, factor.y), 0.0, 1.0);

				if (IN.color.r + IN.color.g + IN.color.b < 0.1) {
					fixed gray = dot(fixed3(0.6, 0.2, 0.01), texColor);
					fixed3 grayCol = fixed3(gray, gray, gray);
					col.rgb = grayCol;
				}

				return col;
			}
			ENDCG
		}
	}
	Fallback "Unlit/Transparent Colored"
}
