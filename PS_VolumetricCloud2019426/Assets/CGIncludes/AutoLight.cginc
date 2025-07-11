﻿// Upgrade NOTE: replaced 'defined _SHADOWS_PCF' with 'defined (_SHADOWS_PCF)'

// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef AUTOLIGHT_INCLUDED
#define AUTOLIGHT_INCLUDED

#include "HLSLSupport.cginc"
#include "UnityShadowLibrary.cginc"

// ----------------
//  Shadow helpers
// ----------------

// If none of the keywords are defined, assume directional?
#if !defined(POINT) && !defined(SPOT) && !defined(DIRECTIONAL) && !defined(POINT_COOKIE) && !defined(DIRECTIONAL_COOKIE)
    #define DIRECTIONAL
#endif

// ---- Screen space direction light shadows helpers (any version)
#if defined (SHADOWS_SCREEN)

    #if defined(UNITY_NO_SCREENSPACE_SHADOWS)
        UNITY_DECLARE_SHADOWMAP(_ShadowMapTexture);
        #define TRANSFER_SHADOW(a) a._ShadowCoord = mul( unity_WorldToShadow[0], mul( unity_ObjectToWorld, v.vertex ) );


#ifdef _SHADOWS_PCF
		float2 DepthGradient(float2 uv, float z)
		{
			float2 dz_duv = 0;

			float3 duvdist_dx = ddx(float3(uv, z));
			float3 duvdist_dy = ddy(float3(uv, z));

			dz_duv.x = duvdist_dy.y * duvdist_dx.z;
			dz_duv.x -= duvdist_dx.y * duvdist_dy.z;

			dz_duv.y = duvdist_dx.x * duvdist_dy.z;
			dz_duv.y -= duvdist_dy.x * duvdist_dx.z;

			float det = (duvdist_dx.x * duvdist_dy.y) - (duvdist_dx.y * duvdist_dy.x);
			dz_duv /= det;

			return dz_duv;
		}
		float BiasedZ(float z0, float2 dz_duv, float2 offset)
		{
			return z0 + dot(dz_duv, offset);
		}

		float4 _ShadowMapTexture_TexelSize;
		//int	   sample9;
#endif

		inline fixed unitySampleShadow(unityShadowCoord4 shadowCoord)
		{
#if defined(SHADOWS_NATIVE)
			fixed shadow = 0;

			/**
			for (int x = -1; x <= 1; ++x)
			{
				for (int y = -1; y <= 1; ++y)
				{
					shadow += UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + float2(x, y) * _ShadowMapTexture_TexelSize.xy, shadowCoord.z));
				}
			}

			shadow /= 9;
			*/
			/**

			shadowCoord.xy 已经过转换到0到1并且除过shadowCoord.w的
			shadowCoord.z也是除过shadowCoord.w的
				*/

#ifdef _SHADOWS_PCF

			//if(sample9 == 0)
			//{
				float4 attenuation4;
				float pixelOffset = 0.5f;
				float4 offset = float4(_ShadowMapTexture_TexelSize.x * pixelOffset, -_ShadowMapTexture_TexelSize.x * pixelOffset,
_ShadowMapTexture_TexelSize.y * pixelOffset, -_ShadowMapTexture_TexelSize.y * pixelOffset);

				attenuation4.x = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + float2(offset.x, offset.z), shadowCoord.z));
				attenuation4.y = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + float2(offset.x, offset.w), shadowCoord.z));
				attenuation4.z = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + float2(offset.y, offset.z), shadowCoord.z));
				attenuation4.w = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + float2(offset.y, offset.w), shadowCoord.z));
				shadow = dot(attenuation4, float(0.25));
			//}
			//else
			//{
				//float PCF_FILTER_STEP_COUNT = 2;
				//float filterRadiusUV = 1;

				//float2 stepUV = _ShadowMapTexture_TexelSize.xy;

				////float2 dz_duv = DepthGradient(shadowCoord.xy, shadowCoord.z);
				//for (float x = -PCF_FILTER_STEP_COUNT; x <= PCF_FILTER_STEP_COUNT; ++x)
				//{
				//	for (float y = -PCF_FILTER_STEP_COUNT; y <= PCF_FILTER_STEP_COUNT; ++y)
				//	{
				//		float2 offset = float2(x, y) * stepUV;
				//		float z = BiasedZ(shadowCoord.z, float2(0.01, 0.01), offset);
				//		shadow += UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + offset, z));;
				//	}
				//}

				//shadow /= 25;
			//}





#else
			shadow = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, shadowCoord.xyz);

#endif
			shadow = lerp(_LightShadowData.r, 1.0f, shadow);
			//shadow = _LightShadowData.r + shadow * (1 - _LightShadowData.r);
			return shadow;
            #else
                unityShadowCoord dist = SAMPLE_DEPTH_TEXTURE(_ShadowMapTexture, shadowCoord.xy);
                // tegra is confused if we use _LightShadowData.x directly
                // with "ambiguous overloaded function reference max(mediump float, float)"
                unityShadowCoord lightShadowDataX = _LightShadowData.x;
                unityShadowCoord threshold = shadowCoord.z;
                return max(dist > threshold, lightShadowDataX);
            #endif
        }

		inline fixed unitySampleShadow_Human(unityShadowCoord4 shadowCoord)
		{
#if defined(SHADOWS_NATIVE)
			fixed shadow = 0;
			/**
			for (int x = -1; x <= 1; ++x)
			{
				for (int y = -1; y <= 1; ++y)
				{
					shadow += UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + float2(x, y) * _ShadowMapTexture_TexelSize.xy, shadowCoord.z));
				}
			}
			shadow /= 9;
			*/
			/**
			shadowCoord.xy 已经过转换到0到1并且除过shadowCoord.w的
			shadowCoord.z也是除过shadowCoord.w的
				*/

#ifdef _SHADOWS_PCF

			//if(sample9 == 0)
			//{
			//	float uvOffset = 1;
			//	shadow += UNITY_SAMPLE_SHADOW(_ShadowMapTexture, shadowCoord.xyz);
			//	shadow += UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + float2(0, uvOffset) * _ShadowMapTexture_TexelSize.xy, shadowCoord.z));
			//	shadow += UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + float2(0, -uvOffset) * _ShadowMapTexture_TexelSize.xy, shadowCoord.z));
			//	shadow += UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + float2(uvOffset, 0) * _ShadowMapTexture_TexelSize.xy, shadowCoord.z));
			//	shadow += UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + float2(-uvOffset, 0) * _ShadowMapTexture_TexelSize.xy, shadowCoord.z));

			//	shadow /= 5;
			//	shadow = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, shadowCoord.xyz);
			//}
			//else
			//{

			// 移动端只做2x2采样
			#if defined(SHADER_API_MOBILE)
				
				float4 attenuation4;
				float pixelOffset = 0.5f;
				float4 offset = float4(_ShadowMapTexture_TexelSize.x * pixelOffset, -_ShadowMapTexture_TexelSize.x * pixelOffset,
_ShadowMapTexture_TexelSize.y * pixelOffset, -_ShadowMapTexture_TexelSize.y * pixelOffset);

				attenuation4.x = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + float2(offset.x, offset.z), shadowCoord.z));
				attenuation4.y = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + float2(offset.x, offset.w), shadowCoord.z));
				attenuation4.z = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + float2(offset.y, offset.z), shadowCoord.z));
				attenuation4.w = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + float2(offset.y, offset.w), shadowCoord.z));
				shadow = dot(attenuation4, float(0.25));
			#else
				float PCF_FILTER_STEP_COUNT = 2;
				float filterRadiusUV = 1;

				float2 stepUV = _ShadowMapTexture_TexelSize.xy;

				//float2 dz_duv = DepthGradient(shadowCoord.xy, shadowCoord.z);
				for (float x = -PCF_FILTER_STEP_COUNT; x <= PCF_FILTER_STEP_COUNT; ++x)
				{
					for (float y = -PCF_FILTER_STEP_COUNT; y <= PCF_FILTER_STEP_COUNT; ++y)
					{
						float2 offset = float2(x, y) * stepUV;
						float z = BiasedZ(shadowCoord.z, float2(0.01, 0.01), offset);
						shadow += UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float3(shadowCoord.xy + offset, z));
					}
				}

				shadow /= ((PCF_FILTER_STEP_COUNT*2+1) * (PCF_FILTER_STEP_COUNT*2+1));
			#endif
			//}
#else
			shadow = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, shadowCoord.xyz);
#endif
			shadow = lerp(_LightShadowData.r, 1.0f, shadow);
			//shadow = _LightShadowData.r + shadow * (1 - _LightShadowData.r);
			return shadow;
#else
			unityShadowCoord dist = SAMPLE_DEPTH_TEXTURE(_ShadowMapTexture, shadowCoord.xy);
			// tegra is confused if we use _LightShadowData.x directly
			// with "ambiguous overloaded function reference max(mediump float, float)"
			unityShadowCoord lightShadowDataX = _LightShadowData.x;
			unityShadowCoord threshold = shadowCoord.z;
			return max(dist > threshold, lightShadowDataX);
#endif
		}
    #else // UNITY_NO_SCREENSPACE_SHADOWS
        UNITY_DECLARE_SCREENSPACE_SHADOWMAP(_ShadowMapTexture);
        #define TRANSFER_SHADOW(a) a._ShadowCoord = ComputeScreenPos(a.pos);
        inline fixed unitySampleShadow (unityShadowCoord4 shadowCoord)
        {
            fixed shadow = UNITY_SAMPLE_SCREEN_SHADOW(_ShadowMapTexture, shadowCoord);
            return shadow;
        }

		inline fixed unitySampleShadow_Human(unityShadowCoord4 shadowCoord)
		{
			fixed shadow = UNITY_SAMPLE_SCREEN_SHADOW(_ShadowMapTexture, shadowCoord);
			return shadow;
		}

    #endif

    #define SHADOW_COORDS(idx1) unityShadowCoord4 _ShadowCoord : TEXCOORD##idx1;
    #define SHADOW_ATTENUATION(a) unitySampleShadow(a._ShadowCoord)
	#define SHADOW_ATTENUATION_HUMAN(a) unitySampleShadow_Human(a._ShadowCoord)
#endif

// -----------------------------
//  Shadow helpers (5.6+ version)
// -----------------------------
// This version depends on having worldPos available in the fragment shader and using that to compute light coordinates.
// if also supports ShadowMask (separately baked shadows for lightmapped objects)

half UnityComputeForwardShadows(float2 lightmapUV, float3 worldPos, float4 screenPos)
{
    //fade value
    float zDist = dot(_WorldSpaceCameraPos - worldPos, UNITY_MATRIX_V[2].xyz);
    float fadeDist = UnityComputeShadowFadeDistance(worldPos, zDist);
    half  realtimeToBakedShadowFade = UnityComputeShadowFade(fadeDist);

    //baked occlusion if any
    half shadowMaskAttenuation = saturate(UnitySampleBakedOcclusion(lightmapUV, worldPos) + _LightShadowData.x);

    half realtimeShadowAttenuation = 1.0f;
    //directional realtime shadow
    #if defined (SHADOWS_SCREEN)
        #if defined(UNITY_NO_SCREENSPACE_SHADOWS) && !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
            realtimeShadowAttenuation = unitySampleShadow(mul(unity_WorldToShadow[0], unityShadowCoord4(worldPos, 1)));
        #else
            //Only reached when LIGHTMAP_ON is NOT defined (and thus we use interpolator for screenPos rather than lightmap UVs). See HANDLE_SHADOWS_BLENDING_IN_GI below.
            realtimeShadowAttenuation = unitySampleShadow(screenPos);
        #endif
    #endif

    #if defined(UNITY_FAST_COHERENT_DYNAMIC_BRANCHING) && defined(SHADOWS_SOFT) && !defined(LIGHTMAP_SHADOW_MIXING)
    //avoid expensive shadows fetches in the distance where coherency will be good
    UNITY_BRANCH
    if (realtimeToBakedShadowFade < (1.0f - 1e-2f))
    {
    #endif

        //spot realtime shadow
        #if (defined (SHADOWS_DEPTH) && defined (SPOT))
            #if !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
                unityShadowCoord4 spotShadowCoord = mul(unity_WorldToShadow[0], unityShadowCoord4(worldPos, 1));
            #else
                unityShadowCoord4 spotShadowCoord = screenPos;
            #endif
            realtimeShadowAttenuation = UnitySampleShadowmap(spotShadowCoord);
        #endif

        //point realtime shadow
        #if defined (SHADOWS_CUBE)
            realtimeShadowAttenuation = UnitySampleShadowmap(worldPos - _LightPositionRange.xyz);
        #endif

    #if defined(UNITY_FAST_COHERENT_DYNAMIC_BRANCHING) && defined(SHADOWS_SOFT) && !defined(LIGHTMAP_SHADOW_MIXING)
    }
    #endif

    return UnityMixRealtimeAndBakedShadows(realtimeShadowAttenuation, shadowMaskAttenuation, realtimeToBakedShadowFade);
}

#if defined(SHADER_API_D3D11) || defined(SHADER_API_D3D12) || defined(SHADER_API_D3D11_9X) || defined(SHADER_API_XBOXONE) || defined(SHADER_API_PSSL)
#   define UNITY_SHADOW_W(_w) _w
#else
#   define UNITY_SHADOW_W(_w) (1.0/_w)
#endif

#if !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
#    define UNITY_READ_SHADOW_COORDS(input) 0
#else
#    define UNITY_READ_SHADOW_COORDS(input) READ_SHADOW_COORDS(input)
#endif

#if defined(HANDLE_SHADOWS_BLENDING_IN_GI) // handles shadows in the depths of the GI function for performance reasons
#   define UNITY_SHADOW_COORDS(idx1) SHADOW_COORDS(idx1)
#   define UNITY_TRANSFER_SHADOW(a, coord) TRANSFER_SHADOW(a)
#   define UNITY_SHADOW_ATTENUATION(a, worldPos) SHADOW_ATTENUATION(a)
#elif defined(SHADOWS_SCREEN) && !defined(LIGHTMAP_ON) && !defined(UNITY_NO_SCREENSPACE_SHADOWS) // no lightmap uv thus store screenPos instead
    // can happen if we have two directional lights. main light gets handled in GI code, but 2nd dir light can have shadow screen and mask.
    // - Disabled on DX9 as we don't get valid .zw in vpos
    // - Disabled on ES2 because WebGL 1.0 seems to have junk in .w (even though it shouldn't)
#   if defined(SHADOWS_SHADOWMASK) && !defined(SHADER_API_D3D9) && !defined(SHADER_API_GLES)
#       define UNITY_SHADOW_COORDS(idx1) unityShadowCoord4 _ShadowCoord : TEXCOORD##idx1;
#       define UNITY_TRANSFER_SHADOW(a, coord) {a._ShadowCoord.xy = coord * unity_LightmapST.xy + unity_LightmapST.zw; a._ShadowCoord.zw = ComputeScreenPos(a.pos).xy;}
#       define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(a._ShadowCoord.xy, worldPos, float4(a._ShadowCoord.zw, 0.0, UNITY_SHADOW_W(a.pos.w)));
#   else
#       define UNITY_SHADOW_COORDS(idx1) SHADOW_COORDS(idx1)
#       define UNITY_TRANSFER_SHADOW(a, coord) TRANSFER_SHADOW(a)
#       define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(0, worldPos, a._ShadowCoord)
#   endif
#else
#   if defined(SHADOWS_SHADOWMASK)
#       define UNITY_SHADOW_COORDS(idx1) unityShadowCoord4 _ShadowCoord : TEXCOORD##idx1;
#       define UNITY_TRANSFER_SHADOW(a, coord) a._ShadowCoord.xy = coord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#       if (defined(SHADOWS_DEPTH) || defined(SHADOWS_SCREEN) || defined(SHADOWS_CUBE) || UNITY_LIGHT_PROBE_PROXY_VOLUME)
#           define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(a._ShadowCoord.xy, worldPos, UNITY_READ_SHADOW_COORDS(a))
#       else
#           define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(a._ShadowCoord.xy, 0, 0)
#       endif
#   else
#       define UNITY_SHADOW_COORDS(idx1) SHADOW_COORDS(idx1)
#       if !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
#           define UNITY_TRANSFER_SHADOW(a, coord)
#       else
#           define UNITY_TRANSFER_SHADOW(a, coord) TRANSFER_SHADOW(a)
#       endif
#       if (defined(SHADOWS_DEPTH) || defined(SHADOWS_SCREEN) || defined(SHADOWS_CUBE))
#           define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(0, worldPos, UNITY_READ_SHADOW_COORDS(a))
#       else
#           if UNITY_LIGHT_PROBE_PROXY_VOLUME
#               define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(0, worldPos, UNITY_READ_SHADOW_COORDS(a))
#           else
#               define UNITY_SHADOW_ATTENUATION(a, worldPos) UnityComputeForwardShadows(0, 0, 0)
#           endif
#       endif
#   endif
#endif

#ifdef POINT
sampler2D_float _LightTexture0;
unityShadowCoord4x4 unity_WorldToLight;
#   define UNITY_LIGHT_ATTENUATION(destName, input, worldPos) \
        unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL * shadow;
#endif

#ifdef SPOT
sampler2D_float _LightTexture0;
unityShadowCoord4x4 unity_WorldToLight;
sampler2D_float _LightTextureB0;
inline fixed UnitySpotCookie(unityShadowCoord4 LightCoord)
{
    return tex2D(_LightTexture0, LightCoord.xy / LightCoord.w + 0.5).w;
}
inline fixed UnitySpotAttenuate(unityShadowCoord3 LightCoord)
{
    return tex2D(_LightTextureB0, dot(LightCoord, LightCoord).xx).UNITY_ATTEN_CHANNEL;
}
#if !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
#define DECLARE_LIGHT_COORD(input, worldPos) unityShadowCoord4 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1))
#else
#define DECLARE_LIGHT_COORD(input, worldPos) unityShadowCoord4 lightCoord = input._LightCoord
#endif
#   define UNITY_LIGHT_ATTENUATION(destName, input, worldPos) \
        DECLARE_LIGHT_COORD(input, worldPos); \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz) * shadow;
#endif

#ifdef DIRECTIONAL
#   define UNITY_LIGHT_ATTENUATION(destName, input, worldPos) fixed destName = UNITY_SHADOW_ATTENUATION(input, worldPos);
#endif

#ifdef POINT_COOKIE
samplerCUBE_float _LightTexture0;
unityShadowCoord4x4 unity_WorldToLight;
sampler2D_float _LightTextureB0;
#   if !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
#       define DECLARE_LIGHT_COORD(input, worldPos) unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz
#   else
#       define DECLARE_LIGHT_COORD(input, worldPos) unityShadowCoord3 lightCoord = input._LightCoord
#   endif
#   define UNITY_LIGHT_ATTENUATION(destName, input, worldPos) \
        DECLARE_LIGHT_COORD(input, worldPos); \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL * texCUBE(_LightTexture0, lightCoord).w * shadow;
#endif

#ifdef DIRECTIONAL_COOKIE
sampler2D_float _LightTexture0;
unityShadowCoord4x4 unity_WorldToLight;
#   if !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
#       define DECLARE_LIGHT_COORD(input, worldPos) unityShadowCoord2 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xy
#   else
#       define DECLARE_LIGHT_COORD(input, worldPos) unityShadowCoord2 lightCoord = input._LightCoord
#   endif
#   define UNITY_LIGHT_ATTENUATION(destName, input, worldPos) \
        DECLARE_LIGHT_COORD(input, worldPos); \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = tex2D(_LightTexture0, lightCoord).w * shadow;
#endif


// -----------------------------
//  Light/Shadow helpers (4.x version)
// -----------------------------
// This version computes light coordinates in the vertex shader and passes them to the fragment shader.

// ---- Spot light shadows
#if defined (SHADOWS_DEPTH) && defined (SPOT)
#define SHADOW_COORDS(idx1) unityShadowCoord4 _ShadowCoord : TEXCOORD##idx1;
#define TRANSFER_SHADOW(a) a._ShadowCoord = mul (unity_WorldToShadow[0], mul(unity_ObjectToWorld,v.vertex));
#define SHADOW_ATTENUATION(a) UnitySampleShadowmap(a._ShadowCoord)
#endif

// ---- Point light shadows
#if defined (SHADOWS_CUBE)
#define SHADOW_COORDS(idx1) unityShadowCoord3 _ShadowCoord : TEXCOORD##idx1;
#define TRANSFER_SHADOW(a) a._ShadowCoord.xyz = mul(unity_ObjectToWorld, v.vertex).xyz - _LightPositionRange.xyz;
#define SHADOW_ATTENUATION(a) UnitySampleShadowmap(a._ShadowCoord)
#define READ_SHADOW_COORDS(a) unityShadowCoord4(a._ShadowCoord.xyz, 1.0)
#endif

// ---- Shadows off
#if !defined (SHADOWS_SCREEN) && !defined (SHADOWS_DEPTH) && !defined (SHADOWS_CUBE)
#define SHADOW_COORDS(idx1)
#define TRANSFER_SHADOW(a)
#define SHADOW_ATTENUATION(a) 1.0
#define SHADOW_ATTENUATION_HUMAN(a) 1.0
#define READ_SHADOW_COORDS(a) 0
#else
#ifndef READ_SHADOW_COORDS
#define READ_SHADOW_COORDS(a) a._ShadowCoord
#endif
#endif

#ifdef POINT
#   if !defined (UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
#       define DECLARE_LIGHT_COORDS(idx)
#       define COMPUTE_LIGHT_COORDS(a)
#       define LIGHT_ATTENUATION(a)
#   else
#       define DECLARE_LIGHT_COORDS(idx) unityShadowCoord3 _LightCoord : TEXCOORD##idx;
#       define COMPUTE_LIGHT_COORDS(a) a._LightCoord = mul(unity_WorldToLight, mul(unity_ObjectToWorld, v.vertex)).xyz;
#       define LIGHT_ATTENUATION(a)    (tex2D(_LightTexture0, dot(a._LightCoord,a._LightCoord).rr).UNITY_ATTEN_CHANNEL * SHADOW_ATTENUATION(a))
#   endif
#endif

#ifdef SPOT
#   if !defined (UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
#       define DECLARE_LIGHT_COORDS(idx)
#       define COMPUTE_LIGHT_COORDS(a)
#       define LIGHT_ATTENUATION(a)
#   else
#       define DECLARE_LIGHT_COORDS(idx) unityShadowCoord4 _LightCoord : TEXCOORD##idx;
#       define COMPUTE_LIGHT_COORDS(a) a._LightCoord = mul(unity_WorldToLight, mul(unity_ObjectToWorld, v.vertex));
#       define LIGHT_ATTENUATION(a)    ( (a._LightCoord.z > 0) * UnitySpotCookie(a._LightCoord) * UnitySpotAttenuate(a._LightCoord.xyz) * SHADOW_ATTENUATION(a) )
#   endif
#endif

#ifdef DIRECTIONAL
#define DECLARE_LIGHT_COORDS(idx)
#define COMPUTE_LIGHT_COORDS(a)
#define LIGHT_ATTENUATION(a) SHADOW_ATTENUATION(a)
#define LIGHT_ATTENUATION_HUMAN(a) SHADOW_ATTENUATION_HUMAN(a)
#endif

#ifdef POINT_COOKIE
#   if !defined (UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
#       define DECLARE_LIGHT_COORDS(idx)
#       define COMPUTE_LIGHT_COORDS(a)
#       define LIGHT_ATTENUATION(a)
#   else
#       define DECLARE_LIGHT_COORDS(idx) unityShadowCoord3 _LightCoord : TEXCOORD##idx;
#       define COMPUTE_LIGHT_COORDS(a) a._LightCoord = mul(unity_WorldToLight, mul(unity_ObjectToWorld, v.vertex)).xyz;
#       define LIGHT_ATTENUATION(a)    (tex2D(_LightTextureB0, dot(a._LightCoord,a._LightCoord).rr).UNITY_ATTEN_CHANNEL * texCUBE(_LightTexture0, a._LightCoord).w * SHADOW_ATTENUATION(a))
#   endif
#endif

#ifdef DIRECTIONAL_COOKIE
#   if !defined (UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
#       define DECLARE_LIGHT_COORDS(idx)
#       define COMPUTE_LIGHT_COORDS(a)
#       define LIGHT_ATTENUATION(a)
#   else
#       define DECLARE_LIGHT_COORDS(idx) unityShadowCoord2 _LightCoord : TEXCOORD##idx;
#       define COMPUTE_LIGHT_COORDS(a) a._LightCoord = mul(unity_WorldToLight, mul(unity_ObjectToWorld, v.vertex)).xy;
#       define LIGHT_ATTENUATION(a)    (tex2D(_LightTexture0, a._LightCoord).w * SHADOW_ATTENUATION(a))
#   endif
#endif

#define UNITY_LIGHTING_COORDS(idx1, idx2) DECLARE_LIGHT_COORDS(idx1) UNITY_SHADOW_COORDS(idx2)
#define LIGHTING_COORDS(idx1, idx2) DECLARE_LIGHT_COORDS(idx1) SHADOW_COORDS(idx2)
#define UNITY_TRANSFER_LIGHTING(a, coord) COMPUTE_LIGHT_COORDS(a) UNITY_TRANSFER_SHADOW(a, coord)
#define TRANSFER_VERTEX_TO_FRAGMENT(a) COMPUTE_LIGHT_COORDS(a) TRANSFER_SHADOW(a)


#endif
