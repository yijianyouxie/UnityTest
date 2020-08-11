 // Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "TLStudio/CharMRAOCutout_01" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Normal("Normal", 2D) = "white" {}
		_Metallic("Metallic", 2D) = "white" {}
		_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
		//_SSSWarp("SSS Warp", Range(0,1)) = 1
		//_SSSScatter("SSS Scatter", Range(0,1)) = 1
		//_SSSScatterColor("SSS Scatter Color", Color) = (1,1,1,1)
		_Occlusion("Occlusion",Range(0,1)) = 1
		_MetallicStrength("MetallicStrength",Range(0,2)) = 1
		_SmoothnessStrength("SmoothnessStrength",Range(0,2)) = 1
	}
	SubShader{
		Tags{ "RenderType" = "Cutout" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows alphatest:_Cutoff vertex:vert_custom finalcolor:finalcustomcolor
		//#include "CYUnityCG.cginc"
		#pragma multi_compile __ _DYNAMIC_LIGHTMAP_EFFECT
		#pragma multi_compile __ CY_FOG_ON
		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0


		struct Input {
		float2 uv_MainTex;
		float3 worldViewDir;
		float3 worldNormal; INTERNAL_DATA
		UNITY_CY_FOG_COORDS(4)
	};

	sampler2D _MainTex;
	sampler2D _Metallic;
	sampler2D _Normal;
	fixed4 _Color;
	float _Occlusion;
	float _MetallicStrength;
	float _SmoothnessStrength;
	
#ifdef CY_FOG_ON
	float4 FogInfo;
	float4 FogColor;
	float4 FogColor2;
	float4 FogColor3;
	float4 FogInfo2;
#endif

	//float _SSSWarp;
	//float _SSSScatter;
	//float3 _SSSScatterColor;

	void vert_custom(inout appdata_full v, out Input o) {
		UNITY_INITIALIZE_OUTPUT(Input, o);

		float4 posW = mul(unity_ObjectToWorld, v.vertex);
		float3 dis = posW.xyz - _WorldSpaceCameraPos;
		UNITY_TRANSFER_CY_FOG(o, dis.xyz, posW.y);
	}

	// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
	// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
	// #pragma instancing_options assumeuniformscaling
	UNITY_INSTANCING_BUFFER_START(Props)
		// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf(Input IN, inout SurfaceOutputStandard o) {
		// Albedo comes from a texture tinted by color
		fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
		o.Albedo = c.rgb;
		// Metallic and smoothness come from slider variables
		fixed4 metallic_roughness = tex2D(_Metallic, IN.uv_MainTex);
		o.Metallic = metallic_roughness.g*_MetallicStrength;
		o.Smoothness = metallic_roughness.r*_SmoothnessStrength;
		o.Alpha = c.a;
		o.Occlusion = metallic_roughness.b * _Occlusion;
		float4 normalpacked = tex2D(_Normal, IN.uv_MainTex);
		float3 normal;
		normal.xy = normalpacked.wy*2.0 - 1.0;
		normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
		//o.Normal = normal;
		o.Normal = normalpacked.rgb*2.0 - 1.0;
		//float3 worldnormal = WorldNormalVector(IN, o.Normal);
		//float A = (saturate(dot(IN.worldViewDir, worldnormal)) + _SSSWarp) / (1.0 + _SSSWarp);
		//float B = A / (_SSSScatter + 0.001);
		//float3 SSS_Color = _SSSScatterColor*B*B*(3 - 2 * B)*lerp(_SSSScatter * 2, _SSSScatter, A);
		//o.Emission = saturate(SSS_Color)*c.rgb*metallic_roughness.b;
		//o.Albedo = c.rgb+ saturate(SSS_Color)*c.rgb;
		
	}

void finalcustomcolor(Input IN, SurfaceOutputStandard o, inout fixed4 color)
{
	UNITY_APPLY_CY_FOG(IN.cyFogCoord, color);
}

	ENDCG
	}
	FallBack "Diffuse"
}
