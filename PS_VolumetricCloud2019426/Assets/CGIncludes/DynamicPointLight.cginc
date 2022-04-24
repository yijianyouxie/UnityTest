//#if DYNAMIC_POINT_LIGHT
//
//struct BRDFData
//{
//	half3 diffuse;
//	half3 specular;
//	half perceptualRoughness;
//	half roughness;
//	half roughness2;
//	half grazingTerm;
//
//	// We save some light invariant BRDF terms so we don't have to recompute
//	// them in the light loop. Take a look at DirectBRDF function for detailed explaination.
//	half normalizationTerm;     // roughness * 4.0 + 2.0
//	half roughness2MinusOne;    // roughness² - 1.0
//};

int			_DynamicPointLightNum = 0;

float4x4	_WorldToLight[4];
float4		_PointLightPos[4];
fixed4		_PointLightColor[4];
float		_PointLightShakeFactor[4];

//-------------------------------------------------------------------------------------
int			_GlobalDynamicPointLightNum;
float4x4	_GlobalWorldToLight[4];
float4		_GlobalPointLightPos[4];
fixed4		_GlobalPointLightColor[4];
float		_GlobalPointLightShakeFactor[4];


int			_GlobalOrLocalDynamicPointLight;  // 1 is large, 0 not.
int			_DynamicPointLight;					//1 is true, 0 not.
//#define kDieletricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)
//#define FLT_EPSILON     1.192092896e-07 // Smallest positive number, such that 1.0 + FLT_EPSILON != 1.0
#define HALF_MIN 6.103515625e-5 


sampler2D_float _DynamicLightTexture0;
//float		_DynamicLightAttenuationArray[1023];

//#endif



//-------------------------------------------------------------------------------------
//custom lightweight fragment pbr.
//-------------------------------------------------------------------------------------

//#if DYNAMIC_POINT_LIGHT
//
//half DistanceAttenuation(half distanceSqr, half2 distanceAttenuation)
//{
//	// We use a shared distance attenuation for additional directional and puctual lights
//	// for directional lights attenuation will be 1
//	half lightAtten = rcp(distanceSqr);
//	half smoothFactor = saturate(distanceSqr * distanceAttenuation.x + distanceAttenuation.y);
//	return lightAtten * smoothFactor;
//}
//
//half AngleAttenuation(half3 spotDirection, half3 lightDirection, half2 spotAttenuation)
//{
//	// Spot Attenuation with a linear falloff can be defined as
//	// (SdotL - cosOuterAngle) / (cosInnerAngle - cosOuterAngle)
//	// This can be rewritten as
//	// invAngleRange = 1.0 / (cosInnerAngle - cosOuterAngle)
//	// SdotL * invAngleRange + (-cosOuterAngle * invAngleRange)
//	// SdotL * spotAttenuation.x + spotAttenuation.y
//
//	// If we precompute the terms in a MAD instruction
//	half SdotL = dot(spotDirection, lightDirection);
//	half atten = saturate(SdotL * spotAttenuation.x + spotAttenuation.y);
//
//	return lerp(atten * atten, 1, step(atten, 0.00001));
//	//return atten * atten;
//}
//
//// Based on Minimalist CookTorrance BRDF
//// Implementation is slightly different from original derivation: http://www.thetenthplanet.de/archives/255
////
//// * NDF [Modified] GGX
//// * Modified Kelemen and Szirmay-​Kalos for Visibility term
//// * Fresnel approximated with 1/LdotH
//half3 DirectBDRF(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS, half Intensity)
//{
//	//#ifndef _SPECULARHIGHLIGHTS_OFF
//	half3 halfDir = normalize(lightDirectionWS + viewDirectionWS);
//
//	half NoH = saturate(dot(normalWS, halfDir));
//	half LoH = saturate(dot(lightDirectionWS, halfDir));
//
//	// GGX Distribution multiplied by combined approximation of Visibility and Fresnel
//	// BRDFspec = (D * V * F) / 4.0
//	// D = roughness² / ( NoH² * (roughness² - 1) + 1 )²
//	// V * F = 1.0 / ( LoH² * (roughness + 0.5) )
//	// See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
//	// https://community.arm.com/events/1155
//
//	// Final BRDFspec = roughness² / ( NoH² * (roughness² - 1) + 1 )² * (LoH² * (roughness + 0.5) * 4.0)
//	// We further optimize a few light invariant terms
//	// brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
//	half d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001h;
//
//	half LoH2 = LoH * LoH;
//	half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);
//
//	// on mobiles (where half actually means something) denominator have risk of overflow
//	// clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
//	// sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
//#if defined (SHADER_API_MOBILE)
//	specularTerm = specularTerm - HALF_MIN;
//	specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
//#endif
//
//	half3 color = specularTerm * brdfData.specular*Intensity + brdfData.diffuse;
//	return color;
//	//#else
//	//	return brdfData.diffuse;
//	//#endif
//}
//
//
//half3 LightingPhysicallyBased(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS, half Intensity)
//{
//	half NdotL = saturate(dot(normalWS, lightDirectionWS));
//	half3 radiance = lightColor * (lightAttenuation * NdotL);
//	return DirectBDRF(brdfData, normalWS, lightDirectionWS, viewDirectionWS, Intensity) * radiance;
//}
//
//half OneMinusReflectivityMetallic(half metallic)
//{
//	// We'll need oneMinusReflectivity, so
//	//   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
//	// store (1-dielectricSpec) in kDieletricSpec.a, then
//	//   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
//	//                  = alpha - metallic * alpha
//	half oneMinusDielectricSpec = kDieletricSpec.a;
//	return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
//}
//
//half PerceptualSmoothnessToPerceptualRoughness(half perceptualSmoothness)
//{
//	return (1.0 - perceptualSmoothness);
//}
//
//
//inline void InitializeBRDFData(half3 albedo, half metallic, half3 specular, half smoothness, out BRDFData outBRDFData)
//{
//	half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
//	half reflectivity = 1.0 - oneMinusReflectivity;
//
//	outBRDFData.diffuse = albedo * oneMinusReflectivity;
//	outBRDFData.specular = lerp(kDieletricSpec.rgb, albedo, metallic);
//	outBRDFData.grazingTerm = saturate(smoothness + reflectivity);
//	outBRDFData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
//	outBRDFData.roughness = PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness);
//	outBRDFData.roughness2 = outBRDFData.roughness * outBRDFData.roughness;
//
//	outBRDFData.normalizationTerm = outBRDFData.roughness * 4.0h + 2.0h;
//	outBRDFData.roughness2MinusOne = outBRDFData.roughness2 - 1.0h;
//}
//
//half4 LightweightFragmentPBR(
//	int index,
//	half3 albedo, half metallic, half3 specular,
//	half smoothness,
//	half occlusion,
//	half3  gi_indirect,
//	half3 normalWS,
//	half3 viewDirectionWS,
//	float4 lightPositionWS,
//	half4 distanceAndSpotAttenuation,
//	fixed4 LightsColor,
//	float3 positionWS,
//	float ShakeFactor/*,
//	float4x4 _WorldToLight*/
//)
//{
//	BRDFData brdfData;
//	InitializeBRDFData(albedo, metallic, specular, smoothness, brdfData);
//	half3 color = half3(0, 0, 0);
//
//	float3 lightVector = lightPositionWS.xyz - positionWS;
//	float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);
//	half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));
//
//	float shakefactor = ShakeFactor;
//	float3 shakeOffset = float3(0, 0, 0);
//	shakeOffset.x = sin(_Time.z * shakefactor);
//	shakeOffset.y = sin(_Time.z * shakefactor + 5);
//	shakeOffset.z = cos(_Time.z * shakefactor + 7);
//	lightDirection += shakeOffset * 0.07;
//
//	lightDirection = normalize(lightDirection);
//
//	half attenuation = DistanceAttenuation(distanceSqr, distanceAndSpotAttenuation.xx*0.01);
//	attenuation *= AngleAttenuation(half4(0, 0, 0, 0),lightDirection,distanceAndSpotAttenuation.zw);
//
//	color += LightingPhysicallyBased(brdfData, LightsColor, lightDirection, attenuation, normalWS, viewDirectionWS, distanceAndSpotAttenuation.y);
//	return half4(color, 1);
//}

//#endif