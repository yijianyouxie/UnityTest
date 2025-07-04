Shader "Unlit/CopyDepth"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			ZTest Always Cull Off ZWrite Off
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
			};

			//sampler2D _MainTex;
			UNITY_DECLARE_DEPTH_TEXTURE(_MainTex);
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//return fixed4(1,1,0,1);
				// sample the texture
				float depth = SAMPLE_RAW_DEPTH_TEXTURE(_MainTex, i.uv);
				//depth = depth - 0.00001;
				depth = clamp(depth, 0, 0.99999);
				/*return float4(depth, 0,0,0);
				depth = LinearEyeDepth(depth);*/
				//float4 col = tex2D(_MainTex, i.uv);
				float4 final = EncodeFloatRGBA(depth);//[0,1)
				//return fixed4(depth, 0,0,1);
				return final;
			}
			ENDCG
		}
	}
}
