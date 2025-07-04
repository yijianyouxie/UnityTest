// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//注意，最多使用8张纹理！！！。为支持OpenGL ES2.0。
Shader "TLStudio/Character/Uber" {
    Properties {
        [Header(Legcy)]
        _Color("AddColor", Color) = (0,0,0,0.5)
        [NoScaleOffset] _MainTex ("MainTex", 2D) = "white" {}
        [NoScaleOffset] _Reflection ("Reflection", 2D) = "white" {}
        _RimColor ("RimColor", Color) = (0,0,0,0.5)
        _ReflectionIntension("Reflection Intensity",Range(0,1)) = 0.1
        [HideInInspector]_Cutoff ("",float) = 0.5

        [Header(ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo)]
        [NoScaleOffset] _AllSpecialMaskTex("r(亮片遮罩) g(流光区域遮罩) b(反光区域1遮罩) a(反光区域2遮罩)", 2D) = "black" {}
        [Header(Glitter)]
        [Toggle(_Toggle_EnableGlitter)] _Toggle_EnableGlitter("?开启亮片?", Float) = 0
        Roughness ("粗糙度", Range(0, 1)) = 0.2
        IndirLight ("背光强度", Range(0, 1)) = 0.8

        [Header(GlitterStatic)]
        GlitterSpecularColor ("第一层反射颜色", Color) = (1,1,1,1)
        [NoScaleOffset] _GlitterSpecularTex ("第一层亮片形状", 2D) = "white" {}
        GlitterSpecularTilingScale ("缩放 xy(tilling) z(总)", vector) = (1,1,5,0)
        GlitterSpecularPower ("强度", Range(0, 5)) = 1.5

        [Header(GlitterDynamic)]
        GlitterColor ("第二层反射颜色", Color) = (1,1,1,1)
        [Toggle(_Toggle_EnableGlitterDynamicTex)] _Toggle_EnableGlitterDynamicTex("?单独增加一张新贴图?", Float) = 0    //1
        [NoScaleOffset] _GlitterTex ("第二层形状", 2D) = "white" {}
        GlitteryTilingScale ("缩放 xy(tilling) z(总)", vector) = (1,1,5,0)
        GlitterPower ("强度", Range(0, 10)) = 2
        GlitterySpeed ("闪烁速度", Range(0, 5)) = 0.1
        GlitterRotateMaskScale ("剔除缩放", Range(0.5, 1.5)) = 1
        GlitterParallaxRotate ("剔除系数", float) = 3.14

        [Header(ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo)]
        [Header(Gloss)]
        [Toggle(_Toggle_EnableGloss)] _Toggle_EnableGloss("?开启流光?", Float) = 0
        [NoScaleOffset] GlossColor("流光颜色", Color) = (1,1,1,1)
        [NoScaleOffset] _GlossTex("流光图", 2D) = "black" {}
        GlossTilingScale ("缩放 xy(tilling) z(总)", vector) = (1,1,5,0)
        [Toggle(_Toggle_GlossRepeat)] _Toggle_GlossRepeat("?开启使用连续流光(贴图选repeat), 否则是间隔时间流光(贴图选clamp)?", Float) = 0
        GlossSpeedXYTotalStop ("x(速度) y(旋转) z(间隔时间) w(回退矫正(0-1))", vector) = (1, 0, 0, 0)
        GlossStrength ("强度", Range(0, 10)) = 2

        [Header(ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo)]
        [Header(Normal)]
        _NormalMap("法线贴图", 2D) = "bump" {}
        BumpValue ("法线强度", Range(0,10)) = 1

        [Header(ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo)]
        [Header(MatCap)]
        [Toggle(_Toggle_EnableMatCap)] _Toggle_EnableMatCap("?开启反光?", Float) = 0    //1
        MatCapMaskValue("反光总强度", Range(0,1)) = 1
        
        [Header(MatCap1)]
        MatCapSpecColor1 ("区域1反射颜色", Color) = (1,1,1,1)
        _MatCapSpecTex1 ("反光贴图", 2D) = "white" {}
        MatCapSpecValue1 ("反射强度", Range(0, 5)) = 1
        MatCapSpecOpposed1 ("原颜色衰减", Range(-0.5, 1)) = 1
        FresnelCol1 ("菲涅尔颜色", Color) = (1, 1, 1, 1)
        FresnelBase1 ("菲涅尔基础值", Range(-1, 5)) = 0.1
        FresnelScale1 ("菲涅尔区域大小", Range(0, 10)) = 0.1
        FresnelIndensity1 ("菲涅尔强度", Range(0, 10)) = 0.1

        [Header(MatCap2)]
        [Toggle(_Toggle_EnableMatCap2)] _Toggle_EnableMatCap2 ("?开启反射区域2?", Float) = 0    //1
        MatCapSpecColor2 ("区域2反射颜色", Color) = (1,1,1,1)
        _MatCapSpecTex2 ("反光贴图", 2D) = "white" {}
        MatCapSpecValue2 ("反射强度", Range(0, 5)) = 1
        MatCapSpecOpposed2 ("原颜色衰减", Range(-0.5, 1)) = 1
        FresnelCol2 ("菲涅尔颜色", Color) = (1, 1, 1, 1)
        FresnelBase2 ("菲涅尔基础值", Range(-1, 5)) = 0.1
        FresnelScale2 ("菲涅尔区域大小", Range(0, 10)) = 0.1
        FresnelIndensity2 ("菲涅尔强度", Range(0, 10)) = 0.1
    }

    Subshader {
        Tags {
            "Queue"="AlphaTest+50"
            "RenderType"="TransparentCutout"
            "ShadowProjector" = "true"
        }
        LOD 150
        Pass {
            Name "ForwardBase"
            Tags {
                "LightMode"="ForwardBase"
            }
            ColorMask RGBA

            CGPROGRAM
            #pragma skip_variants FOG_EXP INSTANCING_ON DIRECTIONAL DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SHADOWS_SCREEN SHADOWS_SHADOWMASK VERTEXLIGHT_ON SHADOWS_CUBE SHADOWS_DEPTH POINT SPOT UNITY_HDR_ON
				#pragma exclude_renderers xbox360 ps3 flash d3d11_9x//why Too many math instructions for SM2.0 (73 needed, max is 64).
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "AutoLight.cginc"
                #include "DepthMapShadow.cginc"
                #include "CharacterUber.cginc"

                #pragma multi_compile __ _Toggle_EnableGlitter
                #pragma multi_compile __ _Toggle_EnableGlitterDynamicTex

                #pragma multi_compile __ _Toggle_EnableGloss
                #pragma multi_compile __ _Toggle_GlossRepeat

                #pragma multi_compile __ _Toggle_EnableMatCap
                #pragma multi_compile __ _Toggle_EnableMatCap2

                struct v2f { 
                    float4 pos : SV_POSITION;
                    float4  uv0 : TEXCOORD0;

                    float4 tspace0 : TEXCOORD1;
                    float4 tspace1 : TEXCOORD2;
                    float4 tspace2 : TEXCOORD3; 

                    LIGHTING_COORDS(4,5)
                    float4 shLight : TEXCOORD6;
                    //UNITY_FOG_COORDS(7)

                    float3 TtoV0 : TEXCOORD7;
                    //float3 TtoV1 : TEXCOORD9;
                };

                uniform float4 _MainTex_ST;

                v2f vert (appdata_tan v)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos (v.vertex);
                    o.uv0.xy = TRANSFORM_TEX(v.texcoord,_MainTex);

                    float3 normalDir = UnityObjectToWorldNormal(v.normal);//  mul(_Object2World, float4(v.normal,0)).xyz;
                    o.shLight.xyz = ShadeSH9(float4(normalDir * 1.0,1));
                    TRANSFER_VERTEX_TO_FRAGMENT(o)
                    //UNITY_TRANSFER_FOG(o,o.pos);

                    float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                    half3 wNormal = UnityObjectToWorldNormal(v.normal);
                    half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
                    half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                    half3 wBitangent = cross(wNormal, wTangent) * tangentSign;
                    o.tspace0 = float4(wTangent.x, wBitangent.x, wNormal.x, worldPos.x);
                    o.tspace1 = float4(wTangent.y, wBitangent.y, wNormal.y, worldPos.y);
                    o.tspace2 = float4(wTangent.z, wBitangent.z, wNormal.z, worldPos.z);

                    TANGENT_SPACE_ROTATION;
                    o.TtoV0 = normalize(mul(rotation, UNITY_MATRIX_IT_MV[0].xyz));
					//o.TtoV1 = normalize(mul(rotation, UNITY_MATRIX_IT_MV[1].xyz));
					float3 TtoV1 = normalize(mul(rotation, UNITY_MATRIX_IT_MV[1].xyz));
					o.shLight.w = TtoV1.x;
					o.uv0.zw = TtoV1.yz;
                    return o;
                }

                uniform fixed4 _LightColor0;
                uniform sampler2D _Reflection; uniform half4 _Reflection_ST;
                uniform sampler2D _MainTex;
                uniform fixed4 _Color;
                uniform fixed4 _RimColor;
                uniform fixed _ReflectionIntension;

                uniform sampler2D _NormalMap;
                uniform fixed BumpValue;

                float4 frag (v2f i) : COLOR
                {
                    fixed4 _MainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
                    clip(_MainTexColor.a-(1-_Color.a));

/////// Vectors:
                    float3 worldPos = float3(i.tspace0.w, i.tspace1.w, i.tspace2.w);
                    float3x3 matrixTBN = float3x3(i.tspace0.xyz, i.tspace1.xyz, i.tspace2.xyz);

                    // 法线贴图xy存在rg通道 区域1的反射mask在b通道，
                    float3 normalTangent = UnpackNormal(tex2D(_NormalMap, i.uv0));
                    normalTangent.xy = normalTangent.xy * BumpValue;
                    normalTangent.z = sqrt(1 - saturate(dot(normalTangent.xy, normalTangent.xy)));
                    float3 normalDir = mul(matrixTBN, normalTangent);
					normalDir = normalize(normalDir);

                    fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);

                    float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
////// Lighting:
                    fixed attenuation = LIGHT_ATTENUATION(i)*0.9;
                    fixed3 attenColor = attenuation*_LightColor0.xyz;
/////// Diffuse:
                    fixed NdotL = max(0.2,dot( normalDir, lightDirection ));
                    //fixed3 indirectDiffuse = UNITY_LIGHTMODEL_AMBIENT.rgb;
                    fixed3 directDiffuse = NdotL* attenColor;
                    fixed3 indirectDiffuse = i.shLight;
                    fixed3 diffuse = (directDiffuse + indirectDiffuse) * _MainTexColor.rgb;
////// Emissive:
                    fixed rimRange = 1-abs(dot(viewDir,normalDir));
                    half2 ReflUV = mul( UNITY_MATRIX_V, float4(normalDir,0)).rg*0.5+0.5;
                    fixed4 _Reflection_var = tex2D(_Reflection,TRANSFORM_TEX(ReflUV, _Reflection));
                    //fixed ReflectionRange = tex2D(_Reflection, TRANSFORM_TEX(i.uv0, _MainTex));
                    fixed3 emissive = _Color.rgb+_Reflection_var.rgb*_ReflectionIntension+rimRange*rimRange*_RimColor;
                    //float3 emissive = _Color.rgb + _Reflection_var.rgb*ReflectionRange;
/// Final Color:
                    fixed3 finalColor = diffuse + emissive;
                    finalColor *= ShadowColorAtten(half4(worldPos, 1));
                    #ifdef PROJECTOR_DEPTH_MAP_ON
                    finalColor *= ProjectorShadowColorAtten(i.posWorld);
                    #endif

/// Glitter Gloss MatCap:
					float3 TtoV1 = float3(i.shLight.w, i.uv0.zw);
					float tailorAlpha = 1.0;
                    finalColor = GetGlitterGlossMatcap(_LightColor0.xyz, finalColor,
                     i.uv0.xy, viewDir, worldPos, normalTangent, normalDir, matrixTBN, i.TtoV0, TtoV1, tailorAlpha);
/// Result:

                    //UNITY_APPLY_FOG(i.fogCoord,finalColor);
                    return fixed4(finalColor,1);
                }

            ENDCG
        }
    }

	FallBack "Mobile/Diffuse"
}
