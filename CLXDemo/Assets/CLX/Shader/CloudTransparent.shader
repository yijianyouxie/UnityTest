Shader "CLX/CloudAdditive"
{
	Properties 
	{
		_CloudLayerTex ("CloudLayerTexture", 2D) = "white" {}
		_BlendFactor("SkyCloudBlendFactor", Float) = 0.5
	}

	CGINCLUDE

	#include "UnityCG.cginc"
	#include "Lighting.cginc"
				#include "CYUnityCG.cginc"
				#pragma multi_compile_fog
				#pragma multi_compile __ CY_FOG_ON

	struct v2f_hdr 
	{
		float4 Position:SV_Position;
		float2 mapTC:TEXCOORD0;
		UNITY_FOG_COORDS(1)
				CY_FOG_COORDS(2)
	};

	sampler2D _CloudLayerTex;

	v2f_hdr vert( appdata_img v ) 
	{
		 v2f_hdr OUT;
		 (OUT)=((v2f_hdr)0);
		 
		 OUT.Position = UnityObjectToClipPos(v.vertex.xyz);
		 
		OUT.mapTC.xy = v.texcoord.xy;

		float4 worldPos = float4(mul(unity_ObjectToWorld, v.vertex).xyz,1);
		float3 dis = worldPos.xyz - _WorldSpaceCameraPos;
			CY_TRANSFER_FOG(OUT, dis.xyz, worldPos.y);
			UNITY_TRANSFER_FOG(OUT, OUT.Position);

		 return OUT;
	}

	float _BlendFactor;

	float4 fragSkyPS(v2f_hdr IN) : SV_Target
	{
		float4 OUT = float4(tex2D(_CloudLayerTex, IN.mapTC).xyz, _BlendFactor);
		UNITY_APPLY_FOG(IN.fogCoord, OUT);
		CY_APPLY_FOG(IN.cyFogCoord, OUT);

		return OUT;
	}

	ENDCG

	SubShader
	{
		LOD 200
		Tags{ "Queue" = "Transparent" }
		ZWrite Off
		Blend  SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			  #pragma vertex vert
			  #pragma fragment fragSkyPS
			  ENDCG
		}
	}

	Fallback off
}


