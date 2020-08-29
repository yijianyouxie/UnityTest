// Simplified Diffuse shader. Differences from regular Diffuse one:
// - no Main Color
// - fully supports only 1 directional light. Other lights can affect it, but it will be per-vertex/SH.

Shader "TLStudio/Opaque/Diffuse" {
	Properties {
		_Color("Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
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
			// compile directives
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma multi_compile GLOBALSH_DISABLE GLOBALSH_ENABLE
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			// Surface shader code generated based on:
			// writes to per-pixel normal: no
			// writes to emission: no
			// needs world space reflection vector: no
			// needs world space normal vector: no
			// needs screen space position: no
			// needs world space position: no
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
			//   half2 _MainTex
			#define UNITY_PASS_FORWARDBASE
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			#define INTERNAL_DATA
			#define WorldReflectionVector(data,normal) data.worldRefl
			#define WorldNormalVector(data,normal) normal

			// Original surface shader snippet:
			#line 12 ""
			#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
			#endif

			//#pragma surface surf Lambert noforwardadd

			sampler2D _MainTex;
			fixed4 _Color;

			struct Input {
				half2 uv_MainTex;
			};

			void surf (Input IN, inout SurfaceOutput o) {
				fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
				o.Albedo = c.rgb*_Color.rgb;
				//o.Alpha = c.a*_Color.a;
			}


			// vertex-to-fragment interpolation data
			// no lightmaps:
			#ifdef LIGHTMAP_OFF
			struct v2f_surf {
			  float4 pos : SV_POSITION;
			  half2 pack0 : TEXCOORD0; // _MainTex
			  half3 worldNormal : TEXCOORD1;
			  float3 worldPos : TEXCOORD2;
			  #if UNITY_SHOULD_SAMPLE_SH
			  half3 sh : TEXCOORD3; // SH
			  #endif
			  SHADOW_COORDS(4)
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
			  half2 pack0 : TEXCOORD0; // _MainTex
			  half3 worldNormal : TEXCOORD1;
			  float3 worldPos : TEXCOORD2;
			  float4 lmap : TEXCOORD3;
			  SHADOW_COORDS(4)
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
				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
				o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				float3 worldPos = mul(_Object2World, v.vertex).xyz;
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
				TRANSFER_SHADOW(o); // pass shadow coordinates to pixel shader
				UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
				return o;
			}

			// fragment shader
			fixed4 frag_surf (v2f_surf IN) : SV_Target {
				// prepare and unpack data
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT(Input,surfIN);
				surfIN.uv_MainTex.x = 1.0;
				surfIN.uv_MainTex = IN.pack0.xy;
				float3 worldPos = IN.worldPos;
				#ifndef USING_DIRECTIONAL_LIGHT
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
				fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif
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
  
				///CYWeather Effect
				#ifdef CYWEATHER_COMMON
				  half horizon = HandleBubbleDistort(worldPos.xz, o.Normal);
				#endif

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
				#if UNITY_SHOULD_SAMPLE_SH
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

				///CYWeather Effect
				#ifdef CYWEATHER_COMMON
				   //c += CustomLightingBlinnPhong (o, viewDir, gi, horizon);
				   //c.rgb = HandleSnowEffect(c.rgb, horizon, worldPos.xz);
					// fixed NdotUp = max(0.0,dot(normalDirection, float3(0,1,0)));
				   // fixed rainCol = 1 - NdotUp;
				   float rainCol = (1 - step(0, dot(o.Normal.xyz, fixed3(0,1,0))));//.g);
				   rainCol *= max(0, dot(o.Normal.xyz, fixed3(0,1,0)));
				   c.rgb = HandleWeatherEffect(c.rgb, o, gi, horizon, worldPos) + rainCol * RainGroundIntensity;
				#else
				   c += LightingLambert (o, gi);
				#endif

				#ifdef GLOBALSH_ENABLE
				  c.xyz = c.xyz*max(fixed3(1.0,1.0,1.0),(IN.vlighting - UNITY_LIGHTMODEL_AMBIENT.xyz)*2);
				#endif
				  UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog
				  UNITY_OPAQUE_ALPHA(c.a);
				  return c;
			}

			ENDCG

		}

		//// ---- deferred lighting base geometry pass:
		//Pass {
		//	Name "PREPASS"
		//	Tags { "LightMode" = "PrePassBase" }

		//	CGPROGRAM
		//	// compile directives
		//	#pragma vertex vert_surf
		//	#pragma fragment frag_surf
		//	#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
		//	#include "HLSLSupport.cginc"
		//	#include "UnityShaderVariables.cginc"
		//	// Surface shader code generated based on:
		//	// writes to per-pixel normal: no
		//	// writes to emission: no
		//	// needs world space reflection vector: no
		//	// needs world space normal vector: no
		//	// needs screen space position: no
		//	// needs world space position: no
		//	// needs view direction: no
		//	// needs world space view direction: no
		//	// needs world space position for lighting: YES
		//	// needs world space view direction for lighting: no
		//	// needs world space view direction for lightmaps: no
		//	// needs vertex color: no
		//	// needs VFACE: no
		//	// passes tangent-to-world matrix to pixel shader: no
		//	// reads from normal: YES
		//	// 0 texcoords actually used
		//	#define UNITY_PASS_PREPASSBASE
		//	#include "UnityCG.cginc"
		//	#include "Lighting.cginc"

		//	#define INTERNAL_DATA
		//	#define WorldReflectionVector(data,normal) data.worldRefl
		//	#define WorldNormalVector(data,normal) normal

		//	// Original surface shader snippet:
		//	#line 12 ""
		//	#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
		//	#endif

		//	//#pragma surface surf Lambert noforwardadd

		//	sampler2D _MainTex;
		//	fixed4 _Color;

		//	struct Input {
		//		half2 uv_MainTex;
		//	};

		//	void surf (Input IN, inout SurfaceOutput o) {
		//		fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
		//		o.Albedo = c.rgb*_Color.rgb;
		//		//o.Alpha = c.a*_Color.a;
		//	}


		//	// vertex-to-fragment interpolation data
		//	struct v2f_surf {
		//	  float4 pos : SV_POSITION;
		//	  half3 worldNormal : TEXCOORD0;
		//	  float3 worldPos : TEXCOORD1;
		//	};

		//	// vertex shader
		//	v2f_surf vert_surf (appdata_full v) {
		//	  v2f_surf o;
		//	  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
		//	  o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
		//	  float3 worldPos = mul(_Object2World, v.vertex).xyz;
		//	  fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
		//	  o.worldPos = worldPos;
		//	  o.worldNormal = worldNormal;
		//	  return o;
		//	}

		//	// fragment shader
		//	fixed4 frag_surf (v2f_surf IN) : SV_Target {
		//		// prepare and unpack data
		//		Input surfIN;
		//		UNITY_INITIALIZE_OUTPUT(Input,surfIN);
		//		surfIN.uv_MainTex.x = 1.0;
		//		float3 worldPos = IN.worldPos;
		//		#ifndef USING_DIRECTIONAL_LIGHT
		//		fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
		//		#else
		//		fixed3 lightDir = _WorldSpaceLightPos0.xyz;
		//		#endif
		//		#ifdef UNITY_COMPILER_HLSL
		//		SurfaceOutput o = (SurfaceOutput)0;
		//		#else
		//		SurfaceOutput o;
		//		#endif
		//		o.Albedo = 0.0;
		//		o.Emission = 0.0;
		//		o.Specular = 0.0;
		//		o.Alpha = 0.0;
		//		o.Gloss = 0.0;
		//		fixed3 normalWorldVertex = fixed3(0,0,1);
		//		o.Normal = IN.worldNormal;
		//		normalWorldVertex = IN.worldNormal;

		//		// call surface function
		//		surf (surfIN, o);

		//		// output normal and specular
		//		fixed4 res;
		//		res.rgb = o.Normal * 0.5 + 0.5;
		//		res.a = o.Specular;
		//		return res;
		//	}

		//	ENDCG

		//}

		//// ---- deferred lighting final pass:
		//Pass {
		//	Name "PREPASS"
		//	Tags { "LightMode" = "PrePassFinal" }
		//	ZWrite Off

		//	CGPROGRAM
		//	// compile directives
		//	#pragma vertex vert_surf
		//	#pragma fragment frag_surf
		//	#pragma multi_compile_fog
		//	#pragma multi_compile_prepassfinal
		//	#include "HLSLSupport.cginc"
		//	#include "UnityShaderVariables.cginc"
		//	// Surface shader code generated based on:
		//	// writes to per-pixel normal: no
		//	// writes to emission: no
		//	// needs world space reflection vector: no
		//	// needs world space normal vector: no
		//	// needs screen space position: no
		//	// needs world space position: no
		//	// needs view direction: no
		//	// needs world space view direction: no
		//	// needs world space position for lighting: YES
		//	// needs world space view direction for lighting: no
		//	// needs world space view direction for lightmaps: no
		//	// needs vertex color: no
		//	// needs VFACE: no
		//	// passes tangent-to-world matrix to pixel shader: no
		//	// reads from normal: no
		//	// 1 texcoords actually used
		//	//   half2 _MainTex
		//	#define UNITY_PASS_PREPASSFINAL
		//	#include "UnityCG.cginc"
		//	#include "Lighting.cginc"

		//	#define INTERNAL_DATA
		//	#define WorldReflectionVector(data,normal) data.worldRefl
		//	#define WorldNormalVector(data,normal) normal

		//	// Original surface shader snippet:
		//	#line 12 ""
		//	#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
		//	#endif

		//	//#pragma surface surf Lambert noforwardadd

		//	sampler2D _MainTex;
		//	fixed4 _Color;

		//	struct Input {
		//		half2 uv_MainTex;
		//	};

		//	void surf (Input IN, inout SurfaceOutput o) {
		//		fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
		//		o.Albedo = c.rgb*_Color.rgb;
		//		//o.Alpha = c.a*_Color.a;
		//	}


		//	// vertex-to-fragment interpolation data
		//	struct v2f_surf {
		//	  float4 pos : SV_POSITION;
		//	  half2 pack0 : TEXCOORD0; // _MainTex
		//	  float3 worldPos : TEXCOORD1;
		//	  float4 screen : TEXCOORD2;
		//	  float4 lmap : TEXCOORD3;
		//	#ifdef LIGHTMAP_OFF
		//	  float3 vlight : TEXCOORD4;
		//	#else
		//	#ifdef DIRLIGHTMAP_OFF
		//	  float4 lmapFadePos : TEXCOORD4;
		//	#endif
		//	#endif
		//	  UNITY_FOG_COORDS(5)
		//	};
		//	float4 _MainTex_ST;

		//	// vertex shader
		//	v2f_surf vert_surf (appdata_full v) {
		//		v2f_surf o;
		//		UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
		//		o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
		//		o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
		//		float3 worldPos = mul(_Object2World, v.vertex).xyz;
		//		fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
		//		o.worldPos = worldPos;
		//		o.screen = ComputeScreenPos (o.pos);
		//	#ifndef DYNAMICLIGHTMAP_OFF
		//		o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
		//	#else
		//		o.lmap.zw = 0;
		//	#endif
		//	#ifndef LIGHTMAP_OFF
		//		o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		//		#ifdef DIRLIGHTMAP_OFF
		//		o.lmapFadePos.xyz = (mul(_Object2World, v.vertex).xyz - unity_ShadowFadeCenterAndType.xyz) * unity_ShadowFadeCenterAndType.w;
		//		o.lmapFadePos.w = (-mul(UNITY_MATRIX_MV, v.vertex).z) * (1.0 - unity_ShadowFadeCenterAndType.w);
		//		#endif
		//	#else
		//		o.lmap.xy = 0;
		//		float3 worldN = UnityObjectToWorldNormal(v.normal);
		//		o.vlight = ShadeSH9 (float4(worldN,1.0));
		//	#endif
		//		UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
		//		return o;
		//	}
		//	sampler2D _LightBuffer;
		//	#if defined (SHADER_API_XBOX360) && defined (UNITY_HDR_ON)
		//	sampler2D _LightSpecBuffer;
		//	#endif
		//	#ifdef LIGHTMAP_ON
		//	float4 unity_LightmapFade;
		//	#endif
		//	fixed4 unity_Ambient;

		//	// fragment shader
		//	fixed4 frag_surf (v2f_surf IN) : SV_Target {
		//		// prepare and unpack data
		//		Input surfIN;
		//		UNITY_INITIALIZE_OUTPUT(Input,surfIN);
		//		surfIN.uv_MainTex.x = 1.0;
		//		surfIN.uv_MainTex = IN.pack0.xy;
		//		float3 worldPos = IN.worldPos;
		//		#ifndef USING_DIRECTIONAL_LIGHT
		//		fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
		//		#else
		//		fixed3 lightDir = _WorldSpaceLightPos0.xyz;
		//		#endif
		//		#ifdef UNITY_COMPILER_HLSL
		//		SurfaceOutput o = (SurfaceOutput)0;
		//		#else
		//		SurfaceOutput o;
		//		#endif
		//		o.Albedo = 0.0;
		//		o.Emission = 0.0;
		//		o.Specular = 0.0;
		//		o.Alpha = 0.0;
		//		o.Gloss = 0.0;
		//		fixed3 normalWorldVertex = fixed3(0,0,1);

		//		// call surface function
		//		surf (surfIN, o);
		//		half4 light = tex2Dproj (_LightBuffer, UNITY_PROJ_COORD(IN.screen));
		//	#if defined (SHADER_API_MOBILE)
		//		light = max(light, half4(0.001, 0.001, 0.001, 0.001));
		//	#endif
		//	#ifndef UNITY_HDR_ON
		//		light = -log2(light);
		//	#endif
		//	#if defined (SHADER_API_XBOX360) && defined (UNITY_HDR_ON)
		//		light.w = tex2Dproj (_LightSpecBuffer, UNITY_PROJ_COORD(IN.screen)).r;
		//	#endif
		//		#ifndef LIGHTMAP_OFF
		//		#ifdef DIRLIGHTMAP_OFF
		//			// single lightmap
		//			fixed4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.lmap.xy);
		//			fixed3 lm = DecodeLightmap (lmtex);
		//			light.rgb += lm;
		//		#elif DIRLIGHTMAP_SEPARATE
		//			// directional with specular - no support
		//		#endif // DIRLIGHTMAP_OFF
		//		#else
		//		light.rgb += IN.vlight;
		//		#endif // !LIGHTMAP_OFF

		//		#ifndef DYNAMICLIGHTMAP_OFF
		//		fixed4 dynlmtex = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, IN.lmap.zw);
		//		light.rgb += DecodeRealtimeLightmap (dynlmtex);
		//		#endif

		//		half4 c = LightingLambert_PrePass (o, light);
		//		UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog
		//		UNITY_OPAQUE_ALPHA(c.a);
		//		return c;
		//	}

		//	ENDCG

		//}

		//// ---- deferred shading pass:
		//Pass {
		//	Name "DEFERRED"
		//	Tags { "LightMode" = "Deferred" }

		//	CGPROGRAM
		//	// compile directives
		//	#pragma vertex vert_surf
		//	#pragma fragment frag_surf
		//	#pragma exclude_renderers nomrt
		//	#pragma multi_compile_prepassfinal
		//	#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
		//	#include "HLSLSupport.cginc"
		//	#include "UnityShaderVariables.cginc"
		//	// Surface shader code generated based on:
		//	// writes to per-pixel normal: no
		//	// writes to emission: no
		//	// needs world space reflection vector: no
		//	// needs world space normal vector: no
		//	// needs screen space position: no
		//	// needs world space position: no
		//	// needs view direction: no
		//	// needs world space view direction: no
		//	// needs world space position for lighting: YES
		//	// needs world space view direction for lighting: no
		//	// needs world space view direction for lightmaps: no
		//	// needs vertex color: no
		//	// needs VFACE: no
		//	// passes tangent-to-world matrix to pixel shader: no
		//	// reads from normal: YES
		//	// 1 texcoords actually used
		//	//   half2 _MainTex
		//	#define UNITY_PASS_DEFERRED
		//	#include "UnityCG.cginc"
		//	#include "Lighting.cginc"

		//	#define INTERNAL_DATA
		//	#define WorldReflectionVector(data,normal) data.worldRefl
		//	#define WorldNormalVector(data,normal) normal

		//	// Original surface shader snippet:
		//	#line 12 ""
		//	#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
		//	#endif

		//	//#pragma surface surf Lambert noforwardadd

		//	sampler2D _MainTex;
		//	fixed4 _Color;

		//	struct Input {
		//		half2 uv_MainTex;
		//	};

		//	void surf (Input IN, inout SurfaceOutput o) {
		//		fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
		//		o.Albedo = c.rgb*_Color.rgb;
		//		//o.Alpha = c.a*_Color.a;
		//	}


		//	// vertex-to-fragment interpolation data
		//	struct v2f_surf {
		//		float4 pos : SV_POSITION;
		//		half2 pack0 : TEXCOORD0; // _MainTex
		//		half3 worldNormal : TEXCOORD1;
		//		float3 worldPos : TEXCOORD2;
		//		float4 lmap : TEXCOORD3;
		//	#ifdef LIGHTMAP_OFF
		//		#if UNITY_SHOULD_SAMPLE_SH
		//		half3 sh : TEXCOORD4; // SH
		//		#endif
		//	#else
		//		#ifdef DIRLIGHTMAP_OFF
		//		float4 lmapFadePos : TEXCOORD4;
		//		#endif
		//	#endif
		//	};
		//	float4 _MainTex_ST;

		//	// vertex shader
		//	v2f_surf vert_surf (appdata_full v) {
		//		v2f_surf o;
		//		UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
		//		o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
		//		o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
		//		float3 worldPos = mul(_Object2World, v.vertex).xyz;
		//		fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
		//		o.worldPos = worldPos;
		//		o.worldNormal = worldNormal;
		//	#ifndef DYNAMICLIGHTMAP_OFF
		//		o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
		//	#else
		//		o.lmap.zw = 0;
		//	#endif
		//	#ifndef LIGHTMAP_OFF
		//		o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		//		#ifdef DIRLIGHTMAP_OFF
		//		o.lmapFadePos.xyz = (mul(_Object2World, v.vertex).xyz - unity_ShadowFadeCenterAndType.xyz) * unity_ShadowFadeCenterAndType.w;
		//		o.lmapFadePos.w = (-mul(UNITY_MATRIX_MV, v.vertex).z) * (1.0 - unity_ShadowFadeCenterAndType.w);
		//		#endif
		//	#else
		//		o.lmap.xy = 0;
		//		#if UNITY_SHOULD_SAMPLE_SH
		//			o.sh = 0;
		//			o.sh = ShadeSHPerVertex (worldNormal, o.sh);
		//		#endif
		//	#endif
		//		return o;
		//	}
		//	#ifdef LIGHTMAP_ON
		//	float4 unity_LightmapFade;
		//	#endif
		//	fixed4 unity_Ambient;

		//	// fragment shader
		//	void frag_surf (v2f_surf IN,
		//		out half4 outDiffuse : SV_Target0,
		//		out half4 outSpecSmoothness : SV_Target1,
		//		out half4 outNormal : SV_Target2,
		//		out half4 outEmission : SV_Target3) {
		//		// prepare and unpack data
		//		Input surfIN;
		//		UNITY_INITIALIZE_OUTPUT(Input,surfIN);
		//		surfIN.uv_MainTex.x = 1.0;
		//		surfIN.uv_MainTex = IN.pack0.xy;
		//		float3 worldPos = IN.worldPos;
		//		#ifndef USING_DIRECTIONAL_LIGHT
		//		fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
		//		#else
		//		fixed3 lightDir = _WorldSpaceLightPos0.xyz;
		//		#endif
		//		#ifdef UNITY_COMPILER_HLSL
		//		SurfaceOutput o = (SurfaceOutput)0;
		//		#else
		//		SurfaceOutput o;
		//		#endif
		//		o.Albedo = 0.0;
		//		o.Emission = 0.0;
		//		o.Specular = 0.0;
		//		o.Alpha = 0.0;
		//		o.Gloss = 0.0;
		//		fixed3 normalWorldVertex = fixed3(0,0,1);
		//		o.Normal = IN.worldNormal;
		//		normalWorldVertex = IN.worldNormal;

		//		// call surface function
		//		surf (surfIN, o);
		//		fixed3 originalNormal = o.Normal;
		//		half atten = 1;

		//		// Setup lighting environment
		//		UnityGI gi;
		//		UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
		//		gi.indirect.diffuse = 0;
		//		gi.indirect.specular = 0;
		//		gi.light.color = 0;
		//		gi.light.dir = half3(0,1,0);
		//		gi.light.ndotl = LambertTerm (o.Normal, gi.light.dir);
		//		// Call GI (lightmaps/SH/reflections) lighting function
		//		UnityGIInput giInput;
		//		UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
		//		giInput.light = gi.light;
		//		giInput.worldPos = worldPos;
		//		giInput.atten = atten;
		//		#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
		//		giInput.lightmapUV = IN.lmap;
		//		#else
		//		giInput.lightmapUV = 0.0;
		//		#endif
		//		#if UNITY_SHOULD_SAMPLE_SH
		//		giInput.ambient = IN.sh;
		//		#else
		//		giInput.ambient.rgb = 0.0;
		//		#endif
		//		giInput.probeHDR[0] = unity_SpecCube0_HDR;
		//		giInput.probeHDR[1] = unity_SpecCube1_HDR;
		//		#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
		//		giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
		//		#endif
		//		#if UNITY_SPECCUBE_BOX_PROJECTION
		//		giInput.boxMax[0] = unity_SpecCube0_BoxMax;
		//		giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
		//		giInput.boxMax[1] = unity_SpecCube1_BoxMax;
		//		giInput.boxMin[1] = unity_SpecCube1_BoxMin;
		//		giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
		//		#endif
		//		LightingLambert_GI(o, giInput, gi);

		//		// call lighting function to output g-buffer
		//		outEmission = LightingLambert_Deferred (o, gi, outDiffuse, outSpecSmoothness, outNormal);
		//		#ifndef UNITY_HDR_ON
		//		outEmission.rgb = exp2(-outEmission.rgb);
		//		#endif
		//		UNITY_OPAQUE_ALPHA(outDiffuse.a);
		//	}

		//	ENDCG

		//}

		//// ---- meta information extraction pass:
		//Pass {
		//	Name "Meta"
		//	Tags { "LightMode" = "Meta" }
		//	Cull Off

		//	CGPROGRAM
		//	// compile directives
		//	#pragma vertex vert_surf
		//	#pragma fragment frag_surf
		//	#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
		//	#include "HLSLSupport.cginc"
		//	#include "UnityShaderVariables.cginc"
		//	// Surface shader code generated based on:
		//	// writes to per-pixel normal: no
		//	// writes to emission: no
		//	// needs world space reflection vector: no
		//	// needs world space normal vector: no
		//	// needs screen space position: no
		//	// needs world space position: no
		//	// needs view direction: no
		//	// needs world space view direction: no
		//	// needs world space position for lighting: YES
		//	// needs world space view direction for lighting: no
		//	// needs world space view direction for lightmaps: no
		//	// needs vertex color: no
		//	// needs VFACE: no
		//	// passes tangent-to-world matrix to pixel shader: no
		//	// reads from normal: no
		//	// 1 texcoords actually used
		//	//   half2 _MainTex
		//	#define UNITY_PASS_META
		//	#include "UnityCG.cginc"
		//	#include "Lighting.cginc"

		//	#define INTERNAL_DATA
		//	#define WorldReflectionVector(data,normal) data.worldRefl
		//	#define WorldNormalVector(data,normal) normal

		//	// Original surface shader snippet:
		//	#line 12 ""
		//	#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
		//	#endif

		//	//#pragma surface surf Lambert noforwardadd

		//	sampler2D _MainTex;
		//	fixed4 _Color;

		//	struct Input {
		//		half2 uv_MainTex;
		//	};

		//	void surf (Input IN, inout SurfaceOutput o) {
		//		fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
		//		o.Albedo = c.rgb*_Color.rgb;
		//		//o.Alpha = c.a*_Color.a;
		//	}

		//	#include "UnityMetaPass.cginc"

		//	// vertex-to-fragment interpolation data
		//	struct v2f_surf {
		//		float4 pos : SV_POSITION;
		//		half2 pack0 : TEXCOORD0; // _MainTex
		//		float3 worldPos : TEXCOORD1;
		//	};
		//	float4 _MainTex_ST;

		//	// vertex shader
		//	v2f_surf vert_surf (appdata_full v) {
		//		v2f_surf o;
		//		UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
		//		o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);
		//		o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
		//		float3 worldPos = mul(_Object2World, v.vertex).xyz;
		//		fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
		//		o.worldPos = worldPos;
		//		return o;
		//	}

		//	// fragment shader
		//	fixed4 frag_surf (v2f_surf IN) : SV_Target {
		//		// prepare and unpack data
		//		Input surfIN;
		//		UNITY_INITIALIZE_OUTPUT(Input,surfIN);
		//		surfIN.uv_MainTex.x = 1.0;
		//		surfIN.uv_MainTex = IN.pack0.xy;
		//		float3 worldPos = IN.worldPos;
		//		#ifndef USING_DIRECTIONAL_LIGHT
		//		fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
		//		#else
		//		fixed3 lightDir = _WorldSpaceLightPos0.xyz;
		//		#endif
		//		#ifdef UNITY_COMPILER_HLSL
		//		SurfaceOutput o = (SurfaceOutput)0;
		//		#else
		//		SurfaceOutput o;
		//		#endif
		//		o.Albedo = 0.0;
		//		o.Emission = 0.0;
		//		o.Specular = 0.0;
		//		o.Alpha = 0.0;
		//		o.Gloss = 0.0;
		//		fixed3 normalWorldVertex = fixed3(0,0,1);

		//		// call surface function
		//		surf (surfIN, o);
		//		UnityMetaInput metaIN;
		//		UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);
		//		metaIN.Albedo = o.Albedo;
		//		metaIN.Emission = o.Emission;
		//		return UnityMetaFragment(metaIN);	
		//	}

		//	ENDCG

		//}

		// ---- end of surface shader generated code

		#LINE 29

		Pass
		{
			Name "ShadowCollector"
			Tags { "LightMode" = "ShadowCollector" }
		
			Fog {Mode Off}
			ZWrite On ZTest LEqual

			CGPROGRAM
	#line 36 ""
	#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
	#endif

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcollector

			#define SHADOW_COLLECTOR_PASS
			#include "UnityCG.cginc"

			struct appdata {
				float4 vertex : POSITION;
			};

			struct v2f {
				V2F_SHADOW_COLLECTOR;
			};

			v2f vert (appdata v)
			{
				v2f o;
				TRANSFER_SHADOW_COLLECTOR(o)
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				SHADOW_COLLECTOR_FRAGMENT(i)
			}
			ENDCG

			#LINE 65

		}
	}

	Fallback "TLStudio/Opaque/UnLit"
}