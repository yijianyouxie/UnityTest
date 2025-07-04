// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_LightmapInd', a built-in variable
// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D
// Upgrade NOTE: replaced tex2D unity_LightmapInd with UNITY_SAMPLE_TEX2D_SAMPLER

Shader "TLStudio/Character/Hair" {
Properties {
	_ColorA("Color1",Color) = (1,1,1,1)
    _ColorB("Color2",Color) = (1,1,1,1)
    _RimColor("RimColor",Color) = (1,1,1,1)
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	 _Reflection ("Reflection", 2D) = "white" {}
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
	_ReflectionIntension("Reflection Intensity",Range(0,1)) = 0.5
}

SubShader {
	Tags {"Queue"="AlphaTest+150" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
	LOD 150
    Cull Off


	Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		ColorMask RGBA

CGPROGRAM
#pragma skip_variants DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN SHADOWS_SHADOWMASK VERTEXLIGHT_ON
// compile directives
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma multi_compile_fwdbase nodirlightmap 
#include "HLSLSupport.cginc"
#include "UnityShaderVariables.cginc"
#define UNITY_PASS_FORWARDBASE
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

#define INTERNAL_DATA
#define WorldReflectionVector(data,normal) data.worldRefl
#define WorldNormalVector(data,normal) normal

#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
#endif

//#pragma surface surf HairSpecular noforwardadd novertexlights alphatest:_Cutoff 

fixed4 _RimColor;
sampler2D  _Reflection;
fixed _ReflectionIntension;
 half4 LightingHairSpecular (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
{
        half3 h = normalize (lightDir + viewDir);
        half diff = max (0.2, dot (s.Normal, lightDir));
        float nh = max (0, dot (s.Normal, h));
        float rim = 1- max (0, dot (s.Normal,viewDir));
        half2 ReflUV =mul( UNITY_MATRIX_V, float4(s.Normal,0)).rg*0.5+0.5;
        fixed4 _Reflection_var = tex2D(_Reflection,ReflUV)*pow(s.Gloss,5);
        half4 c;
        c.rgb = (s.Albedo * _LightColor0.rgb * diff +_Reflection_var*_ReflectionIntension+_RimColor.rgb*rim*rim) * (atten*2 );
        c.a = s.Alpha;
        return c;
}
struct Input {
	float2 uv_MainTex;
};
sampler2D _MainTex;
fixed4 _ColorA;
fixed4 _ColorB;
void surf (Input IN, inout SurfaceOutput o) {
	fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
	o.Albedo =lerp(_ColorB,_ColorA,c.r)*c.g;
	o.Alpha = c.b;
	o.Gloss = c.g;
}

// vertex-to-fragment interpolation data
struct v2f_surf {
  float4 pos : SV_POSITION;
  float2 pack0 : TEXCOORD0;
  fixed3 normal : TEXCOORD1;
  fixed3 vlight : TEXCOORD2;
  float3 viewDir : TEXCOORD3;
  LIGHTING_COORDS(4,5)
};

float4 _MainTex_ST;

// vertex shader
v2f_surf vert_surf (appdata_full v) {
  v2f_surf o;
  o.pos = UnityObjectToClipPos (v.vertex);
  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
  float3 worldN = UnityObjectToWorldNormal(SCALED_NORMAL);// mul((float3x3)_Object2World, SCALED_NORMAL);
  o.normal = worldN;
  float3 viewDirForLight = WorldSpaceViewDir( v.vertex );
  o.viewDir = viewDirForLight;

  // SH/ambient and vertex lights
  o.vlight =ShadeSH9(float4(worldN * 1.0,1));

  // pass lighting information to pixel shader
  TRANSFER_VERTEX_TO_FRAGMENT(o);
  return o;
}

fixed _Cutoff;

// fragment shader
fixed4 frag_surf (v2f_surf IN) : SV_Target {
  // prepare and unpack data
  #ifdef UNITY_COMPILER_HLSL
  Input surfIN = (Input)0;
  #else
  Input surfIN;
  #endif
  surfIN.uv_MainTex = IN.pack0.xy;
  #ifdef UNITY_COMPILER_HLSL
  SurfaceOutput o = (SurfaceOutput)0;
  #else
  SurfaceOutput o;
  #endif
  o.Albedo = 0.0;
  o.Emission = 0.0;
  o.Specular = 0.0;
  o.Alpha = 0.0;
  o.Gloss = 0.0;

  o.Normal = IN.normal;


  // call surface function
  surf (surfIN, o);

  // alpha test
  clip (o.Alpha - _Cutoff);

  // compute lighting & shadowing factor
  fixed atten = LIGHT_ATTENUATION(IN);
  fixed4 c = 0;

  // realtime lighting: call lighting function

  c = LightingHairSpecular (o, _WorldSpaceLightPos0.xyz, normalize(half3(IN.viewDir)), atten);

  c.rgb += o.Albedo * IN.vlight;
  c.a = o.Alpha;
  return c;
}

ENDCG
}
}
}
