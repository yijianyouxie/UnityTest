// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "CYShaders/Legacy Shaders/Transparent/Cutout/Diffuse" {
Properties {
    _Color ("Main Color", Color) = (1,1,1,1)
    _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
    _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
}

SubShader {
    Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
    LOD 200

CGPROGRAM
#pragma surface surf Lambert alphatest:_Cutoff vertex:vert_custom finalcolor:finalcustomcolor
#pragma multi_compile_fog
#pragma multi_compile __ CY_FOG_ON

sampler2D _MainTex;
fixed4 _Color;

#ifdef CY_FOG_ON
float4 FogInfo;
float4 FogColor;
float4 FogColor2;
float4 FogColor3;
float4 FogInfo2;
#endif

struct Input {
    float2 uv_MainTex;
	UNITY_FOG_COORDS(2)

	UNITY_CY_FOG_COORDS(3)
};

void vert_custom(inout appdata_full v, out Input o) {
	UNITY_INITIALIZE_OUTPUT(Input, o);

	float4 oPos = UnityObjectToClipPos(v.vertex);
	UNITY_TRANSFER_FOG(o, oPos);

	float4 posW = mul(unity_ObjectToWorld, v.vertex);
	float3 dis = posW.xyz - _WorldSpaceCameraPos;
	UNITY_TRANSFER_CY_FOG(o, dis.xyz, posW.y);
}

void surf (Input IN, inout SurfaceOutput o) {
    fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
    o.Albedo = c.rgb;
    o.Alpha = c.a;
}

void finalcustomcolor(Input IN, SurfaceOutput o, inout fixed4 color)
{
	UNITY_APPLY_FOG(IN.fogCoord, color);

	UNITY_APPLY_CY_FOG(IN.cyFogCoord, color);

}


ENDCG
}

Fallback "Legacy Shaders/Transparent/Cutout/VertexLit"
}
