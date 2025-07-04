Shader "AA/FXAA"
{
	Properties
	{
		_MainTex("", 2D) = "" {}
	}
	SubShader
	{
		Pass
		{
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#include "UnityCG.cginc"
			//#include "TLPostProcess.cginc"
			#pragma vertex vert
			#pragma fragment frag_FXAA
			#define FXAA_GREEN_AS_LUMA 1

			#define FXAA_LOW 1
			#if FXAA_LOW
			#define FXAA_QUALITY__PRESET 12
			#define FXAA_QUALITY_SUBPIX 1.0
			#define FXAA_QUALITY_EDGE_THRESHOLD 0.166
			#define FXAA_QUALITY_EDGE_THRESHOLD_MIN 0.0625
			#else
			#define FXAA_QUALITY__PRESET 28
			#define FXAA_QUALITY_SUBPIX 1.0
			#define FXAA_QUALITY_EDGE_THRESHOLD 0.063
			#define FXAA_QUALITY_EDGE_THRESHOLD_MIN 0.0312
			#endif

			#include "FXAA3.cginc"
            #pragma exclude_renderers xbox360 ps3 flash d3d11_9x

			sampler2D _MainTex;
			float2 _MainTex_TexelSize;

			v2f_img vert(appdata_img v)
			{
				v2f_img o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy;

				return o;
			}
			half4 frag_FXAA(v2f_img i) : SV_Target
			{
				half4 color = 0.0;

				color = FxaaPixelShader(
					i.uv.xy, // pos
					0.0, // fxaaConsolePosPos (unused)
					_MainTex, // tex
					_MainTex, // fxaaConsole360TexExpBiasNegOne (unused)
					_MainTex, // fxaaConsole360TexExpBiasNegTwo (unused)
					_MainTex_TexelSize.xy, // fxaaQualityRcpFrame
					0.0, // fxaaConsoleRcpFrameOpt (unused)
					0.0, // fxaaConsoleRcpFrameOpt2 (unused)
					0.0, // fxaaConsole360RcpFrameOpt2 (unused)
					FXAA_QUALITY_SUBPIX,
					FXAA_QUALITY_EDGE_THRESHOLD,
					FXAA_QUALITY_EDGE_THRESHOLD_MIN,
					0.0, // fxaaConsoleEdgeSharpness (unused)
					0.0, // fxaaConsoleEdgeThreshold (unused)
					0.0, // fxaaConsoleEdgeThresholdMin (unused)
					0.0 // fxaaConsole360ConstDir (unused)
				);


				return color;
			}
			ENDCG
		}
	}
}
