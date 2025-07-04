// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//注意，最多使用8张纹理！！！。为支持OpenGL ES2.0。
Shader "TLStudio/Character/UberMulti_ashcom2" {
    Properties {
		_StencilValue("StencilValue", Int) = 2
		[HideInInspector][MaterialEnum(UnityEngine.Rendering.CullMode)] _Cull("裁剪模式", Int) = 2
		[HideInInspector][Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 1
		[Group(g1,_MainGroup,3)]_MainGroup("MainGroup", float) = 1
		[Title(g1, Legcy)]
		[Sub(g1)]_Color("AddColor", Color) = (0,0,0,0.5)
		[Sub(g1)][NoScaleOffset] _MainTex ("MainTex", 2D) = "white" {}
		[Sub(g1)][NoScaleOffset] _MainTex2 ("MainTex2", 2D) = "white" {}
		[Sub(g1)][NoScaleOffset] _Reflection("Reflection", 2D) = "white" {}
		[Sub(g1)]_ReflectionIntension("Reflection Intensity",Range(0,1)) = 0.07
		[Sub(g1)]_RimColor("RimColor", Color) = (0,0,0,0.5)
		[Sub(g1)]_RimPower("RimPower,相乘的次数", Range(0,20)) = 2
		[Sub(g1)]_RimIntensity("RimIntensity,强度", Range(0,20)) = 1
		[Sub(g1)]_RimMaskChannel("Rim使用的通道rgba(值是0或1)", vector) = (0, 0, 0 ,0)
		[Title(g1, _MaskTex)]
		[Sub(g1)][NoScaleOffset] _AllSpecialMaskTex("r(亮片遮罩) g(流光区域遮罩) b(反光区域1遮罩) a(反光区域2遮罩)", 2D) = "black" {}

		[Group(g2,_GlitterGroup,3)]_GlitterGroup("GlitterGroup", float) = 1
		[Title(g2, Glitter)]
		[HideInInspector][SubToggle(g2, _Toggle_EnableGlitter)] _Toggle_EnableGlitter("?开启亮片?", Float) = 1
		[Sub(g2)]Roughness ("粗糙度", Range(0, 1)) = 0.2
		[Sub(g2)]IndirLight ("背光强度", Range(0, 1)) = 0.8

		[Title(g2, GlitterStatic)]
		[Sub(g2)]GlitterSpecularColor ("第一层反射颜色", Color) = (1,1,1,1)
		[Sub(g2)][NoScaleOffset] _GlitterSpecularTex ("第一层亮片形状", 2D) = "white" {}
		[Sub(g2)]_GlitterMaskChannel("使用的通道rgba(值是0或1)", vector) = (1, 0, 0 ,0)
		[Sub(g2)]GlitterSpecularTilingScale ("缩放 xy(tilling) z(总)", vector) = (1,1,5,0)
		[Sub(g2)]GlitterSpecularPower ("强度", Range(0, 5)) = 1.5

		[Title(g2, GlitterDynamic)]
		[Sub(g2)]GlitterColor ("第二层反射颜色", Color) = (1,1,1,1)
		[HideInInspector][SubToggle(g2, _Toggle_EnableGlitterDynamicTex)] _Toggle_EnableGlitterDynamicTex("?单独增加一张新贴图?", Float) = 1    //1
		[Sub(g2)][NoScaleOffset] _GlitterTex ("第二层形状", 2D) = "white" {}
		[Sub(g2)]_GlitterDynamicMaskChannel("第二层使用的通道rgba(值是0或1)", vector) = (1, 0, 0 ,0)
		[Sub(g2)]GlitteryTilingScale ("缩放 xy(tilling) z(总)", vector) = (1,1,5,0)
		[Sub(g2)]GlitterPower ("强度", Range(0, 10)) = 2
		[Sub(g2)]GlitterySpeed ("闪烁速度", Range(0, 5)) = 0.1
		[Sub(g2)]GlitterRotateMaskScale ("剔除缩放", Range(0.5, 1.5)) = 1
		[Sub(g2)]GlitterParallaxRotate ("剔除系数", float) = 3.14

		[Group(g3,_GlossGroup,3)]_GlossGroup("GlossGroup", float) = 1
		[Title(g3, Gloss)]
		[HideInInspector][SubToggle(g2, _Toggle_EnableGlitterDynamicTex)] _Toggle_EnableGlitterDynamicTex("?单独增加一张新贴图?", Float) = 1    //1
		[HideInInspector][SubToggle(g3, _Toggle_EnableGloss)] _Toggle_EnableGloss("?开启流光?", Float) = 1
		[Sub(g3)][NoScaleOffset] GlossColor("流光颜色", Color) = (1,1,1,1)
		[Sub(g3)][NoScaleOffset] _GlossTex("流光图", 2D) = "black" {}
		[Sub(g3)]GlossTilingScale ("缩放 xy(tilling) z(总)", vector) = (1,1,1,0)
		[SubToggle(g3, _Toggle_GlossRepeat)] _Toggle_GlossRepeat("?开启使用连续流光(贴图选repeat), 否则是间隔时间流光(贴图选clamp)?", Float) = 0
		[Sub(g3)]GlossSpeedXYTotalStop ("x(速度) |y(贴图旋转) |z(间隔时间) |w(无效)", vector) = (1, 0, 0, 0)
		[Sub(g3)]_GlossDirection("流向:x(方向(0-360)) |y(水平矫正u(-0.5-0.5)) |z(垂直矫正v(-0.5-0.5)) |w(无效)", vector) = (90,0.5,0,0)
		[Sub(g3)]GlossStrength ("强度", Range(0, 10)) = 2
		[Sub(g3)]_GlosslMaskChannel1("使用的通道rgba(值是0或1)", vector) = (0, 1, 0 ,0)

		[Title(g3, Gloss2)]
		[HideInInspector][SubToggle(g3, _Toggle_EnableGloss2)] _Toggle_EnableGloss2("?开启流光?", Float) = 1
		[Sub(g3)][NoScaleOffset] GlossColor2("流光颜色", Color) = (1,1,1,1)
		[Sub(g3)][NoScaleOffset] _GlossTex2("流光图", 2D) = "black" {}
		[Sub(g3)]GlossTilingScale2("缩放 xy(tilling) z(总)", vector) = (1,1,1,0)
		[SubToggle(g3, _Toggle_GlossRepeat2)] _Toggle_GlossRepeat2("?开启使用连续流光(贴图选repeat), 否则是间隔时间流光(贴图选clamp)?", Float) = 0
		[Sub(g3)]GlossSpeedXYTotalStop2("x(速度) |y(贴图旋转) |z(间隔时间) |w(无效)", vector) = (1, 0, 0, 0)
		[Sub(g3)]_GlossDirection2("流向:x(方向(0-360)) |y(水平矫正u(-0.5-0.5)) |z(垂直矫正v(-0.5-0.5)) |w(无效)", vector) = (90,0.5,0,0)
		[Sub(g3)]GlossStrength2("强度", Range(0, 10)) = 2
		[Sub(g3)]_GlosslMaskChannel2("使用的通道rgba(值是0或1)", vector) = (0, 1, 0 ,0)
		[KWEnum(g3, None, None, Mul, Mul, Substract, Substract)] _GlossBlendType("GlossBlendType", float) = 0

		[Group(g4,_NormalGroup,3)]_NormalGroup("NormalGroup", float) = 1
		[Title(g4, _NormalMap)]
		[Sub(g4)]_NormalMap("法线贴图", 2D) = "bump" {}
		[Sub(g4)]BumpValue ("法线强度", Range(0,10)) = 1

		[Group(g5,_MatCapGroup,3)]_MatCapGroup("MatCapGroup", float) = 1
		[Title(g5, MatCap)]
		[HideInInspector][SubToggle(g5, _Toggle_EnableMatCap)] _Toggle_EnableMatCap("?开启反光?", Float) = 1    //1
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
		[HideInInspector][SubToggle(g5, _Toggle_EnableMatCap2)] _Toggle_EnableMatCap2 ("?开启反射区域2?", Float) = 1    //1
		[Sub(g5)]MatCapSpecColor2 ("区域2反射颜色", Color) = (1,1,1,1)
		[Sub(g5)]_MatCapSpecTex2 ("反光贴图", 2D) = "white" {}
		[Sub(g5)]MatCapSpecValue2 ("反射强度", Range(0, 5)) = 1
		[Sub(g5)]MatCapSpecOpposed2 ("原颜色衰减", Range(-0.5, 1)) = 1
		[Sub(g5)]FresnelCol2 ("菲涅尔颜色", Color) = (1, 1, 1, 1)
		[Sub(g5)]FresnelBase2 ("菲涅尔基础值", Range(-1, 5)) = 0.1
		[Sub(g5)]FresnelScale2 ("菲涅尔区域大小", Range(0, 10)) = 0.1
		[Sub(g5)]FresnelIndensity2 ("菲涅尔强度", Range(0, 10)) = 0.1
		[Sub(g5)]_FresnelMaskChannel2("使用的通道rgba(值是0或1)", vector) = (0, 0, 0 ,1)

		[Group(g6,_DetailGroup,3)]_DetailGroup("Disslove", float) = 1
		
		[HideInInspector][SubToggle(g6, _Toggle_Detail1)] _Toggle_Detail1("?开启细节纹理1?", float) = 0
		[HideInInspector][Sub(g6)]_DetailColor1("细节纹理颜色", Color) = (1,1,1,1)
		[HideInInspector][Sub(g6)][NoScaleOffset]_DetailTex1("纹理贴图", 2D) = "black" {}
		[HideInInspector][KWEnum(g6, Screen, Screen, Substract, Substract)] _DetailBlendType1("DetailBlendType1", float) = 0
		[HideInInspector][Sub(g6)]_DetailIntensity1("强度", Range(0, 5)) = 1
		[HideInInspector][Sub(g6)]_DetailScale1("缩放 xy(tilling) z(总)", vector) = (1, 1, 1, 0)
		[HideInInspector][Sub(g6)]_DetailRotate1("x(贴图旋转) |y(水平矫正u(-0.5-0.5)) |z(垂直矫正v(-0.5-0.5)) |w(无效)", vector) = (0, 0, 0, 0)
		[HideInInspector][Sub(g6)]_DetailMaskChannel1("纹理使用的通道rgba(值是0或1)", vector) = (1, 0, 0 ,0)
		[Title(g6, Disslove)]
		[Sub(g6)]_NoiseTex1("Noise", 2D) = "white" {}
		[Sub(g6)]_RampTex("Border Ramp", 2D) = "white" {} //纹理要Clamp
		[Sub(g6)]_EdgeWidth("Edge Width", Range(0.01, 0.2)) = 0.1
		[Sub(g6)]_MinBorderY("Min Border Y", Float) = -0.5 //通常对应脚部Y坐标
		[Sub(g6)]_MaxBorderY("Max Border Y", Float) = 0.5  //通常对应头部Y坐标
		[Sub(g6)]_DistanceEffect("Distance Effect", Range(0.0, 1.0)) = 0.5
		[Sub(g6)]_AshColor("Ash Color", Color) = (1,1,1,1)
		[Sub(g6)]_AshWidth("[Ash Width", Range(0, 0.25)) = 0.1
		[Sub(g6)]_FlyIntensity("Fly Intensity", Range(0,0.3)) = 0.1
		[Sub(g6)]_AshDensity("Ash Density", Range(0, 1)) = 1
		[Sub(g6)]_FlyDirection("Fly Direction", Vector) = (1,1,1,1) 
		[Sub(g6)]_Outline("Outline",Range(0.0, 1.0)) = 0.5
		[Sub(g6)]_Threshold("Threshold", Range(0.0, 1.0)) = 0.001
    }

    Subshader {
        Tags {
            "Queue"="AlphaTest+50"
            "RenderType"="TransparentCutout"
            "ShadowProjector" = "true"
        }
        LOD 150

		CGINCLUDE
		#pragma skip_variants FOG_EXP INSTANCING_ON DIRECTIONAL DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SHADOWS_SCREEN SHADOWS_SHADOWMASK VERTEXLIGHT_ON SHADOWS_CUBE SHADOWS_DEPTH POINT SPOT UNITY_HDR_ON
		#pragma exclude_renderers xbox360 ps3 flash d3d11_9x//why Too many math instructions for SM2.0 (73 needed, max is 64).
		#include "UnityCG.cginc"
        #include "AutoLight.cginc"
        //#include "DepthMapShadow.cginc"
        #include "TLS_Character_UberMulti.cginc"
		#pragma vertex vert
        #pragma fragment frag
		struct VertexInput {
					float4 vertex : POSITION;
					float4 tangent : TANGENT;
					float3 normal : NORMAL;
					float4 texcoord : TEXCOORD0;
					fixed4 color : COLOR;
				};
		 struct v2f { 
                    float4 pos : SV_POSITION;
                    float4 uv0 : TEXCOORD0;

                    float4 tspace0 : TEXCOORD1;
                    float4 tspace1 : TEXCOORD2;
                    float4 tspace2 : TEXCOORD3; 

                    LIGHTING_COORDS(4,5)
                    float4 shLight : TEXCOORD6;
                    //UNITY_FOG_COORDS(7)

                    float4 TtoV0 : TEXCOORD7;
                    //float3 TtoV1 : TEXCOORD9;
					float2 uvNoiseTex1 : TEXCOORD8;
					float3 localPos : TEXCOORD9;
                };
				uniform fixed4 _LightColor0;
                uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
				uniform sampler2D _MainTex2; uniform float4 _MainTex2_ST;
                uniform fixed4 _Color;
				uniform sampler2D _Reflection; uniform half4 _Reflection_ST;
				uniform fixed _ReflectionIntension;
				uniform fixed4 _RimColor;
				half _RimPower;
				half _RimIntensity;
				float4 _RimMaskChannel;

                uniform sampler2D _NormalMap;
                uniform fixed BumpValue;

				

		 ENDCG



		 Pass {
            Name "ForwardBase"
            Tags {
                "LightMode"="ForwardBase"
            }
            ColorMask RGBA
			Cull[_Cull]
			Zwrite[_ZWrite]
			Stencil
			{
				Ref [_StencilValue]         // 写入Stencil的值为1
				Comp always   // 总是写入
				Pass replace  // 替换现有Stencil值
			}

            CGPROGRAM
           
                
             

			
             

				v2f vert (VertexInput v)
                {
                    v2f o = (v2f)0;
                    o.pos = UnityObjectToClipPos (v.vertex);
                    o.uv0.xy = TRANSFORM_TEX(v.texcoord,_MainTex);

                    float3 normalDir = UnityObjectToWorldNormal(v.normal);//  mul(_Object2World, float4(v.normal,0)).xyz;
                    o.shLight.xyz = ShadeSH9(float4(normalDir * 1.0,1));
                    TRANSFER_VERTEX_TO_FRAGMENT(o)
                    //UNITY_TRANSFER_FOG(o,o.pos);

                    float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
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

					//模型空间到切线空间
                    TANGENT_SPACE_ROTATION;
                    o.TtoV0.xyz = normalize(mul(rotation, UNITY_MATRIX_IT_MV[0].xyz));
					o.TtoV0.w = v.color.a;
					float3 TtoV1 = normalize(mul(rotation, UNITY_MATRIX_IT_MV[1].xyz));
					o.shLight.w = TtoV1.x;
					o.uv0.zw = TtoV1.yz;
                    //o.TtoV1 = normalize(mul(rotation, UNITY_MATRIX_IT_MV[1].xyz));
                    return o;
                }
				

                float4 frag (v2f i) : COLOR
                {
                    fixed4 _MainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0.xy, _MainTex));
                    clip(_MainTexColor.a-(1-_Color.a));

/////// Vectors:
                    float3 worldPos = float3(i.tspace0.w, i.tspace1.w, i.tspace2.w);
					//切·	线空间到世界空间的矩阵
                    float3x3 matrixTBN = float3x3(i.tspace0.xyz, i.tspace1.xyz, i.tspace2.xyz);

                    // 法线贴图xy存在rg通道 区域1的反射mask在b通道，
                    float3 normalTangent = UnpackNormal(tex2D(_NormalMap, i.uv0.xy));
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
                    fixed3 indirectDiffuse = i.shLight.xyz;
                    fixed3 diffuse = (directDiffuse + indirectDiffuse) * _MainTexColor.rgb;
////// Emissive:
					fixed4 allMask = tex2D(_AllSpecialMaskTex, i.uv0.xy);
					half rimAlpha = _RimMaskChannel.r * allMask.r + _RimMaskChannel.g * allMask.g + _RimMaskChannel.b * allMask.b + _RimMaskChannel.a * allMask.a;
					half rimAlpha2 = _RimMaskChannel.r + _RimMaskChannel.g + _RimMaskChannel.b + _RimMaskChannel.a;
					rimAlpha2 = saturate(1 - rimAlpha2);
					half meshAlpha = rimAlpha2 * i.TtoV0.w;
					rimAlpha += meshAlpha;

					fixed rimRange = 1 - abs(dot(viewDir, normalDir));
					//测试代码
					/*if (rimRange <= 0)
					{
						return fixed4(rimRange, 0, 0, 1);
					}
					return fixed4(1, 0, 0, 1);*/
					half2 ReflUV = mul(UNITY_MATRIX_V, float4(normalDir, 0)).rg*0.5 + 0.5;
					fixed4 _Reflection_var = tex2D(_Reflection, TRANSFORM_TEX(ReflUV, _Reflection));
                    fixed3 emissive = _Color.rgb + _Reflection_var.rgb*_ReflectionIntension + rimAlpha*_RimIntensity*pow(rimRange, _RimPower)*_RimColor;
/// Final Color:
                    fixed3 finalColor = diffuse + emissive;
                   /* finalColor *= ShadowColorAtten(half4(worldPos, 1));
                    #ifdef PROJECTOR_DEPTH_MAP_ON
                    finalColor *= ProjectorShadowColorAtten(i.posWorld);
                    #endif*/

/// Glitter Gloss MatCap:
					float3 TtoV1 = float3(i.shLight.w, i.uv0.zw);
                    finalColor = GetGlitterGlossMatcap(_LightColor0.xyz, finalColor,
                     i.uv0.xy, viewDir, worldPos, normalTangent, normalDir, matrixTBN, i.TtoV0.xyz, TtoV1);
/// Result:

                    //UNITY_APPLY_FOG(i.fogCoord,finalColor);
                    return fixed4(finalColor,1);
                }

            ENDCG
        }
    





        Pass {
            Name "ForwardBase2"
            Tags {
                "LightMode"="ForwardBase"
            }
            ColorMask RGBA
			Cull[_Cull]
			Zwrite[_ZWrite]

            CGPROGRAM
           

				uniform sampler2D _NoiseTex1;
				uniform float4 _NoiseTex1_ST;
				fixed4 _AshColor;
				float _Threshold;
				float _EdgeWidth;
				sampler2D _RampTex;
				float _MinBorderY;
				float _MaxBorderY;
				float _DistanceEffect;
				float _AshWidth;
				float _FlyIntensity;
				float _AshDensity;
				float4 _FlyDirection;
				float _Outline;

               

				float GetNormalizedDist(float worldPosY)
				{
					float range = _MaxBorderY - _MinBorderY;
					float border = _MaxBorderY;
					
					float dist = abs(worldPosY - border);
				
					float normalizedDist = saturate(dist / range);
					return normalizedDist;
				}


                v2f vert (VertexInput v)
                {
                    v2f o;
                    

                    o.uv0.xy = TRANSFORM_TEX(v.texcoord,_MainTex2);
					o.uvNoiseTex1 = TRANSFORM_TEX(v.texcoord, _NoiseTex1);
					o.localPos = mul(v.vertex,unity_WorldToObject ).xyz;
					float cutout = GetNormalizedDist(o.localPos.y);
					//float3 localFlyDirection = normalize(mul(unity_WorldToObject, _FlyDirection.xyz));
					float3 localFlyDirection = _FlyDirection.xyz;
					float flyDegree = (_Threshold - cutout)/_EdgeWidth;
					float val = max(0, flyDegree * _FlyIntensity);
					v.vertex.xyz += v.normal * _Outline;
					v.vertex.xyz += localFlyDirection * val;

					o.pos = UnityObjectToClipPos(v.vertex);


                    float3 normalDir = UnityObjectToWorldNormal(v.normal);//  mul(_Object2World, float4(v.normal,0)).xyz;
                    o.shLight.xyz = ShadeSH9(float4(normalDir * 1.0,1));
                    TRANSFER_VERTEX_TO_FRAGMENT(o)
                    //UNITY_TRANSFER_FOG(o,o.pos);

                   float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
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

					//模型空间到切线空间
                    TANGENT_SPACE_ROTATION;
                    o.TtoV0.xyz = normalize(mul(rotation, UNITY_MATRIX_IT_MV[0].xyz));
					o.TtoV0.w = v.color.a;
					float3 TtoV1 = normalize(mul(rotation, UNITY_MATRIX_IT_MV[1].xyz));
					o.shLight.w = TtoV1.x;
					o.uv0.zw = TtoV1.yz;
                    //o.TtoV1 = normalize(mul(rotation, UNITY_MATRIX_IT_MV[1].xyz));
                    return o;
                }


                float4 frag (v2f i) : COLOR
                {
                    fixed4 _MainTex2Color = tex2D(_MainTex2, TRANSFORM_TEX(i.uv0.xy, _MainTex2));
                    clip(_MainTex2Color.a-(1-_Color.a));

/////// Vectors:
                    float3 worldPos = float3(i.tspace0.w, i.tspace1.w, i.tspace2.w);
					//切线空间到世界空间的矩阵
                    float3x3 matrixTBN = float3x3(i.tspace0.xyz, i.tspace1.xyz, i.tspace2.xyz);

                    // 法线贴图xy存在rg通道 区域1的反射mask在b通道，
                    float3 normalTangent = UnpackNormal(tex2D(_NormalMap, i.uv0.xy));
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
                    fixed3 indirectDiffuse = i.shLight.xyz;
                    fixed3 diffuse = (directDiffuse + indirectDiffuse) * _MainTex2Color.rgb;
////// Emissive:
					fixed4 allMask = tex2D(_AllSpecialMaskTex, i.uv0.xy);
					half rimAlpha = _RimMaskChannel.r * allMask.r + _RimMaskChannel.g * allMask.g + _RimMaskChannel.b * allMask.b + _RimMaskChannel.a * allMask.a;
					half rimAlpha2 = _RimMaskChannel.r + _RimMaskChannel.g + _RimMaskChannel.b + _RimMaskChannel.a;
					rimAlpha2 = saturate(1 - rimAlpha2);
					half meshAlpha = rimAlpha2 * i.TtoV0.w;
					rimAlpha += meshAlpha;

					fixed rimRange = 1 - abs(dot(viewDir, normalDir));
					//测试代码
					/*if (rimRange <= 0)
					{
						return fixed4(rimRange, 0, 0, 1);
					}
					return fixed4(1, 0, 0, 1);*/
					half2 ReflUV = mul(UNITY_MATRIX_V, float4(normalDir, 0)).rg*0.5 + 0.5;
					fixed4 _Reflection_var = tex2D(_Reflection, TRANSFORM_TEX(ReflUV, _Reflection));
                    fixed3 emissive = _Color.rgb + _Reflection_var.rgb*_ReflectionIntension + rimAlpha*_RimIntensity*pow(rimRange, _RimPower)*_RimColor;
/// Final Color:
                    fixed3 finalColor = diffuse + emissive;
                    /*finalColor *= ShadowColorAtten(half4(worldPos, 1));
                    #ifdef PROJECTOR_DEPTH_MAP_ON
                    finalColor *= ProjectorShadowColorAtten(i.posWorld);
                    #endif*/

/// Glitter Gloss MatCap:
					float3 TtoV1 = float3(i.shLight.w, i.uv0.zw);
                    finalColor = GetGlitterGlossMatcap(_LightColor0.xyz, finalColor,
                     i.uv0.xy, viewDir, worldPos, normalTangent, normalDir, matrixTBN, i.TtoV0.xyz, TtoV1);

//ash
					float commonNoise = tex2D(_NoiseTex1, i.uvNoiseTex1).r;
					float whiteNoise = tex2D(_NoiseTex1, i.uvNoiseTex1).r;

					float normalizedDist = GetNormalizedDist(i.localPos.y);
					float cutout = commonNoise * (1 - _DistanceEffect) + normalizedDist * _DistanceEffect;

					float edgeCutout = cutout - _Threshold;
					clip(edgeCutout + _AshWidth); //延至灰烬宽度处才剔除掉
				
					float degree = saturate(edgeCutout / _EdgeWidth);
					fixed4 edgeColor = tex2D(_RampTex,float2(degree, degree))*fixed4(finalColor.rgb,1)+fixed4(finalColor.rgb,1)*0.3;
					//fixed4 edgeColor =pow(  fixed4(finalColor.rgb,1),0.1);
					//fixed4 edgeColor =fixed4(finalColor.rgb,1);
					fixed4 AshColor =_AshColor*edgeColor+edgeColor;
					
					fixed4 finalColor2 = fixed4(lerp(AshColor, finalColor, degree).rgb, 1);
					if(degree < 0.001)
					{
						clip(whiteNoise * _AshDensity + normalizedDist * _DistanceEffect - _Threshold); //灰烬处用白噪声来进行碎片化
						finalColor2 = AshColor*fixed4(finalColor.rgb,1);
					}
					/*finalColor2 *= ShadowColorAtten(half4(worldPos, 1));
                    #ifdef PROJECTOR_DEPTH_MAP_ON
                    finalColor2 *= ProjectorShadowColorAtten(i.posWorld);
                    #endif*/

/// Result:

                    //UNITY_APPLY_FOG(i.fogCoord,finalColor);
					return fixed4(finalColor2.rgb,_MainTex2Color.a);
                }

            ENDCG
        }
    }

	FallBack "Mobile/Diffuse"
	CustomEditor "ShaderDrawerEditor"
}
