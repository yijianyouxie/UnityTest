// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Simplified Diffuse shader. Differences from regular Diffuse one:
// - no Main Color
// - fully supports only 1 directional light. Other lights can affect it, but it will be per-vertex/SH.

Shader "TLStudio/Weather/Opaque/TLS_Mobile-Diffuse-Weather" {
Properties {
	_Color("Color", Color) = (1,1,1,1)
	_MainTex ("Base (RGB)", 2D) = "white" {}
	_TintMask_SnowR_RainR("SnowMask in R Rain Mask in G", 2D) = "white" {}		
	_TintTex("TintTex if No Mask", 2D) = "white" {}
	_TintTexTiling("TintTex Tiling", Range(0.01, 50)) = 1 
	_TintPowerMaxRange("TintPowerMaxRange",Range(0,2)) = 2     
	_TintNormalEx("Change Color On Side",Range(-0.5,0.5)) = 0.05 
	_RainMaskPower("Rain Mask Power",Range(0.0,1.0)) = 0.5
	_NormalNoiseMap("RainDecalMap (RGB) ",2D) = "Black" {}
	_NormalNoiseSpeed("NormalNoiseSpeed",Range(0,1)) = 1
	_NormalNoiseTiling("NormalNoiseTiling",Range(0.1,10)) = 1
	_DecalPower("DecalPower",Range(0,2)) = 1
	_Decal2Tiling("Decal2Tiling",Range(1,2)) = 1.2
}
SubShader {
	Tags { "RenderType"="Opaque" }
	LOD 200


	// ------------------------------------------------------------
	// Surface shader code generated out of a CGPROGRAM block:
	

	// ---- forward rendering base pass:
	Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }

CGPROGRAM
#pragma skip_variants DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON VERTEXLIGHT_ON
// compile directives
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
//#pragma multi_compile GLOBALSH_DISABLE GLOBALSH_ENABLE
#pragma multi_compile FOG_EXP2 FOG_LINEAR
#pragma multi_compile_fwdbase
#include "HLSLSupport.cginc"
#include "UnityShaderVariables.cginc"

// -------- variant for: TINT_DISABLE RAIN_ENABLE 
//#if defined(TINT_DISABLE) && defined(RAIN_ENABLE) && !defined(RAIN_DISABLE) && !defined(TINT_ENABLE)
// Surface shader code generated based on:
// writes to per-pixel normal: no
// writes to emission: no
// needs world space reflection vector: no
// needs world space normal vector: YES
// needs screen space position: no
// needs world space position: YES
// needs view direction: no
// needs world space view direction: no
// needs world space position for lighting: YES
// needs world space view direction for lighting: no
// needs world space view direction for lightmaps: no
// needs vertex color: no
// needs VFACE: no
// passes tangent-to-world matrix to pixel shader: no
// reads from normal: no
// 1 texcoords actually used
//   float2 _MainTex
#define UNITY_PASS_FORWARDBASE
#include "Assets/TLS_Shaders/UnityCG.cginc"
#include "Assets/TLS_Shaders/CGIncludes/Lighting.cginc"
#include "Assets/TLS_Shaders/CGIncludes/AutoLight.cginc"

#define INTERNAL_DATA
#define WorldReflectionVector(data,normal) data.worldRefl
#define WorldNormalVector(data,normal) normal

// Original surface shader snippet:
#line 23 ""
#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
#endif

//#pragma surface surf Lambert noforwardadd

		#ifndef VAR_TINT_TEX 
		#define VAR_TINT_TEX
		#endif
		
		#include "../../TLS_Shaders/Weather/Include/TintColor.cginc"
		#include "../../TLS_Shaders/Weather/Include/NoiseAndDecal.cginc"
		#include "../../TLS_Shaders/Weather/Include/CommonCal.cginc"

		sampler2D _MainTex;
		fixed4 _Color;
		VAR_TINT_COLOR_NEED 
		VAR_NOISE_DECAL_NEED

struct Input {
	float2 uv_MainTex;
	float3 worldPos;
	float3 worldNormal;
};

void surf (Input IN, inout SurfaceOutput o) {
	fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
	
	if (TINT_ENABLE > 0)
	{
		TINT_TEX_MASKMAP_BASECOLOR_DOT_AUTO_UV(IN.worldPos, IN.worldNormal, IN.uv_MainTex, c.rgb)
	}
	
	if(RAIN_ENABLE > 0)
	{
		//DECAL_COLOR_WORLD_CENTER(IN.worldPos,IN.worldNormal,c.rgb)   
		DECAL_COLOR_MASKMAP_S_R_WORLD_CENTER(IN.worldPos,IN.worldNormal,IN.uv_MainTex,c.rgb)  
	}	
	
	o.Albedo = c.rgb*_Color.rgb;
	//o.Alpha = c.a*_Color.a;
}


// vertex-to-fragment interpolation data
// no lightmaps:
#ifdef LIGHTMAP_OFF
struct v2f_surf {
  float4 pos : SV_POSITION;
  float2 pack0 : TEXCOORD0; // _MainTex
  half3 worldNormal : TEXCOORD1;
  float3 worldPos : TEXCOORD2;
  #if UNITY_SHOULD_SAMPLE_SH
  half3 sh : TEXCOORD3; // SH
  #endif
  UNITY_SHADOW_COORDS(4)
  UNITY_FOG_COORDS(5)
  #if SHADER_TARGET >= 30
  float4 lmap : TEXCOORD6;
  #endif
  #ifdef GLOBALSH_ENABLE
  float3 vlighting : TEXCOORD7;
  #else
  #endif
};
#endif
// with lightmaps:
#ifndef LIGHTMAP_OFF
struct v2f_surf {
  float4 pos : SV_POSITION;
  float2 pack0 : TEXCOORD0; // _MainTex
  half3 worldNormal : TEXCOORD1;
  float3 worldPos : TEXCOORD2;
  float4 lmap : TEXCOORD3;
  UNITY_SHADOW_COORDS(4)
  UNITY_FOG_COORDS(5)
  #ifdef GLOBALSH_ENABLE
  float3 vlighting : TEXCOORD6;
  #else
  #endif
};
#endif
float4 _MainTex_ST;

// vertex shader
v2f_surf vert_surf (appdata_full v) {
  v2f_surf o;
  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
  o.pos = UnityObjectToClipPos (v.vertex);
  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
  fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
  o.worldPos = worldPos;
  o.worldNormal = worldNormal;
  #ifndef DYNAMICLIGHTMAP_OFF
  o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
  #endif
  #ifndef LIGHTMAP_OFF
  o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
  #endif

  // SH/ambient and vertex lights
  #ifdef LIGHTMAP_OFF
    #if UNITY_SHOULD_SAMPLE_SH
      o.sh = 0;
      // Approximated illumination from non-important point lights
      #ifdef VERTEXLIGHT_ON
        o.sh += Shade4PointLights (
          unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
          unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
          unity_4LightAtten0, worldPos, worldNormal);
      #endif
      o.sh = ShadeSHPerVertex (worldNormal, o.sh);
    #endif
  #endif // LIGHTMAP_OFF
  #ifdef GLOBALSH_ENABLE
	o.vlighting = ShadeSH9 (float4(o.worldNormal, 1.0));
  #endif
	UNITY_TRANSFER_SHADOW(o, v.texcoord1); // pass shadow coordinates to pixel shader
  if(UseHeightFog > 0)
  {
  	TL_TRANSFER_FOG(o,o.pos, v.vertex);
  }else
  {
	  UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader  
  }
  return o;
}

// fragment shader
fixed4 frag_surf (v2f_surf IN) : SV_Target {
  // prepare and unpack data
  Input surfIN;
  UNITY_INITIALIZE_OUTPUT(Input,surfIN);
  surfIN.uv_MainTex.x = 1.0;
  surfIN.worldPos.x = 1.0;
  surfIN.worldNormal.x = 1.0;
  surfIN.uv_MainTex = IN.pack0.xy;
  float3 worldPos = IN.worldPos;
  #ifndef USING_DIRECTIONAL_LIGHT
    fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
  #else
    fixed3 lightDir = _WorldSpaceLightPos0.xyz;
  #endif
  surfIN.worldNormal = IN.worldNormal;
  surfIN.worldPos = worldPos;
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
  fixed3 normalWorldVertex = fixed3(0,0,1);
  o.Normal = IN.worldNormal;
  normalWorldVertex = IN.worldNormal;

  // call surface function
  surf (surfIN, o);

  // compute lighting & shadowing factor
  UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
  fixed4 c = 0;

  // Setup lighting environment
  UnityGI gi;
  UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
  gi.indirect.diffuse = 0;
  gi.indirect.specular = 0;
  #if !defined(LIGHTMAP_ON)
      gi.light.color = _LightColor0.rgb;
      gi.light.dir = lightDir;
      gi.light.ndotl = LambertTerm (o.Normal, gi.light.dir);
  #endif
  // Call GI (lightmaps/SH/reflections) lighting function
  UnityGIInput giInput;
  UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
  giInput.light = gi.light;
  giInput.worldPos = worldPos;
  giInput.atten = atten;
  #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
    giInput.lightmapUV = IN.lmap;
  #else
    giInput.lightmapUV = 0.0;
  #endif
  #if UNITY_SHOULD_SAMPLE_SH && LIGHTMAP_OFF
    giInput.ambient = IN.sh;
  #else
    giInput.ambient.rgb = 0.0;
  #endif
  giInput.probeHDR[0] = unity_SpecCube0_HDR;
  giInput.probeHDR[1] = unity_SpecCube1_HDR;
  #if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
    giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
  #endif
  #if UNITY_SPECCUBE_BOX_PROJECTION
    giInput.boxMax[0] = unity_SpecCube0_BoxMax;
    giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
    giInput.boxMax[1] = unity_SpecCube1_BoxMax;
    giInput.boxMin[1] = unity_SpecCube1_BoxMin;
    giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
  #endif
  LightingLambert_GI(o, giInput, gi);

  // realtime lighting: call lighting function
  c += LightingLambert (o, gi);
  #ifdef GLOBALSH_ENABLE
  c.xyz = c.xyz*max(fixed3(1.0,1.0,1.0),(IN.vlighting - UNITY_LIGHTMODEL_AMBIENT.xyz)*2);
  #endif
  if(UseHeightFog > 0)
  {
  	TL_APPLY_FOG(IN.fogCoord, c.rgb);
  }else
  {
	  UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog  
  }
  UNITY_OPAQUE_ALPHA(c.a);
  return c;
}


//#endif

ENDCG

}
	// ---- end of surface shader generated code

#LINE 69

 
}

Fallback "TLStudio/Opaque/UnLit"
}
