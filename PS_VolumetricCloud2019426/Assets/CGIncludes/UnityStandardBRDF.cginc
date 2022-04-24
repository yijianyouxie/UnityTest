// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef UNITY_STANDARD_BRDF_INCLUDED
    #define UNITY_STANDARD_BRDF_INCLUDED

    #include "UnityCG.cginc"
    #include "CGIncludes/UnityStandardConfig.cginc"
    #include "UnityLightingCommon.cginc"

    //-----------------------------------------------------------------------------
    // Helper to convert smoothness to roughness
    //-----------------------------------------------------------------------------
    //fixed _GIDiffuseScale;
    float PerceptualRoughnessToRoughness(float perceptualRoughness)
    {
        return perceptualRoughness * perceptualRoughness;
    }

    half RoughnessToPerceptualRoughness(half roughness)
    {
        return sqrt(roughness);
    }

    // Smoothness is the user facing name
    // it should be perceptualSmoothness but we don't want the user to have to deal with this name
    half SmoothnessToRoughness(half smoothness)
    {
        return (1 - smoothness) * (1 - smoothness);
    }

    float SmoothnessToPerceptualRoughness(float smoothness)
    {
        return (1 - smoothness);
    }

    //-------------------------------------------------------------------------------------

    inline half Pow4 (half x)
    {
        return x*x*x*x;
    }

    inline float2 Pow4 (float2 x)
    {
        return x*x*x*x;
    }

    inline half3 Pow4 (half3 x)
    {
        return x*x*x*x;
    }

    inline half4 Pow4 (half4 x)
    {
        return x*x*x*x;
    }

    // Pow5 uses the same amount of instructions as generic pow(), but has 2 advantages:
    // 1) better instruction pipelining
    // 2) no need to worry about NaNs
    inline half Pow5 (half x)
    {
        return x*x * x*x * x;
    }

    inline half2 Pow5 (half2 x)
    {
        return x*x * x*x * x;
    }

    inline half3 Pow5 (half3 x)
    {
        return x*x * x*x * x;
    }

    inline half4 Pow5 (half4 x)
    {
        return x*x * x*x * x;
    }

    inline half3 FresnelTerm (half3 F0, half cosA)
    {
    half t = Pow5(1 - cosA); // ala Schlick interpoliation
    
    // 降低地形材质的fresnel效果，这样，平视地形时不会泛白
    #if defined(_LAYER_FOUR) || defined(_LAYER_FIVE) || defined(_LAYER_SIX) || defined(_LAYER_SEVEN) || defined(_LAYER_EIGHT)    
        return F0 + saturate(0.3 - F0) * t;
    #else
        return F0 + (1 - F0) * t;
    #endif
    }
    inline half3 FresnelLerp (half3 F0, half3 F90, half cosA)
    {
        half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
        return lerp (F0, F90, t);
    }
    // approximage Schlick with ^4 instead of ^5
    inline half3 FresnelLerpFast (half3 F0, half3 F90, half cosA)
    {
        half t = Pow4 (1 - cosA);
        return lerp (F0, F90, t);
    }

    // Note: Disney diffuse must be multiply by diffuseAlbedo / PI. This is done outside of this function.
    half DisneyDiffuse(half NdotV, half NdotL, half LdotH, half perceptualRoughness)
    {
        half fd90 = 0.5 + 2 * LdotH * LdotH * perceptualRoughness;
        // Two schlick fresnel term
        half lightScatter   = (1 + (fd90 - 1) * Pow5(1 - NdotL));
        half viewScatter    = (1 + (fd90 - 1) * Pow5(1 - NdotV));

        return lightScatter * viewScatter;
    }

    // NOTE: Visibility term here is the full form from Torrance-Sparrow model, it includes Geometric term: V = G / (N.L * N.V)
    // This way it is easier to swap Geometric terms and more room for optimizations (except maybe in case of CookTorrance geom term)

    // Generic Smith-Schlick visibility term
    inline half SmithVisibilityTerm (half NdotL, half NdotV, half k)
    {
        half gL = NdotL * (1-k) + k;
        half gV = NdotV * (1-k) + k;
        return 1.0 / (gL * gV + 1e-5f); // This function is not intended to be running on Mobile,
        // therefore epsilon is smaller than can be represented by half
    }

    // Smith-Schlick derived for Beckmann
    inline half SmithBeckmannVisibilityTerm (half NdotL, half NdotV, half roughness)
    {
        half c = 0.797884560802865h; // c = sqrt(2 / Pi)
        half k = roughness * c;
        return SmithVisibilityTerm (NdotL, NdotV, k) * 0.25f; // * 0.25 is the 1/4 of the visibility term
    }

    // Ref: http://jcgt.org/published/0003/02/03/paper.pdf
    inline half SmithJointGGXVisibilityTerm (half NdotL, half NdotV, half roughness)
    {
        #if 0
            // Original formulation:
            //  lambda_v    = (-1 + sqrt(a2 * (1 - NdotL2) / NdotL2 + 1)) * 0.5f;
            //  lambda_l    = (-1 + sqrt(a2 * (1 - NdotV2) / NdotV2 + 1)) * 0.5f;
            //  G           = 1 / (1 + lambda_v + lambda_l);

            // Reorder code to be more optimal
            half a          = roughness;
            half a2         = a * a;

            half lambdaV    = NdotL * sqrt((-NdotV * a2 + NdotV) * NdotV + a2);
            half lambdaL    = NdotV * sqrt((-NdotL * a2 + NdotL) * NdotL + a2);

            // Simplify visibility term: (2.0f * NdotL * NdotV) /  ((4.0f * NdotL * NdotV) * (lambda_v + lambda_l + 1e-5f));
            return 0.5f / (lambdaV + lambdaL + 1e-5f);  // This function is not intended to be running on Mobile,
            // therefore epsilon is smaller than can be represented by half
        #else
            // Approximation of the above formulation (simplify the sqrt, not mathematically correct but close enough)
            half a = roughness;
            half lambdaV = NdotL * (NdotV * (1 - a) + a);
            half lambdaL = NdotV * (NdotL * (1 - a) + a);

            return 0.5f / (lambdaV + lambdaL + 1e-5f);
        #endif
    }

    inline float GGXTerm (float NdotH, float roughness)
    {
        float a2 = roughness * roughness;
        float d = (NdotH * a2 - NdotH) * NdotH + 1.0f; // 2 mad
        return UNITY_INV_PI * a2 / (d * d + 1e-7f); // This function is not intended to be running on Mobile,
        // therefore epsilon is smaller than what can be represented by half
    }

    inline half PerceptualRoughnessToSpecPower (half perceptualRoughness)
    {
        half m = PerceptualRoughnessToRoughness(perceptualRoughness);   // m is the true academic roughness.
        half sq = max(1e-4f, m*m);
        half n = (2.0 / sq) - 2.0;                          // https://dl.dropboxusercontent.com/u/55891920/papers/mm_brdf.pdf
        n = max(n, 1e-4f);                                  // prevent possible cases of pow(0,0), which could happen when roughness is 1.0 and NdotH is zero
        return n;
    }

    // BlinnPhong normalized as normal distribution function (NDF)
    // for use in micro-facet model: spec=D*G*F
    // eq. 19 in https://dl.dropboxusercontent.com/u/55891920/papers/mm_brdf.pdf
    inline half NDFBlinnPhongNormalizedTerm (half NdotH, half n)
    {
        // norm = (n+2)/(2*pi)
        half normTerm = (n + 2.0) * (0.5/UNITY_PI);

        half specTerm = pow (NdotH, n);
        return specTerm * normTerm;
    }

    //-------------------------------------------------------------------------------------
    /*
    // https://s3.amazonaws.com/docs.knaldtech.com/knald/1.0.0/lys_power_drops.html

    const float k0 = 0.00098, k1 = 0.9921;
    // pass this as a constant for optimization
    const float fUserMaxSPow = 100000; // sqrt(12M)
    const float g_fMaxT = ( exp2(-10.0/fUserMaxSPow) - k0)/k1;
    float GetSpecPowToMip(float fSpecPow, int nMips)
    {
        // Default curve - Inverse of TB2 curve with adjusted constants
        float fSmulMaxT = ( exp2(-10.0/sqrt( fSpecPow )) - k0)/k1;
        return float(nMips-1)*(1.0 - clamp( fSmulMaxT/g_fMaxT, 0.0, 1.0 ));
    }

    //float specPower = PerceptualRoughnessToSpecPower(perceptualRoughness);
    //float mip = GetSpecPowToMip (specPower, 7);
    */

    inline float3 Unity_SafeNormalize(float3 inVec)
    {
        float dp3 = max(0.001f, dot(inVec, inVec));
        return inVec * rsqrt(dp3);
    }

    //-------------------------------------------------------------------------------------

    // Note: BRDF entry points use smoothness and oneMinusReflectivity for optimization
    // purposes, mostly for DX9 SM2.0 level. Most of the math is being done on these (1-x) values, and that saves
    // a few precious ALU slots.

    half4 fillLightColor;
    half4 _AOParam;
    half _MainLightSpecularIntensity;
    half3 _MainLightSpecularDirection;
    half _MainLightDiffuseAO;
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
    half4 BRDF1_Unity_PBS (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
    float3 normal, float3 viewDir,float4 TreeAmbientTop,float4 TreeAmbientMiddle,float4 TreeAmbientDown,
    UnityLight light, UnityIndirect gi, float4 treeParam)
    {
        float perceptualRoughness = SmoothnessToPerceptualRoughness (smoothness);
        float3 halfDir = Unity_SafeNormalize (float3(light.dir) + viewDir);
        float3 halfDirCustom = Unity_SafeNormalize (_MainLightSpecularDirection + viewDir);

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
            half nv = saturate(abs(dot(normal, viewDir)));    // This abs allow to limit artifact
        #endif

        half nl = saturate(dot(normal, light.dir));
        half nlCustom = saturate(dot(normal, _MainLightSpecularDirection));
        float nh = saturate(dot(normal, halfDir));
        float nhCustom = saturate(dot(normal, halfDirCustom));

        // 实时点光源不受自定义高光调整与diffuse光照调整的影响
        #ifdef POINT
            nlCustom = nl;
            nhCustom = nh;  
            _MainLightSpecularIntensity = 1;
        #endif
    
        half lv = saturate(dot(light.dir, viewDir));
    
        half lh = saturate(dot(light.dir, halfDir));
        float lhCustom = saturate(dot(_MainLightSpecularDirection, halfDirCustom));

        #ifdef POINT
            lhCustom = lh;
        #endif
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
            half V = SmithJointGGXVisibilityTerm (nlCustom, nv, roughness);
            float D = GGXTerm (nhCustom, roughness);
        #else
            // Legacy
            half V = SmithBeckmannVisibilityTerm (nlCustom, nv, roughness);
            half D  = NDFBlinnPhongNormalizedTerm (nhCustom, PerceptualRoughnessToSpecPower(perceptualRoughness));
        #endif

        half specularTerm = V*D * UNITY_PI; // Torrance-Sparrow model, Fresnel is applied later

        #   ifdef UNITY_COLORSPACE_GAMMA
        specularTerm = sqrt(max(1e-4h, specularTerm));
        #   endif

        // specularTerm * nl can be NaN on Metal in some cases, use max() to make sure it's a sane value
        specularTerm = max(0, specularTerm * nlCustom);
        #if defined(_SPECULARHIGHLIGHTS_OFF)
            specularTerm = 0.0;
        #endif

        // surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(roughness^2+1)
        half surfaceReduction;
        #   ifdef UNITY_COLORSPACE_GAMMA
        surfaceReduction = 1.0-0.28*roughness*perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
        #   else
        surfaceReduction = 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]
        #   endif

        // To provide true Lambert lighting, we need to be able to kill specular completely.这个在metallic workflow可以去掉，没有完全没有specColor的物体
        //specularTerm *= any(specColor) ? 1.0 : 0.0;
        /**
        oneMinusReflectivity metel 0 non metal 0.96
        */
        // 总体的环境球的F90都减弱，这样在暗部的物体侧面的环境球的反射不会那么强
        half grazingTerm = saturate(smoothness * 1 + (1-oneMinusReflectivity)) * 0.5;

        // xwl 直接使用NL，不使用Disney，大概指令数能减少10条，效果差别很小
        // 加强间接光照体积感，使用模型法线作为光照方向来模拟天球光的阴影。
        //float3 ScaleGiDiffuse =  _GIDiffuseScale;
    	// 使用lightmap来scale主光源的diffuse，这样，能造成一些亮部颜色的明暗变化，类似于ao的效果
    
        #ifdef POINT
            half3 diffuseFinal = diffColor * light.color * nl;
        #else
            half3 diffuseFinal = diffColor * (gi.diffuse + min(gi.diffuse.g * _MainLightDiffuseAO, 1) * light.color * nl /*diffuseTerm*/);
        #endif
    
			half3 color = diffuseFinal + specularTerm * light.color * FresnelTerm(specColor, lhCustom) * _MainLightSpecularIntensity;//调整mainlight的高光强度
    
        #if defined(_LEAF_ON)
			//树叶没有lightmap烘焙的光,有自己的顶点里的阴影+下面的颜色混合
            fixed diff = max (0,(dot (normal,light.dir)+ treeParam.x)/(1+ treeParam.x));
            float4 ambientColor = lerp(TreeAmbientMiddle,TreeAmbientTop,saturate(dot(normal,float3(0,1,0))));
            ambientColor = lerp(ambientColor,TreeAmbientDown,saturate(dot(normal,float3(0,-1,0))));

            ambientColor *= saturate(treeParam.y + treeParam.z + max(0, dot(normal, light.dir)) * treeParam.w);

			color = diffColor * (ambientColor + light.color *  diff /*diffuseTerm*/) + specularTerm * light.color * FresnelTerm(specColor, lh);
        #endif

        #if !defined(_LEAF_ON)
            //间接高光考虑上lightmap的影响，这样同样的物体在不同位置，间接高光的明暗会有变化
			//地面原来用的是surfaceReduction * gi.specular * FresnelLerp(specColor, grazingTerm, nv) * min(gi.diffuse, 1);
			//现在统一成这个了
            half lightMapLum = gi.diffuse.g;
            color += surfaceReduction * gi.specular * FresnelLerp(specColor, grazingTerm, nv) * saturate(lightMapLum + 0.3);
        #endif
    
        #ifndef POINT
            color += diffColor * fillLightColor;
        #endif
    
        // 最后输出颜色强制裁剪，避免出现某些角度和材质的物体过亮过曝，而且目前RGBM的倍数是8
        color = clamp(color, 0, 16);
        return half4(color, 1);    
    }
//原始BRDF1走新的BRDF1 对应TLSTUDIO_BRDF_HIGH
half4 BRDF1_Unity_PBS (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
    float3 normal, float3 viewDir,
    UnityLight light, UnityIndirect gi)
    {
       return  BRDF1_Unity_PBS ( diffColor,  specColor,  oneMinusReflectivity,  smoothness,
         normal,  viewDir, float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1),
         light,gi, float4(0, 0, 0, 0));
    }


    // Based on Minimalist CookTorrance BRDF
    // Implementation is slightly different from original derivation: http://www.thetenthplanet.de/archives/255
    //
    // * NDF (depending on UNITY_BRDF_GGX):
    //  a) BlinnPhong
    //  b) [Modified] GGX
    // * Modified Kelemen and Szirmay-​Kalos for Visibility term
    // * Fresnel approximated with 1/LdotH
	// TLSTUDIO_BRDF_HIGH == 0的情况 ，从unitystandarad brdf2改过来的，主要区别就是高光 还有就是用FresnelLerpFast代替FresnelLerp
    half4 BRDF2_Unity_PBS (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
		float3 normal, float3 viewDir, float4 TreeAmbientTop, float4 TreeAmbientMiddle, float4 TreeAmbientDown,
		UnityLight light, UnityIndirect gi, float4 treeParam)
    {
        float3 halfDir = Unity_SafeNormalize (float3(light.dir) + viewDir);
		float3 halfDirCustom = Unity_SafeNormalize(_MainLightSpecularDirection + viewDir);

        half nl = saturate(dot(normal, light.dir));
        float nh = saturate(dot(normal, halfDir));
        //half nv = saturate(dot(normal, viewDir));
		half nv = saturate(abs(dot(normal, viewDir)));

		half nlCustom = saturate(dot(normal, _MainLightSpecularDirection));
		float nhCustom = saturate(dot(normal, halfDirCustom));


#ifdef POINT
		nlCustom = nl;
		nhCustom = nh;
		_MainLightSpecularIntensity = 1;
#endif

        half lh = saturate(dot(light.dir, halfDir));
        float lhCustom = saturate(dot(_MainLightSpecularDirection, halfDirCustom));

#ifdef POINT
			lhCustom = lh;
#endif

        // Specular term
        half perceptualRoughness = SmoothnessToPerceptualRoughness (smoothness);
        half roughness = PerceptualRoughnessToRoughness(perceptualRoughness);

        #if UNITY_BRDF_GGX
            // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
            // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
            // https://community.arm.com/events/1155
            half a = roughness;
            float a2 = a*a;

            float d = nhCustom * nhCustom * (a2 - 1.f) + 1.00001f;
            #ifdef UNITY_COLORSPACE_GAMMA
                // Tighter approximation for Gamma only rendering mode!
                // DVF = sqrt(DVF);
                // DVF = (a * sqrt(.25)) / (max(sqrt(0.1), lh)*sqrt(roughness + .5) * d);
                float specularTerm = a / (max(0.32f, lhCustom) * (1.5f + roughness) * d);
            #else
                float specularTerm = a2 / (max(0.1f, lhCustom*lhCustom) * (roughness + 0.5f) * (d * d) * 4);
            #endif

            // on mobiles (where half actually means something) denominator have risk of overflow
            // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
            // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
            #if defined (SHADER_API_MOBILE)
                specularTerm = specularTerm - 1e-4f;
            #endif


        #else

            // Legacy
            half specularPower = PerceptualRoughnessToSpecPower(perceptualRoughness);
            // Modified with approximate Visibility function that takes roughness into account
            // Original ((n+1)*N.H^n) / (8*Pi * L.H^3) didn't take into account roughness
            // and produced extremely bright specular at grazing angles

            half invV = lhCustom * lhCustom * smoothness + perceptualRoughness * perceptualRoughness; // approx ModifiedKelemenVisibilityTerm(lh, perceptualRoughness);
            half invF = lhCustom;

            half specularTerm = ((specularPower + 1) * pow (nhCustom, specularPower)) / (8 * invV * invF + 1e-4h);

            #ifdef UNITY_COLORSPACE_GAMMA
                specularTerm = sqrt(max(1e-4f, specularTerm));
            #endif

        #endif

        #if defined (SHADER_API_MOBILE)
            specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
        #endif
        #if defined(_SPECULARHIGHLIGHTS_OFF)
            specularTerm = 0.0;
        #endif

        // surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(realRoughness^2+1)

        // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
        // 1-x^3*(0.6-0.08*x)   approximation for 1/(x^4+1)
		half surfaceReduction;
		#   ifdef UNITY_COLORSPACE_GAMMA
		surfaceReduction = 1.0 - 0.28*roughness*perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
		#   else
		surfaceReduction = 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]
		#   endif

		// 总体的环境球的F90都减弱，这样在暗部的物体侧面的环境球的反射不会那么强
		half grazingTerm = saturate(smoothness * 1 + (1 - oneMinusReflectivity)) * 0.5;


		#ifdef POINT
		half3 diffuseFinal = diffColor * light.color * nl;
		#else
		half3 diffuseFinal = diffColor * (gi.diffuse + min(gi.diffuse.g * _MainLightDiffuseAO, 1) * light.color * nl /*diffuseTerm*/);
		#endif

		half3 color = diffuseFinal +specularTerm  * specColor* light.color * nlCustom * _MainLightSpecularIntensity;//调整mainlight的高光强度


		#if defined(_LEAF_ON)
		fixed diff = max(0, (dot(normal, light.dir) + treeParam.x) / (1 + treeParam.x));
		float4 ambientColor = lerp(TreeAmbientMiddle, TreeAmbientTop, saturate(dot(normal, float3(0, 1, 0))));
		ambientColor = lerp(ambientColor, TreeAmbientDown, saturate(dot(normal, float3(0, -1, 0))));

		ambientColor *= saturate(treeParam.y + treeParam.z + max(0, dot(normal, light.dir)) * treeParam.w);

		color = diffColor * (ambientColor + light.color *  diff /*diffuseTerm*/) + specularTerm  * specColor* light.color * nlCustom * _MainLightSpecularIntensity;
		#endif

		#if !defined(_LEAF_ON)
		// 间接高光考虑上lightmap的影响，这样同样的物体在不同位置，间接高光的明暗会有变化
		half lightMapLum = gi.diffuse.g;
		color += surfaceReduction * gi.specular * FresnelLerpFast(specColor, grazingTerm, nv) * saturate(lightMapLum + 0.3);

		#endif

		#ifndef POINT
		// 暂时实时点光源不考虑补光，应该补光的lightcolor没用点光源的_LightTexture0来计算衰减，会出现一个大方块
		color += diffColor * fillLightColor;
		#endif

        // 最后输出颜色强制裁剪，避免出现某些角度和材质的物体过亮过曝，而且目前RGBM的倍数是8
        color = clamp(color, 0, 16);

        return half4(color, 1);
    }
	//原始BRDF1走新的BRDF1 对应TLSTUDIO_BRDF_HIGH
	half4 BRDF2_Unity_PBS(half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
		float3 normal, float3 viewDir,
		UnityLight light, UnityIndirect gi)
	{
		return  BRDF2_Unity_PBS(diffColor, specColor, oneMinusReflectivity, smoothness,
			normal, viewDir, float4(1, 1, 1, 1), float4(1, 1, 1, 1), float4(1, 1, 1, 1),
			light, gi, float4(0, 0, 0, 0));
	}
    sampler2D_float unity_NHxRoughness;
    half3 BRDF3_Direct(half3 diffColor, half3 specColor, half rlPow4, half smoothness)
    {
        half LUT_RANGE = 16.0; // must match range in NHxRoughness() function in GeneratedTextures.cpp
        // Lookup texture to save instructions
        half specular = tex2D(unity_NHxRoughness, half2(rlPow4, SmoothnessToPerceptualRoughness(smoothness))).UNITY_ATTEN_CHANNEL * LUT_RANGE;
        #if defined(_SPECULARHIGHLIGHTS_OFF)
            specular = 0.0;
        #endif

        return diffColor + specular * specColor;
    }

    half3 BRDF3_Indirect(half3 diffColor, half3 specColor, UnityIndirect indirect, half grazingTerm, half fresnelTerm)
    {
        half3 c = indirect.diffuse * diffColor;
        c += indirect.specular * lerp (specColor, grazingTerm, fresnelTerm);
        return c;
    }

    // Old school, not microfacet based Modified Normalized Blinn-Phong BRDF
    // Implementation uses Lookup texture for performance
    //
    // * Normalized BlinnPhong in RDF form
    // * Implicit Visibility term
    // * No Fresnel term
    //
    // TODO: specular is too weak in Linear rendering mode
    half4 BRDF3_Unity_PBS (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
    float3 normal, float3 viewDir,
    UnityLight light, UnityIndirect gi)
    {
        float3 reflDir = reflect (viewDir, normal);

        half nl = saturate(dot(normal, light.dir));
        half nv = saturate(dot(normal, viewDir));

        // Vectorize Pow4 to save instructions
        half2 rlPow4AndFresnelTerm = Pow4 (float2(dot(reflDir, light.dir), 1-nv));  // use R.L instead of N.H to save couple of instructions
        half rlPow4 = rlPow4AndFresnelTerm.x; // power exponent must match kHorizontalWarpExp in NHxRoughness() function in GeneratedTextures.cpp
        half fresnelTerm = rlPow4AndFresnelTerm.y;

        half grazingTerm = saturate(smoothness + (1-oneMinusReflectivity));

        half3 color = BRDF3_Direct(diffColor, specColor, rlPow4, smoothness);
        color *= light.color * nl;
        color += BRDF3_Indirect(diffColor, specColor, gi, grazingTerm, fresnelTerm);

        color +=fillLightColor * diffColor;
        return half4(color, 1);
        half LUT_RANGE = 16.0; // must match range in NHxRoughness() function in GeneratedTextures.cpp
        // Lookup texture to save instructions
        half specular = tex2D(unity_NHxRoughness, half2(rlPow4, SmoothnessToPerceptualRoughness(smoothness))).UNITY_ATTEN_CHANNEL * LUT_RANGE;
        return half4(specColor * specular * light.color * nl,1);
        
    }

	//sampler2D_float	_DynamicNHxRoughnessTexture0;
//	float	_DynamicNHxRoughnessArray[960];
//	half3 BRDF3_Direct_DPL(half3 diffColor, half3 specColor, half rlPow4, half smoothness)
//	{
//		half LUT_RANGE = 16.0; // must match range in NHxRoughness() function in GeneratedTextures.cpp
//		// Lookup texture to save instructions
//		//half specular = tex2D(_DynamicNHxRoughnessTexture0, half2(rlPow4, SmoothnessToPerceptualRoughness(smoothness))).UNITY_ATTEN_CHANNEL * LUT_RANGE;
//		half2 temp = half2(rlPow4, SmoothnessToPerceptualRoughness(smoothness));
//		int x = (int)(temp.x * 63);
//		int y = (int)(temp.y * 14);
//
//		int index = 64 * y + x;
//		half specular = _DynamicNHxRoughnessArray[index] * LUT_RANGE;
//#if defined(_SPECULARHIGHLIGHTS_OFF)
//		specular = 0.0;
//#endif
//
//		return diffColor + specular * specColor;
//	}

	//only used for dynamic point lighting.
	half4 BRDF3_Unity_PBS_DPL(half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
		float3 normal, float3 viewDir,
		UnityLight light, UnityIndirect gi)
	{
		//float3 reflDir = reflect(viewDir, normal);

		half nl = saturate(dot(normal, light.dir));
		//half nv = saturate(dot(normal, viewDir));

		//// Vectorize Pow4 to save instructions
		//half2 rlPow4AndFresnelTerm = Pow4(float2(dot(reflDir, light.dir), 1 - nv));  // use R.L instead of N.H to save couple of instructions
		//half rlPow4 = rlPow4AndFresnelTerm.x; // power exponent must match kHorizontalWarpExp in NHxRoughness() function in GeneratedTextures.cpp
		//half fresnelTerm = rlPow4AndFresnelTerm.y;

		//half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));

		//half3 color = BRDF3_Direct_DPL(diffColor, specColor, rlPow4, smoothness);
    half3 color = diffColor + specColor*0.2;
		color *= light.color * nl;
		//color += BRDF3_Indirect(diffColor, specColor, gi, grazingTerm, fresnelTerm);

		//color += fillLightColor * diffColor;
		return half4(color, 1);
		//half LUT_RANGE = 16.0; // must match range in NHxRoughness() function in GeneratedTextures.cpp
		//// Lookup texture to save instructions
		//half specular = tex2D(unity_NHxRoughness, half2(rlPow4, SmoothnessToPerceptualRoughness(smoothness))).UNITY_ATTEN_CHANNEL * LUT_RANGE;
		//return half4(specColor * specular * light.color * nl, 1);

	}

    // Include deprecated function
    #define INCLUDE_UNITY_STANDARD_BRDF_DEPRECATED
    #include "UnityDeprecated.cginc"
    #undef INCLUDE_UNITY_STANDARD_BRDF_DEPRECATED

#endif // UNITY_STANDARD_BRDF_INCLUDED
