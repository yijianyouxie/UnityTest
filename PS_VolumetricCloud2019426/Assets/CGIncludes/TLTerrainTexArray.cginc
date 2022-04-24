#ifndef TL_TERRAIN
#define TL_TERRAIN

#include "CGIncludes/DynamicPointLight.cginc"
#include "CGIncludes/UnityStandardBRDF.cginc"
sampler2D _FirstAlphaTex;
sampler2D _SecondAlphaTex;

half _Splat1_uvScale;
half _Splat2_uvScale;
half _Splat3_uvScale;
half _Splat4_uvScale;
half _Splat5_uvScale;
half _Splat6_uvScale;
half _Splat7_uvScale;
half _Splat8_uvScale;

half _Splat1_Metallic;
half _Splat2_Metallic;
half _Splat3_Metallic;
half _Splat4_Metallic;
half _Splat5_Metallic;
half _Splat6_Metallic;
half _Splat7_Metallic;
half _Splat8_Metallic;

float _NormalScale;

sampler2D _RainNormal;
float _rainIntensity;
float _rainSmoothness;
float _flowRate;
float _rainTiling;

struct Input 
{
	float2 uv_Control;	
	half4 fogCoord;
	float3 worldPos;
	fixed4 poweredNormal;
};

void vert(inout appdata_full v, out Input o) 
{
	UNITY_INITIALIZE_OUTPUT(Input, o);

	o.poweredNormal.w = mul(UNITY_MATRIX_MV, v.vertex).z;
	float4 oPos = UnityObjectToClipPos(v.vertex);
	TL_TRANSFER_FOG(o, oPos, v.vertex);
}

#ifdef V_T2M_STANDARD
void finalColor(Input IN, SurfaceOutputStandard o, inout fixed4 color)
#else
void finalColor(Input IN, SurfaceOutput o, inout fixed4 color)
#endif
{
	
	color *= o.Alpha;
	TL_APPLY_FOG(IN.fogCoord, color.rgb);
}
#ifdef V_T2M_STANDARD


#ifdef V_T2M_STANDARD
void finalColor_Simple(Input IN, SurfaceOutputStandard o, inout fixed4 color)
#else
void finalColor_Simple(Input IN, SurfaceOutput o, inout fixed4 color)
#endif
{
	TL_APPLY_FOG(IN.fogCoord, color.rgb);
}
#ifdef V_T2M_STANDARD

inline half3 FresnelTerm_Terrain(half3 F0, half cosA)
{
	half t = Pow5(1 - cosA); // ala Schlick interpoliation

	// 降低地形材质的fresnel效果，这样，平视地形时不会泛白
	return F0 + saturate(0.3 - F0) * t;
}

//half4 fillLightColor;
//
//// fillLightDir在SceneStandard里是通过vf里计算并传过来的世界坐标的法线，alpha通道存放了贴图的ao，主要是体现fillLight的法线细节，这部分计算在标准的Standard里没有，所以这里为0，所以将相关效果都注释掉，影响不大
//half4 fillLightDir;
//half4 _AOParam;
//half _MainLightSpecularIntensity;
//half3 _MainLightSpecularDirection;
// Main Physically Based BRDF
// Derived from Disney work and based on Torrance-Sparrow micro-facet model
//
//   BRDF = kD / pi + kS * (D * V * F) / 4
//   I = BRDF * NdotL
//
// * NDF (depending on UNITY_BRDF_GGX):
//  a) Normalized BlinnPhong
//  b) GGX
// * Smith for Visiblity term
// * Schlick approximation for Fresnel
half4 BRDF1_Unity_PBS_Terrain(half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
	float3 normal, float3 viewDir, UnityLight light, UnityIndirect gi)
{
	//return half4(smoothness, smoothness, smoothness,1);
	float perceptualRoughness = SmoothnessToPerceptualRoughness(smoothness);
	float3 halfDir = Unity_SafeNormalize(float3(light.dir) + viewDir);
	float3 halfDirCustom = Unity_SafeNormalize(_MainLightSpecularDirection + viewDir);

	// NdotV should not be negative for visible pixels, but it can happen due to perspective projection and normal mapping
	// In this case normal should be modified to become valid (i.e facing camera) and not cause weird artifacts.
	// but this operation adds few ALU and users may not want it. Alternative is to simply take the abs of NdotV (less correct but works too).
	// Following define allow to control this. Set it to 0 if ALU is critical on your platform.
	// This correction is interesting for GGX with SmithJoint visibility function because artifacts are more visible in this case due to highlight edge of rough surface
	// Edit: Disable this code by default for now as it is not compatible with two sided lighting used in SpeedTree.
#define UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV 0

#if UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV
	// The amount we shift the normal toward the view vector is defined by the dot product.
	half shiftAmount = dot(normal, viewDir);
	normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f) : normal;
	// A re-normalization should be applied here but as the shift is small we don't do it to save ALU.
	//normal = normalize(normal);

	half nv = saturate(dot(normal, viewDir)); // TODO: this saturate should no be necessary here
#else
	// 有可能是因为法线贴图错误导致计算出来的nv值是错的，导致后续在FresnelLerp (specColor, grazingTerm, nv)在ios或mac上能看到错误的白点，加上saturate之后白点消失
	half nv = saturate(abs(dot(normal, viewDir))); // This abs allow to limit artifact
#endif

	half nl = saturate(dot(normal, light.dir));
	half nlCustom = saturate(dot(normal, _MainLightSpecularDirection));
	//return float4(nlCustom, nlCustom, nlCustom, 1);
	float nh = saturate(dot(normal, halfDir));
	float nhCustom = saturate(dot(normal, halfDirCustom));

	half lv = saturate(dot(light.dir, viewDir));

	half lh = saturate(dot(light.dir, halfDir));
	float lhCustom = saturate(dot(_MainLightSpecularDirection, halfDirCustom));

	// Diffuse term
	half diffuseTerm = DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;
	// Specular term
	// HACK: theoretically we should divide diffuseTerm by Pi and not multiply specularTerm!
	// BUT 1) that will make shader look significantly darker than Legacy ones
	// and 2) on engine side "Non-important" lights have to be divided by Pi too in cases when they are injected into ambient SH
	float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
#if UNITY_BRDF_GGX
	// GGX with roughtness to 0 would mean no specular at all, using max(roughness, 0.002) here to match HDrenderloop roughtness remapping.
	roughness = max(roughness, 0.002);
	half V = SmithJointGGXVisibilityTerm(nlCustom, nv, roughness);
	float D = GGXTerm(nhCustom, roughness);
#else
	// Legacy
	half V = SmithBeckmannVisibilityTerm(nlCustom, nv, roughness);
	half D = NDFBlinnPhongNormalizedTerm(nhCustom, PerceptualRoughnessToSpecPower(perceptualRoughness));
#endif

	half specularTerm = V * D * UNITY_PI; // Torrance-Sparrow model, Fresnel is applied later

#ifdef UNITY_COLORSPACE_GAMMA
	specularTerm = sqrt(max(1e-4h, specularTerm));
#endif

	// specularTerm * nl can be NaN on Metal in some cases, use max() to make sure it's a sane value
	specularTerm = max(0, specularTerm * nlCustom);
#if defined(_SPECULARHIGHLIGHTS_OFF)
	specularTerm = 0.0;
#endif

	// surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(roughness^2+1)
	half surfaceReduction;
#ifdef UNITY_COLORSPACE_GAMMA
	surfaceReduction = 1.0 - 0.28 * roughness * perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
#else
	surfaceReduction = 1.0 / (roughness * roughness + 1.0); // fade \in [0.5;1]
#endif

// To provide true Lambert lighting, we need to be able to kill specular completely.这个在metallic workflow可以去掉，没有完全没有specColor的物体
//specularTerm *= any(specColor) ? 1.0 : 0.0;

	half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));

	fixed ao = pow(dot(min(gi.diffuse * _AOParam.x, 1), half3(0.2126, 0.7152, 0.0722)), _AOParam.y);
	// xwl 直接使用NL，不使用Disney，大概指令数能减少10条，效果差别很小
	// 加强间接光照体积感，使用模型法线作为光照方向来模拟天球光的阴影。
	//float3 ScaleGiDiffuse =  _GIDiffuseScale;
	//float3 indirect = saturate(dot(normal, fillLightDir.xyz));
	half3 color = diffColor * (gi.diffuse + light.color * nl /*diffuseTerm*/)
		+ specularTerm * light.color * FresnelTerm_Terrain(specColor, lhCustom) * _MainLightSpecularIntensity; //调整mainlight的高光强度

	//return float4(light.color * nl * diffColor, 1);
	color += surfaceReduction * gi.specular * FresnelLerp(specColor, grazingTerm, nv) * min(gi.diffuse, 1);

#ifndef POINT
	// 因为ao跟根据gi来计算的，而在fragForwardAddInternal传入的是ZeroIndirect，所以相当于没有ao，所以实时点光源不应该考虑ao
	//color *= ao;
	// 暂时实时点光源不考虑补光，因为补光的lightcolor没用点光源的_LightTexture0来计算衰减，会出现一个大方块
	//color += saturate(dot(normal, fillLightDir.xyz)) * fillLightColor * diffColor;
	//color += saturate(dot(normal, fillLightDir1.xyz)) * fillLightColor1 * diffColor;
	color += diffColor * fillLightColor;
#endif
	// color = specularTerm * FresnelTerm (specColor, lh) * light.color;
	//return half4(surfaceReduction * gi.specular * FresnelLerp (specColor, grazingTerm, nv),1);
	// 最终颜色乘上ao通道，让直接光也受ao影响，体积感更强
	//color *= fillLightDir.w;
	//color = ao;
	//color = min(gi.diffuse, 1);
	// 最后输出颜色强制裁剪，避免出现某些角度和材质的物体过亮过曝，而且目前RGBM的倍数是8
	color = clamp(color, 0, 16);
	return half4(color, 1);
}


	inline half4 LightingTerrain (SurfaceOutputStandard s, float3 worldPos,float3 viewDir, UnityGI gi)
	{
		s.Normal = normalize(s.Normal);

		half oneMinusReflectivity;
		half3 specColor;
		s.Albedo = DiffuseAndSpecularFromMetallic (s.Albedo, s.Metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

		// shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
		// this is necessary to handle transparency in physically correct way - only diffuse component gets affected by alpha
		half outputAlpha;
		s.Albedo = PreMultiplyAlpha (s.Albedo, s.Alpha, oneMinusReflectivity, /*out*/ outputAlpha);

		half4 c = TLSTUDIO_BRDF_PBS(s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect);


#if TLSTUDIO_BRDF_HIGH > 0
		if(_DynamicPointLight ==  1)
		{
			for (int index = 0; index < _GlobalDynamicPointLightNum; index++)
			{

				unityShadowCoord3 lightCoord = mul(_GlobalWorldToLight[index], unityShadowCoord4(worldPos, 1)).xyz;
				//fixed shadow = UNITY_SHADOW_ATTENUATION(i, worldPos);
				fixed attenpoint = tex2D(_DynamicLightTexture0, dot(lightCoord, lightCoord).rr).r;
				//int kkk = int(clamp(dot(lightCoord, lightCoord), 0, 1) * 1022);
				//float attenpoint = _DynamicLightAttenuationArray[kkk];

				float3 lightVector = _GlobalPointLightPos[index] - worldPos;
				float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);
				half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));

				float shakefactor = _GlobalPointLightShakeFactor[index];
				float3 shakeOffset = float3(0, 0, 0);
				shakeOffset.x = sin(_Time.z * shakefactor);
				shakeOffset.y = sin(_Time.z * shakefactor + 5);
				shakeOffset.z = cos(_Time.z * shakefactor + 7);
				lightDirection += shakeOffset * 0.07;


				UnityLight pointLight;
				pointLight.color = _GlobalPointLightColor[index];
				pointLight.dir = normalize(lightDirection);
				pointLight.color *= attenpoint;

				//c.rgb += fixed3(attenpoint, attenpoint, attenpoint);

				UnityIndirect noIndirect;
				noIndirect.diffuse = 0;
				noIndirect.specular = 0;
				//c.rgb += pointLight.color;
				//c.rgb+= float3(attenpoint, attenpoint, attenpoint);
				//c.rgb += LightweightFragmentPBR(index, o.Albedo, o.Metallic, specColor, o.Smoothness, o.Occlusion, gi.indirect.diffuse, worldN, -lightDir,
				//	_GlobalPointLightPos[index], half4(_GlobalPointLightRange[index], _GlobalPointLightIntensity[index], 1, 1), _GlobalPointLightColor[index], worldPos, _GlobalPointLightShakeFactor[index]);
				c.rgb += BRDF3_Unity_PBS_DPL(s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, pointLight, noIndirect).rgb;

			}
		}



#endif
		c.a = outputAlpha;
		return c;
	}

	inline void LightingTerrain_GI (SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
	{
	#if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
		gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal);
	#else
		Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.Smoothness, data.worldViewDir, s.Normal, lerp(unity_ColorSpaceDielectricSpec.rgb, s.Albedo, s.Metallic));
		gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal, g);
	#endif
	}
#else

	inline fixed4 LightingTerrain (SurfaceOutput s, UnityGI gi)
	{
		fixed4 c;
		c = UnityLambertLight (s, gi.light);

		#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
			c.rgb += s.Albedo * gi.indirect.diffuse;
		#endif

		return c;
	}

	inline void LightingTerrain_GI (
		SurfaceOutput s,
		UnityGIInput data,
		inout UnityGI gi)
	{
		gi = UnityGlobalIllumination (data, 1.0, s.Normal);
	}

#endif

half4 GetTriPlanarBlend(sampler2D tex, float3 worldPos, fixed3 blending, half tilling) 
{   
	half4 xUV = tex2D(tex,worldPos.zy * tilling);
	half4 yUV = tex2D(tex,worldPos.xz * tilling);
	half4 zUV = tex2D(tex,worldPos.xy * tilling);
	half4 blendCol = xUV * blending.x + yUV * blending.y +zUV * blending.z;
	return blendCol;
}

UNITY_DECLARE_TEX2DARRAY(_Tex2DArray);
UNITY_DECLARE_TEX2DARRAY(_Normal2DArray);

#ifdef V_T2M_STANDARD
void surf (Input IN, inout SurfaceOutputStandard o)
#else
void surf (Input IN, inout SurfaceOutput o) 
#endif
{
	half4 splat_control = tex2D (_FirstAlphaTex, IN.uv_Control);

	half weight = dot(splat_control, half4(1, 1, 1, 1));

	// Normalize weights before lighting and restore weights in final modifier functions so that the overal
	// lighting result can be correctly weighted.
	splat_control /= (weight + 1e-3f);

	fixed4 mainTex = splat_control.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat1_uvScale, 0));
	mainTex += splat_control.g * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat2_uvScale, 1));
	mainTex += splat_control.b * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat3_uvScale, 2));
	mainTex += splat_control.a * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat4_uvScale, 3));
	


	o.Albedo = mainTex.rgb;

	#ifdef V_T2M_STANDARD

	fixed4 nrm = 0.0f;
	nrm = splat_control.r * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat1_uvScale, 0));
	nrm += splat_control.g * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat2_uvScale, 1));
	nrm += splat_control.b * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat3_uvScale, 2));
	nrm += splat_control.a * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat4_uvScale, 3));


	half4 t_Splat_Metallic = half4(_Splat1_Metallic, _Splat2_Metallic, _Splat3_Metallic, _Splat4_Metallic);
	half metallic = dot(splat_control, t_Splat_Metallic);
	//metallic += splat_control.r * _Splat1_Metallic;
	//metallic += splat_control.g * _Splat2_Metallic;
	//metallic += splat_control.b * _Splat3_Metallic;
	//metallic += splat_control.a * _Splat4_Metallic;


	o.Normal = UnpackScaleNormal(nrm,_NormalScale);
	o.Normal = normalize(o.Normal);

	o.Metallic = metallic;
	o.Smoothness = mainTex.a;
	#endif



	o.Alpha = weight;
}


#ifdef V_T2M_STANDARD
void surf_second(Input IN, inout SurfaceOutputStandard o)
#else
void surf_second(Input IN, inout SurfaceOutput o)
#endif
{
	
	half4 secondCtrol = tex2D(_SecondAlphaTex, IN.uv_Control);

	half weight = dot(secondCtrol, half4(1, 1, 1, 1));

	// Normalize weights before lighting and restore weights in final modifier functions so that the overal
	// lighting result can be correctly weighted.
	secondCtrol /= (weight + 1e-3f);

	fixed4 mainTex = fixed4(0, 0, 0, 0);
#if _LAYER_FIVE
	mainTex += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
#elif _LAYER_SIX
	mainTex += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	mainTex += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
#elif _LAYER_SEVEN
	mainTex += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	mainTex += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
	mainTex += secondCtrol.b * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat7_uvScale, 6));
#elif _LAYER_EIGHT
	mainTex += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	mainTex += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
	mainTex += secondCtrol.b * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat7_uvScale, 6));
	mainTex += secondCtrol.a * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat8_uvScale, 7));
#endif
	o.Albedo = mainTex.rgb;

#ifdef V_T2M_STANDARD

	fixed4 nrm = 0.0f;

	//half metallic = 0;
	half4 t_Splat_Metallic = half4(_Splat5_Metallic, _Splat6_Metallic, _Splat7_Metallic, _Splat8_Metallic);
#if _LAYER_FIVE
	nrm += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	//metallic += secondCtrol.r * _Splat5_Metallic;
#elif _LAYER_SIX
	nrm += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	nrm += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
	//metallic += secondCtrol.r * _Splat5_Metallic;
	//metallic += secondCtrol.g * _Splat6_Metallic;
#elif _LAYER_SEVEN
	nrm += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	nrm += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
	nrm += secondCtrol.b * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat7_uvScale, 6));
	//metallic += secondCtrol.r * _Splat5_Metallic;
	//metallic += secondCtrol.g * _Splat6_Metallic;
	//metallic += secondCtrol.b * _Splat7_Metallic;
#elif _LAYER_EIGHT
	nrm += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	nrm += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
	nrm += secondCtrol.b * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat7_uvScale, 6));
	nrm += secondCtrol.a * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat8_uvScale, 7));
	//metallic += secondCtrol.r * _Splat5_Metallic;
	//metallic += secondCtrol.g * _Splat6_Metallic;
	//metallic += secondCtrol.b * _Splat7_Metallic;
	//metallic += secondCtrol.a * _Splat8_Metallic;
#endif
	half metallic = dot(secondCtrol, t_Splat_Metallic);
	o.Normal = UnpackScaleNormal(nrm, _NormalScale);
	o.Normal = normalize(o.Normal);

	o.Metallic = metallic;
	o.Smoothness = mainTex.a;
#endif



	o.Alpha = weight;
}

#endif



#ifdef V_T2M_STANDARD
void surf_Simple(Input IN, inout SurfaceOutputStandard o)
#else
void surf_Simple(Input IN, inout SurfaceOutput o)
#endif
{
	half4 splat_control = tex2D(_FirstAlphaTex, IN.uv_Control);
	half4 secondCtrol = tex2D(_SecondAlphaTex, IN.uv_Control);

	fixed4 mainTex = splat_control.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat1_uvScale, 0));
	mainTex += splat_control.g * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat2_uvScale, 1));
	mainTex += splat_control.b * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat3_uvScale, 2));
	mainTex += splat_control.a * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat4_uvScale, 3));

#if _LAYER_FIVE
	mainTex += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
#elif _LAYER_SIX
	mainTex += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	mainTex += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
#elif _LAYER_SEVEN
	mainTex += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	mainTex += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
	mainTex += secondCtrol.b * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat7_uvScale, 6));
#elif _LAYER_EIGHT
	mainTex += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	mainTex += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
	mainTex += secondCtrol.b * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat7_uvScale, 6));
	mainTex += secondCtrol.a * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat8_uvScale, 7));
#endif
	o.Albedo = mainTex.rgb;

#ifdef V_T2M_STANDARD

	fixed4 nrm = 0.0f;
	nrm = splat_control.r * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat1_uvScale, 0));
	nrm += splat_control.g * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat2_uvScale, 1));
	nrm += splat_control.b * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat3_uvScale, 2));
	nrm += splat_control.a * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat4_uvScale, 3));

	half metallic = 0;
	metallic += splat_control.r * _Splat1_Metallic;
	metallic += splat_control.g * _Splat2_Metallic;
	metallic += splat_control.b * _Splat3_Metallic;
	metallic += splat_control.a * _Splat4_Metallic;

#if _LAYER_FIVE
	nrm += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	metallic += secondCtrol.r * _Splat5_Metallic;
#elif _LAYER_SIX
	nrm += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	nrm += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
	metallic += secondCtrol.r * _Splat5_Metallic;
	metallic += secondCtrol.g * _Splat6_Metallic;
#elif _LAYER_SEVEN
	nrm += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	nrm += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
	nrm += secondCtrol.b * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat7_uvScale, 6));
	metallic += secondCtrol.r * _Splat5_Metallic;
	metallic += secondCtrol.g * _Splat6_Metallic;
	metallic += secondCtrol.b * _Splat7_Metallic;
#elif _LAYER_EIGHT
	nrm += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	nrm += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
	nrm += secondCtrol.b * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat7_uvScale, 6));
	nrm += secondCtrol.a * UNITY_SAMPLE_TEX2DARRAY(_Normal2DArray, half3(IN.uv_Control * _Splat8_uvScale, 7));
	metallic += secondCtrol.r * _Splat5_Metallic;
	metallic += secondCtrol.g * _Splat6_Metallic;
	metallic += secondCtrol.b * _Splat7_Metallic;
	metallic += secondCtrol.a * _Splat8_Metallic;
#endif

	o.Normal = UnpackScaleNormal(nrm, _NormalScale);
	o.Normal = normalize(o.Normal);

	o.Metallic = metallic;
	o.Smoothness = mainTex.a;
#endif



	o.Alpha = 1.0;
}



#ifdef V_T2M_STANDARD
void surf_Simple_NoNormal(Input IN, inout SurfaceOutputStandard o)
#else
void surf_Simple_NoNormal(Input IN, inout SurfaceOutput o)
#endif
{
	half4 splat_control = tex2D(_FirstAlphaTex, IN.uv_Control);
	half4 secondCtrol = tex2D(_SecondAlphaTex, IN.uv_Control);

	fixed4 mainTex = splat_control.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat1_uvScale, 0));
	mainTex += splat_control.g * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat2_uvScale, 1));
	mainTex += splat_control.b * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat3_uvScale, 2));
	mainTex += splat_control.a * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat4_uvScale, 3));

#if _LAYER_FIVE
	mainTex += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
#elif _LAYER_SIX
	mainTex += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	mainTex += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
#elif _LAYER_SEVEN
	mainTex += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	mainTex += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
	mainTex += secondCtrol.b * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat7_uvScale, 6));
#elif _LAYER_EIGHT
	mainTex += secondCtrol.r * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat5_uvScale, 4));
	mainTex += secondCtrol.g * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat6_uvScale, 5));
	mainTex += secondCtrol.b * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat7_uvScale, 6));
	mainTex += secondCtrol.a * UNITY_SAMPLE_TEX2DARRAY(_Tex2DArray, half3(IN.uv_Control * _Splat8_uvScale, 7));
#endif
	o.Albedo = mainTex.rgb;

#ifdef V_T2M_STANDARD

	half metallic = 0;
	metallic += splat_control.r * _Splat1_Metallic;
	metallic += splat_control.g * _Splat2_Metallic;
	metallic += splat_control.b * _Splat3_Metallic;
	metallic += splat_control.a * _Splat4_Metallic;

#if _LAYER_FIVE
	metallic += secondCtrol.r * _Splat5_Metallic;
#elif _LAYER_SIX
	metallic += secondCtrol.r * _Splat5_Metallic;
	metallic += secondCtrol.g * _Splat6_Metallic;
#elif _LAYER_SEVEN
	metallic += secondCtrol.r * _Splat5_Metallic;
	metallic += secondCtrol.g * _Splat6_Metallic;
	metallic += secondCtrol.b * _Splat7_Metallic;
#elif _LAYER_EIGHT
	metallic += secondCtrol.r * _Splat5_Metallic;
	metallic += secondCtrol.g * _Splat6_Metallic;
	metallic += secondCtrol.b * _Splat7_Metallic;
	metallic += secondCtrol.a * _Splat8_Metallic;
#endif

	o.Metallic = metallic;
	o.Smoothness = mainTex.a;
#endif



	o.Alpha = 1.0;
}

#endif