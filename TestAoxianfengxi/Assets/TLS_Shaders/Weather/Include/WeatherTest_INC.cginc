#ifndef WEATHER_TEST_INC_INCLUDE  
#define WEATHER_TEST_INC_INCLUDE  

	#ifndef VAR_TINT_COLOR_NEED_4_PBR
	#define VAR_TINT_COLOR_NEED_4_PBR
	#endif 
	
	//#ifndef VAR_TINT_COLOR_FAKENOR
	//#define VAR_TINT_COLOR_FAKENOR
	//#endif
	
	#ifndef TINT_PBR
	#define TINT_PBR
	#endif
	
	#include "UnityStandardCore.cginc"  
	#include "TintColor.cginc"
	#include "NoiseAndDecal.cginc"
	#include "Volume_Fog.cginc"
	
	VertexOutputForwardBase vertForwardBase_Weather (VertexInput v)         
	{
		UNITY_SETUP_INSTANCE_ID(v);
		VertexOutputForwardBase o;
		UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBase, o);
		UNITY_TRANSFER_INSTANCE_ID(v, o);
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

		float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
		#if UNITY_REQUIRE_FRAG_WORLDPOS
			#if UNITY_PACK_WORLDPOS_WITH_TANGENT
				o.tangentToWorldAndPackedData[0].w = posWorld.x;
				o.tangentToWorldAndPackedData[1].w = posWorld.y;
				o.tangentToWorldAndPackedData[2].w = posWorld.z;
			#else
				o.posWorld = posWorld.xyz;
			#endif
		#endif
		o.pos = UnityObjectToClipPos(v.vertex);

		o.tex = TexCoords(v);
		o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
		float3 normalWorld = UnityObjectToWorldNormal(v.normal);
		#ifdef _TANGENT_TO_WORLD
			float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

			float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
			o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
			o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
			o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
		#else
			o.tangentToWorldAndPackedData[0].xyz = 0;
			o.tangentToWorldAndPackedData[1].xyz = 0;
			o.tangentToWorldAndPackedData[2].xyz = normalWorld; 
		#endif

		//We need this for shadow receving
		UNITY_TRANSFER_SHADOW(o, v.uv1);

		o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);

		#ifdef _PARALLAXMAP
			TANGENT_SPACE_ROTATION;
			half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
			o.tangentToWorldAndPackedData[0].w = viewDirForParallax.x;
			o.tangentToWorldAndPackedData[1].w = viewDirForParallax.y;
			o.tangentToWorldAndPackedData[2].w = viewDirForParallax.z;
		#endif

		if(UseHeightFog > 0)
		{
			TL_TRANSFER_FOG(o,o.pos, v.vertex);
		}else
		{
			UNITY_TRANSFER_FOG(o,o.pos);		
		}
		return o;
	}
	
	half4 fragForwardBaseInternal_Weather (VertexOutputForwardBase i) 
	{
		FRAGMENT_SETUP(s)

		UNITY_SETUP_INSTANCE_ID(i);
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i); 

		UnityLight mainLight = MainLight ();
		UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);

		half occlusion = Occlusion(i.tex.xy);
		UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, mainLight);

		if (RAIN_ENABLE > 0)
		{
			//法线扰动
			s.normalWorld = NOISE_NOR_RECAL_UP_2_DOWN(s.posWorld,s.normalWorld)
			//return OutputForward (half4(s.normalWorld.xyz,1), s.alpha);
		}
		
		if (TINT_ENABLE > 0)
		{
			//TINT_CAL_COLOR_MASK_DOT_GRAYSCALE_AUTO_UV_CENTER_POS_BLEND(s.posWorld ,s.normalWorld,s.diffColor.rgb)
			STRUCT_TINT_4_PBR tintInput;
			tintInput.finalColorPBR = s.diffColor.rgb;
			tintInput.metallicAndSmoothness = float2(_Metallic,_Glossiness);
			tintInput.tintNormal = s.normalWorld;
			tintInput.tangentToWorld4Tint = i.tangentToWorldAndPackedData;
			TINT_CAL_COLOR_MASK_UP_BLEND_ALPHA_4_PBR_NOR(i.tex.xy ,s.normalWorld,tintInput) 
			s.diffColor = tintInput.finalColorPBR;
			s.smoothness = tintInput.metallicAndSmoothness.y;
			s.normalWorld = tintInput.tintNormal;
			//TINT_CAL_COLOR_MASK_UP_BLEND(i.tex.xy ,s.normalWorld,s.diffColor.rgb)
		}
		
		half4 c = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
		c.rgb += Emission(i.tex.xy);

		VOLUME_FOG_COLOR(s.posWorld,c.rgb)
		if(UseHeightFog > 0)
		{
			TL_APPLY_FOG(i.fogCoord, c.rgb.rgb);
		}else
		{
			UNITY_APPLY_FOG(i.fogCoord, c.rgb);		
		}
		return OutputForward (c, s.alpha);
	}
	
    VertexOutputForwardBase vertBase (VertexInput v) { return vertForwardBase_Weather(v); }
	half4 fragBase (VertexOutputForwardBase i) : SV_Target { return fragForwardBaseInternal_Weather(i); }	
	
#endif
