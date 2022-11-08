Shader "Pet Fur/Pet_FurLOD" 
{
	Properties 
	{
        _FurColor ("Fur Color", Color) = (1,1,1,1)
        _MainTex ("Fur Texture (RGB)", 2D) = "white" { }
        _ControlTex ("Control Texture (RGB)", 2D) = "white" { }     
		// mask begin
		_ControlAddTex ("Control Add Texture (RGB)", 2D) = "white" { }     
		// mask end
        _NoiseTex ("Noise Texture (RGB)", 2D) = "white" { }	
        _FurGlossiness("Smoothness", Range(0.0, 1.0)) = 0.5
        _FurSpecularColor ("Specular", Color) = (0.2,0.2,0.2,1)
		_FurSpecularMap("Specular", 2D) = "white" {}

		_FurBumpScale("Normal Scale", Float) = 1.0
		[Normal]_FurBumpMap("Normal Map", 2D) = "bump" {}	
                                                
        _Color ("Color", Color) = (1,1,1,1)
		_SkinTex ("Skin Albedo (RGB)", 2D) = "white" {}

		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		[Gamma] _SpecularColor("Specular",  Color) = (0.2,0.2,0.2,1)
		_SpecGlossMap("Specular", 2D) = "white" {}
		
		_BumpScale("Normal Scale", Float) = 1.0
		[Normal]_BumpMap("Normal Map", 2D) = "bump" {}	
		
        _StrandThickness ("Strand Density", Range(0,10)) = 1
        _MaxHairLength ("Max Strand Length", Range(0,0.5)) = 0.08
        _EdgeFade ("Edge Fade", Range(0,1)) = 0.4
		
		// simplified begin!
		_EnvironmentLightAdd("_EnvironmentLightAdd", Range(0.0, 3.0)) = 1
		// simplified end!
		
        _ShadowStrength ("Shadow Strength", Range(0,1)) = 0.75
        _ShadowWeakness ("Shadow Weakness", Range(0,1)) = 0.75

      	_RimColor ("Rim Color", Color) = (0,0,1,0.0)
      	_RimPower ("Rim Power", Range(0.5,8.0)) = 2.0
		_RimStrength ("Rim Strength", Range(0, 5)) = 2.0
              
		_DissolveAmount ("Dissolve Amount", Range (0, 1)) = 0
		_DissolveInfo ("StartAmount, Illuminate, Tile, Power", Vector) = (0.1, 0.2, 1, 0)
		_DissolveColor ("Dissolve Color", color) = (1,1,1,1)
		_DissolveSrc ("Dissolve Src", 2D) = "white" {}
		
		_ExtraControl ("Extra Control", Vector) = (0, 0, 0, 0)
		
		_DecalColorControlSrc("Decal Color Control Src", 2D) = "white" {}
		_DecalColor1("Decal Color1", Color) = (1,1,1,1)

        [HideInInspector] _RimLightMode ("__rimlightmode", Float) = 0.0
        [HideInInspector] _ShadowMode ("__shadowmode", Float) = 0.0
        [HideInInspector] _SkinMode ("__skinmode", Float) = 0.0
        
        [HideInInspector] _UseFurSecondMap ("__usefursecondmap", Float) = 0.0
        [HideInInspector] _UseHeightMap ("__useheightmap", Float) = 0.0
        [HideInInspector] _UseBiasMap ("__usebiasmap", Float) = 0.0
        [HideInInspector] _UseSkinSecondMap ("__useskinsecondmap", Float) = 0.0
        [HideInInspector] _UseStrengthMap ("__usestrengthmap", Float) = 0.0
 	}
	
	SubShader 
	{
		ZWrite On
		Tags { "QUEUE"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True"}	
		Blend SrcAlpha OneMinusSrcAlpha
		LOD 100

		// ---- forward rendering base pass:
		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma vertex vert_surfSkin
			#pragma fragment frag_surfSkin 
			#pragma target 3.0		
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"

			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "AutoLight.cginc"
		
			#define CURRENTLAYER 0.0
			#define NOISEFACTOR 0.0
			#include "ImperialFurSpecular.cginc"
			

	// vertex-to-fragment interpolation data
	// no lightmaps:
	#ifndef LIGHTMAP_ON
	struct v2f_surfSkin2 {
	  UNITY_POSITION(pos);
	  half2 pack0 : TEXCOORD0; // _MainTex
	  half4 tSpace0 : TEXCOORD1;
	  half4 tSpace1 : TEXCOORD2;
	  half4 tSpace2 : TEXCOORD3;
	  half custompack0 : TEXCOORD4; // alpha
	  #if UNITY_SHOULD_SAMPLE_SH
	  half3 sh : TEXCOORD5; // SH
	  #endif
	  UNITY_LIGHTING_COORDS(6, 7)
	  //UNITY_FOG_COORDS(7)
	  #if SHADER_TARGET >= 30
	  half4 lmap : TEXCOORD8;
	  #endif
	  half4 pack1: TEXCOORD9;
	  #ifdef ENABLECLOTHFURCONTROLTEX
	   // mask begin
	  float4 projPos : TEXCOORD10;
	  // mask end
	  #endif
	  UNITY_VERTEX_INPUT_INSTANCE_ID
	  UNITY_VERTEX_OUTPUT_STEREO
	};
	#endif
	// with lightmaps:
	#ifdef LIGHTMAP_ON
	struct v2f_surfSkin2 {
	  UNITY_POSITION(pos);
	  half2 pack0 : TEXCOORD0; // _MainTex
	  half4 tSpace0 : TEXCOORD1;
	  half4 tSpace1 : TEXCOORD2;
	  half4 tSpace2 : TEXCOORD3;
	  half custompack0 : TEXCOORD4; // alpha
	  half4 lmap : TEXCOORD5;
	  UNITY_LIGHTING_COORDS(6, 7)
	  //UNITY_FOG_COORDS(7)
	  half4 pack1: TEXCOORD9;
	  #ifdef ENABLECLOTHFURCONTROLTEX
	  // mask begin
	  float4 projPos : TEXCOORD10;
	  // mask end
	  #endif
	  UNITY_VERTEX_INPUT_INSTANCE_ID
	  UNITY_VERTEX_OUTPUT_STEREO
	};
	#endif
	half4 _MainTex_ST;

	// vertex shader
	v2f_surfSkin2 vert_surfSkin (appdata_full v) {
	  UNITY_SETUP_INSTANCE_ID(v);
	  v2f_surfSkin2 o;
	  UNITY_INITIALIZE_OUTPUT(v2f_surfSkin2,o);
	  UNITY_TRANSFER_INSTANCE_ID(v,o);
	  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
	  Input customInputData;
	  vertSkin (v, customInputData);
	  o.custompack0.x = customInputData.alpha;
	  
		
	  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
	  
	  //float4 srcObjPos = UnityObjectToClipPos(v.vertex);
	  //float4 spos1 = ComputeScreenPos (srcObjPos);		
	  //COMPUTE_EYEDEPTH(spos1.z);
	  //o.pack0.w = spos1.z;

	  o.pack1.xyz = v.vertex.xyz;

	  
		v.vertex.xyz += v.normal * v.color.x * _ExtraControl.x * 0.1f;
	  o.pos = UnityObjectToClipPos(v.vertex);
		
	  #ifdef ENABLECLOTHFURCONTROLTEX
	  o.projPos = ComputeScreenPos (o.pos);
	  COMPUTE_EYEDEPTH(o.projPos.z);
	  #endif
	  
	  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	  fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
	  fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
	  fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	  fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
	  o.tSpace0 = half4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
	  o.tSpace1 = half4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
	  o.tSpace2 = half4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
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

	  UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy); // pass shadow coordinates to pixel shader
	  UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
	  return o;
	}



	// fragment shader
	fixed4 frag_surfSkin (v2f_surfSkin2 IN) : SV_Target {
	   
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
	  
	  float3 worldPos = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
	  // mask begin
	  fixed4 ct_02 = tex2D (_ControlAddTex, surfIN.uv_MainTex);
	  if (ct_02.r < 0.1)
		  discard;


	  #ifndef USING_DIRECTIONAL_LIGHT
		fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	  #else
		fixed3 lightDir = _WorldSpaceLightPos0.xyz;
	  #endif
	  fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
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
	  o.Normal = fixed3(0,0,1);

	  // call surface function
	  surfSkin (surfIN, o);

	  UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
	  fixed4 c = 0;
	  fixed3 worldN;
	  worldN.x = dot(IN.tSpace0.xyz, o.Normal);
	  worldN.y = dot(IN.tSpace1.xyz, o.Normal);
	  worldN.z = dot(IN.tSpace2.xyz, o.Normal);
	  worldN = normalize(worldN);
	  o.Normal = worldN;

	  fixed NdL = saturate(dot(lightDir, o.Normal.xyz));
	  c.rgb += _LightColor0.rgb * o.Albedo * NdL +  + UNITY_LIGHTMODEL_AMBIENT.rgb * _EnvironmentLightAdd * o.Albedo;
	  c.rgb += o.Emission;
	  c.a = o.Alpha;
	  
	  c  = Dissolve(c, surfIN);
	  //return 0;
	  UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog
	  UNITY_OPAQUE_ALPHA(c.a);
	  return c;
	}

	ENDCG

	}

		// ------------------------------------------------------------
		// Surface shader code generated out of a CGPROGRAM block:
		ZWrite Off ColorMask RGB
		

		// ---- forward rendering base pass:
		Pass {
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
			// compile directives
	//#pragDISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma target 3.0

			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbasealpha noshadow
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"

			#define CURRENTLAYER 0.1
			#define NOISEFACTOR 0.05
			
			#include "PetExtraFur.cginc"
	ENDCG

	}

	//	// ---- forward rendering additive lights pass:
	//	Pass {
	//		Name "FORWARD"
	//		Tags { "LightMode" = "ForwardAdd" }
	//		ZWrite Off Blend One One
	//		Blend SrcAlpha One
	//
	//CGPROGRAM
	//// compile directives
	//#pragma vertex vert_surf
	//#pragma fragment frag_surf
	//#pragma target 3.0
	//
	//#pragma multi_compile_instancing
	//#pragma multi_compile_fog
	//#pragma skip_variants INSTANCING_ON
	//#pragma multi_compile_fwdadd_fullshadows noshadow
	//#include "HLSLSupport.cginc"
	//#include "UnityShaderVariables.cginc"
	//#include "UnityShaderUtilities.cginc"
	//
	//		#define CURRENTLAYER 1.0
	//		#define NOISEFACTOR 0.05
	//		
	//		#include "PetExtraFur2.cginc"
	//ENDCG
	//
	//}
			
	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
			// compile directives
	//#pragDISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma target 3.0

			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbasealpha noshadow
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"

			#define CURRENTLAYER 0.2
			#define NOISEFACTOR 0.1
			
			#include "PetExtraFur.cginc"
	ENDCG

	}

	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
			// compile directives
	//#pragDISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma target 3.0

			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbasealpha noshadow
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"

			#define CURRENTLAYER 0.3
			#define NOISEFACTOR 0.15
			
			#include "PetExtraFur.cginc"
	ENDCG

	}

	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
			// compile directives
	//#pragDISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma target 3.0

			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbasealpha noshadow
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"

			#define CURRENTLAYER 0.4
			#define NOISEFACTOR 0.2
			
			#include "PetExtraFur.cginc"
	ENDCG

	}

	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
			// compile directives
	//#pragDISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma target 3.0

			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbasealpha noshadow
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"

			#define CURRENTLAYER 0.5
			#define NOISEFACTOR 0.3
			
			#include "PetExtraFur.cginc"
	ENDCG

	}

	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
			// compile directives
	//#pragDISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma target 3.0

			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbasealpha noshadow
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"

			#define CURRENTLAYER 0.6
			#define NOISEFACTOR 0.4
			
			#include "PetExtraFur.cginc"
	ENDCG

	}

	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
			// compile directives
	//#pragDISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma target 3.0

			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbasealpha noshadow
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"

			#define CURRENTLAYER 0.7
			#define NOISEFACTOR 0.5
			
			#include "PetExtraFur.cginc"
	ENDCG

	}

	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
			// compile directives
	//#pragDISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma target 3.0

			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbasealpha noshadow
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"

			#define CURRENTLAYER 0.8
			#define NOISEFACTOR 0.6
			
			#include "PetExtraFur.cginc"
	ENDCG

	}

	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
			// compile directives
	//#pragDISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma target 3.0

			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbasealpha noshadow
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"

			#define CURRENTLAYER 0.9
			#define NOISEFACTOR 0.8
			
			#include "PetExtraFur.cginc"
	ENDCG

	}

	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
			// compile directives
		//#pragDISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma target 3.0

			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbasealpha noshadow
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"

			#define CURRENTLAYER 1.0
			#define NOISEFACTOR 1.0
			
			#include "PetExtraFur.cginc"
	ENDCG

	}

		} 
		   SubShader {
		ZWrite On
		Tags { "QUEUE"="Transparent" "RenderType"="Opaque" "IgnoreProjector"="True"}  
		Blend SrcAlpha OneMinusSrcAlpha
		LOD 150


	  // ---- forward rendering base pass:
	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }

	CGPROGRAM
	// compile directives
	//#pragma multi_compile DISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
	#pragma vertex vert_surfSkin
	#pragma fragment frag_surfSkin
	#pragma target 3.0    
	#pragma multi_compile_instancing
	#pragma multi_compile_fog
	#pragma multi_compile_fwdbase
	#include "HLSLSupport.cginc"
	#include "UnityShaderVariables.cginc"
	#include "UnityShaderUtilities.cginc"
	// -------- variant for: <when no other keywords are defined>
	#if !defined(INSTANCING_ON)
	// Surface shader code generated based on:
	// vertex modifier: 'vertSkin'
	// writes to per-pixel normal: YES
	// writes to emission: no
	// writes to occlusion: no
	// needs world space reflection vector: no
	// needs world space normal vector: no
	// needs screen space position: no
	// needs world space position: no
	// needs view direction: no
	// needs world space view direction: no
	// needs world space position for lighting: YES
	// needs world space view direction for lighting: YES
	// needs world space view direction for lightmaps: no
	// needs vertex color: no
	// needs VFACE: no
	// passes tangent-to-world matrix to pixel shader: YES
	// reads from normal: no
	// 1 texcoords actually used
	//   half2 _MainTex
	#ifndef UNITY_PASS_FORWARDBASE
	#define UNITY_PASS_FORWARDBASE
	#endif
	#include "UnityCG.cginc"
	#include "Lighting.cginc"
	#include "UnityPBSLighting.cginc"
	#include "AutoLight.cginc"

	#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
	#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
	#define WorldNormalVector(data,normal) fixed3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))

	// Original surface shader snippet:
	#line 47 ""
	#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
	#endif
	/* UNITY: Original start of shader */
		//#pragma surface surfSkin StandardSpecular fullforwardshadows vertex:vertSkin
		//#pragma target 3.0    
		#define CURRENTLAYER 0.0
		#define NOISEFACTOR 0.0
		#include "ImperialFurSpecular.cginc"
		

	// vertex-to-fragment interpolation data
	// no lightmaps:
	#ifndef LIGHTMAP_ON
	struct v2f_surfSkin2 {
	  UNITY_POSITION(pos);
	  half2 pack0 : TEXCOORD0; // _MainTex
	  half4 tSpace0 : TEXCOORD1;
	  half4 tSpace1 : TEXCOORD2;
	  half4 tSpace2 : TEXCOORD3;
	  half custompack0 : TEXCOORD4; // alpha
	  #if UNITY_SHOULD_SAMPLE_SH
	  half3 sh : TEXCOORD5; // SH
	  #endif
	  UNITY_LIGHTING_COORDS(6, 7)
	  //UNITY_FOG_COORDS(7)
	  #if SHADER_TARGET >= 30
	  half4 lmap : TEXCOORD8;
	  #endif
	  half4 pack1: TEXCOORD9;
	  UNITY_VERTEX_INPUT_INSTANCE_ID
	  UNITY_VERTEX_OUTPUT_STEREO
	};
	#endif
	// with lightmaps:
	#ifdef LIGHTMAP_ON
	struct v2f_surfSkin2 {
	  UNITY_POSITION(pos);
	  half2 pack0 : TEXCOORD0; // _MainTex
	  half4 tSpace0 : TEXCOORD1;
	  half4 tSpace1 : TEXCOORD2;
	  half4 tSpace2 : TEXCOORD3;
	  half custompack0 : TEXCOORD4; // alpha
	  half4 lmap : TEXCOORD5;
	  UNITY_LIGHTING_COORDS(6,7)
	  //UNITY_FOG_COORDS(7)
	  half4 pack1: TEXCOORD9;
	  UNITY_VERTEX_INPUT_INSTANCE_ID
	  UNITY_VERTEX_OUTPUT_STEREO
	};
	#endif
	half4 _MainTex_ST;

	// vertex shader
	v2f_surfSkin2 vert_surfSkin (appdata_full v) {
	  UNITY_SETUP_INSTANCE_ID(v);
	  v2f_surfSkin2 o;
	  UNITY_INITIALIZE_OUTPUT(v2f_surfSkin2,o);
	  UNITY_TRANSFER_INSTANCE_ID(v,o);
	  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
	  Input customInputData;
	  vertSkin (v, customInputData);
	  o.custompack0.x = customInputData.alpha;
	  
	  v.vertex.xyz += v.normal * v.color.x * _ExtraControl.x * 0.1f;
	  
	  o.pos = UnityObjectToClipPos(v.vertex);
	  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
	  o.pack1.xy = v.texcoord1.xy;
	  o.pack1.zw = v.texcoord2.xy;
	  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	  fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
	  fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
	  fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	  fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
	  o.tSpace0 = half4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
	  o.tSpace1 = half4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
	  o.tSpace2 = half4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
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

	  UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy); // pass shadow coordinates to pixel shader
	  UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
	  return o;
	}



	// fragment shader
	fixed4 frag_surfSkin (v2f_surfSkin2 IN) : SV_Target {
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
	  float3 worldPos = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
	  // mask begin
	  fixed4 ct_02 = tex2D (_ControlAddTex, surfIN.uv_MainTex);
	  if(ct_02.r < 0.1)
		discard;  
	  // mask end
	  #ifndef USING_DIRECTIONAL_LIGHT
		fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	  #else
		fixed3 lightDir = _WorldSpaceLightPos0.xyz;
	  #endif
	  fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
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
	  o.Normal = fixed3(0,0,1);

	  // call surface function
	  surfSkin (surfIN, o);

	  //ColorMaskMudule(surfIN, o);
	  
	  // compute lighting & shadowing factor
	  UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
	  fixed4 c = 0;
	  fixed3 worldN;
	  worldN.x = dot(IN.tSpace0.xyz, o.Normal);
	  worldN.y = dot(IN.tSpace1.xyz, o.Normal);
	  worldN.z = dot(IN.tSpace2.xyz, o.Normal);
	  worldN = normalize(worldN);
	  o.Normal = worldN;

	  fixed NdL = saturate(dot(lightDir, o.Normal.xyz));
	  c.rgb += _LightColor0.rgb * o.Albedo * NdL +  + UNITY_LIGHTMODEL_AMBIENT.rgb * _EnvironmentLightAdd * o.Albedo;
	  c.rgb += o.Emission;
	  c.a = o.Alpha;
	  
	  c  = Dissolve(c, surfIN);
	  
	  UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog
	  UNITY_OPAQUE_ALPHA(c.a);
	  return c;
	}


	#endif


	ENDCG

	}

	  // ---- forward rendering additive lights pass:
	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardAdd" }
		ZWrite Off Blend One One

	CGPROGRAM
	// compile directives
	//#pragma multi_compile DISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
	#pragma vertex vert_surfSkin
	#pragma fragment frag_surfSkin
	#pragma target 3.0    
	#pragma multi_compile_instancing
	#pragma multi_compile_fog
	#pragma skip_variants INSTANCING_ON
	#pragma multi_compile_fwdadd_fullshadows
	#include "HLSLSupport.cginc"
	#include "UnityShaderVariables.cginc"
	#include "UnityShaderUtilities.cginc"
	// -------- variant for: <when no other keywords are defined>
	#if !defined(INSTANCING_ON)
	// Surface shader code generated based on:
	// vertex modifier: 'vertSkin'
	// writes to per-pixel normal: YES
	// writes to emission: no
	// writes to occlusion: no
	// needs world space reflection vector: no
	// needs world space normal vector: no
	// needs screen space position: no
	// needs world space position: no
	// needs view direction: no
	// needs world space view direction: no
	// needs world space position for lighting: YES
	// needs world space view direction for lighting: YES
	// needs world space view direction for lightmaps: no
	// needs vertex color: no
	// needs VFACE: no
	// passes tangent-to-world matrix to pixel shader: YES
	// reads from normal: no
	// 1 texcoords actually used
	//   half2 _MainTex
	#ifndef UNITY_PASS_FORWARDADD
	#define UNITY_PASS_FORWARDADD
	#endif
	#include "UnityCG.cginc"
	#include "Lighting.cginc"
	#include "UnityPBSLighting.cginc"
	#include "AutoLight.cginc"

	#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
	#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
	#define WorldNormalVector(data,normal) fixed3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))

	// Original surface shader snippet:
	#line 47 ""
	#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
	#endif
	/* UNITY: Original start of shader */
		//#pragma surface surfSkin StandardSpecular fullforwardshadows vertex:vertSkin
		//#pragma target 3.0    
		#define CURRENTLAYER 0.0
		#define NOISEFACTOR 0.0
		#include "ImperialFurSpecular.cginc"
		

	// vertex-to-fragment interpolation data
	struct v2f_surfSkin2 {
	  UNITY_POSITION(pos);
	  half2 pack0 : TEXCOORD0; // _MainTex
	  fixed3 tSpace0 : TEXCOORD1;
	  fixed3 tSpace1 : TEXCOORD2;
	  fixed3 tSpace2 : TEXCOORD3;
	  float3 worldPos : TEXCOORD4;
	  half custompack0 : TEXCOORD5; // alpha
	  UNITY_LIGHTING_COORDS(6, 7)
	  //UNITY_FOG_COORDS(7)
	  UNITY_VERTEX_INPUT_INSTANCE_ID
	  UNITY_VERTEX_OUTPUT_STEREO
	};
	half4 _MainTex_ST;

	// vertex shader
	v2f_surfSkin2 vert_surfSkin (appdata_full v) {
	  UNITY_SETUP_INSTANCE_ID(v);
	  v2f_surfSkin2 o;
	  UNITY_INITIALIZE_OUTPUT(v2f_surfSkin2,o);
	  UNITY_TRANSFER_INSTANCE_ID(v,o);
	  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
	  Input customInputData;
	  vertSkin (v, customInputData);
	  o.custompack0.x = customInputData.alpha;
	  v.vertex.xyz += v.normal * v.color.x * _ExtraControl.x * 0.1f;
	  o.pos = UnityObjectToClipPos(v.vertex);
	  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
	  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	  fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
	  fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
	  fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	  fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
	  o.tSpace0 = fixed3(worldTangent.x, worldBinormal.x, worldNormal.x);
	  o.tSpace1 = fixed3(worldTangent.y, worldBinormal.y, worldNormal.y);
	  o.tSpace2 = fixed3(worldTangent.z, worldBinormal.z, worldNormal.z);
	  o.worldPos = worldPos;

	  UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy); // pass shadow coordinates to pixel shader
	  UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
	  return o;
	}

	// fragment shader
	fixed4 frag_surfSkin (v2f_surfSkin2 IN) : SV_Target {
	  UNITY_SETUP_INSTANCE_ID(IN);
	  // prepare and unpack data
	  Input surfIN;
	  UNITY_INITIALIZE_OUTPUT(Input,surfIN);
	  surfIN.alpha.x = 1.0;
	  surfIN.uv_MainTex.x = 1.0;
	  surfIN.worldRefl.x = 1.0;
	  surfIN.viewDir.x = 1.0;
	  surfIN.uv_MainTex = IN.pack0.xy;
	  surfIN.alpha = IN.custompack0.x;
	  float3 worldPos = IN.worldPos;
	  // mask begin
	  fixed4 ct_02 = tex2D (_ControlAddTex, surfIN.uv_MainTex);
	  if(ct_02.r < 0.1)
		discard;  
	  // mask end
	  #ifndef USING_DIRECTIONAL_LIGHT
		fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	  #else
		fixed3 lightDir = _WorldSpaceLightPos0.xyz;
	  #endif
	  fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
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
	  o.Normal = fixed3(0,0,1);

	  // call surface function
	  surfSkin (surfIN, o);
	  
	  //ColorMaskMudule(surfIN, o);
	  
	  UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
	  fixed4 c = 0;
	  fixed3 worldN;
	  worldN.x = dot(IN.tSpace0.xyz, o.Normal);
	  worldN.y = dot(IN.tSpace1.xyz, o.Normal);
	  worldN.z = dot(IN.tSpace2.xyz, o.Normal);
	  worldN = normalize(worldN);
	  o.Normal = worldN;

	  // Setup lighting environment
	  UnityGI gi;
	  UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
	  gi.indirect.diffuse = 0;
	  gi.indirect.specular = 0;
	  gi.light.color = _LightColor0.rgb;
	  gi.light.dir = lightDir;
	  gi.light.color *= atten;
	  c += LightingStandardSpecular (o, worldViewDir, gi);
	  c.a = 0.0;
	  
	c  = Dissolve(c, surfIN);
			
	  UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog
	  UNITY_OPAQUE_ALPHA(c.a);
	  return c;
	}


	#endif


	ENDCG

	}

	  
	  
	  // ------------------------------------------------------------
	  // Surface shader code generated out of a CGPROGRAM block:
	  ZWrite Off ColorMask RGB
	  

	  // ---- forward rendering base pass:
	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
		// compile directives
	//#pragma multi_compile DISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
		#pragma vertex vert_surf_simplified
		#pragma fragment frag_surf_simplified
		#pragma target 3.0

		#pragma multi_compile_instancing
		#pragma multi_compile_fog
		#pragma multi_compile_fwdbasealpha noshadow
		#include "HLSLSupport.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityShaderUtilities.cginc"

		#define CURRENTLAYER 0.1
		#define NOISEFACTOR 0.05
		
		#include "PetExtraFur.cginc"
	ENDCG

	}
		
	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
		// compile directives
	//#pragma multi_compile DISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
		#pragma vertex vert_surf_simplified
		#pragma fragment frag_surf_simplified
		#pragma target 3.0

		#pragma multi_compile_instancing
		#pragma multi_compile_fog
		#pragma multi_compile_fwdbasealpha noshadow
		#include "HLSLSupport.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityShaderUtilities.cginc"

		#define CURRENTLAYER 0.2
		#define NOISEFACTOR 0.1
		
		#include "PetExtraFur.cginc"
	ENDCG

	}

	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
		// compile directives
	//#pragma multi_compile DISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
		#pragma vertex vert_surf_simplified
		#pragma fragment frag_surf_simplified
		#pragma target 3.0

		#pragma multi_compile_instancing
		#pragma multi_compile_fog
		#pragma multi_compile_fwdbasealpha noshadow
		#include "HLSLSupport.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityShaderUtilities.cginc"

		#define CURRENTLAYER 0.3
		#define NOISEFACTOR 0.15
		
		#include "PetExtraFur.cginc"
	ENDCG

	}

	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
		// compile directives
	//#pragma multi_compile DISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
		#pragma vertex vert_surf_simplified
		#pragma fragment frag_surf_simplified
		#pragma target 3.0

		#pragma multi_compile_instancing
		#pragma multi_compile_fog
		#pragma multi_compile_fwdbasealpha noshadow
		#include "HLSLSupport.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityShaderUtilities.cginc"

		#define CURRENTLAYER 0.4
		#define NOISEFACTOR 0.2
		
		#include "PetExtraFur.cginc"
	ENDCG

	}

	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
		// compile directives
	//#pragma multi_compile DISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
		#pragma vertex vert_surf_simplified
		#pragma fragment frag_surf_simplified
		#pragma target 3.0

		#pragma multi_compile_instancing
		#pragma multi_compile_fog
		#pragma multi_compile_fwdbasealpha noshadow
		#include "HLSLSupport.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityShaderUtilities.cginc"

		#define CURRENTLAYER 0.5
		#define NOISEFACTOR 0.3
		
		#include "PetExtraFur.cginc"
	ENDCG

	}

	  } 
	  
		SubShader {
		ZWrite On
		Tags { "QUEUE"="Transparent" "RenderType"="Opaque" "IgnoreProjector"="True"}  
		Blend SrcAlpha OneMinusSrcAlpha
		LOD 100
		

	  // ---- forward rendering base pass:
	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }

	CGPROGRAM
	// compile directives
	//#pragma multi_compile DISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
	#pragma vertex vert_surfSkin
	#pragma fragment frag_surfSkin
	#pragma target 3.0    
	#pragma multi_compile_instancing
	#pragma multi_compile_fog
	#pragma multi_compile_fwdbase
	#include "HLSLSupport.cginc"
	#include "UnityShaderVariables.cginc"
	#include "UnityShaderUtilities.cginc"
	// -------- variant for: <when no other keywords are defined>
	#if !defined(INSTANCING_ON)
	// Surface shader code generated based on:
	// vertex modifier: 'vertSkin'
	// writes to per-pixel normal: YES
	// writes to emission: no
	// writes to occlusion: no
	// needs world space reflection vector: no
	// needs world space normal vector: no
	// needs screen space position: no
	// needs world space position: no
	// needs view direction: no
	// needs world space view direction: no
	// needs world space position for lighting: YES
	// needs world space view direction for lighting: YES
	// needs world space view direction for lightmaps: no
	// needs vertex color: no
	// needs VFACE: no
	// passes tangent-to-world matrix to pixel shader: YES
	// reads from normal: no
	// 1 texcoords actually used
	//   half2 _MainTex
	#ifndef UNITY_PASS_FORWARDBASE
	#define UNITY_PASS_FORWARDBASE
	#endif
	#include "UnityCG.cginc"
	#include "Lighting.cginc"
	#include "UnityPBSLighting.cginc"
	#include "AutoLight.cginc"

	#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
	#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
	#define WorldNormalVector(data,normal) fixed3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))

	// Original surface shader snippet:
	#line 47 ""
	#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
	#endif
	/* UNITY: Original start of shader */
		//#pragma surface surfSkin StandardSpecular fullforwardshadows vertex:vertSkin
		//#pragma target 3.0    
		#define CURRENTLAYER 0.0
		#define NOISEFACTOR 0.0
		#include "ImperialFurSpecular.cginc"
		

	// vertex-to-fragment interpolation data
	// no lightmaps:
	#ifndef LIGHTMAP_ON
	struct v2f_surfSkin2 {
	  UNITY_POSITION(pos);
	  half2 pack0 : TEXCOORD0; // _MainTex
	  half4 tSpace0 : TEXCOORD1;
	  half4 tSpace1 : TEXCOORD2;
	  half4 tSpace2 : TEXCOORD3;
	  half custompack0 : TEXCOORD4; // alpha
	  #if UNITY_SHOULD_SAMPLE_SH
	  half3 sh : TEXCOORD5; // SH
	  #endif
	  UNITY_LIGHTING_COORDS(6, 7)
	  //UNITY_FOG_COORDS(7)
	  #if SHADER_TARGET >= 30
	  half4 lmap : TEXCOORD8;
	  #endif
	  half4 pack1: TEXCOORD9;
	  UNITY_VERTEX_INPUT_INSTANCE_ID
	  UNITY_VERTEX_OUTPUT_STEREO
	};
	#endif
	// with lightmaps:
	#ifdef LIGHTMAP_ON
	struct v2f_surfSkin2 {
	  UNITY_POSITION(pos);
	  half2 pack0 : TEXCOORD0; // _MainTex
	  half4 tSpace0 : TEXCOORD1;
	  half4 tSpace1 : TEXCOORD2;
	  half4 tSpace2 : TEXCOORD3;
	  half custompack0 : TEXCOORD4; // alpha
	  half4 lmap : TEXCOORD5;
	  UNITY_LIGHTING_COORDS(6, 7)
	  //UNITY_FOG_COORDS(7)
	  half4 pack1: TEXCOORD9;
	  UNITY_VERTEX_INPUT_INSTANCE_ID
	  UNITY_VERTEX_OUTPUT_STEREO
	};
	#endif
	half4 _MainTex_ST;

	// vertex shader
	v2f_surfSkin2 vert_surfSkin (appdata_full v) {
	  UNITY_SETUP_INSTANCE_ID(v);
	  v2f_surfSkin2 o;
	  UNITY_INITIALIZE_OUTPUT(v2f_surfSkin2,o);
	  UNITY_TRANSFER_INSTANCE_ID(v,o);
	  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
	  Input customInputData;
	  vertSkin (v, customInputData);
	  o.custompack0.x = customInputData.alpha;
	  
	  v.vertex.xyz += v.normal * v.color.x * _ExtraControl.x * 0.1f;
	  
	  o.pos = UnityObjectToClipPos(v.vertex);
	  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
	  o.pack1.xy = v.texcoord1.xy;
	  o.pack1.zw = v.texcoord2.xy;
	  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	  fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
	  fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
	  fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	  fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
	  o.tSpace0 = half4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
	  o.tSpace1 = half4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
	  o.tSpace2 = half4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
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

	  UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy); // pass shadow coordinates to pixel shader
	  UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
	  return o;
	}



	// fragment shader
	fixed4 frag_surfSkin (v2f_surfSkin2 IN) : SV_Target {
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
	  float3 worldPos = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
	  // mask begin
	  fixed4 ct_02 = tex2D (_ControlAddTex, surfIN.uv_MainTex);
	  if(ct_02.r < 0.1)
		discard;  
	  // mask end
	  #ifndef USING_DIRECTIONAL_LIGHT
		fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	  #else
		fixed3 lightDir = _WorldSpaceLightPos0.xyz;
	  #endif
	  fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
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
	  o.Normal = fixed3(0,0,1);

	  // call surface function
	  surfSkin (surfIN, o);

	  //ColorMaskMudule(surfIN, o);
	  
	  // compute lighting & shadowing factor
	  UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
	  fixed4 c = 0;
	  fixed3 worldN;
	  worldN.x = dot(IN.tSpace0.xyz, o.Normal);
	  worldN.y = dot(IN.tSpace1.xyz, o.Normal);
	  worldN.z = dot(IN.tSpace2.xyz, o.Normal);
	  worldN = normalize(worldN);
	  o.Normal = worldN;

	  fixed NdL = saturate(dot(lightDir, o.Normal.xyz));
	  c.rgb += _LightColor0.rgb * o.Albedo * NdL +  + UNITY_LIGHTMODEL_AMBIENT.rgb * _EnvironmentLightAdd * o.Albedo;
	  c.rgb += o.Emission;
	  c.a = o.Alpha;
	  
	  c  = Dissolve(c, surfIN);
	  
	  UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog
	  UNITY_OPAQUE_ALPHA(c.a);
	  return c;
	}


	#endif


	ENDCG

	}

	  // ---- forward rendering additive lights pass:
	  Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardAdd" }
		ZWrite Off Blend One One

	CGPROGRAM
	// compile directives
	//#pragma multi_compile DISENABLECLOTHFURCONTROLTEX ENABLECLOTHFURCONTROLTEX 
	#pragma vertex vert_surfSkin
	#pragma fragment frag_surfSkin
	#pragma target 3.0    
	#pragma multi_compile_instancing
	#pragma multi_compile_fog
	#pragma skip_variants INSTANCING_ON
	#pragma multi_compile_fwdadd_fullshadows
	#include "HLSLSupport.cginc"
	#include "UnityShaderVariables.cginc"
	#include "UnityShaderUtilities.cginc"
	// -------- variant for: <when no other keywords are defined>
	#if !defined(INSTANCING_ON)
	// Surface shader code generated based on:
	// vertex modifier: 'vertSkin'
	// writes to per-pixel normal: YES
	// writes to emission: no
	// writes to occlusion: no
	// needs world space reflection vector: no
	// needs world space normal vector: no
	// needs screen space position: no
	// needs world space position: no
	// needs view direction: no
	// needs world space view direction: no
	// needs world space position for lighting: YES
	// needs world space view direction for lighting: YES
	// needs world space view direction for lightmaps: no
	// needs vertex color: no
	// needs VFACE: no
	// passes tangent-to-world matrix to pixel shader: YES
	// reads from normal: no
	// 1 texcoords actually used
	//   half2 _MainTex
	#ifndef UNITY_PASS_FORWARDADD
	#define UNITY_PASS_FORWARDADD
	#endif
	#include "UnityCG.cginc"
	#include "Lighting.cginc"
	#include "UnityPBSLighting.cginc"
	#include "AutoLight.cginc"

	#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
	#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
	#define WorldNormalVector(data,normal) fixed3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))

	// Original surface shader snippet:
	#line 47 ""
	#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
	#endif
	/* UNITY: Original start of shader */
		//#pragma surface surfSkin StandardSpecular fullforwardshadows vertex:vertSkin
		//#pragma target 3.0    
		#define CURRENTLAYER 0.0
		#define NOISEFACTOR 0.0
		#include "ImperialFurSpecular.cginc"
		

	// vertex-to-fragment interpolation data
	struct v2f_surfSkin2 {
	  UNITY_POSITION(pos);
	  half2 pack0 : TEXCOORD0; // _MainTex
	  fixed3 tSpace0 : TEXCOORD1;
	  fixed3 tSpace1 : TEXCOORD2;
	  fixed3 tSpace2 : TEXCOORD3;
	  float3 worldPos : TEXCOORD4;
	  half custompack0 : TEXCOORD5; // alpha
	  UNITY_LIGHTING_COORDS(6, 7)
	  //UNITY_FOG_COORDS(7)
	  UNITY_VERTEX_INPUT_INSTANCE_ID
	  UNITY_VERTEX_OUTPUT_STEREO
	};
	half4 _MainTex_ST;

	// vertex shader
	v2f_surfSkin2 vert_surfSkin (appdata_full v) {
	  UNITY_SETUP_INSTANCE_ID(v);
	  v2f_surfSkin2 o;
	  UNITY_INITIALIZE_OUTPUT(v2f_surfSkin2,o);
	  UNITY_TRANSFER_INSTANCE_ID(v,o);
	  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
	  Input customInputData;
	  vertSkin (v, customInputData);
	  o.custompack0.x = customInputData.alpha;
	  v.vertex.xyz += v.normal * v.color.x * _ExtraControl.x * 0.1f;
	  o.pos = UnityObjectToClipPos(v.vertex);
	  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
	  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	  fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
	  fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
	  fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	  fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
	  o.tSpace0 = fixed3(worldTangent.x, worldBinormal.x, worldNormal.x);
	  o.tSpace1 = fixed3(worldTangent.y, worldBinormal.y, worldNormal.y);
	  o.tSpace2 = fixed3(worldTangent.z, worldBinormal.z, worldNormal.z);
	  o.worldPos = worldPos;

	  UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy); // pass shadow coordinates to pixel shader
	  UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
	  return o;
	}

	// fragment shader
	fixed4 frag_surfSkin (v2f_surfSkin2 IN) : SV_Target {
	  UNITY_SETUP_INSTANCE_ID(IN);
	  // prepare and unpack data
	  Input surfIN;
	  UNITY_INITIALIZE_OUTPUT(Input,surfIN);
	  surfIN.alpha.x = 1.0;
	  surfIN.uv_MainTex.x = 1.0;
	  surfIN.worldRefl.x = 1.0;
	  surfIN.viewDir.x = 1.0;
	  surfIN.uv_MainTex = IN.pack0.xy;
	  surfIN.alpha = IN.custompack0.x;
	  float3 worldPos = IN.worldPos;
	  // mask begin
	  fixed4 ct_02 = tex2D (_ControlAddTex, surfIN.uv_MainTex);
	  if(ct_02.r < 0.1)
		discard;  
	  // mask end
	  #ifndef USING_DIRECTIONAL_LIGHT
		fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	  #else
		fixed3 lightDir = _WorldSpaceLightPos0.xyz;
	  #endif
	  fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
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
	  o.Normal = fixed3(0,0,1);

	  // call surface function
	  surfSkin (surfIN, o);
	  
	  //ColorMaskMudule(surfIN, o);
	  
	  UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
	  fixed4 c = 0;
	  fixed3 worldN;
	  worldN.x = dot(IN.tSpace0.xyz, o.Normal);
	  worldN.y = dot(IN.tSpace1.xyz, o.Normal);
	  worldN.z = dot(IN.tSpace2.xyz, o.Normal);
	  worldN = normalize(worldN);
	  o.Normal = worldN;

	  // Setup lighting environment
	  UnityGI gi;
	  UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
	  gi.indirect.diffuse = 0;
	  gi.indirect.specular = 0;
	  gi.light.color = _LightColor0.rgb;
	  gi.light.dir = lightDir;
	  gi.light.color *= atten;
	  c += LightingStandardSpecular (o, worldViewDir, gi);
	  c.a = 0.0;
	  
	c  = Dissolve(c, surfIN);
			
	  UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog
	  UNITY_OPAQUE_ALPHA(c.a);
	  return c;
	}


	#endif


	ENDCG

	}

	}
  
	
	FallBack "VertexLit"
    //CustomEditor "ImperialFurLODShaderGUI"
}
