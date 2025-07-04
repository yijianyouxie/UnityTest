Shader "Custom/Texture2DArray Colored"
{
	Properties
	{
		_MainTex("Texture Array", 2DArray) = "" {}
		// _Index("Texture Array Index", Float) = 0
		_FrameCount("frames", Float) = 0
	}
	
	SubShader
	{
		LOD 150

		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"DisableBatching" = "True"
		}
		
		Pass
		{
			Cull Off
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			Offset -1, -1
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#include "UnityCG.cginc"
            #pragma exclude_renderers xbox360 ps3 flash d3d11_9x

			UNITY_DECLARE_TEX2DARRAY(_MainTex);
            // int _Index;
			int _FrameCount;
	
			struct appdata_t
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				fixed4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
	
			struct v2f
			{
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
				fixed4 color : COLOR;
				UNITY_VERTEX_OUTPUT_STEREO
			};
	
			v2f o;

			v2f vert (appdata_t v)
			{
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = v.texcoord;
				o.color = v.color;
				return o;
			}
				
			fixed4 frag (v2f IN) : SV_Target
			{
				// 每秒10帧
				int index = floor(fmod(_Time.y * 10.0, _FrameCount));
				fixed4 texColor = UNITY_SAMPLE_TEX2DARRAY(_MainTex, float3(IN.texcoord, index));
				fixed4 col = texColor * IN.color;

				return col;
			}
			ENDCG
		}
	}
}
