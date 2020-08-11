Shader "Custom/DepthTest" {
 
	CGINCLUDE
	#include "UnityCG.cginc"
 
	//��ȻҪ����һ��_CameraDepthTexture�����������ȻUnity���������unity�ڲ���ֵ
	sampler2D _CameraDepthTexture;
	sampler2D _MainTex;
	float4	  _MainTex_TexelSize;
 
	struct v2f
	{
		float4 pos : SV_POSITION;
		float2 uv  : TEXCOORD0;
	};
 
	v2f vert(appdata_img v)
	{
		v2f o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv.xy = v.texcoord.xy;
 
		return o;
	}
 
	fixed4 frag(v2f i) : SV_Target
	{
		//ֱ�Ӹ���UV����ȡ�õ�����ֵ
		float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, 1 - i.uv);
		//�����ֵ��Ϊ����01�ռ�
		depth = Linear01Depth(depth);
		return float4(depth, depth, depth, 1);
	}
 
	ENDCG
 
	SubShader
	{
		Pass
		{
 
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }
 
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
 
	}
}
