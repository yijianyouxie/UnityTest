// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "CYShaders/Skybox/6 Sided" {
Properties {
    _Tint ("Tint Color", Color) = (.5, .5, .5, .5)
    [Gamma] _Exposure ("Exposure", Range(0, 8)) = 1.0
    _Rotation ("Rotation", Range(0, 360)) = 0
    [NoScaleOffset] _FrontTex ("Front [+Z]   (HDR)", 2D) = "grey" {}
    [NoScaleOffset] _BackTex ("Back [-Z]   (HDR)", 2D) = "grey" {}
    [NoScaleOffset] _LeftTex ("Left [+X]   (HDR)", 2D) = "grey" {}
    [NoScaleOffset] _RightTex ("Right [-X]   (HDR)", 2D) = "grey" {}
    [NoScaleOffset] _UpTex ("Up [+Y]   (HDR)", 2D) = "grey" {}
    [NoScaleOffset] _DownTex ("Down [-Y]   (HDR)", 2D) = "grey" {}

	_FogParamZ("FogFactor", Range(0,1)) = 0.67
	_SkyWeight("SkyWeight", Range(0,1)) = 0.5
	_DragSkyDownSpeed("Drag Sky Down", Range(0,0.1)) = 0.00125
	_HorizonHeight("Horizon Height", Float) = 0
}

SubShader {
    Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
    Cull Off ZWrite Off

    CGINCLUDE
    #include "UnityCG.cginc"

    half4 _Tint;
    half _Exposure;
    float _Rotation;
	float _DragSkyDownSpeed;
	float _HorizonHeight;
#ifdef CY_FOG_ON
	float _FogParamZ;
	float _SkyWeight;

	float4 FogInfo2;

	float4 FogColor;
	float4 FogColor2;
	float4 FogColor3;
#endif

    float3 RotateAroundYInDegrees (float3 vertex, float degrees)
    {
        float alpha = degrees * UNITY_PI / 180.0;
        float sina, cosa;
        sincos(alpha, sina, cosa);
        float2x2 m = float2x2(cosa, -sina, sina, cosa);
        return float3(mul(m, vertex.xz), vertex.y).xzy;
    }

    struct appdata_t {
        float4 vertex : POSITION;
        float2 texcoord : TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };
    struct v2f {
        float4 vertex : SV_POSITION;
        float2 texcoord : TEXCOORD0;
#ifdef CY_FOG_ON
		float4 disValue : TEXCOORD4;
#endif
        UNITY_VERTEX_OUTPUT_STEREO
    };
    v2f vert (appdata_t v)
    {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        float3 rotated = RotateAroundYInDegrees(v.vertex, _Rotation);
		rotated.y -= _DragSkyDownSpeed * (_WorldSpaceCameraPos.y - _HorizonHeight);
#ifdef CY_FOG_ON
		float3 posWorld = mul(unity_ObjectToWorld, rotated);
		o.disValue.xyz = posWorld - _WorldSpaceCameraPos.xyz;
#endif
        o.vertex = UnityObjectToClipPos(rotated);
        o.texcoord = v.texcoord;
        return o;
    }
    half4 skybox_frag (v2f i, sampler2D smp, half4 smpDecode)
    {
        half4 tex = tex2D (smp, i.texcoord);
        half3 c = DecodeHDR (tex, smpDecode);
        c = c * _Tint.rgb * unity_ColorSpaceDouble.rgb;
        c *= _Exposure;

#ifdef CY_FOG_ON
		float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
		float3 tmpvar_4;
		tmpvar_4 = normalize(-(i.disValue.xyz));

		float tmpvar_9;
		tmpvar_9 = clamp((smpDecode.y - _FogParamZ), 0.0, 1.0);
		float tmpvar_10;
		tmpvar_10 = clamp(tmpvar_9 * tmpvar_9, 0.0, 1.0);
		float tmpvar_11;
		tmpvar_11 = clamp(dot(-tmpvar_4, lightDirection.xyz), 0.0, 1.0);
		float3 finalC = c.xyz;
		c.xyz = lerp(c.xyz, (((c.xyz * (1.0 - tmpvar_10)) + FogColor.xyz) + (((tmpvar_11 * tmpvar_11) * FogColor3).xyz + (FogColor2.xyz * clamp(((tmpvar_4.y * 5.0) + 1.0), 0.0, 1.0)))), tmpvar_10);

		c.xyz = c.xyz * float3(FogColor.w, FogColor2.w, FogColor3.w);
		c.xyz = ((c.xyz / (c.xyz + 0.187)) * 1.035);
		c.xyz = lerp(finalC, c.xyz, FogInfo2.x*_SkyWeight);
#endif
        return half4(c, 1);
    }
    ENDCG

    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 2.0
		#pragma multi_compile __ CY_FOG_ON
        sampler2D _FrontTex;
        half4 _FrontTex_HDR;
        half4 frag (v2f i) : SV_Target { return skybox_frag(i,_FrontTex, _FrontTex_HDR); }
        ENDCG
    }
    Pass{
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 2.0
		#pragma multi_compile __ CY_FOG_ON
        sampler2D _BackTex;
        half4 _BackTex_HDR;
        half4 frag (v2f i) : SV_Target { return skybox_frag(i,_BackTex, _BackTex_HDR); }
        ENDCG
    }
    Pass{
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 2.0
		#pragma multi_compile __ CY_FOG_ON
        sampler2D _LeftTex;
        half4 _LeftTex_HDR;
        half4 frag (v2f i) : SV_Target { return skybox_frag(i,_LeftTex, _LeftTex_HDR); }
        ENDCG
    }
    Pass{
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 2.0
		#pragma multi_compile __ CY_FOG_ON
        sampler2D _RightTex;
        half4 _RightTex_HDR;
        half4 frag (v2f i) : SV_Target { return skybox_frag(i,_RightTex, _RightTex_HDR); }
        ENDCG
    }
    Pass{
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 2.0
		#pragma multi_compile __ CY_FOG_ON
        sampler2D _UpTex;
        half4 _UpTex_HDR;
        half4 frag (v2f i) : SV_Target { return skybox_frag(i,_UpTex, _UpTex_HDR); }
        ENDCG
    }
    Pass{
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 2.0
		#pragma multi_compile __ CY_FOG_ON
        sampler2D _DownTex;
        half4 _DownTex_HDR;
        half4 frag (v2f i) : SV_Target { return skybox_frag(i,_DownTex, _DownTex_HDR); }
        ENDCG
    }
}
}
