﻿Shader "Hidden/Custom/Texture2DArray Colored 2"
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
			float4 _ClipRange0 = float4(0.0, 0.0, 1.0, 1.0);
			float4 _ClipArgs0 = float4(1000.0, 1000.0, 0.0, 1.0);
			float4 _ClipRange1 = float4(0.0, 0.0, 1.0, 1.0);
			float4 _ClipArgs1 = float4(1000.0, 1000.0, 0.0, 1.0);
	
			struct appdata_t
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				fixed4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			float2 Rotate(float2 v, float2 rot)
			{
				float2 ret;
				ret.x = v.x * rot.y - v.y * rot.x;
				ret.y = v.x * rot.x + v.y * rot.y;
				return ret;
			}
	
			struct v2f
			{
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
				fixed4 color : COLOR;
				float4 worldPos : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};
	
			v2f o;

			v2f vert (appdata_t v)
			{
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = v.texcoord;
				o.color = v.color;
				o.worldPos.xy = v.vertex.xy * _ClipRange0.zw + _ClipRange0.xy;
				o.worldPos.zw = Rotate(v.vertex.xy, _ClipArgs1.zw) * _ClipRange1.zw + _ClipRange1.xy;
				return o;
			}
				
			fixed4 frag (v2f IN) : SV_Target
			{
				// First clip region
				float2 factor = (float2(1.0, 1.0) - abs(IN.worldPos.xy)) * _ClipArgs0.xy;
				float f = min(factor.x, factor.y);

				// Second clip region
				factor = (float2(1.0, 1.0) - abs(IN.worldPos.zw)) * _ClipArgs1.xy;
				f = min(f, min(factor.x, factor.y));

				// 每秒10帧
				int index = floor(fmod(_Time.y * 10.0, _FrameCount));
				fixed4 texColor = UNITY_SAMPLE_TEX2DARRAY(_MainTex, float3(IN.texcoord, index));
				fixed4 col = texColor * IN.color;

				col.a *= clamp(f, 0.0, 1.0);
				return col;
			}
			ENDCG
		}
	}
}
