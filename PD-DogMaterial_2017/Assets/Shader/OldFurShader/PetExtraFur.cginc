// Upgrade NOTE: replaced 'defined ENABLECLOTHFURCONTROLTEX' with 'defined (ENABLECLOTHFURCONTROLTEX)'

		

// -------- variant for: <when no other keywords are defined>
#if !defined(INSTANCING_ON)
// Surface shader code generated based on:
// vertex modifier: 'vert'
// writes to per-pixel normal: no
// writes to emission: YES
// writes to occlusion: no
// needs world space reflection vector: no
// needs world space normal vector: no
// needs screen space position: no
// needs world space position: no
// needs view direction: YES
// needs world space view direction: no
// needs world space position for lighting: YES
// needs world space view direction for lighting: YES
// needs world space view direction for lightmaps: no
// needs vertex color: no
// needs VFACE: no
// passes tangent-to-world matrix to pixel shader: no
// reads from normal: YES
// 1 texcoords actually used
//   float2 _MainTex
#ifndef UNITY_PASS_FORWARDBASE
#define UNITY_PASS_FORWARDBASE
#endif
#define _ALPHABLEND_ON 1
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

#define INTERNAL_DATA
#define WorldReflectionVector(data,normal) data.worldRefl
#define WorldNormalVector(data,normal) normal

// Original surface shader snippet:
#line 55 ""
#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
#endif
/* UNITY: Original start of shader */
		//#pragma surface surf StandardSpecular fullforwardshadows alpha:blend vertex:vert
		//#pragma target 3.0

 		#include "ImperialFurSpecular.cginc"
		

// vertex-to-fragment interpolation data
// no lightmaps:
#ifndef LIGHTMAP_ON
struct v2f_surf {
  UNITY_POSITION(pos);
  float4 pack0 : TEXCOORD0; // _MainTex
  half3 worldNormal : TEXCOORD1;
  float3 worldPos : TEXCOORD2;
  half custompack0 : TEXCOORD3; // alpha
  #if UNITY_SHOULD_SAMPLE_SH
  half3 sh : TEXCOORD4; // SH
  #endif
  UNITY_FOG_COORDS(5)
  #if SHADER_TARGET >= 30
  float4 lmap : TEXCOORD6;
  #endif
  float4 pack1: TEXCOORD9;
  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
#ifdef ENABLECLOTHFURCONTROLTEX
  // mask begin
  float4 projPos : TEXCOORD10;
#endif
  // mask end
};
#endif
// with lightmaps:
#ifdef LIGHTMAP_ON
struct v2f_surf {
  UNITY_POSITION(pos);
  float4 pack0 : TEXCOORD0; // _MainTex
  half3 worldNormal : TEXCOORD1;
  float3 worldPos : TEXCOORD2;
  half custompack0 : TEXCOORD3; // alpha
  float4 lmap : TEXCOORD4;
  UNITY_FOG_COORDS(5)
  #ifdef DIRLIGHTMAP_COMBINED
  fixed3 tSpace0 : TEXCOORD6;
  fixed3 tSpace1 : TEXCOORD7;
  fixed3 tSpace2 : TEXCOORD8;
  #endif
  float4 pack1: TEXCOORD9;
  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
#ifdef ENABLECLOTHFURCONTROLTEX
  // mask begin
  float4 projPos : TEXCOORD10;
  // mask end
#endif
};
#endif
float4 _MainTex_ST;

// vertex shader
v2f_surf vert_surf (appdata_full v) {
  UNITY_SETUP_INSTANCE_ID(v);
  v2f_surf o;
  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
  UNITY_TRANSFER_INSTANCE_ID(v,o);
  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
  Input customInputData;
  
  vert (v, customInputData);
  o.custompack0.x = customInputData.alpha;
  v.vertex.xyz += v.normal * v.color.x * _ExtraControl.x * 0.1f;
  o.pos = UnityObjectToClipPos(v.vertex);
  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
  
  o.pack1.xy = v.texcoord1.xy;
  o.pack1.zw = v.texcoord2.xy;
  
  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
  fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
  #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
  fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
  fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
  fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
  #endif
  #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
  o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
  o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
  o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
  #endif
  o.worldPos = worldPos;
  o.worldNormal = worldNormal;
  #ifdef DYNAMICLIGHTMAP_ON
  o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
  #endif
  #ifdef LIGHTMAP_ON
  o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
  #endif

  // SH/ambient and vertex lights
  #ifndef LIGHTMAP_ON
    #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
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
  #endif // !LIGHTMAP_ON

  UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
  return o;
}

// fragment shader
fixed4 frag_surf (v2f_surf IN) : SV_Target {
  UNITY_SETUP_INSTANCE_ID(IN);
  // prepare and unpack data
  Input surfIN;
  UNITY_INITIALIZE_OUTPUT(Input,surfIN);
  surfIN.alpha.x = 1.0;
  surfIN.uv_MainTex.x = 1.0;
  surfIN.worldRefl.x = 1.0;
  surfIN.viewDir.x = 1.0;
  surfIN.uv_MainTex = IN.pack0.xy;
  surfIN.uv_MainTex1.xyz = IN.pack1.xyz;
  surfIN.alpha = IN.custompack0.x;
  float3 worldPos = IN.worldPos;
  #ifndef USING_DIRECTIONAL_LIGHT
    fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
  #else
    fixed3 lightDir = _WorldSpaceLightPos0.xyz;
  #endif
  fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
  fixed3 viewDir = worldViewDir;
  surfIN.viewDir = viewDir;
  #ifdef UNITY_COMPILER_HLSL
  SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
  #else
  SurfaceOutputStandardSpecular o;
  #endif
  o.Albedo = 0.0;
  o.Emission = 0.0;
  o.Specular = 0.0;
  o.Alpha = 0.0;
  o.Occlusion = 1.0;
  fixed3 normalWorldVertex = fixed3(0,0,1);
  o.Normal = IN.worldNormal;
  normalWorldVertex = IN.worldNormal;

  // call surface function
  surf (surfIN, o);

  //fixed4 cc = fixed4(o.Albedo,1);
  //cc  = Dissolve(cc, surfIN);
  //o.Albedo = cc.xyz;
  //ColorMaskMudule(surfIN, o);
  
  // compute lighting & shadowing factor
  UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
  fixed4 c = 0;

  // Setup lighting environment
  UnityGI gi;
  UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
  gi.indirect.diffuse = 0;
  gi.indirect.specular = 0;
  gi.light.color = _LightColor0.rgb;
  gi.light.dir = lightDir;
  // Call GI (lightmaps/SH/reflections) lighting function
  UnityGIInput giInput;
  UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
  giInput.light = gi.light;
  giInput.worldPos = worldPos;
  giInput.worldViewDir = worldViewDir;
  giInput.atten = atten;
  #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
    giInput.lightmapUV = IN.lmap;
  #else
    giInput.lightmapUV = 0.0;
  #endif
  #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
    giInput.ambient = IN.sh;
  #else
    giInput.ambient.rgb = 0.0;
  #endif
  giInput.probeHDR[0] = unity_SpecCube0_HDR;
  giInput.probeHDR[1] = unity_SpecCube1_HDR;
  #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
    giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
  #endif
  #ifdef UNITY_SPECCUBE_BOX_PROJECTION
    giInput.boxMax[0] = unity_SpecCube0_BoxMax;
    giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
    giInput.boxMax[1] = unity_SpecCube1_BoxMax;
    giInput.boxMin[1] = unity_SpecCube1_BoxMin;
    giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
  #endif
  LightingStandardSpecular_GI(o, giInput, gi);

  // realtime lighting: call lighting function
  c += LightingStandardSpecular (o, worldViewDir, gi);
  c.rgb += o.Emission;
  
	c  = Dissolve(c, surfIN);
				
  UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog
  return c;
}

////////////////// Simplified Begin! ////////////////////

// vertex shader
v2f_surf vert_surf_simplified (appdata_full v) {
  UNITY_SETUP_INSTANCE_ID(v);
  v2f_surf o;
  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
  UNITY_TRANSFER_INSTANCE_ID(v,o);
  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
  Input customInputData;
  
  v.vertex.xyz += v.normal * v.color.x * _ExtraControl.x * 0.1f;

  vert (v, customInputData);
  o.custompack0.x = customInputData.alpha;
  
  o.pos = UnityObjectToClipPos(v.vertex);
#ifdef ENABLECLOTHFURCONTROLTEX  
  o.projPos = ComputeScreenPos (o.pos);
  COMPUTE_EYEDEPTH(o.projPos.z);
#endif
  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
  
  o.pack1.xy = v.texcoord1.xy;
  o.pack1.zw = v.texcoord2.xy;
  
  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
  fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
  #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
  fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
  fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
  fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
  #endif
  // #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
  // o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
  // o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
  // o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
  // #endif
  o.worldPos = worldPos;
  o.worldNormal = worldNormal;
  #ifdef DYNAMICLIGHTMAP_ON
  o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
  #endif
  #ifdef LIGHTMAP_ON
  o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
  #endif

  // SH/ambient and vertex lights
  #ifndef LIGHTMAP_ON
    #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
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
  #endif // !LIGHTMAP_ON

  UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
  return o;
}

// fragment shader
fixed4 frag_surf_simplified (v2f_surf IN) : SV_Target {
  UNITY_SETUP_INSTANCE_ID(IN);
  // prepare and unpack data
  Input surfIN;
  UNITY_INITIALIZE_OUTPUT(Input,surfIN);
  surfIN.alpha.x = 1.0;
  surfIN.uv_MainTex.x = 1.0;
  surfIN.worldRefl.x = 1.0;
  surfIN.viewDir.x = 1.0;
  surfIN.uv_MainTex = IN.pack0.xy;
  // mask begin
  //surfIN.uv_ClothTex = IN.projPos.xy;
  // mask end
  surfIN.uv_MainTex1.xyz = IN.pack1.xyz;
  surfIN.alpha = IN.custompack0.x;
  float3 worldPos = IN.worldPos;
  #ifndef USING_DIRECTIONAL_LIGHT
    fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
  #else
    fixed3 lightDir = _WorldSpaceLightPos0.xyz;
  #endif
  fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
  fixed3 viewDir = worldViewDir;
  surfIN.viewDir = viewDir;
  #ifdef UNITY_COMPILER_HLSL
  SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
  #else
  SurfaceOutputStandardSpecular o;
  #endif
  o.Albedo = 1.0;
  o.Emission = 0.0;
  o.Specular = 0.0;
  o.Alpha = 0.00;
  o.Occlusion = 1.0;
  fixed3 normalWorldVertex = fixed3(0,0,1);
  o.Normal = IN.worldNormal;
  normalWorldVertex = IN.worldNormal;
  
#include "IFCommonClothCommandMask.cginc"

  // call surface function
  // surf_simplified (surfIN, o);
  surf(surfIN, o);
  
  // compute lighting & shadowing factor
  UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
  
  fixed4 c = 0;
	
  fixed NdL = saturate(dot(lightDir, o.Normal.xyz));
  c.rgb += _LightColor0.rgb * o.Albedo * NdL + UNITY_LIGHTMODEL_AMBIENT.rgb * _EnvironmentLightAdd * o.Albedo;
  c.rgb += o.Emission;
  c.a = o.Alpha;
  c  = Dissolve(c, surfIN);
				
  UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog
  return c;
}
////////////////// Simplified End! ////////////////////
#endif
