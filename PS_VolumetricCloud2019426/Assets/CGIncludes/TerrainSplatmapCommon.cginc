// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef TERRAIN_SPLATMAP_COMMON_CGINC_INCLUDED
#define TERRAIN_SPLATMAP_COMMON_CGINC_INCLUDED

#ifdef _NORMALMAP
    // Since 2018.3 we changed from _TERRAIN_NORMAL_MAP to _NORMALMAP to save 1 keyword.
    #define _TERRAIN_NORMAL_MAP
#endif

struct Input
{
    float4 tc;
    #ifndef TERRAIN_BASE_PASS
        float4 fogCoord : TEXCOORD0; 
    #endif
};

sampler2D _Control;
float4 _Control_ST;
float4 _Control_TexelSize;
sampler2D _Splat0, _Splat1, _Splat2, _Splat3;
float4 _Splat0_ST, _Splat1_ST, _Splat2_ST, _Splat3_ST;

#if defined(UNITY_INSTANCING_ENABLED) && !defined(SHADER_API_D3D11_9X)
    sampler2D _TerrainHeightmapTexture;
    sampler2D _TerrainNormalmapTexture;
    float4    _TerrainHeightmapRecipSize;   // float4(1.0f/width, 1.0f/height, 1.0f/(width-1), 1.0f/(height-1))
    float4    _TerrainHeightmapScale;       // float4(hmScale.x, hmScale.y / (float)(kMaxHeight), hmScale.z, 0.0f)
#endif

UNITY_INSTANCING_BUFFER_START(Terrain)
    UNITY_DEFINE_INSTANCED_PROP(float4, _TerrainPatchInstanceData) // float4(xBase, yBase, skipScale, ~)
UNITY_INSTANCING_BUFFER_END(Terrain)

#ifdef _NORMALMAP
    sampler2D _Normal0, _Normal1, _Normal2, _Normal3;
    float _NormalScale0, _NormalScale1, _NormalScale2, _NormalScale3;
#endif

#if defined(TERRAIN_BASE_PASS) && defined(UNITY_PASS_META)
    // When we render albedo for GI baking, we actually need to take the ST
    float4 _MainTex_ST;
#endif

void SplatmapVert(inout appdata_full v, out Input data)
{
    UNITY_INITIALIZE_OUTPUT(Input, data);

#if defined(UNITY_INSTANCING_ENABLED) && !defined(SHADER_API_D3D11_9X)

    float2 patchVertex = v.vertex.xy;
    float4 instanceData = UNITY_ACCESS_INSTANCED_PROP(Terrain, _TerrainPatchInstanceData);

    float4 uvscale = instanceData.z * _TerrainHeightmapRecipSize;
    float4 uvoffset = instanceData.xyxy * uvscale;
    uvoffset.xy += 0.5f * _TerrainHeightmapRecipSize.xy;
    float2 sampleCoords = (patchVertex.xy * uvscale.xy + uvoffset.xy);

    float hm = UnpackHeightmap(tex2Dlod(_TerrainHeightmapTexture, float4(sampleCoords, 0, 0)));
    v.vertex.xz = (patchVertex.xy + instanceData.xy) * _TerrainHeightmapScale.xz * instanceData.z;  //(x + xBase) * hmScale.x * skipScale;
    v.vertex.y = hm * _TerrainHeightmapScale.y;
    v.vertex.w = 1.0f;

    v.texcoord.xy = (patchVertex.xy * uvscale.zw + uvoffset.zw);
    v.texcoord3 = v.texcoord2 = v.texcoord1 = v.texcoord;

    #ifdef TERRAIN_INSTANCED_PERPIXEL_NORMAL
        v.normal = float3(0, 1, 0); // TODO: reconstruct the tangent space in the pixel shader. Seems to be hard with surface shader especially when other attributes are packed together with tSpace.
        data.tc.zw = sampleCoords;
    #else
        float3 nor = tex2Dlod(_TerrainNormalmapTexture, float4(sampleCoords, 0, 0)).xyz;
        v.normal = 2.0f * nor - 1.0f;
    #endif
#endif

    v.tangent.xyz = cross(v.normal, float3(0,0,1));
    v.tangent.w = -1;

    data.tc.xy = v.texcoord;
#ifdef TERRAIN_BASE_PASS
    #ifdef UNITY_PASS_META
        data.tc.xy = v.texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
    #endif
#else
    float4 pos = UnityObjectToClipPos(v.vertex);
	TL_TRANSFER_FOG(data, pos, v.vertex);
#endif
}

#ifndef TERRAIN_BASE_PASS

#ifdef TERRAIN_STANDARD_SHADER
void SplatmapMix(Input IN, half4 defaultAlpha, out half4 splat_control, out half weight, out fixed4 mixedDiffuse, inout fixed3 mixedNormal)
#else
void SplatmapMix(Input IN, out half4 splat_control, out half weight, out fixed4 mixedDiffuse, inout fixed3 mixedNormal)
#endif
{
    // adjust splatUVs so the edges of the terrain tile lie on pixel centers
    //float2 splatUV = (IN.tc.xy * (_Control_TexelSize.zw - 1.0f) + 0.5f) * _Control_TexelSize.xy;
	float2 splatUV = IN.tc.xy;
    splat_control = tex2D(_Control, splatUV);
    weight = dot(splat_control, half4(1,1,1,1));

    #if !defined(SHADER_API_MOBILE) && defined(TERRAIN_SPLAT_ADDPASS)
        clip(weight == 0.0f ? -1 : 1);
    #endif

    // Normalize weights before lighting and restore weights in final modifier functions so that the overal
    // lighting result can be correctly weighted.
    splat_control /= (weight + 1e-3f);

    float2 uvSplat0 = TRANSFORM_TEX(IN.tc.xy, _Splat0);
    float2 uvSplat1 = TRANSFORM_TEX(IN.tc.xy, _Splat1);
    float2 uvSplat2 = TRANSFORM_TEX(IN.tc.xy, _Splat2);
    float2 uvSplat3 = TRANSFORM_TEX(IN.tc.xy, _Splat3);

    mixedDiffuse = 0.0f;
    #ifdef TERRAIN_STANDARD_SHADER
        mixedDiffuse += splat_control.r * tex2D(_Splat0, uvSplat0) * half4(1.0, 1.0, 1.0, defaultAlpha.r);
        mixedDiffuse += splat_control.g * tex2D(_Splat1, uvSplat1) * half4(1.0, 1.0, 1.0, defaultAlpha.g);
        mixedDiffuse += splat_control.b * tex2D(_Splat2, uvSplat2) * half4(1.0, 1.0, 1.0, defaultAlpha.b);
        mixedDiffuse += splat_control.a * tex2D(_Splat3, uvSplat3) * half4(1.0, 1.0, 1.0, defaultAlpha.a);
    #else
        mixedDiffuse += splat_control.r * tex2D(_Splat0, uvSplat0);
        mixedDiffuse += splat_control.g * tex2D(_Splat1, uvSplat1);
        mixedDiffuse += splat_control.b * tex2D(_Splat2, uvSplat2);
        mixedDiffuse += splat_control.a * tex2D(_Splat3, uvSplat3);
    #endif

    #ifdef _NORMALMAP
        mixedNormal  = UnpackNormalWithScale(tex2D(_Normal0, uvSplat0), _NormalScale0) * splat_control.r;
        mixedNormal += UnpackNormalWithScale(tex2D(_Normal1, uvSplat1), _NormalScale1) * splat_control.g;
        mixedNormal += UnpackNormalWithScale(tex2D(_Normal2, uvSplat2), _NormalScale2) * splat_control.b;
        mixedNormal += UnpackNormalWithScale(tex2D(_Normal3, uvSplat3), _NormalScale3) * splat_control.a;
        mixedNormal.z += 1e-5f; // to avoid nan after normalizing
    #endif

    #if defined(INSTANCING_ON) && defined(SHADER_TARGET_SURFACE_ANALYSIS) && defined(TERRAIN_INSTANCED_PERPIXEL_NORMAL)
        mixedNormal = float3(0, 0, 1); // make sure that surface shader compiler realizes we write to normal, as UNITY_INSTANCING_ENABLED is not defined for SHADER_TARGET_SURFACE_ANALYSIS.
    #endif

    #if defined(UNITY_INSTANCING_ENABLED) && !defined(SHADER_API_D3D11_9X) && defined(TERRAIN_INSTANCED_PERPIXEL_NORMAL)
        float3 geomNormal = normalize(tex2D(_TerrainNormalmapTexture, IN.tc.zw).xyz * 2 - 1);
        #ifdef _NORMALMAP
            float3 geomTangent = normalize(cross(geomNormal, float3(0, 0, 1)));
            float3 geomBitangent = normalize(cross(geomTangent, geomNormal));
            mixedNormal = mixedNormal.x * geomTangent
                          + mixedNormal.y * geomBitangent
                          + mixedNormal.z * geomNormal;
        #else
            mixedNormal = geomNormal;
        #endif
        mixedNormal = mixedNormal.xzy;
    #endif
}

inline half3 FresnelTerm_Terrain(half3 F0, half cosA)
{
    half t = Pow5(1 - cosA); // ala Schlick interpoliation
    
    // 降低地形材质的fresnel效果，这样，平视地形时不会泛白
    return F0 + saturate(0.3 - F0) * t;
}

    half4 fillLightColor;

// fillLightDir在SceneStandard里是通过vf里计算并传过来的世界坐标的法线，alpha通道存放了贴图的ao，主要是体现fillLight的法线细节，这部分计算在标准的Standard里没有，所以这里为0，所以将相关效果都注释掉，影响不大
    //half4 fillLightDir;
    half4 _AOParam;
    half _MainLightSpecularIntensity;
    half3 _MainLightSpecularDirection;
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
        // * Schlick approximation for Fresnel 无法和scenestandardbrdf.cginc中的合并为一个,因为surf会默认采用自己的brdf1_unity_pbs除非大改,把整个unity默认的standard抽离.所以分2个写
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

#ifndef TERRAIN_SURFACE_OUTPUT
    #define TERRAIN_SURFACE_OUTPUT SurfaceOutput
#endif

void SplatmapFinalColor(Input IN, TERRAIN_SURFACE_OUTPUT o, inout fixed4 color)
{
    color *= o.Alpha;
        #ifdef TERRAIN_SPLAT_ADDPASS 
    #else
		TL_APPLY_FOG(IN.fogCoord, color.rgb);
    #endif
}

void SplatmapFinalPrepass(Input IN, TERRAIN_SURFACE_OUTPUT o, inout fixed4 normalSpec)
{
    normalSpec *= o.Alpha;
}

void SplatmapFinalGBuffer(Input IN, TERRAIN_SURFACE_OUTPUT o, inout half4 outGBuffer0, inout half4 outGBuffer1, inout half4 outGBuffer2, inout half4 emission)
{
    UnityStandardDataApplyWeightToGbuffer(outGBuffer0, outGBuffer1, outGBuffer2, o.Alpha);
    emission *= o.Alpha;
}

#endif // TERRAIN_BASE_PASS

#endif // TERRAIN_SPLATMAP_COMMON_CGINC_INCLUDED
