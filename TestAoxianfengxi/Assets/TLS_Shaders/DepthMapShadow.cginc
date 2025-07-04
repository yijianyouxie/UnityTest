#ifndef DEPTH_MAP_SHADOW_COLOR_ATTEN  
#define DEPTH_MAP_SHADOW_COLOR_ATTEN 
 
 #include "UnityCG.cginc"   

uniform sampler2D _LightDepthTex;	 
uniform float4x4 _LightProjection;
uniform float _ShadowColorAtten;

uniform sampler2D _ProjectorDepthTex;	 
uniform float4x4 _ProjectorMatrix;

fixed CalculateFinalColorAtten(fixed textureDepth,fixed targetPosDepth,fixed targetPosY )
{  
	#ifndef DEPTH_MAP_SHADOW_COLOR_ATTEN
		return 1;
	#endif
	fixed currentDepth = 0;
    #if UNITY_UV_STARTS_AT_TOP
        currentDepth = targetPosDepth;
    #else
        currentDepth = targetPosDepth  * 0.5 + 0.5;
    #endif
	float depthMin = 0.01;
	float depthMax = 0.99;
	fixed isInRightTargetDepth = step(currentDepth,depthMax) * step(depthMin,currentDepth);
	fixed isInRightTextureDepth = step(textureDepth,depthMax) * step(depthMin,textureDepth);
	fixed isInShadowY = step(2.0,targetPosY);
    #if defined(UNITY_REVERSED_Z)
        fixed isInShadowDepth = step(currentDepth,textureDepth);
        return 1 -  _ShadowColorAtten*isInShadowDepth*isInShadowY*isInRightTargetDepth*isInRightTextureDepth; 
    #else
        fixed isInShadowDepth =  step(1-textureDepth,currentDepth);
        return 1 - _ShadowColorAtten*isInShadowDepth*isInShadowY*isInRightTargetDepth*isInRightTextureDepth; 
    #endif
}

fixed ShadowColorAtten(fixed4 worldPos)
{
    fixed4 lightSpacePos = mul(_LightProjection, worldPos);
    lightSpacePos.xyz = lightSpacePos.xyz / lightSpacePos.w;
    fixed4 depthRGBA = tex2D(_LightDepthTex, lightSpacePos.xy);
    fixed depth = DecodeFloatRG(depthRGBA.xy);
    return CalculateFinalColorAtten(depth,lightSpacePos.z,worldPos.y);
}

fixed ProjectorShadowColorAtten(fixed4 worldPos)
{
    fixed4 lightSpacePos = mul(_ProjectorMatrix, worldPos);
    lightSpacePos.xyz = lightSpacePos.xyz / lightSpacePos.w;
    fixed4 depthRGBA = tex2D(_ProjectorDepthTex, lightSpacePos.xy);
    fixed depth = depthRGBA.x;
	return CalculateFinalColorAtten(depth,lightSpacePos.z,worldPos.y);
}

#endif

