// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//注意，最多使用8张纹理！！！。为支持OpenGL ES2.0。
Shader "TLStudio/Character/UberBlend" {
    Properties {
		_Color("AddColor", Color) = (0,0,0,1)
        _MainTex ("MainTex", 2D) = "white" {}
	
		[NoScaleOffset] _TailorTex("裁剪控制图TailorTex", 2D) = "white" {}
		_TailorGradientTex("裁剪渐变图", 2D) = "white" {}
		_TailorMaskChannel1("区域1裁剪使用的通道rgba(值是0或1)", vector) = (1, 0, 0 ,0)
		_TailorValue1("区域1裁剪比例", Range(0,0.99)) = 0
		_TailorGradientDis1("区域1裁剪渐变距离", Range(0,0.5)) = 0.1
		_TailorGradientTex2("裁剪渐变图2", 2D) = "white" {}
		_TailorMaskChannel2("区域2裁剪使用的通道rgba(值是0或1)", vector) = (0, 1, 0 ,0)
		_TailorValue2("区域2裁剪比例", Range(0,0.99)) = 0
		_TailorGradientDis2("区域2裁剪渐变距离", Range(0,0.5)) = 0.1
		_TailorGradientTex3("裁剪渐变图3", 2D) = "white" {}
		_TailorMaskChannel3("区域3裁剪使用的通道rgba(值是0或1)", vector) = (0, 0, 1 ,0)
		_TailorValue3("区域3裁剪比例", Range(0,0.99)) = 0
		_TailorGradientDis3("区域3裁剪渐变距离", Range(0,0.5)) = 0.1
		_TailorGradientTex4("裁剪渐变图4", 2D) = "white" {}
		_TailorMaskChannel4("区域4裁剪使用的通道rgba(值是0或1)", vector) = (0, 0, 0 ,1)
		_TailorValue4("区域4裁剪比例", Range(0,0.99)) = 0
		_TailorGradientDis("区域4裁剪渐变距离", Range(0,0.5)) = 0.1
		_TailorRotate("裁剪区域旋转", Range(-60,60)) = 0
		_XCenter("uv坐标的u的中心", Range(0,1)) = 0

        _Reflection ("Reflection", 2D) = "white" {}
        _RimColor ("RimColor", Color) = (1,1,1,1)
		_ReflectionIntension("Reflection Intensity",Range(0,1)) = 0.5

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

    SubShader {
        Tags {
            "Queue"="Transparent"
            "RenderType"="Transparent"
			"ShadowProjector" = "true"
        }
		LOD 150
        Pass {
            Name "ForwardBase"
            Tags {
                "LightMode"="ForwardBase"
            }
            ColorMask RGBA
			Blend SrcAlpha OneMinusSrcAlpha  
            CGPROGRAM
            #pragma skip_variants FOG_EXP INSTANCING_ON DIRECTIONAL DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SHADOWS_SCREEN SHADOWS_SHADOWMASK VERTEXLIGHT_ON SHADOWS_CUBE SHADOWS_DEPTH _Toggle_GlossRepeat POINT SPOT UNITY_HDR_ON
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x//why Too many math instructions for SM2.0 (73 needed, max is 64).
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            //#define SHOULD_SAMPLE_SH_PROBE ( defined (LIGHTMAP_OFF) )
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            /*#pragma multi_compile __ PROJECTOR_DEPTH_MAP_ON
            #include "DepthMapShadow.cginc"*/
            #include "CharacterUber.cginc"
            uniform float4 _LightColor0;
            uniform sampler2D _Reflection; uniform float4 _Reflection_ST;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform fixed4 _Color;
            uniform fixed4 _RimColor;
            uniform fixed _ReflectionIntension;

            #pragma multi_compile __ _Toggle_EnableGlitter
            #pragma multi_compile __ _Toggle_EnableGlitterDynamicTex

            #pragma multi_compile __ _Toggle_EnableGloss
            #pragma multi_compile __ _Toggle_GlossRepeat

            #pragma multi_compile __ _Toggle_EnableMatCap
            #pragma multi_compile __ _Toggle_EnableMatCap2

            uniform sampler2D _NormalMap;
            uniform fixed BumpValue;
            
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
                float4 tangent : TANGENT;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float4 uv0 : TEXCOORD0;

                LIGHTING_COORDS(1,2)
                float4 shLight : TEXCOORD3;

                float4 tspace0 : TEXCOORD4;
                float4 tspace1 : TEXCOORD5;
                float4 tspace2 : TEXCOORD6; 

                float3 TtoV0 : TEXCOORD7;
                //float3 TtoV1 : TEXCOORD8;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0.xy = v.texcoord0;
                //#if SHOULD_SAMPLE_SH_PROBE
                float3 normalDir = UnityObjectToWorldNormal(v.normal);
                o.shLight.xyz = ShadeSH9(float4(normalDir * 1.0,1));
                //#endif
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o)

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
            fixed4 frag(VertexOutput i) : COLOR {
/////// Vectors:
                float3 worldPos = float3(i.tspace0.w, i.tspace1.w, i.tspace2.w);
                float3x3 matrixTBN = float3x3(i.tspace0.xyz, i.tspace1.xyz, i.tspace2.xyz);

                // 法线贴图xy存在rg通道 区域1的反射mask在b通道，
                float3 normalTangent = UnpackNormal(tex2D(_NormalMap, i.uv0));
                normalTangent.xy = normalTangent.xy * BumpValue;
                normalTangent.z = sqrt(1 - saturate(dot(normalTangent.xy, normalTangent.xy)));
                float3 normalDir = mul(matrixTBN, normalTangent);
				normalDir = normalize(normalDir);

                float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));


				fixed4 _MainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
                fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
////// Lighting:
                fixed attenuation = LIGHT_ATTENUATION(i)*0.9;
                fixed3 attenColor = attenuation*_LightColor0.xyz;
/////// Diffuse:
                fixed NdotL = max(0.2,dot( normalDir, lightDirection ));
                //fixed3 indirectDiffuse = UNITY_LIGHTMODEL_AMBIENT.rgb;
                fixed3 directDiffuse = NdotL* attenColor;
                //#if SHOULD_SAMPLE_SH_PROBE
                fixed3 indirectDiffuse = i.shLight;
                //#endif
                fixed3 diffuse = (directDiffuse + indirectDiffuse) * _MainTexColor.rgb;
				float gray = 0.2125 * _MainTexColor.r + 0.7154 * _MainTexColor.g + 0.0721 * _MainTexColor.b;
////// Emissive:
				fixed rimRange = 1-abs(dot(viewDir,normalDir));
                half2 ReflUV = mul( UNITY_MATRIX_V, float4(normalDir,0)).rg*0.5+0.5;
                fixed4 _Reflection_var = tex2D(_Reflection,TRANSFORM_TEX(ReflUV, _Reflection));
				//fixed ReflectionRange = tex2D(_Reflection, TRANSFORM_TEX(i.uv0, _MainTex));
                fixed3 emissive = _Color.rgb+_Reflection_var.rgb*_ReflectionIntension+rimRange*rimRange*_RimColor;
				//float3 emissive = _Color.rgb + _Reflection_var.rgb*ReflectionRange;

/// Final Color:
                fixed3 finalColor = diffuse + emissive;
                /*finalColor *= ShadowColorAtten(half4(worldPos, 1));
				#ifdef PROJECTOR_DEPTH_MAP_ON
				finalColor *= ProjectorShadowColorAtten(half4(worldPos, 1));
				#endif*/

/// Glitter MatCap:
				float3 TtoV1 = float3(i.shLight.w, i.uv0.zw);
				float tailorAlpha = 1.0;
                finalColor = GetGlitterGlossMatcap(_LightColor0.xyz, finalColor,
                 i.uv0.xy, viewDir, worldPos, normalTangent, normalDir, matrixTBN, i.TtoV0, TtoV1, tailorAlpha);
				//return fixed4(gray,0,0,1);
                return fixed4(finalColor,_MainTexColor.a * tailorAlpha);
            }
            ENDCG
        }
//                	Pass {
//		Name "Caster"
//		Tags { "LightMode" = "ShadowCaster" }
//		Offset 1, 1
		
//		Fog {Mode Off}
//		ZWrite On ZTest LEqual Cull Off

//CGPROGRAM
//#pragma vertex vert
//#pragma fragment frag
//#pragma multi_compile_shadowcaster
//#include "UnityCG.cginc"

//struct v2f { 
//	V2F_SHADOW_CASTER;
//	float2  uv : TEXCOORD1;
//};

//uniform float4 _MainTex_ST;

//v2f vert( appdata_base v )
//{
//	v2f o;
//	TRANSFER_SHADOW_CASTER(o)
	
//	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
//	return o;
//}

//uniform sampler2D _MainTex;
//uniform fixed _Cutoff;
//uniform fixed4 _Color;

//float4 frag( v2f i ) : SV_Target
//{
//	fixed4 _MainTexColor = tex2D(_MainTex,i.uv);
//	clip(_MainTexColor.a-(1-_Color.a));
	
//	SHADOW_CASTER_FRAGMENT(i)
//}
//ENDCG
//	}
    }
			FallBack "Mobile/Diffuse"
}
