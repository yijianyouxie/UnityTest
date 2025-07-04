// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/**
* 角色渲染材质，适用于角色上除了头发之外的所有部位
* 基于brdf2的pbr修改，支持3s皮肤，染色，细节法线
* 受场景中的light probe影响，以及自定义的两个方向光影响，不支持点光源以及场景中的其他光源
* 主光和辅光都进行标准pbr计算，其中辅光的diffuse来自于辅光的方向，辅光的specular来自于视线方向，皮肤部分
* 支持自定义环境球
* workflow只保留metallic workflow
* 控制图 r通道金属度，g通道光滑度，b通道皮肤通道（皮肤部分有各个部队的具体数值，非皮肤部分严格为0），a通道为ao，控制图要去掉srgb勾选项
* CharMask图 r通道控制DyeColor1的部位，g通道控制DyeColor2的部位，b通道控制DetailNormal1的部位，a通道控制DetailNormal2的部位，如果某个通道没使用，填为0，CharMask图要去掉srgb勾选项，Mask图请使用_CharMask后缀，建议128即可，CharMask图不要压缩
* 细节法线请统一使用_DetailNormal后缀，建议大小为32，不压缩，通过调大平铺次数来增加细节
* */

Shader "TLStudio/CharSkin_Middle"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_BodySkinColor("BodySkinColor(肤色用)", Color) = (1,1,1,1)
		//_SkinShadowColor("SkinShadow Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Normal("Normal", 2D) = "bump" {}
		_Metallic("MixedConfigMap", 2D) = "white" {}
		_AO("AO", Range(0,1)) = 1
		//_Mask("Mask", 2D) = "black" {}
		_ScatterColor("Scatter Color", Color) = (0,0,0,1)
		_ScatterProfileColor("Scatter Profile Color", Color) = (1,0,0,1)
		_SkinLightIntensity("SkinLightIntensity", float) = 1
		//_SkinSI("SkinSpecularIntensity",Range(1,10)) = 1
		[Toggle] _gray("Gray", float) = 0
		_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
		[NoScaleOffset]_EnvCube("Environment Cube", Cube) = "evn" {}
		[HDR]_EnvColor("Environment Color", Color) = (1,1,1,1)

		[MaterialEnum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
		[HideInInspector] _Mode("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
		[HideInInspector] _ZWrite("__zw", Float) = 1.0

		[HideInInspector] _GlitterColor("GlitterColor", Color) = (0,0,0,1)//闪白颜色
		[HideInInspector] _GlitterColorWidth("GlitterColorWidth",Range(2,10)) = 2
	}

	/////////////////////<-Properties/////////////////////////////
    SubShader {

        Tags {
            /*"Queue"="Geometry+400"
            "RenderType"="Opaque"*/

			"Queue" = "AlphaTest+50"
			"RenderType" = "TransparentCutout"
			"ShadowProjector" = "true"
        }
		LOD 150
		/*Stencil{
			Ref 1
			Comp always
			Pass replace
		}*/
		cull [_Cull]
		Blend[_SrcBlend][_DstBlend]
		ZWrite[_ZWrite]

        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
			//#include "CGIncludes/DynamicPointLight.cginc"
			//#include "CGIncludes/UnityStandardBRDF.cginc"
//#ifdef	_AVATARMESHHINT
//			#include "AvatarCommon.cginc"
//#endif
            #pragma multi_compile_fwdbase
			#pragma multi_compile _ _ALPHATEST_ON _ALPHAPREMULTIPLY_ON
			//#pragma multi_compile _ _AVATARMESHHINT
			//#pragma multi_compile _ _RAIN
			//#pragma multi_compile _ _SHADOWS_PCF
			#pragma multi_compile _ _UICHAR
            #pragma multi_compile FOG_EXP2 FOG_LINEAR
            #pragma exclude_renderers  xbox360 xboxone ps3 ps4 psp2 

			/*#pragma multi_compile __ PROJECTOR_DEPTH_MAP_ON
			#include "DepthMapShadow.cginc"*/
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
            #pragma exclude_renderers xbox360 ps3 flash d3d11_9x
///Color////////////////////
			fixed4 _Color;
			fixed4 _GlitterColor;
			//float4 _EmissionColor;
			float4 _SkinShadowColor;
			half3 _EnvColor;
			fixed3 _ScatterColor;
			fixed3 _ScatterProfileColor;
			float4 _AmbientTop;
			float4 _AmbinetDown;
//float4 _EmitIntensity;
///Sampler//////////////
            sampler2D _MainTex; 
            sampler2D _Normal;
            sampler2D _Metallic;
			//sampler2D _Mask;
			sampler2D _SkinProfile;
            //sampler2D _Emit;
//#ifdef _DETAILNORMAL
//			sampler2D _DetailNormal;
//			half _DetailNormalScale;
//			sampler2D _DetailNormal2;
//			half _DetailNormal2Scale;
//			sampler2D _DetailNormal3;
//			half _DetailNormal3Scale;
//#endif
			samplerCUBE _EnvCube;
//#ifdef _RAIN
//			sampler2D _RainCharNormal;
//#endif
///float//////////////////
            //fixed _MetallicAdjust;
            //fixed _GlossAdjust;
			fixed _AO;
			fixed _gray;
			float _GlobalEnvIntensity;
			//half _SSSWrap;
			//fixed _SSSOpen;
			fixed _ShadowAttenFactor;
			half _GlitterColorWidth;
			float _SkinLightIntensity;
			//float _SkinSI;
//float _EmitDensity,_EmitSize;
			
#ifdef _ALPHATEST_ON
			fixed _Cutoff;
#endif

//#ifdef _RAIN
		//float _rainIntensity;
		//float _flowRate;
		//float _rainTiling;
//#endif
		
///float4////////////////////
		half4 _CharLightDir;
		half4 _CharLightColor;
		half4 _CharFillLightDir;
		half4 _CharFillLightColor;

		half4 _UICharLightDir;
		half4 _UICharLightColor;
		half4 _UICharFillLightDir;
		half4 _UICharFillLightColor;

		float4 _MainTex_ST;
		//float4 _DetailNormal_ST;
		//float4 _DetailNormal2_ST;
		//float4 _DetailNormal3_ST;

		//float4 _Aniso;

		float3 _BodySkinColor;

				///sparkle相关
		sampler2D _SparkleTex;
		sampler2D _SparkleMaskTex;

		float4 _SparkleEyeColor;
		float _SparkleEyeSpacing;
		float4 _SparkleLipColor;
		float _SparkleLipSpacing;
		float4 _SparkleCheekColor;
		float _SparkleCheekSpacing;

///////////Struct/////////////////////////////////
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
                float4 viewPos : TEXCOORD7;
                UNITY_FOG_COORDS(8)
            };
///////////Fuction/////////////////
		inline half3 DiffuseAndSpecularFromMetallic (half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
		{
			specColor = lerp (unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
			half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
			oneMinusReflectivity = oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
			return albedo * oneMinusReflectivity;
		}
		//float hash(float2 p) 
		//{
		//    float h = dot(p, float2(127.1, 311.7));
		//    return frac(sin(h)*43758.5453123);
		//}
		//float noise(float2 p) 
		//{
		//    float2 i = floor(p);
		//    float2 f = frac(p);
		//    float2 u = f*f*(3.0 - 2.0*f);
		//    float n = lerp(lerp(hash(i),hash(i + float2(1.0, 0.0)), u.x),lerp(hash(i + float2(0.0, 1.0)),hash(i + 1), u.x), u.y);
		//    return n;
		//}
////反射计算 
		inline void Reflection(float3 Normal,float Metallic,float Roughness,half3 worldViewDir,inout float3 indirectSpecular)
		{
			half3 reflUVW   = reflect(-worldViewDir, Normal);
			half perceptualRoughness = Roughness /* perceptualRoughness */;
			perceptualRoughness = perceptualRoughness * (1.7 - 0.7*perceptualRoughness);
			half mip =perceptualRoughness*4+2;
			half3 R = reflUVW;
			half4 rgbm = texCUBElod(_EnvCube, half4(R, mip));
////改用RGBM编码将亮度信息存储到A通道 默认rgbm.a*15，现在因为反射图都没有a信息所以先乘零。
			indirectSpecular = rgbm.rgb*(1+rgbm.a*0)* _GlobalEnvIntensity* _EnvColor.rgb;
		}
		//inline half4 Pow5 (half4 x)
		//{
		//	return x*x * x*x * x;
		//}
		//inline half3 FresnelTerm (half3 F0, half cosA)
		//{
		//	half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
		//	return F0 + (1-F0) * t;
		//}

		//inline half PerceptualRoughnessToSpecPower (half perceptualRoughness)
		//{
		//	half m = perceptualRoughness*perceptualRoughness;   // m is the true academic roughness.
		//	half sq = max(1e-4f, m*m);
		//	half n = (2.0 / sq) - 2.0;                          // https://dl.dropboxusercontent.com/u/55891920/papers/mm_brdf.pdf
		//	n = max(n, 1e-4f);                                  // prevent possible cases of pow(0,0), which could happen when roughness is 1.0 and NdotH is zero
		//	return n;
		//}


		half GetSpecularTerm(half roughness, half nh, half lh, half curvature)
		{
			
			// GGX Distribution multiplied by combined approximation of Visibility and Fresnel
			// See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
			// https://community.arm.com/events/1155
			roughness += lerp(0, 0.25, ceil(curvature));
			half a = roughness;
			half a2 = a*a;

			half d = nh * nh * (a2 - 1.h) + 1.00001h;

			half specularTerm = a2 / (max(0.1h, lh*lh) * (roughness + 0.5h) * (d * d) * 4);
			// on mobiles (where half actually means something) denominator have risk of overflow
			// clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
			// sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
			#if defined (SHADER_API_MOBILE)
				specularTerm = specularTerm - 1e-4h;
			#endif

			#if defined (SHADER_API_MOBILE)
				specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
			#endif
			#if defined(_SPECULARHIGHLIGHTS_OFF)
				specularTerm = 0.0;
			#endif

			return specularTerm;
		}

		//float KS_Skin_Specular(half3 N,// Bumped surface normal
		//half3 L,// Points to light
		//half3 V,// Points to eye
		//half m// Roughness
		//)
		//{
		//	//m = m * 0.09 + 0.23;
		//	half3 h = L + V; // Unnormalized half-way vector
		//	half3 H = normalize( h );
		//	half ndoth = (dot( N, H ));
		//	//half4 profileUV = half4(ndoth, m, 0, 0);
		//	half PH = pow( 2.0 * tex2D( _SkinProfile, half2(ndoth, m)).a, 10);
		//	//float F = fresnelReflectance( H, V, 0.028 );
		//	half F = FresnelTerm(0.028, saturate(ndoth));
		//	return max( PH * F / dot( h, h ), 0 );
		//}

		half3 BlendNormals(half3 n1, half3 n2)
		{
			return normalize(half3(n1.xy + n2.xy, n1.z*n2.z));
		}
///VF:
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _MainTex);
//#ifdef _DETAILNORMAL
//				o.uv1 = TRANSFORM_TEX(v.texcoord0, _DetailNormal);
//				o.uv2 = TRANSFORM_TEX(v.texcoord0, _DetailNormal2);
//				o.uv3 = TRANSFORM_TEX(v.texcoord0, _DetailNormal3);
//#endif
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul(unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex );
				o.viewPos.xy = UnityObjectToViewPos(v.vertex).xy;
				o.viewPos.zw = v.vertex.xz;
                if(UseHeightFog > 0)
                {
                	TL_TRANSFER_FOG(o,o.pos, v.vertex);
                }else
                {
	                UNITY_TRANSFER_FOG(o,o.pos);                
                }
                TRANSFER_VERTEX_TO_FRAGMENT(o)
				TRANSFER_SHADOW(o)
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
///tex2D:
				float4 _MainTex_var = tex2D(_MainTex,i.uv0);
				float3 _Normal_var = UnpackNormal(tex2D(_Normal,i.uv0));
				float4 _Metallic_var = tex2D(_Metallic,i.uv0);
				//float4 _Mask_var =tex2D(_Mask,i.uv0);
//#ifdef _DETAILNORMAL
//				float3 _DetailNormal_var = UnpackNormal(tex2D(_DetailNormal,i.uv1));
//				float3 _DetailNormal_var2 = UnpackNormal(tex2D(_DetailNormal2,i.uv2));
//				float3 _DetailNormal_var3 = UnpackNormal(tex2D(_DetailNormal3,i.uv3));
//			    _Normal_var= BlendNormals(_Normal_var,lerp(float3(0,0,1),_DetailNormal_var,_Mask_var.r*_DetailNormalScale));
//				_Normal_var= BlendNormals(_Normal_var,lerp(float3(0,0,1),_DetailNormal_var2,_Mask_var.g*_DetailNormal2Scale));
//				_Normal_var= BlendNormals(_Normal_var,lerp(float3(0,0,1),_DetailNormal_var3,_Mask_var.b*_DetailNormal3Scale));
//#endif

			#ifdef _ALPHATEST_ON
				clip(_MainTex_var.a - _Cutoff);
			#endif
//#ifdef _RAIN
	//#ifndef _UICHAR
	//			float coefficient = _rainIntensity*(1-_Metallic_var.b);
	//			float4 RainNormal = float4(noise(i.viewPos.zw*float2(80,260)-(_Time.y*10)),noise(i.viewPos.zw*float2(70,300)-(_Time.y*5)),1,1);
	//			RainNormal.xy *= 0.1;
	//			_Normal_var = lerp(_Normal_var,BlendNormals(_Normal_var,RainNormal),coefficient);
	//#endif
//#endif
///////// MSA: 
				float Metallic = (_Metallic_var.r);
				float Smoothness = (_Metallic_var.g);
//#ifdef _RAIN
	//#ifndef _UICHAR
	//			Metallic = lerp(Metallic, max(0.3, Metallic),coefficient);
	//			Smoothness = lerp(Smoothness, max(0.5,Smoothness), coefficient);
	//#endif
//#endif
                float Ao = _Metallic_var.a;
                float curvature =_Metallic_var.b;
				half perceptualRoughness = 1-Smoothness;
				half roughness = perceptualRoughness * perceptualRoughness;
///normal:
                i.normalDir = normalize(i.normalDir);
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 normalLocal = _Normal_var.rgb;
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals

////// LightingData:
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				float attenuation = 0.5;// LIGHT_ATTENUATION(i);
#ifdef _UICHAR
				float3 lightDirection =normalize( _UICharLightDir.xyz);
				float3 lightColor =  _UICharLightColor.xyz *= saturate(attenuation + _ShadowAttenFactor);
				float3 fillLightDir = normalize(_UICharFillLightDir.xyz);
				fixed3 fillLightColor = _UICharFillLightColor.rgb;
#else
				float3 lightDirection = normalize(_CharLightDir.xyz);
				float3 lightColor = _CharLightColor.xyz *= saturate(attenuation + _ShadowAttenFactor);
				float3 fillLightDir = normalize(_CharFillLightDir.xyz);
				fixed3 fillLightColor = _CharFillLightColor.rgb;
#endif
////增加了一个皮肤部分主光强度的控制
				lightColor = lerp(lightColor,lightColor*_SkinLightIntensity,ceil(curvature));
				fillLightColor =  lerp(fillLightColor,fillLightColor*_SkinLightIntensity,ceil(curvature));
				//lightDirection = mul(unity_ObjectToWorld, lightDirection);
                float3 attenColor = attenuation *  _CharLightColor.rgb;
				float3 diffuseColor = (_MainTex_var.rgb*_Color.rgb); 
				
//#ifdef	_AVATARMESHHINT
//				diffuseColor = ExecuteAvatarHintMesh(fixed4(diffuseColor,1),i.uv0);
//#endif
				diffuseColor = lerp(diffuseColor, diffuseColor * _BodySkinColor, ceil(_Metallic_var.b));

				float alpha = 1;
#ifdef _ALPHAPREMULTIPLY_ON
				alpha =_MainTex_var.a*_Color.a;
				diffuseColor *=alpha;
#endif
/////// GI Data:
				float3 indirectDiffuse;
				float3 indirectSpecular;
				float TopN = (dot(normalDirection,float3(0,1,0))+1)*0.5;
				float4 ambientColor = lerp(_AmbinetDown,_AmbientTop,TopN);
				half fillLightFactor = saturate(dot(normalDirection, fillLightDir)) * 0.65 + 0.35;
				indirectDiffuse = ambientColor.rgb+fillLightColor * fillLightFactor;
				Reflection(normalDirection,Metallic,perceptualRoughness,viewDirection,indirectSpecular );
////// Specular:
				float3 halfDirection = normalize(viewDirection+lightDirection);
                float NdotL =dot( normalDirection, lightDirection );
                float LdotH = saturate(dot(lightDirection, halfDirection));
                float3 specularColor;
                float specularMonochrome;
                diffuseColor = DiffuseAndSpecularFromMetallic( diffuseColor, Metallic, specularColor, specularMonochrome );
                //specularMonochrome = 1.0-specularMonochrome;
                float NdotV = saturate(dot( normalDirection, viewDirection ));
////主光源各向异性高光计算 kajiya-kay光照模型
				normalDirection =normalize( normalDirection);
                float NdotH = max(0.0,dot(normalDirection, halfDirection ));
				//NdotH = lerp(NdotH,max(0,sin(radians(NdotH+_Aniso.z)*180)),_Mask_var.a);
				//specularColor = lerp(specularColor,diffuseColor*0.3,_Mask_var.a);
                float SpecularTerm;
//				if (curvature >0.05)
//				{
//////这里控制了一下光滑度的衰减速度避免脸上一大片高光。
//					//half SpecularTerm = KS_Skin_Specular(normalDirection, lightDirection, viewDirection, saturate(1 - 1.5*Smoothness));
//////预处理粗糙度取max（x，0.1）是避免脸部绝对光滑。过于光滑的表面高光会变成一个点，比如瓷器。
//					SpecularTerm = KS_Skin_Specular(normalDirection, lightDirection, viewDirection, max(perceptualRoughness,0.1));
//				//	SpecularTerm = half3(skinSpecular, skinSpecular, skinSpecular);
//				}else
//				{
//					SpecularTerm = GetSpecularTerm(roughness, perceptualRoughness, Smoothness,NdotH, LdotH);
//				}
				SpecularTerm = GetSpecularTerm(roughness,NdotH, LdotH, curvature);
////用视代替光照方向计算第二高光 因为h = Normalize（L+V） 所以h = normalize（V+V）V是单位向量因此h= 2V /2 = V 
				//float NdotH2 =NdotV;
////丝绸部分用和头发一样的kj光照模型来处理各向异性高光。
				//NdotH2 = lerp(NdotH2,max(0,sin(radians(NdotH2+_Aniso.a)*180)),_Mask_var.a);
////直接光照高光计算
                float3 directSpecular = SpecularTerm*lightColor*saturate(NdotL)*specularColor;//高光不明显用这一行替换。因为KS皮肤不用s走非金属F0 为0.04的反射计算。
				//half specularPower = PerceptualRoughnessToSpecPower(perceptualRoughness);

////计算第二个高光
				//SpecularTerm = ((specularPower + 1) * pow(NdotH2,specularPower))/8;
				//SpecularTerm = clamp(SpecularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
                //directSpecular +=SpecularTerm * specularColor * fillLightColor *(1-ceil(curvature));
                //half grazingTerm = saturate( Smoothness + specularMonochrome );
                indirectSpecular *=specularColor;
////衣服的遮蔽计算直接从GGX里抄过来。
				half surfaceReduction = (0.6 - 0.08*perceptualRoughness);
				surfaceReduction = 1.0 - roughness*perceptualRoughness*surfaceReduction;
/////去掉皮肤部分的遮蔽计算。
                surfaceReduction = lerp(surfaceReduction,1,(1-ceil(curvature)));
				//float noisenoise = frac(sin(dot(floor(i.uv1.xy*100),float2(425,1025)))*43758.32654);
				//float2 noiseuvfloor = floor(i.uv0*50);
				//float3 transView = mul(UNITY_MATRIX_IT_MV, float4(0.01,0.01,0.01,0));
				//noisenoise = frac(sin(dot(noisenoise*transView.xy*0.01, float2(100,200)))*500);
				//float aa = saturate(frac(sin(dot(float2(3469.336,4463.251)+transView.xz, noiseuvfloor))*4689.215)-0.49);
				//float bb = round(saturate(frac(sin(dot(float2(421.336,1463.251), noiseuvfloor))*689.215)+1.49));
				//float4 SilkNoise = tex2D(_Emit,i.uv0.xy*15);//闪点控制图的b通道用来给丝绸加一层noise
                float3 specular = (/*(SilkNoise.b*3*directSpecular.r+directSpecular)*_Mask_var.a+(1-_Mask_var.a)*/directSpecular + indirectSpecular)*surfaceReduction;///如果美术角色皮肤有一层白光去掉皮肤部分的反射就可以。使用这一行代替下一行代码。
               // float3 specular = (directSpecular + indirectSpecular*ceil(curvature)*3)*surfaceReduction;

//// Diffuse:
				half scaledNL = saturate( (NdotL + 1 + curvature) / (2.0 + curvature) );
				//half4 profileUV = half4(scaledNL, curvature, 0, 0);
				//fixed3 profileColor = tex2Dlod(_SkinProfile, profileUV).rgb;
				fixed3 profileColor = tex2D(_SkinProfile, half2(scaledNL, curvature)).rgb;
				fixed3 diffuseTerm =lerp( profileColor.rgb, profileColor.rrr,_ScatterProfileColor);
				half3 directDiffuse = lerp(lightColor*saturate(NdotL),_ScatterColor *diffuseTerm*lightColor, ceil(curvature));
#ifdef _UICHAR
////UI角色不计算闪白
				float3 diffuse = (directDiffuse + indirectDiffuse) * diffuseColor * lerp(_SkinShadowColor, 1, attenuation);
#else
                float3 diffuse = (directDiffuse + indirectDiffuse) * diffuseColor * lerp(_SkinShadowColor, 1, attenuation) + _GlitterColor.rgb*pow(1-NdotV,_GlitterColorWidth);
#endif
/// Final Color:
                float3 finalColor = diffuse + specular;
				//float3 finalColor = specular;
				Ao =1- _AO*float3(1,1,1)+Ao*_AO;
				finalColor *=Ao;
//				float4 _Emit_var = tex2D(_Emit,i.uv0);
/////两套noiseUV，互相有偏移
//				float2 scaleUV = i.uv0*200;
//				float2 scaleUVoffset = (i.uv0 + float2(0.7,-0.5))*200;
//				float2 floorUV =floor(scaleUV);
//				float2 fractUV = frac(scaleUV);
//				float2 floorUVoffset = floor(scaleUVoffset);
//				float2 fractUVoffset = frac(scaleUVoffset);
/////四个dot放一起计算
//				float4 append = float4(dot(floorUV, float2(127,311)),dot(floorUV, float2(269,183)),dot(floorUVoffset, float2(127,311)),dot(floorUVoffset, float2(269,183)));
//				float4 append_random = frac(sin(append)*43758.55);
//				float4 append_random_random = sin(append_random*5+float4(10,15,10,25))*0.25+0.5;
//				float4 final_random = (append_random_random - float4(fractUV, fractUVoffset))*_EmitSize;
////两套uv出两套闪点
//				float pointA = 1-smoothstep(0,1,length(final_random.xy));
//				float pointB = 1-smoothstep(0,1,length(final_random.zw));
/////随视角变动闪烁
//				float3 transView = mul(UNITY_MATRIX_IT_MV, float4(0.01,0.01,0.01,0))*0.01;
//				float2 shanAppend = float2(dot(append_random_random.xy*transView.xz,float2(100,200)),dot(append_random_random.zw*transView.xz,float2(100,200)));
//				float2 shanshuo = saturate(_Emit_var.g*_EmitDensity -frac(sin(shanAppend)*500));
//				float shanpoint = pointA * shanshuo.x + pointB * shanshuo.y;
//				shanpoint = shanpoint *smoothstep(0.3,1,NdotV) + shanpoint * smoothstep(0.2,0.5,specular.r)*100;

//                _EmitDensity = _EmitDensity*_Emit_var.g+0.5;
////闪点计算参考了暖暖的计算方法，利用噪波来随机闪点位置整数部分划分网格，小数部分做细节偏移。
//                float2 scaleUV = i.uv0*100;
//////通过UV计算闪点密度网格
//                float2 floorUV =floor(scaleUV);
/////两次随机计算控制出现位置
//                float random = frac(sin(dot(floorUV,float2(12.9898,78.5896)))*_Time.y*0.1);
//				float random2 = frac(sin(dot(floor(i.viewPos.xy*50),float2(59.9898,44.5896)))*_Time.y*0.1);
//////Mask控制闪点呼吸亮度和大小
//				float mask =frac(sin(dot(floorUV,float2(65.44687,93.8866)))*792468.135843218);
///////位置的偏移，打破闪点的规律性，看上去分布更随机一些。
//                float2 PointPos = frac(scaleUV)+lerp(float2(-0.333,0),float2(0.333,0),mask);
//////随机大小
//                 float randomSize =lerp(1,4,mask*_EmitSize);
//				float4 flashPoint = tex2D(_Emit,saturate(PointPos*randomSize-(randomSize-1)*0.5));
//                float4 randomflashPoint =flashPoint*round(random*_EmitDensity)*round(random2*_EmitDensity);
/// sin函数实现 随机呼吸两度 mask是相位的偏移值
                //finalColor = clamp(finalColor,0,16)+randomflashPoint.r*_EmitIntensity*saturate(sin((_Time.x+mask*360)*2))*_Emit_var.b*max(NdotL*attenuation,0.2)*pow(NdotV,4);
				finalColor = clamp(finalColor,0,16);
				//finalColor.rgb += _EmissionColor.rgb * _Emit_var.a;
///整体角色灰色显示
				finalColor = lerp(finalColor,Luminance(finalColor)*float3(1,1,1),_gray);

                fixed4 finalRGBA = fixed4(finalColor,alpha);
				//阴影
//				finalRGBA *= ShadowColorAtten(i.posWorld);
//#ifdef PROJECTOR_DEPTH_MAP_ON
//				finalRGBA *= ProjectorShadowColorAtten(i.posWorld);
//#endif
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(i.fogCoord, finalRGBA.rgb);
				}else
				{
					UNITY_APPLY_FOG(i.fogCoord, finalRGBA);				
				}
                return finalRGBA;
            }
            ENDCG
        }
    }

	//Fallback "TLStudio/Fallback/AlphaTestVertexLit"
	CustomEditor "CustomStandardShaderEditor"
}
