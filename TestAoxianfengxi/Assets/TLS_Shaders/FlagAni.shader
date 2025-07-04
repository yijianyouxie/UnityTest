//2021-01-11 美术反应如何使用顶点色改动的资源较多，改为使用坐标点,z轴顶部为0
//2021-01-08 不能使用uv，因为模型中的uv不一定从0-1区间，模型中使用的uv是一个大图中的一部分，改为使用顶点色alpha
//Z轴朝上，uv坐标的v从左下角开始
Shader "TLStudio/Transparent/Cutout_FlagAni"
{
	Properties
	{
		_Color("Color",Color) = (1.0, 1.0, 1.0, 1.0)
		_MainTex("Base (RGB)", 2D) = "white" {}
		_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
		_Frequence("频率",Float) = 1
		_Amplitude("振幅",Float) = 0.3
		_Speed("速度",Float) = 3
	}
	SubShader
	{
		Tags{ "Queue" = "AlphaTest+50" "IgnoreProjector" = "False" "RenderType" = "TransparentCutout" }
		LOD 200
		Cull Off


		// ------------------------------------------------------------
		// Surface shader code generated out of a CGPROGRAM block:


		// ---- forward rendering base pass:
		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }
			ColorMask RGBA

			CGPROGRAM
			#pragma skip_variants DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH VERTEXLIGHT_ON SHADOWS_CUBE
			// compile directives
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			//#pragma multi_compile GLOBALSH_DISABLE GLOBALSH_ENABLE
			#pragma multi_compile_fwdbase
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			//#pragma multi_compile_instancing

			//#pragma multi_compile _ INSTANCE_ENABLE
			#if defined(INSTANCE_ENABLE) && defined(LIGHTMAP_ON)
			#if defined(LIGHTPROBE_SH)
			#undef LIGHTPROBE_SH
			#endif
			#endif

			//#pragma multi_compile_fwdbase_fullshadows
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#define UNITY_PASS_FORWARDBASE
			#include "UnityCG.cginc"
			#include "Assets/TLS_Shaders/CGIncludes/Lighting.cginc"
			#include "Assets/TLS_Shaders/CGIncludes/AutoLight.cginc"


			#define INTERNAL_DATA
			#define WorldReflectionVector(data,normal) data.worldRefl
			#define WorldNormalVector(data,normal) normal

			// Original surface shader snippet:
			#line 14 ""
			#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
			#endif

			//#pragma surface surf Lambert noforwardadd alphatest:_Cutoff

			sampler2D _MainTex;
			fixed4 _Color;
			uniform float _Frequence;
			uniform float _Amplitude;
			uniform float _Speed;

			struct Input {
				half2 uv_MainTex;
			};

			void surf(Input IN, inout SurfaceOutput o) {
				fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
				o.Albedo = c.rgb*_Color.rgb;
				o.Alpha = c.a*_Color.a;
			}


			// vertex-to-fragment interpolation data
			#ifdef LIGHTMAP_OFF
			struct v2f_surf {
				float4 pos : SV_POSITION;
				half2 pack0 : TEXCOORD0;
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
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			#endif

			// with lightmaps:
			#ifndef LIGHTMAP_OFF
			struct v2f_surf {
				float4 pos : SV_POSITION;
				half2 pack0 : TEXCOORD0;
				half3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float4 lmap : TEXCOORD3;
				UNITY_SHADOW_COORDS(4)
				UNITY_FOG_COORDS(5)
	#ifdef GLOBALSH_ENABLE
				float3 vlighting : TEXCOORD6;
	#else
	#endif
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
	#endif

			float4 _MainTex_ST;
			fixed _Cutoff;

			float4 vertFlagAni(float4 vertex)
			{
				vertex.y = vertex.y + sin((vertex.z - _Time.y * _Speed) * _Frequence) * (vertex.z * _Amplitude);

				return vertex;
			}

			#if defined(INSTANCE_ENABLE) && defined(UNITY_INSTANCING_ENABLED) && defined(LIGHTMAP_ON)
					UNITY_INSTANCING_BUFFER_START(Props)
					UNITY_DEFINE_INSTANCED_PROP(fixed4, unity_LightmapST)
					UNITY_INSTANCING_BUFFER_END(Props)
			#endif

			// vertex shader
			v2f_surf vert_surf(appdata_full v) {
				v2f_surf o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
				v.vertex = vertFlagAni(v.vertex);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = worldPos;
				o.worldNormal = worldNormal;
		#ifndef DYNAMICLIGHTMAP_OFF
				o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
		#endif
		#ifndef LIGHTMAP_OFF
		#if defined(INSTANCE_ENABLE) && defined(UNITY_INSTANCING_ENABLED)
				unity_LightmapST = UNITY_ACCESS_INSTANCED_PROP(Props, unity_LightmapST);
		#endif
				o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		#endif

			// SH/ambient and vertex lights
		#ifdef LIGHTMAP_OFF
		#if UNITY_SHOULD_SAMPLE_SH
				o.sh = 0;
				// Approximated illumination from non-important point lights
		#ifdef VERTEXLIGHT_ON
				o.sh += Shade4PointLights(
					unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
					unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
					unity_4LightAtten0, worldPos, worldNormal);
		#endif
				o.sh = ShadeSHPerVertex(worldNormal, o.sh);
		#endif
		#endif // LIGHTMAP_OFF
		#ifdef GLOBALSH_ENABLE
				o.vlighting = ShadeSH9(float4(o.worldNormal, 1.0));
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
			fixed4 frag_surf(v2f_surf IN) : SV_Target{
				// prepare and unpack data
				Input surfIN;
				UNITY_SETUP_INSTANCE_ID(IN);
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


				// call surface function
				surf(surfIN, o);

				// alpha test
				clip(o.Alpha - _Cutoff);

				// compute lighting & shadowing factor
				UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
				//atten = 0.5;
				fixed4 c = 0;

				// Setup lighting environment
				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
		#if defined(LIGHTMAP_ON)
				gi.light.color = _LightColor0.rgb;
				gi.light.dir = lightDir*1.5;
				gi.light.ndotl = LambertTerm(o.Normal, gi.light.dir);
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

				c += LightingLambert(o, gi);

				//#ifdef GLOBALSH_ENABLE
				//  c.xyz = c.xyz*max(fixed3(1.0,1.0,1.0),(IN.vlighting - UNITY_LIGHTMODEL_AMBIENT.xyz)*2);
				//#endif
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(IN.fogCoord, c.rgb);
				}else
				{
					UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog				
				}
												 //UNITY_OPAQUE_ALPHA(c.a);
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
	}
		//Fallback "Transparent/Cutout/VertexLit"
}
