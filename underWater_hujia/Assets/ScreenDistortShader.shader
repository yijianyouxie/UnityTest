Shader "Hidden/ScreenDistortEffect"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_NoiseTex("Base (RGB)", 2D) = "black" {}
	}
 
	CGINCLUDE
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	sampler2D _NoiseTex;
	float _DistortTimeFactor;
	float _DistortStrength;
 
	fixed4 frag(v2f_img i) : SV_Target
	{
		float4 noise = tex2D(_NoiseTex, i.uv - _Time.xy * _DistortTimeFactor);
		float2 offset = noise.xy * _DistortStrength;
		float2 uv = offset + i.uv;
		return tex2D(_MainTex, uv);
	}
 
	ENDCG
 
	SubShader
	{
		Pass
		{
			ZTest Always
			Cull Off
			ZWrite Off
			Fog{ Mode off }
 
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest 
			ENDCG
		}
	}
	Fallback off
}
