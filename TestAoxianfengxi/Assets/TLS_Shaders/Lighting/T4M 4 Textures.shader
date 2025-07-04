// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable
// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

Shader "TLStudio/Lighting/T4MShaders/ShaderModel2/Diffuse/T4M 4 Textures"
{
	Properties
	{
		_SpecColor("地表反射光颜色", Color) = (0.4862, 0.4049, 0.2822, 0)

		_HaveAlphaL0("层1-是否开启反射，(只可填0或1，其中0代表不反射，1代表反射)", Int) = 0
		_ShininessL0("层1-反射强度", Range(0.03, 1)) = 0.078125
		_Splat0("层1-纹理贴图", 2D) = "white" {}

		_HaveAlphaL1("层2-是否开启反射，(只可填0或1，其中0代表不反射，1代表反射)", Int) = 0
		_ShininessL1("层2-反射强度", Range(0.03, 1)) = 0.078125
		_Splat1("层2-纹理贴图", 2D) = "white" {}

		_HaveAlphaL2("层3-是否开启反射，(只可填0或1，其中0代表不反射，1代表反射)", Int) = 0
		_ShininessL2("层3-反射强度", Range(0.03, 1)) = 0.078125
		_Splat2("层3-纹理贴图", 2D) = "white" {}

		_HaveAlphaL3("层4-是否开启反射，(只可填0或1，其中0代表不反射，1代表反射)", Int) = 0
		_ShininessL3("层4-反射强度", Range(0.03, 1)) = 0.078125
		_Splat3("层4-纹理贴图", 2D) = "white" {}

		_Control("层5-控制贴图", 2D) = "white" {}

		_LightPos("光源位置", Vector) = (100,100,100,100)
		
		_MinIntensity("MinIntensity", Range (0.5, 5)) = 0.5
	}
		SubShader
	{
		Tags
	{
		"Queue" = "Geometry+500"
		"SplatCount" = "4"
		"RenderType" = "Opaque"
	}
		Pass
	{
		Name "ForwardBase"
		Tags
	{
		"LightMode" = "ForwardBase"
	}
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile FOG_EXP2 FOG_LINEAR
		#include "Assets/TLS_Shaders/UnityCG.cginc"
		#include "AutoLight.cginc"
		#include "Lighting.cginc"
		#pragma multi_compile_fwdbase_fullshadows
		#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
		uniform sampler2D _Splat0; uniform half4 _Splat0_ST;
		uniform sampler2D _Splat1; uniform half4 _Splat1_ST;
		uniform sampler2D _Splat2; uniform half4 _Splat2_ST;
		uniform sampler2D _Splat3; uniform half4 _Splat3_ST;
		// uniform sampler2D unity_Lightmap; // uniform float4 unity_LightmapST;
		uniform sampler2D _Control; uniform half4 _Control_ST;

		uniform fixed _ShininessL0;
		uniform fixed _ShininessL1;
		uniform fixed _ShininessL2;
		uniform fixed _ShininessL3;

		uniform fixed _HaveAlphaL0;
		uniform fixed _HaveAlphaL1;
		uniform fixed _HaveAlphaL2;
		uniform fixed _HaveAlphaL3;

		uniform float4 _LightPos;
		fixed  _MinIntensity;

		struct VertexInput {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			half2 texcoord0 : TEXCOORD0;
			half2 texcoord1 : TEXCOORD1;
		};
		struct VertexOutput {
			float4 pos : SV_POSITION;
			half2 uv0 : TEXCOORD0;
			//fixed3 lightDirection1 : TEXCOORD1;//xyz: lightDirection; w: attenuation
			half2 uv1 : TEXCOORD1;
			half2 uv2 : TEXCOORD2;
			half2 uv3 : TEXCOORD3;
			half2 uv4 : TEXCOORD4;
			float4 worldpos : TEXCOORD7;
			float4 normalDir : TEXCOORD8;
			LIGHTING_COORDS(5,6)
			UNITY_FOG_COORDS(9)
		};
	VertexOutput vert(VertexInput v) {
		VertexOutput o = (VertexOutput)0;
		o.uv0 = TRANSFORM_TEX(v.texcoord0, _Splat0);
		o.uv1 = TRANSFORM_TEX(v.texcoord0, _Splat1);
		o.uv2 = TRANSFORM_TEX(v.texcoord0, _Splat2);
		o.uv3 = TRANSFORM_TEX(v.texcoord0, _Splat3);
		o.uv4 = TRANSFORM_TEX(v.texcoord0, _Control);
		o.normalDir.xyz = v.normal;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.worldpos.xyz = mul(unity_ObjectToWorld, v.vertex);
		fixed3 lightColor = _LightColor0.rgb;
		TRANSFER_VERTEX_TO_FRAGMENT(o)
		if(UseHeightFog > 0)
		{
			TL_TRANSFER_FOG(o,o.pos, v.vertex);
		}else
		{
			UNITY_TRANSFER_FOG(o,o.pos);		
		}
		return o;
	}
	fixed4 frag(VertexOutput i) : COLOR
	{
		fixed3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.worldpos.xyz);
		fixed3 normalDirection = normalize(i.normalDir.xyz);
		fixed3 lightDirection1 = normalize(_LightPos.xyz);
		fixed3 halfDirection = normalize(viewDirection + lightDirection1.xyz);
		fixed attenuation = LIGHT_ATTENUATION(i);

		fixed3 lightDirection = normalize(_LightPos.xyz);
		fixed3 attenColor = attenuation * _LightColor0.xyz;
		fixed3 lightColor = _LightColor0.rgb;
		fixed NdotL = 0.5*dot(normalDirection, lightDirection)+_MinIntensity;
		fixed3 directDiffuse = max(0.0, NdotL) * attenColor;

		fixed4 _Control_var = tex2D(_Control,i.uv4);
		fixed4 _Splat0_var = tex2D(_Splat0,i.uv0);
		fixed4 _Splat1_var = tex2D(_Splat1,i.uv1);
		fixed4 _Splat2_var = tex2D(_Splat2,i.uv2);
		fixed4 _Splat3_var = tex2D(_Splat3,i.uv3);
		fixed3 f_c = ((_Control_var.r*_Splat0_var.rgb) + (_Control_var.g*_Splat1_var.rgb) + (_Control_var.b*_Splat2_var.rgb) + (_Control_var.a*_Splat3_var.rgb));
		fixed f_g = (_HaveAlphaL0 * _Control_var.r * _Splat0_var.a) + (_HaveAlphaL1 * _Control_var.g * _Splat1_var.a) + (_HaveAlphaL2 * _Control_var.b * _Splat2_var.a) + (_HaveAlphaL3 * _Control_var.a * _Splat3_var.a);
		fixed f_s = _ShininessL0 * _Control_var.r + _ShininessL1 * _Control_var.g + _ShininessL2 * _Control_var.b + _ShininessL3 * _Control_var.a;
		fixed nh = max(0, dot(halfDirection, normalDirection));
		fixed spec = max(0, pow(nh, f_s * 128)) * f_g;
		fixed3 fs = ((f_c * _SpecColor.w) + (_SpecColor.xyz * spec)) * 2.0;
		fixed3 fc = fs + (f_c * directDiffuse);
		if(UseHeightFog > 0)
		{
			TL_APPLY_FOG(i.fogCoord, fc.rgb);
		}else
		{
			UNITY_APPLY_FOG(i.fogCoord, fc); // apply fog		
		}
										 //UNITY_APPLY_FOG_COLOR(i.fogCoord, fc, fixed4(0,0,0,0)); //custom fog color
		return fixed4(fc,1);
	}
		ENDCG
	}
	}
}

