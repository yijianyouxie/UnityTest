Shader "FX/Water_WithColorDepth"
{
	Properties
	{
		[Header(Wave)]
		_MainWaterBump("主波纹扰动程度", Range(-3, 3)) = 0.01
		_SubWaterBump("副波纹扰动程度", Range(-3, 3)) = 0.01

		_BumpMap1("浪花NormalMap1" , 2D) = "bump" {}
		_BumpMap2("浪花NormalMap2 ", 2D) = "bump" {}
	
		_LightDir("光源位置", Vector) = (100,100,100,100)
		[Header(Specular)]
		_SpecularPower("高光光泽度", Range(5,800)) = 600
		[Header(GISpecular)]
		[HDR]_GISpecColor("GI高光颜色", Color) = (1.0, 1.0, 1.0, 1.0)
		[Header(Deepth)]
		_DepthPower("深度强度", Range(0.5,12)) = 12
		_DepthPower2("深水颜色强度", Range(0.5,12)) = 12
		_DepthColor("深水颜色", Color) = (1.0, 1.0, 1.0, 1.0)
		_SSRColor("_SSRColor", Color) = (1.0, 1.0, 1.0, 1.0)
		[Header(Fresnel)]
		_FresnelPow("菲尼尔系数", Range(0,30)) = 0.0

		[Header(Environment_IndirectSpec)]
		_EnvCube("环境probe", Cube) = "White"{}
		_EnvDistort("环境扰动", Range(-1,2)) = 0.40
		//_EnvUpAndDown("环境上下(重要参数)", Range(-1,2)) = 1

		[Header(CustomRefraction)]
		_RefrDistort("折射扰动", Range(0,3)) = 0.40
		_ReflColor("折射颜色", Color) = (0.0, 0.0, 0.0, 1.0)
		//后续是全局设置 to do
		/*_WaterEnvColor("_WaterEnvColor", Color) = (1.0, 1.0, 1.0, 1.0)
		_WaterSpecColor("_WaterSpecColor", Color) = (1.0, 1.0, 1.0, 1.0)*/


		//区域冰冻效果
		_FrostTex("冰冻贴图", 2D) = "white" {}
		_IceBumpMap("法线贴图",2D) = "white"{}
		_IceBumpMapStrength("法线贴图强度",Range(0,2)) = 1
		_NoiseMask("冰冻贴图整体噪声遮罩",2D) = "white"{}
		[HDR]_IceColor("冰面颜色",Color) = (0.6,0.6,0.6,1)//冰冻的颜色
		_IceLumin("冰面亮度", Range(1, 3)) = 2.0
		_IceOpacity("冰面不透明度",Range(0,1)) = 1//冰冻整体进程
		_IceWidth("结冰厚度",Range(0,1)) = 0.03
		_IceSpecular("冰冻反射", Range(0, 1)) = 0.5
		_IceAttenuation("冰冻衰减", Range(0, 5)) = 2

		_TargetPosition("冰冻起始点", vector) = (0,0,0,0)
		_Ice_R("冰冻半径", Float) = 200
		_Ice_Progress("冰冻进程", Range(0, 1)) = 0
		[Toggle]_UseVertexAlpha("是否使用顶点alpha", int) = 0

	}
	Subshader
	{
		Tags{ "WaterMode" = "Refractive" "Queue" = "Transparent-100" "RenderType" = "Opaque" }

		Pass
	{
		ZWrite off
		Blend SrcAlpha OneMinusSrcAlpha
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag	
		#pragma multi_compile FOG_EXP2 FOG_LINEAR
		//#pragma multi_compile __ _WATER_SSR _WATER_SIMPLE 
		#pragma multi_compile _WATER_SSR _WATER_SIMPLE 
		//#include "CGIncludes/TLStudioCG.cginc"
		#include "UnityCG.cginc"
        #pragma exclude_renderers xbox360 ps3 flash d3d11_9x

   
		float _SubWaterBump;
		float _MainWaterBump;
		float _RefrDistort;

		float _EnvDistort;
		float _EnvUpAndDown;


		sampler2D_float _WaterDepthTexture;
		float _FresnelPow;
		sampler2D _GrabTexture;
		float4 _GrabTexture_TexelSize;
		//float _Test;
		float _DepthPower;
		sampler2D _BumpMap1;
		float4 	_BumpMap1_ST;
		sampler2D _BumpMap2;
		float4 	_BumpMap2_ST;

		float _SpecularPower;
		float3 _WaterSpecColor;

		samplerCUBE _EnvCube;
		float3 _WaterEnvColor;
		float4 _LightDir;

		float4 	_ReflColor;

		float3 _GISpecColor;

		float _DepthPower2;
		float3 _DepthColor;
		float3 _SSRColor;
		float3 _SSRColorInput;

		float _DepthFactor;//用于整体削弱深度相关的值
		sampler2D_float _SceneColorTex;
		sampler2D_float _SceneDepthTex;
		float _UseVertexAlpha;
		//sampler2D _SceneDepthTexWithStencil;
		struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
			float2 texcoord : TEXCOORD0;
			fixed4 color : COLOR;
		};
		struct v2f
		{
			float4 pos : SV_POSITION;
			float4 screenPos : TEXCOORD0;
			float2 bumpuv0 : TEXCOORD1;
			float2 bumpuv1 : TEXCOORD2;
			float4 worldPos : TEXCOORD4;

			float4 TtoW0 : TEXCOORD6;
			float4 TtoW1 : TEXCOORD7;
			float4 TtoW2 : TEXCOORD8;

			float4 deepScreenPos : TEXCOORD9;

			UNITY_FOG_COORDS(10)
			fixed4 color : COLOR;
		};

		v2f vert(appdata v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);//获取裁剪空间下的坐标值，xy范围是(-w,w)

			o.screenPos = ComputeScreenPos(o.pos);//返回齐次坐标系下的xy的屏幕坐标值，范围是(0,w)。z和w值还是o.pos的
			o.deepScreenPos = ComputeScreenPos(o.pos);//这个可以无损优化为一个参数,随便塞在哪里就行了
			o.worldPos = mul(unity_ObjectToWorld, v.vertex);

			o.bumpuv0 = o.worldPos.xz;
			o.bumpuv1 = o.worldPos.xz;
			o.bumpuv0 = o.bumpuv0 * _BumpMap1_ST.xy + frac(_BumpMap1_ST.zw * _Time.y);//优化1
			o.bumpuv1 = o.bumpuv1 * _BumpMap2_ST.xy + frac(_BumpMap2_ST.zw * _Time.y);//优化1
			float3 worldNormal = UnityObjectToWorldNormal(v.normal);
			float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
			float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;


			o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x,o.worldPos.x);
			o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y,o.worldPos.y);
			o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z,o.worldPos.z);

			//o.lightMapUV = v.texcoord1* customLightMapST.xy + customLightMapST.zw;
			COMPUTE_EYEDEPTH(o.deepScreenPos.z);//#define COMPUTE_EYEDEPTH(o) o = -UnityObjectToViewPos( v.vertex ).z
			//TL_TRANSFER_FOG(o, o.pos, v.vertex);

			if (UseHeightFog > 0)
			{
				TL_TRANSFER_FOG(o, o.pos, v.vertex);
			}
			else
			{
				UNITY_TRANSFER_FOG(o, o.pos);
			}
			o.color = v.color;
			return o;
		}
		float InterleavedRandomUV(in float2 xy)
		{
			return frac(((52.9829189)*(frac(dot(xy, float2(0.06711056, -0.00583715))))));
		}
		//世界空间坐标；
		//屏幕坐标系下的（0,1）
		//反射向量
		float3 ScreenSpaceRayCast(in float3 WorldPosition, in float2 PixelPos, in float3 R)
		{

			float2 UVMul = float2(0.5, ((0.5)));
#if UNITY_UV_STARTS_AT_TOP

			UVMul = float2(0.5, ((-0.5)));
//#else
//			UVMul = float2(0.5, ((0.5)));
#endif
			//将当前水面的点的坐标转换到裁剪空间
			float4 RayStartClip = mul(UNITY_MATRIX_VP, float4(WorldPosition, 1.0));
			float3 RayStartDevice;
			float k = ((1.0) / (RayStartClip.w));//k就是start裁剪空间的1/w
			//得到设备坐标后进行视口映射，不是屏幕映射。start的xy转化到(0,1)
			(RayStartDevice.xy) = (((((((RayStartClip.xy)*(k)))*(UVMul))) + (0.5)));//视 口 空间 中的 坐标

			(RayStartDevice.z) = (k);
			float4 RayEndClip = mul(UNITY_MATRIX_VP, float4(((WorldPosition)+(R)), 1.0));
			float3 RayEndDevice;
			(k) = (((1.0) / (RayEndClip.w)));//k就是end裁剪空间的1/w
			//得到设备坐标后进行视口映射，不是屏幕映射。end的xy转化到(0,1)
			(RayEndDevice.xy) = (((((((RayEndClip.xy)*(k)))*(UVMul))) + (0.5)));//视 口 空间 中的 坐标

			(RayEndDevice.z) = (k);

			//透视投影下，w越大，越靠后
			if (((RayEndClip.w)<(RayStartClip.w)))
				return float3(0, 0, 0);

			//视口空间的start指向end的向量。start的z是比end的z值要大
			float3 RayDirDevice = ((RayEndDevice)-(RayStartDevice));
			//检查上边的向量是水平还是垂直方向上更长
			if (((abs(RayDirDevice.x))>(abs(RayDirDevice.y))))
				(RayDirDevice) *= (((1/ _ScreenParams.x) / (abs(RayDirDevice.x))));
			else
				(RayDirDevice) *= ((( 1 / _ScreenParams.y) / (abs(RayDirDevice.y))));
			(RayDirDevice) *= (16);

			float StepOffset = InterleavedRandomUV(PixelPos) * 0.1;
			float LastRayDepth = RayStartClip.w;//起始的射线depth
			float SampleTime = StepOffset + 1;
			//[unroll] // #define UNITY_UNROLL    [unroll]  表示编译时尝试展开循环，x为尝试展开循环的最大次数
			for (int i = 0; i < 12; ++i)
			{
				//SampleUVZ的z值表示的是距离摄像机的距离的倒数
				//这里的z值是不是要提前判断下，如果小于零，直接下一次循环 to do
				float3 SampleUVZ = ((RayStartDevice)+(((RayDirDevice)*(SampleTime))));

				if (((((((((SampleUVZ.x) <= (0))) || (((SampleUVZ.x) >= (1))))) || (((SampleUVZ.y) <= (0))))) || (((SampleUVZ.y) >= (1)))))
					break;

			//	float Depth = ((((LinearEyeDepth(tex2D(_SceneDepthTex, SampleUVZ.xy).x))*(((_ProjectionParams.z) - (_ProjectionParams.y))))) + (_ProjectionParams.z));
				//深度图里的线性深度值。范围是摄像机的近裁剪面到远裁剪面
				//float Depth = LinearEyeDepth(tex2D(_SceneDepthTex, SampleUVZ.xy).x);
				float Depth = LinearEyeDepth(DecodeFloatRGBA(tex2D(_SceneDepthTex, SampleUVZ.xy ))/*+ 0.00001*/);

				float RayDepth = ((1.0) / (SampleUVZ.z));
				float DepthDiff = ((RayDepth)-(Depth));// return float3(Depth, Depth, 0);
				 
				if (((((((DepthDiff)>(0))) && (((Depth)>(RayStartClip.w))))) && (((DepthDiff)<(((abs(((RayDepth)-(LastRayDepth))))*(1.3)))))))
					return float3(SampleUVZ.xy, 1);

				(LastRayDepth) = (RayDepth);
				(SampleTime) += (0.7);
				//(SampleTime) += (1.5);
			} 
			//上面循环之后还没接触到深度图里的深度值，那么直接顶到头，获取采样的uv
			float4 RayInfClip = mul(UNITY_MATRIX_VP, float4(((WorldPosition)+(((R)*(10000000)))), 1.0));
			float2 RayInfDevice = ((RayInfClip.xy) / (RayInfClip.w));
			if (((((((((RayInfDevice.x)>(-2))) && (((RayInfDevice.x)<(2))))) && (((RayInfDevice.y)>(-1))))) && (((RayInfDevice.y)<(1)))))
			{
				float2 SampleUV = ((((RayInfDevice)*(UVMul))) + (0.5));
			
				//float Depth = ((LinearEyeDepth(tex2D(_SceneDepthTex, SampleUV).x)));
				float Depth = ((LinearEyeDepth(DecodeFloatRGBA(tex2D(_SceneDepthTex, SampleUV)) /*+ 0.00001*/)));
				if (((Depth)>(RayStartClip.w)))
					return float3(SampleUV, 1);
			}


			return float3(0, 0, 0);
		}
		//世界空间坐标；
		//屏幕坐标系下的（0,1）
		//反射向量
		//法线和视线的点积
		float3 ScreenSpaceReflection(float3 WorldPosition, float2 PixelPos, float3 R, float NoV)
		{
			float SSRRate = 0;
			float2 ScreenUV = PixelPos * 2 - 1;
			ScreenUV *= ScreenUV;
			SSRRate = saturate(1 - dot(ScreenUV, ScreenUV));
			NoV = saturate(NoV * 2);
			SSRRate *= 1 - NoV * NoV * NoV;

			float3 OUT = float3(0,0,0);
			if (SSRRate > 0.005)
			{
				float3 SSR = ScreenSpaceRayCast(WorldPosition, PixelPos, R);
				SSR.z *= SSRRate;
				OUT = SSR;
			}
			return OUT;
		}

		//世界空间坐标；
		//屏幕坐标系下的（0,1）；
		//固定值0.05，
		//反射向量
		//法线和视线的点积
		//间接光（环境光）
		float4 IBL_SpecularWithSSR(float3 WorldPos, float2 PixelPos, float Roughness, float3 R, float NoV,float3 env)
		{
			float3 SSRColor = float3(0, 0, 0);
			float3 SSR = float3(0, 0, 0);
			SSR = ScreenSpaceReflection(WorldPos, PixelPos, R, NoV);
			if (SSR.x == 0 && SSR.y == 0)
			{
				return float4(env, 0);
			}
			SSRColor = tex2D(_SceneColorTex, SSR.xy);

			if (SSR.z >= 0.99)
			{
				return float4(SSRColor, SSR.z);
			}

			//如果SSR.z不大于0.99那么就lerp环境和scenColor颜色
			float4 OUT = float4(0,0,0,0);
			OUT.rgb = (lerp(env, SSRColor, SSR.z));
			OUT.a = SSR.z;
			//}
			//return ((OUT)*(((((cEnvStrength)*(GILighting.a)))*(EnvInfo.w))));
			 
			//return float3(SSR.z, SSR.z, SSR.z);
			return float4(OUT);
		}
		//float4 SpecularLightingWithSSR(in float3 WorldPos, in float2 PixelPos, in float Roughness, in float3 R, in float NoV, float3 env)
		//{
		//	float4 Spec;
		//	float3 SpecularColor = float3(0.04, 0.04, 0.04);
		//	{
		//		float fresnel = saturate(((exp2((((-(4.5)))*(NoV)))) + (0.04)));
		//		(SpecularColor) -= (((((SpecularColor)*(fresnel))) - (fresnel)));

		//		(Spec) = (((IBL_SpecularWithSSR(WorldPos, PixelPos, Roughness, R, NoV, env))));
		//		(Spec).rgb *= SpecularColor;

		//		return Spec;
		//	}
		//}
		float4 frag(v2f i) : SV_Target
		{
			_LightDir = normalize(_LightDir);
			float farFade = distance(i.worldPos.xyz ,_WorldSpaceCameraPos.xyz);

			//float normalFade = 1-saturate((farFade - 200) / 80);
			float3 bump1 = UnpackNormal(tex2D(_BumpMap1, i.bumpuv0)).rgb * float3 (_MainWaterBump, _MainWaterBump, 1);
			float3 bump2 = UnpackNormal(tex2D(_BumpMap2, i.bumpuv1)).rgb * float3 (_SubWaterBump, _SubWaterBump, 1);
			//float3 bump3 = UnpackNormal(tex2D(_BumpMap2, i.bumpuv1)).rgb * float3 (_SubWaterBump, _SubWaterBump, 1);

#if defined (_WATER_SIMPLE) 
			float3 bump = bump2;//低配下,只采样1次法线
#else
			float3 bump = (bump1 + bump2);
#endif
			//法线贴图扰动后的法线
			float3 worldNormal = normalize(float3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

			float2 refrOffset = bump.xy * _RefrDistort;// * _GrabTexture_TexelSize.xy; 

			//指向此点的视方向
			float3 viewDirection = normalize(i.worldPos.xyz - _WorldSpaceCameraPos.xyz);

			float4 refrUV1 = i.screenPos; refrUV1.xy = i.screenPos + refrOffset;

			/*float depth0 = SAMPLE_DEPTH_TEXTURE_PROJ(_SceneDepthTex, (refrUV1));
			return float4(depth0, 0, 0, 1);*/

			float depth = DecodeFloatRGBA(tex2Dproj(_SceneDepthTex, refrUV1))/* + 0.00001*/;
			float refeDepth = 1;
			if (LinearEyeDepth(depth) < i.deepScreenPos.z)
			{
				refeDepth = saturate(i.deepScreenPos.z -LinearEyeDepth(depth) )/10;
			}
			depth = (LinearEyeDepth(depth) - i.deepScreenPos.z);//深度图-水面的深度   

																//////////
			float4 refrUV3 = i.screenPos; refrUV3.xy = i.screenPos + refrOffset * saturate(depth);
			//float depth2 = SAMPLE_DEPTH_TEXTURE_PROJ(_SceneDepthTex, refrUV3);
			float depth2 = DecodeFloatRGBA(tex2Dproj(_SceneDepthTex, refrUV3))/* + 0.00001*/;

			depth2 = (LinearEyeDepth(depth2) - i.deepScreenPos.z);//深度图-水面的深度   
			float signDepth = saturate(depth2 * 10);
			depth = lerp(depth , depth2 , signDepth);

			//
			float4 refrUV2 = i.screenPos; refrUV2.xy = i.screenPos + refrOffset* saturate(depth) *(signDepth) * refeDepth;
																										  //depth = saturate(temp / _DepthPower/ _DepthFactor) *( abs(viewDirection.y)/ i.deepScreenPos.z);

			//float depth4 = SAMPLE_DEPTH_TEXTURE_PROJ(_SceneDepthTexWithStencil, refrUV2);
			//float depth5 = SAMPLE_DEPTH_TEXTURE_PROJ(_SceneDepthTex, refrUV2);
			//depth4 = (LinearEyeDepth(depth4) - i.deepScreenPos.z);//深度图-水面的深度   
			//depth5 = (LinearEyeDepth(depth5) - i.deepScreenPos.z);//深度图-水面的深度   
			//
			//if (depth4<0 && depth5<0)
			//{
			//	//return float4(1,1,1,1);
			//	refrUV2.xy = i.screenPos;
			//
			//	//float3 refr2 = tex2Dproj(_SceneColorTex, refrUV2);
			//	//return float4(refr2,1);
			//}
			//float3 refr = tex2Dproj(_SceneColorTex, refrUV2);
			float3 refr = /*DecodeFloatRGBA*/(tex2Dproj(_SceneColorTex, refrUV2)) /*+ 0.00001*/;
			float3 normalDirection = float3(0, 1, 0);
			float viewDotNormal = saturate(dot(-viewDirection, worldNormal));

			float3 reflDir = reflect(viewDirection, worldNormal);

			float3 GILighting = saturate(_GISpecColor.rgb * (saturate(dot(_LightDir, worldNormal))));// *shadowMaskColor;
																									 //normalDirection.xy = worldNormal.xy * float2(_EnvDistort, _EnvUpAndDown);
			//法线扰动后，继续环境扰动的法线，这里并没有归一化
			normalDirection = worldNormal *float3(_EnvDistort, 1, _EnvDistort);
			float3 envColor = texCUBE(_EnvCube, reflect(viewDirection, normalDirection));
			//return fixed4(envColor, 1);

			float3 IndirectSpec = _WaterEnvColor * envColor;// _EnvStrength;// *lightMapAlpha;

			float3 N = normalDirection;
			//获取反射向量
			float3 R = reflect(((viewDirection)), N);
			//法线和反视方向的点积
			float viewDotNormal2 = saturate(dot(N, -viewDirection));

			IndirectSpec = _WaterEnvColor * envColor;

			//return fixed4(IndirectSpec, 1);
			//TL_APPLY_FOG(i.fogCoord, IndirectSpec.rgb);
#if defined (_WATER_SSR) 
			//世界空间坐标；
			//屏幕坐标系下的（0,1）；
			//固定值0.05，
			//反射向量
			//法线和视线的点积
			//间接光（环境光）
			float4 SSR = IBL_SpecularWithSSR(i.worldPos, i.screenPos.xy / i.screenPos.w, 0.05, R, viewDotNormal2, IndirectSpec);
			//return fixed4(SSR.rgb, SSR.a);

			float luminance = 0.2125 * SSR.r + 0.7154 * SSR.g + 0.0721 * SSR.b;

			luminance = 1 - luminance;


			//return float4(luminance, luminance, luminance, luminance);
			//创建一个饱和度为0的颜色值
			//使用_Saturation和其上一步得到的颜色之间进行插值，得到希望的饱和度
			SSR.rgb = lerp(SSR.rgb, SSR.rgb * _SSRColor * _SSRColorInput, saturate(luminance));//灰度公式算一个饱和度,调色一下,天空更亮的部分变化较小.暗的部分会有比较大的变化,这样就可以分开调色
			IndirectSpec = SSR.rgb;

#endif


			float3 DirectSpec = pow(saturate(dot(reflDir, _LightDir.xyz)), _SpecularPower) * _WaterSpecColor * 2;


			float4 color;
			//color.xyz = (Indirect + GILighting) * diffuse + IndirectSpec;// +DirectSpec;
			color.xyz = (GILighting)+IndirectSpec;//先去掉lightmap
															   //color.xyz = GILighting;
															   //color.xyz = diffuse;
															   //color.xyz = IndirectSpec;
															   //color.xyz = DirectSpec;

#if defined (_WATER_SIMPLE) 
			refr.xyz = _DepthColor * 0.5;//去掉深度计算,只是单纯的加深颜色
#else
			refr.xyz = lerp(refr.xyz, _DepthColor, saturate(depth / _DepthPower2));
#endif

			farFade = 1 - saturate((farFade - 100) / 80);

			float fresnel = (pow(1.0 - viewDotNormal, _FresnelPow)) ;// *(1 - saturate(max(viewDirection2.y - 60, 0)));
																						   //float fresnel = pow(1.0 - viewDotNormal, _FresnelPow * _DepthFactor );// *(1 - saturate(max(viewDirection2.y - 60, 0)));
			color.xyz = fresnel  * color.xyz + (1.0 - fresnel)  * refr * _ReflColor;

			//return fixed4(color.xyz, 1);

			float3 fogColor = color.xyz;


#if defined (_WATER_SIMPLE) 
			//去掉深度计算,低配下没有深度了
#else
			color.xyz = lerp(refr, color.xyz, saturate(depth / (_DepthPower * farFade)));
#endif
			
			color.xyz += DirectSpec;//高光不被深度削弱
			//TL_APPLY_WATER_FOG(i.fogCoord, color.rgb);
			if (UseHeightFog > 0)
			{
				TL_APPLY_WATER_FOG(i.fogCoord, color.rgb);
			}
			else
			{
				UNITY_APPLY_FOG(i.fogCoord, color);
			}

			color.xyz = clamp(color.xyz, 0, 16);

			color.a = _UseVertexAlpha > 0 ? i.color.a : 1;
			return color;
		}
			ENDCG
		}
		Pass
		{
			zWrite off
			Blend  SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile FOG_EXP2 FOG_LINEAR
#pragma multi_compile _WATER_SSR _WATER_SIMPLE 
#include "UnityCG.cginc"
#include "Assets/TLS_Shaders/CGIncludes/WeatherLibrary.cginc"


			struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
			float freeze : TEXCOORD1;
			float3 lightDir :TEXCOORD2;
			float3 viewDir :TEXCOORD3;
			float2 uv2 : TEXCOORD4;
			float4 worldPos : TEXCOORD5;
			UNITY_FOG_COORDS(6)
		};

		sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _FrostTex;
		sampler2D _IceBumpMap;
		float4 _IceBumpMap_ST;
		float _IceBumpMapStrength;
		fixed4 _IceColor;
		sampler2D _NoiseMask;
		float _IceOpacity;
		uniform fixed 	_CubeRelDistortion;
		float _IceWidth;
		float4 _FrostTex_ST;
		uniform float4 	_CubeWaveSpeed;
		float4 _start;
		uniform float4 _TargetPosition;
		float _Ice_R;
		float _Ice_Progress;
		float _IceLumin;
		float _IceAttenuation;
		float _IceSpecular;
		samplerCUBE _EnvCube;
		float _EnvDistort;

		v2f vert(appdata v)
		{
			v2f o;

			v.vertex.xyz += v.normal*_IceWidth*_Ice_Progress;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = TRANSFORM_TEX(v.uv, _MainTex);
			o.uv2 = TRANSFORM_TEX(v.uv, _FrostTex);
			fixed2 uv = v.uv - float2(_start.x, _start.y);
			o.freeze = 1;
			TANGENT_SPACE_ROTATION;
			o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
			o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			o.worldPos.xyz = worldPos;
			float3 worldPos2 = float3(worldPos.x, 0, worldPos.z);
			float3 targetPos2 = float3(_TargetPosition.x, 0, _TargetPosition.z);
			//float dot1 = dot(_Dir, worldPos2);
			//float dot2 = dot(_Dir, targetPos2);
			float dis3 = distance(worldPos2, targetPos2);
			o.worldPos.w = dis3;
			if (UseHeightFog > 0)
			{
				TL_TRANSFER_FOG(o, o.vertex, v.vertex);
			}
			else
			{
				UNITY_TRANSFER_FOG(o, o.vertex);
			}
			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			//fixed4 col = tex2D(_MainTex, i.uv);

			fixed a = _IceOpacity  * i.freeze;

			float3 _UVOffset = UnpackNormal(tex2D(_IceBumpMap, TRANSFORM_TEX(i.uv2, _IceBumpMap)));
			_UVOffset.r *= _IceBumpMapStrength;
			float2 uv3 = i.uv2 + _UVOffset.rb;

			fixed4 frostCol = tex2D(_FrostTex, TRANSFORM_TEX(uv3, _FrostTex)) * _IceColor;

			fixed noiseMask = tex2D(_NoiseMask, TRANSFORM_TEX(uv3, _FrostTex)).r*2;
			noiseMask = saturate(noiseMask);

			float dis = i.worldPos.w;
			float Ice_R = _Ice_R * _Ice_Progress;
			float delta = Ice_R - dis;
			float zero2One = saturate(delta);
			float zeroOrOne = ceil(zero2One);
			_IceAttenuation = Ice_R / (5 - _IceAttenuation);
			float IceIndentity = 1 - smoothstep(Ice_R, Ice_R + _IceAttenuation, dis);
			IceIndentity = lerp(IceIndentity, IceIndentity * noiseMask, step(IceIndentity, 0.99f));
			//IceIndentity = IceIndentity * noiseMask;
			_IceOpacity = 1 - pow(Ice_R / 300 - 1,6);

#if !defined (_WATER_SIMPLE) 
			float3 normalDirection = float3(0, 1, 0);
			float3 viewDirection = normalize(i.worldPos.xyz - _WorldSpaceCameraPos.xyz);
			float3 envColor = texCUBE(_EnvCube, reflect(viewDirection, normalDirection));
			frostCol.rgb =  lerp(frostCol.rgb, frostCol.rgb * envColor, _IceSpecular);
#endif

			frostCol = fixed4(frostCol.rgb * _IceLumin, a * IceIndentity );

			if (UseHeightFog > 0)
			{
				TL_APPLY_WATER_FOG(i.fogCoord, frostCol.rgb);
			}
			else
			{
				UNITY_APPLY_FOG(i.fogCoord, frostCol);
			}
			return frostCol;
		}
			ENDCG
		}

	}
}