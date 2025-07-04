#ifndef BLEND_LIGHTMAP_INCLUDED
#define BLEND_LIGHTMAP_INCLUDED

#include "HLSLSupport.cginc"
#include "UnityCG.cginc"

// Lightmaps

// Main lightmap
UNITY_DECLARE_TEX2D_HALF(_TargetLightmap);
// Directional lightmap (always used with unity_Lightmap, so can share sampler)
UNITY_DECLARE_TEX2D_NOSAMPLER_HALF(_TargetLightmapInd);
// Combined light masks
#if defined (SHADOWS_SHADOWMASK)
    #if defined(LIGHTMAP_ON)
        //Can share sampler if lightmap are used.
        UNITY_DECLARE_TEX2D_NOSAMPLER(_TargetShadowMask);
    #else
        UNITY_DECLARE_TEX2D(_TargetShadowMask);
    #endif
#endif

fixed _LightmapLerp;
fixed _UseLightmapLerp;

inline half3 BlendLightmap(half3 sourceBakedColor, float2 lightmapUV)
{
    // return sourceBakedColor;
    half4 targetBakedColorTex = UNITY_SAMPLE_TEX2D(_TargetLightmap, lightmapUV);
    half3 targetBakedColor = DecodeLightmap(targetBakedColorTex);

    half3 lerpBakedColor = lerp(sourceBakedColor, targetBakedColor, _LightmapLerp);
    return lerp(sourceBakedColor, lerpBakedColor, _UseLightmapLerp);
}

inline fixed4 BlendLightmapInd(fixed4 sourceBakedDirTex, float2 lightmapUV)
{
    // return sourceBakedDirTex;
    fixed4 targetBakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER (_TargetLightmapInd, _TargetLightmap, lightmapUV);
    fixed4 lerpBakedDirTex = lerp(sourceBakedDirTex, targetBakedDirTex, _LightmapLerp);
    return lerp(sourceBakedDirTex, lerpBakedDirTex, _UseLightmapLerp);
}

#if defined (SHADOWS_SHADOWMASK)
    inline fixed4 BlendShadowMask(fixed4 sourceRawOcclusionMask, float2 lightmapUV)
    {
        // return sourceRawOcclusionMask;
        #if defined(LIGHTMAP_ON)
            fixed4 targetRawOcclusionMask = UNITY_SAMPLE_TEX2D_SAMPLER(_TargetShadowMask, _TargetLightmap, lightmapUV);
        #else
            fixed4 targetRawOcclusionMask = UNITY_SAMPLE_TEX2D(_TargetShadowMask, lightmapUV);
        #endif
    
        fixed4 lerpBakedDirTex = lerp(sourceRawOcclusionMask, targetRawOcclusionMask, _LightmapLerp);
        return lerp(sourceRawOcclusionMask, lerpBakedDirTex, _UseLightmapLerp);
    }
#endif


#endif
