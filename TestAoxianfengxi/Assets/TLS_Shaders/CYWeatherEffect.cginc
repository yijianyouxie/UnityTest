// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

#ifndef CY_WEATHER_EFFECT_CGINC
#define CY_WEATHER_EFFECT_CGINC


#if defined (CYWEATHER_RAIN) || defined (CYWEATHER_SNOW)
	#define CYWEATHER_COMMON 1
#endif

	sampler2D _RainBubbleTexture;
	sampler2D _RainDistortTexture;
	samplerCUBE _RainEffectCube;
	sampler2D _SnowNoiseTexture;
	
	half4 _WeatherEffectControl;
	half4 _RainEffectParams;
	half4 _RainEffectParams2;
	fixed RainGroundIntensity;
	float3 _CustomLightDir;
	
	half4 _SnowColor;
	half4 _AlbedoMultiplyColor;
	
	half4 _WindControl;
	
inline float3 HandleSnowEffect(float3 finalColor, half horizon, float2 uv)
{
	float3 objSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz;
	half distance = length(objSpaceCameraPos) * 0.1;
	half noise = tex2D(_SnowNoiseTexture, uv * _RainEffectParams2.a);
	finalColor = lerp(finalColor, (_SnowColor.rgb + noise * _SnowColor.rgb * _RainEffectParams2.b), _WeatherEffectControl.b * (horizon));
	return finalColor;
}

inline float2 GenBubbleOffset(float2 uv)
{
	half4 bubbleNormal = tex2D(_RainBubbleTexture, uv * _RainEffectParams2.r);
    bubbleNormal.xy = bubbleNormal.xy * 2 - 1;
	float bubbleFrac = frac(bubbleNormal.w + _Time.x * _RainEffectParams2.g);
	float timeFrac = bubbleFrac - 1.0 + bubbleNormal.z;
	float dropFactor = saturate(_WeatherEffectControl.g - bubbleFrac);
	float finalFactor = dropFactor * bubbleNormal.z *  sin( clamp(timeFrac * 9.0f, 0.0f, 3.0f) * 3.1415);
	//float finalFactor = dropFactor * bubbleNormal.z *  sin( (timeFrac * 3.0f * 0.5 + 0.5) * 9.1415);
	float2 offset = bubbleNormal.xy * finalFactor;
	return offset;
}

inline half HandleBubbleDistort(float2 uv, inout float3 normal)
{
	half horizon = saturate(dot(normal, float3(0, 1, 0)));
#ifdef CYWEATHER_RAIN
	float2 offset1 = GenBubbleOffset(uv);
	//float2 offset2 = GenBubbleOffset(uv + float2(0.25, 0.25));
	//float2 offset = (offset1 + offset2);
	float3 n = normal;
	n.xy += offset1;
	normal = lerp(normal, n, horizon);
	normalize(normal);
#endif
	return horizon;
}

inline void HandleAlbedoScale(inout half3 albedo)
{
	albedo *= lerp(1.0, _RainEffectParams.r, _WeatherEffectControl.r) * _AlbedoMultiplyColor.rgb;
}

inline void HandleAlbedoDiffuse(inout half3 albedo, inout half3 indirectDiffuse, float3 viewDir, float3 normalDir)
{
	HandleAlbedoScale(albedo);
	indirectDiffuse *= lerp(1.0, (dot(normalDir, viewDir) * 0.5 + 0.5), _WeatherEffectControl.r);
}

inline half3 CaculateSpecular(float3 lightDir, float3 viewDir, float3 normalDir, half horizon, half3 albedo)
{
	half3 h = normalize (lightDir + viewDir);
	float nh = max (0, dot (normalDir, h));
    float spec = pow (nh, _RainEffectParams.g *128.0) * _RainEffectParams.b;
	half3 specColor = albedo * _WeatherEffectControl.g * spec;
	return specColor;
}

inline half3 CaculateDiffuse(float3 lightDir, float3 normalDir, half3 albedo, half3 lightColor)
{
	half diff = max (0, dot (normalDir, lightDir));
	return albedo * diff * lightColor;
}

inline half3 CaculateReflection(float3 viewDir, float3 normalDir, half horizon, half3 albedo)
{
	half3 reflectDir = reflect(-viewDir, normalDir);
	half4 cubemapValue = texCUBE (_RainEffectCube, reflectDir) * _RainEffectParams.a * horizon * _WeatherEffectControl.g;
	return cubemapValue.rgb * albedo;
}

inline fixed4 CustomLightingBlinnPhongReflection (SurfaceOutput s, half3 viewDir, UnityGI gi, half horizon)
{
	UnityLight light = gi.light;
	half3 lightDir = normalize(_CustomLightDir);

	half3 diffuseCol = 0;//CaculateDiffuse(lightDir, s.Normal, s.Albedo, light.color);
	//half3 reflectionCol = CaculateReflection(viewDir, s.Normal, horizon, s.Albedo);
	//half3 specCol = 0;//CaculateSpecular(lightDir, viewDir, s.Normal, horizon, s.Albedo);
   
    fixed4 c;
	c.rgb = diffuseCol;// + specCol + reflectionCol;
    c.a = s.Alpha;

    #ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
        c.rgb += s.Albedo * gi.indirect.diffuse;
    #endif

    return c;
}

inline fixed4 CustomLightingLambert(SurfaceOutput s, half3 viewDir, UnityGI gi, half horizon)
{
	UnityLight light = gi.light;
	half3 lightDir = normalize(_CustomLightDir);
   
    fixed4 c;
	c.rgb = CaculateDiffuse(lightDir, s.Normal, s.Albedo, light.color);
    c.a = s.Alpha;

    #ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
        c.rgb += s.Albedo * gi.indirect.diffuse;
    #endif

    return c;
}

inline fixed4 CustomLightingBlinnPhongPuddle (SurfaceOutput s, half3 worldPos, UnityGI gi, half horizon)
{
	UnityLight light = gi.light;
	float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
	half3 lightDir = normalize(_CustomLightDir);
	HandleAlbedoDiffuse(s.Albedo, gi.indirect.diffuse, viewDir, s.Normal);
	
	half3 diffuseCol = CaculateDiffuse(lightDir, s.Normal, s.Albedo, light.color);
	half3 specCol = CaculateSpecular(lightDir, viewDir, s.Normal, horizon, s.Albedo);
	
	half3 reflectDir = reflect(-viewDir, s.Normal);
	half4 cubemapValue = texCUBE (_RainEffectCube, reflectDir) * lerp(1.0, _RainEffectParams.r, _WeatherEffectControl.r);;
	cubemapValue.rgb = Luminance(cubemapValue.rgb);
	
    fixed4 c;
	c.rgb = diffuseCol + specCol + cubemapValue * 0.6;
    c.a = s.Alpha;

    #ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
        c.rgb += s.Albedo * gi.indirect.diffuse;
    #endif

    return c;
}

inline half3 HandleWeatherEffectBlinnPhongOnly(half3 color, SurfaceOutput s, float3 worldPos, fixed atten, half horizon)
{
#ifdef CYWEATHER_RAIN
	half3 lightDir = normalize(_CustomLightDir);
	float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
	half3 reflectionCol = CaculateReflection(viewDir, s.Normal, horizon, s.Albedo);
	half3 specCol = CaculateSpecular(lightDir, viewDir, s.Normal, horizon, s.Albedo);
	return color + specCol + reflectionCol;
#elif CYWEATHER_SNOW
	color = HandleSnowEffect(color, horizon, worldPos.xz);
	return color;
#endif
	return color;
}

inline half3 HandleWeatherEffect(half3 color, SurfaceOutput s, UnityGI gi, half horizon, float3 worldPos)
{
	float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
	HandleAlbedoDiffuse(s.Albedo, gi.indirect.diffuse, viewDir, s.Normal);
	return CustomLightingBlinnPhongReflection(s, viewDir, gi, horizon);
#ifdef CYWEATHER_RAIN
	color += CustomLightingBlinnPhongReflection(s, viewDir, gi, horizon);
#elif CYWEATHER_SNOW
	color += CustomLightingLambert(s, viewDir, gi, horizon);
	color = HandleSnowEffect(color, horizon, worldPos.xz);
#endif
	return color;
}

#endif // CY_WEATHER_EFFECT_CGINC
