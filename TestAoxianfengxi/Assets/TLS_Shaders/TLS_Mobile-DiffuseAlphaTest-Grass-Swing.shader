// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_LightmapInd', a built-in variable
// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D
// Upgrade NOTE: replaced tex2D unity_LightmapInd with UNITY_SAMPLE_TEX2D_SAMPLER

// Simplified Diffuse shader. Differences from regular Diffuse one:
// - no Main Color
// - fully supports only 1 directional light. Other lights can affect it, but it will be per-vertex/SH.

Shader "TLStudio/Transparent/Cutout_Ani" {
Properties {
	_MainTex ("Base (RGB)", 2D) = "white" {}
	_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
	_Color("Color",Color) = (1.0, 1.0, 1.0, 1.0)
	//_Range("Range" , Range(0,0.1)) = 0.05
	_Wind("Wind params",Vector) = (0,0,0,0.1)
	_WindEdgeFlutter("Wind edge fultter factor", float) = 3
	_WindEdgeFlutterFreqScale("Wind edge fultter freq scale",float) = 0.5
	
	[Space(20)]
//	_SnowIntensity("Snow Intensity", Range(0, 1)) = 1
//	_SnowColorNew("Snow Color", Color) = (1,1,1,1)
//	_SnowCoverage("Snow Coverage", Range(0, 1)) = 1
	_WhereHasSnow("Where Has Snow", Color) = (1,1,1,1)
}
SubShader {
	Tags { "Queue"="AlphaTest+50" "IgnoreProjector"="True" "RenderType"="TransparentCutout" }
	LOD 200
	Cull Off


	// ------------------------------------------------------------
	// Surface shader code generated out of a CGPROGRAM block:
	

	// ---- forward rendering base pass:
	Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		ColorMask RGBA

CGPROGRAM
#pragma skip_variants DIRLIGHTMAP_COMBINED SHADOWS_SCREEN VERTEXLIGHT_ON SHADOWS_CUBE
// compile directives
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma multi_compile_fwdbase
#pragma multi_compile FOG_EXP2 FOG_LINEAR
//#pragma multi_compile_instancing

//#pragma multi_compile _ INSTANCE_ENABLE
#if defined(INSTANCE_ENABLE) && defined(LIGHTMAP_ON)
	#if defined(LIGHTPROBE_SH)
		#undef LIGHTPROBE_SH
	#endif
#endif

//#include "HLSLSupport.cginc"
//#include "UnityShaderVariables.cginc"
#define UNITY_PASS_FORWARDBASE
#include "UnityCG.cginc"
#include "Assets/TLS_Shaders/CGIncludes/Lighting.cginc"
#include "Assets/TLS_Shaders/CGIncludes/AutoLight.cginc"
#include "Assets/TLS_Shaders/CGIncludes/WeatherLibrary.cginc"
#include "TerrainEngine.cginc"


#define INTERNAL_DATA
//#define WorldReflectionVector(data,normal) data.worldRefl
//#define WorldNormalVector(data,normal) normal

// Original surface shader snippet:
#line 14 ""
#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
#endif

//#pragma surface surf Lambert noforwardadd alphatest:_Cutoff

sampler2D _MainTex;
	fixed4 _Color;

struct Input {
	half2 uv_MainTex;
	float3 worldPosition;
	float3 worldNormal;
};

void surf (Input IN, inout SurfaceOutput o) {
	fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
	o.Albedo = c.rgb*_Color.rgb;
	if (_SnowIntensity > 0)
	{
		o.Albedo = BlendSnowTree(o.Albedo, IN.worldNormal);
	}
	o.Alpha = c.a*_Color.a;
}


// vertex-to-fragment interpolation data
#ifdef LIGHTMAP_OFF
struct v2f_surf {
  float4 pos : SV_POSITION;
  half2 pack0 : TEXCOORD0;
  fixed3 normal : TEXCOORD1;
  fixed3 vlight : TEXCOORD2;
  LIGHTING_COORDS(3,4)
  UNITY_FOG_COORDS(5)
  half3 worldPos : TEXCOORD6;
  UNITY_VERTEX_INPUT_INSTANCE_ID
};
#endif
#ifndef LIGHTMAP_OFF
struct v2f_surf {
  float4 pos : SV_POSITION;
  half2 pack0 : TEXCOORD0;
  half2 lmap : TEXCOORD1;
  LIGHTING_COORDS(2,3)
  UNITY_FOG_COORDS(4)
  half3 normal : TEXCOORD5;
  half3 worldPos : TEXCOORD6;
  UNITY_VERTEX_INPUT_INSTANCE_ID
};
#endif
#ifndef LIGHTMAP_OFF
// float4 unity_LightmapST;
#endif
half4 _MainTex_ST;
half	_Range;
float _WindEdgeFlutter;
float _WindEdgeFlutterFreqScale;
inline float4 AnimateVertex2(float4 pos, float3 normal, float4 animParams,float4 wind,float2 time)
{	
	// animParams stored in color
	// animParams.x = branch phase
	// animParams.y = edge flutter factor
	// animParams.z = primary factor
	// animParams.w = secondary factor

	float fDetailAmp = 0.1f;
	float fBranchAmp = 0.3f;
	
	// Phases (object, vertex, branch)
	//float fObjPhase = dot(_Object2World[3].xyz, 1);
	//float fBranchPhase = fObjPhase + animParams.x;
	
	float fVtxPhase = dot(pos.xyz, animParams.y + animParams.x);
	
	// x is used for edges; y is used for branches
	float2 vWavesIn = time  + float2(fVtxPhase,animParams.x );
	
	// 1.975, 0.793, 0.375, 0.193 are good frequencies
	float4 vWaves = (frac( vWavesIn.xxyy * float4(1.975, 0.793, 0.375, 0.193) ) * 2.0 - 1.0);
	
	vWaves = SmoothTriangleWave( vWaves );
	float2 vWavesSum = vWaves.xz + vWaves.yw;

	// Edge (xz) and branch bending (y)
	float3 bend = animParams.y * fDetailAmp * normal.xyz;
	bend.y = animParams.w * fBranchAmp;
	pos.xyz += ((vWavesSum.xyx * bend) + (wind.xyz * vWavesSum.y * animParams.w)) * wind.w; 

	// Primary bending
	// Displace position
	pos.xyz += animParams.z * wind.xyz;
	
	return pos;
}

#if defined(INSTANCE_ENABLE) && defined(UNITY_INSTANCING_ENABLED) && defined(LIGHTMAP_ON)
	UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_DEFINE_INSTANCED_PROP(fixed4, unity_LightmapST)
	UNITY_INSTANCING_BUFFER_END(Props)
#endif

// vertex shader
v2f_surf vert_surf (appdata_full v) {
//	half4	finalpos = mul(_Object2World,v.vertex);
//half4 winDirection =normalize( mul(_World2Object,float4(1,0,0,1)));
//	half3	dist =	_WorldSpaceCameraPos.xyz - finalpos.xyz;
//	half4	mdlPos;
//	if(length(dist) < 25)
//	{
//		float 	finalbias = fmod(finalpos.x*finalpos.x + finalpos.y*finalpos.y + finalpos.z*finalpos.z,4);
//		if(v.color.r == 0)
//		{
//			mdlPos	= v.vertex;
//		}
//		else
//		{
//			half st = 0;
//			if(finalbias < 1) st = max(_CosTime.w + 0.3, -0.5);
//			else if(finalbias >= 1 && finalbias < 2) st = min(_SinTime.w, 0.8) * finalbias;
//			else if(finalbias >= 2 && finalbias < 3) st = min(_CosTime.w, 0.9) * finalbias;
//			else if(finalbias >= 3 && finalbias < 4) st = max(_SinTime.w + 0.8, -0.8) * finalbias;
//			mdlPos.xyz = v.vertex.xyz + v.tangent * st * _Range ;
//			mdlPos.w = v.vertex.w;
//		}
//	}
//	else
//	{
//		mdlPos = v.vertex;
//	}
		float4 wind;
        float	bendingFact= v.color.a;
        wind.xyz	= mul((float3x3)unity_WorldToObject,_Wind.xyz);
		wind.w		= _Wind.w  * bendingFact;
		float4	windParams	= float4(0,_WindEdgeFlutter,bendingFact.xx);
		float 	windTime = _Time.y * float2(_WindEdgeFlutterFreqScale,1);
		float4	mdlPos= AnimateVertex2(v.vertex,v.normal,windParams,wind,windTime);
   //mdlPos = v.vertex+_SinTime.w*_Range*v.color.r*winDirection;
	v2f_surf o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	o.pos = UnityObjectToClipPos(mdlPos);
	o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

	#ifndef LIGHTMAP_OFF
		#if defined(INSTANCE_ENABLE) && defined(UNITY_INSTANCING_ENABLED)
			unity_LightmapST = UNITY_ACCESS_INSTANCED_PROP(Props, unity_LightmapST);
		#endif
		o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	#endif
	
	float3 worldN = UnityObjectToWorldNormal(SCALED_NORMAL);// normalize(mul((float3x3)_Object2World, SCALED_NORMAL));
	float3 worldPos = mul(unity_ObjectToWorld, mdlPos).xyz;

	o.normal = worldN;
	o.worldPos = worldPos;


	// SH/ambient and vertex lights
	#ifdef LIGHTMAP_OFF
		float3 shlight = ShadeSH9 (float4(worldN,1.0));
		o.vlight = shlight;
		#ifdef VERTEXLIGHT_ON
			
			o.vlight += Shade4PointLights (
			  unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			  unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			  unity_4LightAtten0, worldPos, worldN );
		#endif // VERTEXLIGHT_ON
	#endif // LIGHTMAP_OFF

	  // pass lighting information to pixel shader
	  TRANSFER_VERTEX_TO_FRAGMENT(o);
	  if(UseHeightFog > 0)
	  {
	  	TL_TRANSFER_FOG(o,o.pos, v.vertex);
	  }else
	  {
		  UNITY_TRANSFER_FOG(o,o.pos);	  
	  }
	  return o;
}
inline fixed4 LightingLambert (SurfaceOutput s, fixed3 lightDir, fixed atten)
{
    fixed diff = max (0, dot (normalize(s.Normal), normalize(lightDir)));
    
    fixed4 c;
    c.rgb = s.Albedo * _LightColor0.rgb * (diff * atten);
    c.a = s.Alpha;
    return c;
}
#ifndef LIGHTMAP_OFF
// sampler2D unity_Lightmap;
#ifndef DIRLIGHTMAP_OFF
// sampler2D unity_LightmapInd;
#endif
#endif
fixed _Cutoff;
 
// fragment shader
fixed4 frag_surf (v2f_surf IN) : SV_Target {
  // prepare and unpack data
  UNITY_SETUP_INSTANCE_ID(IN);
  #ifdef UNITY_COMPILER_HLSL
  Input surfIN = (Input)0;
  #else
  Input surfIN;
  #endif
  surfIN.uv_MainTex = IN.pack0.xy;
  surfIN.worldPosition = IN.worldPos;
  surfIN.worldNormal = IN.normal;
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
  fixed4 c = 0;  // realtime lighting: call lighting function
  #ifndef LIGHTMAP_OFF
  c = LightingLambert (o, _WorldSpaceLightPos0.xyz, atten);
  #endif // LIGHTMAP_OFF || DIRLIGHTMAP_OFF
  #ifdef LIGHTMAP_OFF
  c.rgb += o.Albedo * IN.vlight;
  #endif // LIGHTMAP_OFF

  // lightmaps:
  #ifndef LIGHTMAP_OFF
     #ifdef DIRLIGHTMAP_OFF
      // single lightmap
      fixed4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.lmap.xy);
      fixed3 lm = DecodeLightmap (lmtex);
	  lm = BlendLightmap(lm, IN.lmap.xy);
      //light.rgb += lm;
    #elif DIRLIGHTMAP_COMBINED
      // directional lightmaps
      fixed4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.lmap.xy);
      half4 lm = half4(DecodeLightmap(lmtex), 0);
	  lm = BlendLightmap(lm, IN.lmap.xy);
      //light += lm;
    #elif DIRLIGHTMAP_SEPARATE
      // directional with specular - no support
    #endif // DIRLIGHTMAP_OFF

    // combine lightmaps with realtime shadows
    #ifdef SHADOWS_SCREEN
      #if defined(UNITY_NO_RGBM)
      c.rgb += o.Albedo * min(lm, atten*2);
      #else
      c.rgb += o.Albedo * max(min(lm,(atten*2)*lmtex.rgb), lm*atten);
      #endif
    #else // SHADOWS_SCREEN
      c.rgb += o.Albedo * lm;
    #endif // SHADOWS_SCREEN
  c.a = o.Alpha;
  #endif // LIGHTMAP_OFF
  
  c.a = o.Alpha;
  if(UseHeightFog > 0)
  {
  	TL_APPLY_FOG(IN.fogCoord, c.rgb);
  }else
  {
	  UNITY_APPLY_FOG(IN.fogCoord, c);  
  }
  return c;
}

ENDCG

}
    	
			Pass
		{
			//此pass就是 从默认的fallBack中找到的 "LightMode" = "ShadowCaster" 产生阴影的Pass
			Tags{ "LightMode" = "ShadowCaster" }

			CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#pragma multi_compile_shadowcaster
//#pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
#pragma shader_feature _RENDERING_CUTOUT
#pragma shader_feature _SMOOTHNESS_ALBEDO
#include "UnityCG.cginc"
			sampler2D _MainTex;
		float4 _MainTex_ST;
		fixed _Cutoff;
		struct v2f {
			V2F_SHADOW_CASTER;
			float2 uv : TEXCOORD1;
			UNITY_VERTEX_OUTPUT_STEREO
		};

		v2f vert(appdata_base v)
		{
			v2f o;
			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
			o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
			TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
		}

		float4 frag(v2f i) : SV_Target
		{
			fixed4 testColor = tex2D(_MainTex, i.uv);
		clip(testColor.a - _Cutoff);
		SHADOW_CASTER_FRAGMENT(i)
		}
			ENDCG

		}
#LINE 31

}
//Fallback "Transparent/Cutout/VertexLit"
}
