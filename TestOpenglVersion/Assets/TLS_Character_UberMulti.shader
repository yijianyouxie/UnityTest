Shader "TLStudio/Character/UberMulti" {
    Properties {
		[Group(g1,_MainGroup,3)]_MainGroup("MainGroup", float) = 1
		[Title(g1, Legcy)]
		[Sub(g1)]_Color("AddColor", Color) = (0,0,0,0.5)
		[Sub(g1)][NoScaleOffset] _MainTex ("MainTex", 2D) = "white" {}

		[Group(g2,_GlitterGroup,3)]_GlitterGroup("GlitterGrfdoup", float) = 1
		[Title(g2, _MaskTex)]
		[Sub(g2)][NoScaleOffset] _AllSpecialMaskTex("r(亮片遮罩) g(流光区域遮罩) b(反光区域1遮罩) a(反光区域2遮罩)", 2D) = "black" {}
		[Title(g2, Glitter)]
		[SubToggle(g2, _Toggle_EnableGlitter)] _Toggle_EnableGlitter("?开启亮片?", Float) = 0
		[Sub(g2)]Roughness ("粗糙度", Range(0, 1)) = 0.2
		[Sub(g2)]IndirLight ("背光强度", Range(0, 1)) = 0.8
		[Sub(g2)]_GlitterMaskChannel("使用的通道rgba(值是0或1)", vector) = (1, 0, 0 ,0)

		[Title(g2, GlitterStatic)]
		[Sub(g2)]GlitterSpecularColor ("第一层反射颜色", Color) = (1,1,1,1)
		[Sub(g2)][NoScaleOffset] _GlitterSpecularTex ("第一层亮片形状", 2D) = "white" {}
		[Sub(g2)]GlitterSpecularTilingScale ("缩放 xy(tilling) z(总)", vector) = (1,1,5,0)
		[Sub(g2)]GlitterSpecularPower ("强度", Range(0, 5)) = 1.5

		[Title(g2, GlitterDynamic)]
		[Sub(g2)]GlitterColor ("第二层反射颜色", Color) = (1,1,1,1)
		[SubToggle(g2, _Toggle_EnableGlitterDynamicTex)] _Toggle_EnableGlitterDynamicTex("?单独增加一张新贴图?", Float) = 0    //1
		[Sub(g2)][NoScaleOffset] _GlitterTex ("第二层形状", 2D) = "white" {}
		[Sub(g2)]GlitteryTilingScale ("缩放 xy(tilling) z(总)", vector) = (1,1,5,0)
		[Sub(g2)]GlitterPower ("强度", Range(0, 10)) = 2
		[Sub(g2)]GlitterySpeed ("闪烁速度", Range(0, 5)) = 0.1
		[Sub(g2)]GlitterRotateMaskScale ("剔除缩放", Range(0.5, 1.5)) = 1
		[Sub(g2)]GlitterParallaxRotate ("剔除系数", float) = 3.14

		[Group(g3,_GlossGroup,3)]_GlossGroup("GlossGroup", float) = 1
		[Title(g3, Gloss)]
		[SubToggle(g3, _Toggle_EnableGloss)] _Toggle_EnableGloss("?开启流光?", Float) = 0
		[Sub(g3)][NoScaleOffset] GlossColor("流光颜色", Color) = (1,1,1,1)
		[Sub(g3)][NoScaleOffset] _GlossTex("流光图", 2D) = "black" {}
		[Sub(g3)]GlossTilingScale ("缩放 xy(tilling) z(总)", vector) = (1,1,1,0)
		[SubToggle(g3, _Toggle_GlossRepeat)] _Toggle_GlossRepeat("?开启使用连续流光(贴图选repeat), 否则是间隔时间流光(贴图选clamp)?", Float) = 0
		[Sub(g3)]GlossSpeedXYTotalStop ("x(速度) |y(贴图旋转) |z(间隔时间) |w(无效)", vector) = (1, 0, 0, 0)
		[Sub(g3)]_GlossDirection("流向:x(方向(0-360)) |y(水平矫正u(-0.5-0.5)) |z(垂直矫正v(-0.5-0.5)) |w(无效)", vector) = (0,0.5,0,0)
		[Sub(g3)]GlossStrength ("强度", Range(0, 10)) = 2
		[Sub(g3)]_GlosslMaskChannel1("使用的通道rgba(值是0或1)", vector) = (0, 1, 0 ,0)

		[Title(g3, Gloss2)]
		[SubToggle(g3, _Toggle_EnableGloss2)] _Toggle_EnableGloss2("?开启流光?", Float) = 0
		[Sub(g3)][NoScaleOffset] GlossColor2("流光颜色", Color) = (1,1,1,1)
		[Sub(g3)][NoScaleOffset] _GlossTex2("流光图", 2D) = "black" {}
		[Sub(g3)]GlossTilingScale2("缩放 xy(tilling) z(总)", vector) = (1,1,1,0)
		[SubToggle(g3, _Toggle_GlossRepeat2)] _Toggle_GlossRepeat2("?开启使用连续流光(贴图选repeat), 否则是间隔时间流光(贴图选clamp)?", Float) = 0
		[Sub(g3)]GlossSpeedXYTotalStop2("x(速度) |y(贴图旋转) |z(间隔时间) |w(无效)", vector) = (1, 0, 0, 0)
		[Sub(g3)]_GlossDirection2("流向:x(方向(0-360)) |y(水平矫正u(-0.5-0.5)) |z(垂直矫正v(-0.5-0.5)) |w(无效)", vector) = (0,0.5,0,0)
		[Sub(g3)]GlossStrength2("强度", Range(0, 10)) = 2
		[Sub(g3)]_GlosslMaskChannel2("使用的通道rgba(值是0或1)", vector) = (0, 1, 0 ,0)

		[Group(g4,_NormalGroup,3)]_NormalGroup("NormalGroup", float) = 1
		[Title(g4, _NormalMap)]
		[Sub(g4)]_NormalMap("法线贴图", 2D) = "bump" {}
		[Sub(g4)]BumpValue ("法线强度", Range(0,10)) = 1

		[Group(g5,_MatCapGroup,3)]_MatCapGroup("MatCapGroup", float) = 1
		[Title(g5, MatCap)]
		[SubToggle(g5, _Toggle_EnableMatCap)] _Toggle_EnableMatCap("?开启反光?", Float) = 0    //1
		//[Sub(g5)]MatCapMaskValue("反光总强度（未起作用）", Range(0,1)) = 1
        
		[Title(g5, MatCap1)]
		[Sub(g5)] MatCapSpecColor1 ("区域1反射颜色", Color) = (1,1,1,1)
		[Sub(g5)]_MatCapSpecTex1 ("反光贴图", 2D) = "white" {}
		[Sub(g5)]MatCapSpecValue1 ("反射强度", Range(0, 5)) = 1
		[Sub(g5)]MatCapSpecOpposed1 ("原颜色衰减", Range(-0.5, 1)) = 1
		[Sub(g5)]FresnelCol1 ("菲涅尔颜色", Color) = (1, 1, 1, 1)
		[Sub(g5)]FresnelBase1 ("菲涅尔基础值", Range(-1, 5)) = 0.1
		[Sub(g5)]FresnelScale1 ("菲涅尔区域大小", Range(0, 10)) = 0.1
		[Sub(g5)]FresnelIndensity1 ("菲涅尔强度", Range(0, 10)) = 0.1
		[Sub(g5)]_FresnelMaskChannel1("使用的通道rgba(值是0或1)", vector) = (0, 0, 1 ,0)

		[Title(g5, MatCap2)]
		[SubToggle(g5, _Toggle_EnableMatCap2)] _Toggle_EnableMatCap2 ("?开启反射区域2?", Float) = 0    //1
		[Sub(g5)]MatCapSpecColor2 ("区域2反射颜色", Color) = (1,1,1,1)
		[Sub(g5)]_MatCapSpecTex2 ("反光贴图", 2D) = "white" {}
		[Sub(g5)]MatCapSpecValue2 ("反射强度", Range(0, 5)) = 1
		[Sub(g5)]MatCapSpecOpposed2 ("原颜色衰减", Range(-0.5, 1)) = 1
		[Sub(g5)]FresnelCol2 ("菲涅尔颜色", Color) = (1, 1, 1, 1)
		[Sub(g5)]FresnelBase2 ("菲涅尔基础值", Range(-1, 5)) = 0.1
		[Sub(g5)]FresnelScale2 ("菲涅尔区域大小", Range(0, 10)) = 0.1
		[Sub(g5)]FresnelIndensity2 ("菲涅尔强度", Range(0, 10)) = 0.1
		[Sub(g5)]_FresnelMaskChannel2("使用的通道rgba(值是0或1)", vector) = (0, 0, 0 ,1)

		[Title(g5, MatCap3)]
		[SubToggle(g5, _Toggle_EnableMatCap3)] _Toggle_EnableMatCap3("?开启反射区域3?", Float) = 0    //1
		[Sub(g5)]MatCapSpecColor3("区域3反射颜色", Color) = (1,1,1,1)
		[Sub(g5)]_MatCapSpecTex3("反光贴图", 2D) = "white" {}
		[Sub(g5)]MatCapSpecValue3("反射强度", Range(0, 5)) = 1
		[Sub(g5)]MatCapSpecOpposed3("原颜色衰减", Range(-0.5, 1)) = 1
		[Sub(g5)]FresnelCol3("菲涅尔颜色", Color) = (1, 1, 1, 1)
		[Sub(g5)]FresnelBase3("菲涅尔基础值", Range(-1, 5)) = 0.1
		[Sub(g5)]FresnelScale3("菲涅尔区域大小", Range(0, 10)) = 0.1
		[Sub(g5)]FresnelIndensity3("菲涅尔强度", Range(0, 10)) = 0.1
		[Sub(g5)]_FresnelMaskChannel3("使用的通道rgba(值是0或1)", vector) = (0, 0, 0 ,1)

		[Group(g6,_DetailGroup,3)]_DetailGroup("DetailGroup", float) = 1
		[Title(g6, Detail1)]
		[SubToggle(g6, _Toggle_Detail1)] _Toggle_Detail1("?开启细节纹理1?", float) = 0
		[Sub(g6)]_DetailColor1("细节纹理颜色", Color) = (1,1,1,1)
		[Sub(g6)][NoScaleOffset]_DetailTex1("纹理贴图", 2D) = "black" {}
		[KWEnum(g6, Normal, Normal, Screen, Screen, Lighten, Lighten)] _DetailBlendType1("DetailBlendType1", float) = 0
		[Sub(g6)]_DetailIntensity1("强度", Range(0, 5)) = 1
		[Sub(g6)]_DetailScale1("缩放 xy(tilling) z(总)", vector) = (1, 1, 1, 0)
		[Sub(g6)]_DetailRotate1("x(贴图旋转) |y(水平矫正u(-0.5-0.5)) |z(垂直矫正v(-0.5-0.5)) |w(无效)", vector) = (0, 0, 0, 0)
		[Sub(g6)]_DetailMaskChannel1("纹理使用的通道rgba(值是0或1)", vector) = (1, 0, 0 ,0)
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
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "AutoLight.cginc"
                #include "DepthMapShadow.cginc"
                #include "TLS_Character_UberMulti.cginc"

                #pragma multi_compile __ _Toggle_EnableGlitter
                #pragma multi_compile __ _Toggle_EnableGlitterDynamicTex

                #pragma multi_compile __ _Toggle_EnableGloss
                #pragma multi_compile __ _Toggle_GlossRepeat

                #pragma multi_compile __ _Toggle_EnableMatCap
                #pragma multi_compile __ _Toggle_EnableMatCap2

				#pragma multi_compile __ _Toggle_Detail1

                struct v2f { 
                    float4 pos : SV_POSITION;
                    float2  uv0 : TEXCOORD0;

                    float4 tspace0 : TEXCOORD1;
                    float4 tspace1 : TEXCOORD2;
                    float4 tspace2 : TEXCOORD3; 

                    LIGHTING_COORDS(4,5)
                    float3 shLight : TEXCOORD6;
                    UNITY_FOG_COORDS(7)

                    float3 TtoV0 : TEXCOORD8;
                    float3 TtoV1 : TEXCOORD9;
                };

                uniform float4 _MainTex_ST;

                v2f vert (appdata_tan v)
                {
                    v2f o;
                    o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
                    o.uv0 = TRANSFORM_TEX(v.texcoord,_MainTex);

                    float3 normalDir = UnityObjectToWorldNormal(v.normal);//  mul(_Object2World, float4(v.normal,0)).xyz;
                    o.shLight = ShadeSH9(float4(normalDir * 1.0,1));
                    TRANSFER_VERTEX_TO_FRAGMENT(o)
                    UNITY_TRANSFER_FOG(o,o.pos);

                    float3 worldPos = mul(_Object2World, v.vertex).xyz;
                    half3 wNormal = UnityObjectToWorldNormal(v.normal);
                    half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
					//计算方向，后面用到
                    half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
					//通过T和N的向量积，得到垂直这两个向量的向量，但是它的方向有两个，所以乘以上面得到的方向参数，得到最终的向量，得到切线空间的B
                    half3 wBitangent = cross(wNormal, wTangent) * tangentSign;
					//所以下面是得到模型的顶点的切线空间到世界空间的矩阵，分行显示
                    o.tspace0 = float4(wTangent.x, wBitangent.x, wNormal.x, worldPos.x);
                    o.tspace1 = float4(wTangent.y, wBitangent.y, wNormal.y, worldPos.y);
                    o.tspace2 = float4(wTangent.z, wBitangent.z, wNormal.z, worldPos.z);

                    TANGENT_SPACE_ROTATION;
                    o.TtoV0 = normalize(mul(rotation, UNITY_MATRIX_IT_MV[0].xyz));
                    o.TtoV1 = normalize(mul(rotation, UNITY_MATRIX_IT_MV[1].xyz));
                    return o;
                }

                uniform fixed4 _LightColor0;
                uniform sampler2D _MainTex;
                uniform fixed4 _Color;

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
                    fixed3 emissive = _Color.rgb;
/// Final Color:
                    fixed3 finalColor = diffuse + emissive;
                    finalColor *= ShadowColorAtten(half4(worldPos, 1));
                    #ifdef PROJECTOR_DEPTH_MAP_ON
                    finalColor *= ProjectorShadowColorAtten(i.posWorld);
                    #endif

/// Glitter Gloss MatCap:
                    finalColor = GetGlitterGlossMatcap(_LightColor0.xyz, finalColor,
                     i.uv0.xy, viewDir, worldPos, normalTangent, normalDir, matrixTBN, i.TtoV0, i.TtoV1);
/// Result:

                    UNITY_APPLY_FOG(i.fogCoord,finalColor);
                    return fixed4(finalColor,1);
                }

            ENDCG
        }
    }

	FallBack "Mobile/Diffuse"
	CustomEditor "ShaderDrawerEditor"
}