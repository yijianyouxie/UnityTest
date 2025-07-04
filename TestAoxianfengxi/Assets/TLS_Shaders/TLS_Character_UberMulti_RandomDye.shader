// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//注意，最多使用8张纹理！！！。为支持OpenGL ES2.0。
Shader "TLStudio/Character/UberMulti_RandomDye" {
	Properties{
		_StencilValue("StencilValue", Int) = 2
		[MaterialEnum(UnityEngine.Rendering.BlendMode)] _SrcBlend("    源混合因子SrcBlend", Float) = 5
		[MaterialEnum(UnityEngine.Rendering.BlendMode)] _DstBlend("    目标混合因子DestBlend", Int) = 10
		_DyeColor1("染色区域1颜色", Color) = (0,0,0,0)
		_Alpha1("颜色1浓度",Range(0,1)) = 1
		_DyeColor2("染色区域2颜色", Color) = (0,0,0,0)
		_Alpha2("颜色2浓度",Range(0,1)) = 1
		_DyeColor3("染色区域3颜色", Color) = (0,0,0,0)
		_Alpha3("颜色3浓度",Range(0,1)) = 1
		_DyeDivisionalMask("控制图：r(染色1) g(染色2) b(细节) a(灰度图)", 2D) = "black" {}
		//[HideInInspector]
		_Limit("颜色最大值",Range(0,1)) = 0.9
		_SpecOffet_S("反光饱和度差",Range(0,0.5)) = 0.2
		_SpecOffet_V("反光明度差",Range(0,0.5)) = 0.2
		[Group(g1,_MainGroup,3)]_MainGroup("MainGroup", float) = 1
		[Title(g1, Legcy)]
		[Sub(g1)]_Color("AddColor", Color) = (0,0,0,0.5)
		[Sub(g1)][NoScaleOffset] _MainTex ("MainTex", 2D) = "white" {}

		[Title(g1, Tailor)]
		[Sub(g1)][NoScaleOffset] _TailorTex("裁剪控制图TailorTex", 2D) = "white" {}
		[Sub(g1)]_TailorGradientTex("裁剪渐变图", 2D) = "white" {}
		[Title(g1, Tailor1)]
		[Sub(g1)]_TailorMaskChannel1("区域1裁剪使用的通道rgba(值是0或1)", vector) = (1, 0, 0 ,0)
		[Sub(g1)]_TailorValue1("区域1裁剪比例", Range(0,0.99)) = 0
		[Sub(g1)]_TailorGradientDis1("区域1裁剪渐变距离", Range(0,0.5)) = 0.1
		[Title(g1, Tailor2)]
		[Sub(g1)]_TailorMaskChannel2("区域2裁剪使用的通道rgba(值是0或1)", vector) = (0, 1, 0 ,0)
		[Sub(g1)]_TailorValue2("区域2裁剪比例", Range(0,0.99)) = 0
		[Sub(g1)]_TailorGradientDis2("区域2裁剪渐变距离", Range(0,0.5)) = 0.1
		[Title(g1, Tailor3)]
		[Sub(g1)]_TailorMaskChannel3("区域3裁剪使用的通道rgba(值是0或1)", vector) = (0, 0, 1 ,0)
		[Sub(g1)]_TailorValue3("区域3裁剪比例", Range(0,0.99)) = 0
		[Sub(g1)]_TailorGradientDis3("区域3裁剪渐变距离", Range(0,0.5)) = 0.1
		[Title(g1, Tailor4)]
		[Sub(g1)]_TailorMaskChannel4("区域4裁剪使用的通道rgba(值是0或1)", vector) = (0, 0, 0 ,1)
		[Sub(g1)]_TailorValue4("区域4裁剪比例", Range(0,0.99)) = 0
		[Sub(g1)]_TailorGradientDis4("区域4裁剪渐变距离", Range(0,0.5)) = 0.1
		[Sub(g1)]_TailorRotate("裁剪区域旋转", Range(-60,60)) = 0
		[Sub(g1)]_XCenter("uv坐标的u的中心", Range(0,1)) = 0

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
		[SubToggle(g2, _Toggle_EnableGlitter)] _Toggle_EnableGlitter("?开启亮片?", Float) = 0
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
		[SubToggle(g2, _Toggle_EnableGlitterDynamicTex)] _Toggle_EnableGlitterDynamicTex("?单独增加一张新贴图?", Float) = 0    //1
		[Sub(g2)][NoScaleOffset] _GlitterTex ("第二层形状", 2D) = "white" {}
		[Sub(g2)]_GlitterDynamicMaskChannel("第二层使用的通道rgba(值是0或1)", vector) = (1, 0, 0 ,0)
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
		[Sub(g3)]_GlossDirection("流向:x(方向(0-360)) |y(水平矫正u(-0.5-0.5)) |z(垂直矫正v(-0.5-0.5)) |w(无效)", vector) = (90,0.5,0,0)
		[Sub(g3)]GlossStrength ("强度", Range(0, 10)) = 2
		[Sub(g3)]_GlosslMaskChannel1("使用的通道rgba(值是0或1)", vector) = (0, 1, 0 ,0)

		[Title(g3, Gloss2)]
		[SubToggle(g3, _Toggle_EnableGloss2)] _Toggle_EnableGloss2("?开启流光?", Float) = 0
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

		[Group(g6,_DetailGroup,3)]_DetailGroup("DetailGroup", float) = 1
		[Title(g6, Detail1)]
		[SubToggle(g6, _Toggle_Detail1)] _Toggle_Detail1("?开启细节纹理1?", float) = 0
		[Sub(g6)]_DetailColor1("细节纹理颜色", Color) = (1,1,1,1)
		[Sub(g6)][NoScaleOffset]_DetailTex1("纹理贴图", 2D) = "black" {}
		[KWEnum(g6, Screen, Screen, Substract, Substract)] _DetailBlendType1("DetailBlendType1", float) = 0
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
			Blend[_SrcBlend][_DstBlend]
			Stencil
			{
				Ref [_StencilValue]         // 写入Stencil的值为1
				Comp always   // 总是写入
				Pass replace  // 替换现有Stencil值
			}

            CGPROGRAM
            #pragma skip_variants FOG_EXP INSTANCING_ON DIRECTIONAL DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SHADOWS_SCREEN SHADOWS_SHADOWMASK VERTEXLIGHT_ON SHADOWS_CUBE SHADOWS_DEPTH POINT SPOT UNITY_HDR_ON
				#pragma exclude_renderers xbox360 ps3 flash d3d11_9x//why Too many math instructions for SM2.0 (73 needed, max is 64).
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "AutoLight.cginc"
                //#include "DepthMapShadow.cginc"
                #include "TLS_Character_UberMulti.cginc"

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
				};

				uniform fixed4 _LightColor0;
				uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
				uniform fixed4 _Color;
				uniform fixed4 _DyeColor1;
				uniform fixed4 _DyeColor2;
				uniform fixed4 _DyeColor3;
				uniform sampler2D _DyeDivisionalMask;
				uniform fixed _Alpha1;
				uniform fixed _Alpha2;
				uniform fixed _Alpha3;
				uniform fixed _Limit;
				uniform fixed _SpecOffet_S;
				uniform fixed _SpecOffet_V;
				//uniform fixed _Constract;
				//uniform fixed _ValueOffset;
				uniform sampler2D _Reflection; uniform half4 _Reflection_ST;
				uniform fixed _ReflectionIntension;
				uniform fixed4 _RimColor;
				half _RimPower;
				half _RimIntensity;
				float4 _RimMaskChannel;

				uniform sampler2D _NormalMap;
				uniform fixed BumpValue;

				v2f vert (VertexInput v)
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

				fixed getLuma(fixed3 rgb) {
					const fixed3 lum = fixed3(0.299, 0.587, 0.144);
					fixed3 lumCol = dot(rgb, lum);
					return lumCol;
				}
				fixed3 getLimit(fixed3 col) {
					col.r = _Limit * col.r + (1 - _Limit);
					col.g = _Limit * col.g + (1 - _Limit);
					col.b = _Limit * col.b + (1 - _Limit);
					return col;
				}
				float3 RGB2HSV(float3 c)
				{
					float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
					float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
					float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

					float d = q.x - min(q.w, q.y);
					float e = 1.0e-10;
					return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
				}
				float3 HSV2RGB(float3 c) {
					float3 rgb = clamp(abs(fmod(c.x*6.0 + float3(0.0, 4.0, 2.0), 6) - 3.0) - 1.0, 0, 1);
					rgb = rgb*rgb*(3.0 - 2.0*rgb);
					return c.z * lerp(float3(1, 1, 1), rgb, c.y);
				}
				float4 frag(v2f i) : COLOR
                {
                    fixed4 _MainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0.xy, _MainTex));
                    clip(_MainTexColor.a-(1-_Color.a));

////// 随心染:
					fixed4 dyeMask = tex2D(_DyeDivisionalMask, i.uv0.xy);
					fixed3 ModelCol = fixed3(dyeMask.a, dyeMask.a, dyeMask.a);
					fixed3 Color1 = lerp(_MainTexColor.rgb, ModelCol*getLimit(_DyeColor1), _Alpha1)*dyeMask.r;
					fixed3 Color2 = lerp(_MainTexColor.rgb, ModelCol*getLimit(_DyeColor2), _Alpha2)*dyeMask.g;
					fixed3 Color3 = lerp(_MainTexColor.rgb, ModelCol*getLimit(_DyeColor3), _Alpha3)*dyeMask.b;
					fixed3 TargetCol = Color1 + Color2 + Color3 +  _MainTexColor*(1 - dyeMask.g - dyeMask.b - dyeMask.r);
					//随心染的反光
					fixed3 TargetH = RGB2HSV(_DyeColor3.rgb).r;
					fixed3 TargetS = RGB2HSV(_DyeColor3.rgb).g;
					fixed3 TargetV = RGB2HSV(_DyeColor3.rgb).b;
#if _Toggle_EnableMatCap
					fixed3 MatCapSpecColor1_HSV = RGB2HSV(MatCapSpecColor1.rgb);
					MatCapSpecColor1_HSV.r = TargetH;
					MatCapSpecColor1_HSV.g = TargetS - _SpecOffet_S;
					MatCapSpecColor1_HSV.b = TargetV + _SpecOffet_V;
					MatCapSpecColor1 = lerp(MatCapSpecColor1, HSV2RGB(MatCapSpecColor1_HSV), _Alpha3);
#if _Toggle_EnableMatCap2

				fixed3 MatCapSpecColor2_HSV = RGB2HSV(MatCapSpecColor2.rgb);
				MatCapSpecColor2_HSV.r = TargetH;
				MatCapSpecColor2_HSV.g = TargetS - _SpecOffet_S;
				MatCapSpecColor2_HSV.b = TargetV + _SpecOffet_V;
				MatCapSpecColor2 = lerp(MatCapSpecColor1, HSV2RGB(MatCapSpecColor2_HSV), _Alpha3);
#endif
#endif		

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
					fixed3 diffuse = (directDiffuse + indirectDiffuse) * TargetCol.rgb;
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
					float tailorAlpha = 1.0;
					float3 TtoV1 = float3(i.shLight.w, i.uv0.zw);
					finalColor = GetGlitterGlossMatcapTailor(_LightColor0.xyz, finalColor,
						i.uv0.xy, viewDir, worldPos, normalTangent, normalDir, matrixTBN, i.TtoV0.xyz, TtoV1, tailorAlpha);
/// Result:

                    //UNITY_APPLY_FOG(i.fogCoord,finalColor);
                    return fixed4(finalColor, tailorAlpha);
                }

		ENDCG
	}
	}

		FallBack "Mobile/Diffuse"
		CustomEditor "ShaderDrawerEditor"
}
