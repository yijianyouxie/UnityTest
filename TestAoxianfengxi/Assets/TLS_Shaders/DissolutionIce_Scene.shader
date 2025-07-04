// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/FX/DissolutionIce_Scene"
{
	//适用于整个场景的情况
	//需要定义溶解方向的起始点和结束点
	//外部传入一个世界坐标的位置点，将模型的点转为世界坐标系，与此点进行比较。
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Base (RGB)", 2D) = "white" {}

		[Header(oooooooooooooooooooooooooooooICE)]
		//Ice
		_DiffuseColor("DiffuseColor", Color) = (0.25,0.25,0.25,1)
		_NormalTex("NormalTex", 2D) = "bump" {}
		_IceTexture("IceTexture", 2D) = "white"{}
		_NoiseTexture("NoiseTexture", 2D) = "white"{}
		_Cube("Reflection Cubemap", Cube) = "" {}
		_RefrectionNoise("RefrectionNoise", Range(-0.5, 0.5)) = -0.232
		_TexOffset("TexOffset", float) = 0.0
		_IceBlendNoiseDegree("IceBlendNoiseDegree", float) = 5.0
		_NDotLDrgree("NDotLDrgree", float) = 0.5
		_SpecularDrgree("SpecularDrgree", float) = 0.7
		_SpecularScatterArea("SpecularScatterArea", float) = 2.02
		_Specular2Drgree("Specular2Drgree", Range(0, 1)) = 0.882
		_Lerp("Lerp", Range(0, 1)) = 0.73
		_LerpAlpha("LerpAlpha", Range(0, 1)) = 1.0
		_Intensity("Intensity", Range(0, 5)) = 1.0
		//_StartPoint("StartPoint", vector) = (0,0,0,0)
		//_EndPoint("EndPoint", vector) = (0,0,0,0)
		//_DissoveSpeed("DissoveSpeed", float) = 1
		//_TargetPosition("TargetPosition", vector) = (0,0,0,0)
		//_Dir("Dir", vector) = (1,0,1,0)
		_DissoveRange("DissoveRange", Range(0,15)) = 5
		_DissoveTex("DissoveTex", 2D) = "white" {}
		[NoScaleOffset]_GlossTex("GlossTex", 2D) = "black" {}
		_GlossCol("GlossCol", Color) = (1,1,1,1)
		_GlossIntensity("GlossIntensity", Range(0,5)) = 1
		_GlossTilingScale("缩放 xy(tilling) z(总)", vector) = (1,1,1,0)
		[Toggle(_Toggle_GlossRepeat)] _Toggle_GlossRepeat("?开启使用连续流光(贴图选repeat), 否则是间隔时间流光(贴图选clamp)?", Float) = 1
		_GlossSpeedXYTotalStop("x(速度) |y(贴图旋转) |z(间隔时间) |w(无效)", vector) = (1, 0, 0, 0)
		_GlossDirection("流向:x(方向(0-360)) |y(水平矫正u(-0.5-0.5)) |z(垂直矫正v(-0.5-0.5)) |w(无效)", vector) = (0,0.5,0,0)
	}
	SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 200

		Pass{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma skip_variants DIRLIGHTMAP_COMBINED LIGHTMAP_SHADOW_MIXING VERTEXLIGHT_ON
			// compile directives
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			//#pragma multi_compile GLOBALSH_DISABLE GLOBALSH_ENABLE
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbase noshadow
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#define UNITY_PASS_FORWARDBASE
			#include "UnityCG.cginc"
			#include "Assets/TLS_Shaders/CGIncludes/Lighting.cginc"
			#include "Assets/TLS_Shaders/CGIncludes/AutoLight.cginc"


			#define INTERNAL_DATA
			#define WorldReflectionVector(data,normal) data.worldRefl
			#define WorldNormalVector(data,normal) normal

			// Original surface shader snippet:
			#line 12 ""
			#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
			#endif

			//#pragma surface surf Lambert noforwardadd

			sampler2D _MainTex;
			half4 _MainTex_ST;
			fixed4 _Color;
			uniform float4 _TargetPosition;
			uniform float4 _Dir;
			uniform half _DissoveSpeed;
			half _DissoveRange;

			//冰
			fixed4 _DiffuseColor;
			sampler2D _GrabTexture;
			sampler2D _IceTexture;
			sampler2D _NoiseTexture;
			sampler2D _NormalTex;
			samplerCUBE _Cube;
			half4 _IceTexture_ST;
			half4 _NoiseTexture_ST;
			half4 _NormalTex_ST;
			half _RefrectionNoise;
			half _TexOffset;
			half _IceBlendNoiseDegree;
			half _NDotLDrgree;
			half _SpecularDrgree;
			half _SpecularScatterArea;
			half _Specular2Drgree;
			half _Lerp;
			half _LerpAlpha;
			half _Intensity;

			sampler2D _DissoveTex;	half4 _DissoveTex_ST;
			sampler2D _GlossTex; half4 _GlossTex_ST;
			fixed4 _GlossCol;
			half _GlossIntensity;
			half3 _GlossTilingScale;
			half _Toggle_GlossRepeat;
			half4 _GlossSpeedXYTotalStop;
			half4 _GlossDirection;

			struct Input {
				half2 uv_MainTex;
			};

			void surf(Input IN, inout SurfaceOutput o) {
				fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
				o.Albedo = c.rgb*_Color.rgb;
				//o.Alpha = c.a*_Color.a;
			}


			// vertex-to-fragment interpolation data
			// no lightmaps:
		#ifdef LIGHTMAP_OFF
			struct v2f_surf {
				float4 pos : SV_POSITION;
				half2 pack0 : TEXCOORD0; // _MainTex
				half3 worldNormal : TEXCOORD1;
				float4 worldPos : TEXCOORD2;
				float4 screenPos : TEXCOORD3;
				float3 worldTangent : TEXCOORD4;
				float3 worldBitangent : TEXCOORD5;
		#if UNITY_SHOULD_SAMPLE_SH
				half3 sh : TEXCOORD6; // SH
		#endif
				UNITY_SHADOW_COORDS(7)
				UNITY_FOG_COORDS(8)
		#if SHADER_TARGET >= 30
				float4 lmap : TEXCOORD9;
		#endif
		#ifdef GLOBALSH_ENABLE
				float3 vlighting : TEXCOORD10;
		#else
		#endif
			};
		#endif
			// with lightmaps:
		#ifndef LIGHTMAP_OFF
			struct v2f_surf {
				float4 pos : SV_POSITION;
				half2 pack0 : TEXCOORD0; // _MainTex
				half3 worldNormal : TEXCOORD1;
				float4 worldPos : TEXCOORD2;
				float4 lmap : TEXCOORD3;
				float4 screenPos : TEXCOORD4;
				float3 worldTangent : TEXCOORD5;
				float3 worldBitangent : TEXCOORD6;
				UNITY_SHADOW_COORDS(7)
				UNITY_FOG_COORDS(8)
		#ifdef GLOBALSH_ENABLE
				float3 vlighting : TEXCOORD9;
		#else
		#endif
			};
		#endif

			//流光
			fixed3 GetGloss(float2 uv)
			{
				//定义旋转的轴心点Pivot
				float2 pivot = float2(0.5, 0.5);
				// 角度变弧度
				float glossTexAngle = _GlossSpeedXYTotalStop.y * 3.14 / 180;
				//Rotation Matrix
				float cosAngle = cos(glossTexAngle);
				float sinAngle = sin(glossTexAngle);
				//构造2维旋转矩阵，顺时针旋转
				float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
				//先移到中心旋转
				float2 targetUV = uv - pivot;
				targetUV = mul(rot, targetUV);
				//再移回来
				targetUV += pivot;

				//顺时针旋转
				float dir = (360 - _GlossDirection.x) * 3.14 / 180;
				float u = cos(dir);
				float v = sin(dir);
				float2 glossUV = float2(0, 0);

				glossUV = targetUV + (_GlossSpeedXYTotalStop.x * _Time.y) * float2(u, v) - float2(_GlossDirection.y, _GlossDirection.z);
				glossUV *= _Toggle_GlossRepeat;
				// 每段间隔时间
				float glossAnimLength = 1 + _GlossSpeedXYTotalStop.z;
				// 这段前进长度
				float glossCurAnimX = _Time.y % glossAnimLength;
				// 矫正
				float2 glossUV2 = targetUV + glossCurAnimX * _GlossSpeedXYTotalStop.x * float2(u, v) - float2(_GlossDirection.y, _GlossDirection.z);
				glossUV2 *= (1- _Toggle_GlossRepeat);

				fixed3 glossCol = tex2D(_GlossTex, (glossUV + glossUV2)* _GlossTilingScale.xy * _GlossTilingScale.z) * _GlossCol;
				glossCol *= _GlossIntensity;

				return glossCol;
			}

			// vertex shader
			v2f_surf vert_surf(appdata_full v) {
				v2f_surf o;
				UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.pack0 = TRANSFORM_TEX(v.texcoord, _MainTex);

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos.xyz = worldPos;
				o.worldNormal = worldNormal;

				float3 worldPos2 = float3(worldPos.x, 0, worldPos.z);
				float3 targetPos2 = float3(_TargetPosition.x, 0, _TargetPosition.z);
				float dot1 = dot(_Dir, normalize(worldPos2));
				float dot2 = dot(_Dir, normalize(targetPos2));
				float dis1 = distance(worldPos2, float3(0, 0, 0));
				float dis2 = distance(targetPos2, float3(0, 0, 0));
				float delta = dis1 * dot1 - dis2 * dot2;
				o.worldPos.w = delta;

		#ifndef DYNAMICLIGHTMAP_OFF
				o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
		#endif
		#ifndef LIGHTMAP_OFF
				o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		#endif

				// SH/ambient and vertex lights
		#ifdef LIGHTMAP_OFF
		#if UNITY_SHOULD_SAMPLE_SH
				o.sh = 0;
				// Approximated illumination from non-important point lights
		#ifdef VERTEXLIGHT_ON
				o.sh += Shade4PointLights(
					unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
					unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
					unity_4LightAtten0, worldPos, worldNormal);
		#endif
				o.sh = ShadeSHPerVertex(worldNormal, o.sh);
		#endif
		#endif // LIGHTMAP_OFF
		#ifdef GLOBALSH_ENABLE
				o.vlighting = ShadeSH9(float4(o.worldNormal, 1.0));
		#endif

				o.screenPos = o.pos;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldTangent = mul(unity_ObjectToWorld, v.tangent);
				o.worldBitangent = cross(normalize(o.worldNormal), normalize(o.worldTangent));

				TRANSFER_SHADOW(o); // pass shadow coordinates to pixel shader
				if(UseHeightFog > 0)
				{
					TL_TRANSFER_FOG(o,o.pos, v.vertex);
				}else
				{
					UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader				
				}
				return o;
			}

			// fragment shader
			fixed4 frag_surf(v2f_surf IN) : SV_Target{

				//float3 unitDir = normalize(_EndPoint.xyz - _StartPoint.xyz);
				//float3 targetPoint = _StartPoint + _DissoveSpeed * unitDir * _Time.y;

				//裁掉走过的地方
				//clip(IN.worldPos.x - targetPoint.x);
				//float3 worldPos2 = float3(IN.worldPos.x, 0, IN.worldPos.z);
				//float3 targetPos2 = float3(_TargetPosition.x, 0, _TargetPosition.z);
				//float dot1 = dot(_Dir, normalize(worldPos2));
				//float dot2 = dot(_Dir, normalize(targetPos2));
				//float dis1 = distance(worldPos2, float3(0,0,0));
				//float dis2 = distance(targetPos2, float3(0,0,0));
				//float delta = dis1 * dot1 - dis2 * dot2;
				float delta = IN.worldPos.w;
				float zero2One = saturate(delta);
				float zeroOrOne = ceil(zero2One);
				
				fixed4 c = 0;
				// prepare and unpack data
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT(Input,surfIN);
				surfIN.uv_MainTex.x = 1.0;
				surfIN.uv_MainTex = IN.pack0;
				float3 worldPos = IN.worldPos;
			#ifndef USING_DIRECTIONAL_LIGHT
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
			#else
				fixed3 lightDir = _WorldSpaceLightPos0.xyz;
			#endif
			#ifdef UNITY_COMPILER_HLSL
				SurfaceOutput o = (SurfaceOutput)0;
			#else
				SurfaceOutput o;
			#endif
				o.Albedo = 0.0;
				o.Emission = 0.0;
				o.Specular = 0.0;
				o.Alpha = 0.0;
				o.Gloss = 0.0;
				fixed3 normalWorldVertex = fixed3(0,0,1);
				o.Normal = IN.worldNormal;
				normalWorldVertex = IN.worldNormal;


				// call surface function
				surf(surfIN, o);

				// compute lighting & shadowing factor
				UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
						

				// Setup lighting environment
				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
			#if !defined(LIGHTMAP_ON)
				gi.light.color = _LightColor0.rgb;
				gi.light.dir = lightDir;
				gi.light.ndotl = LambertTerm(o.Normal, gi.light.dir);
			#endif
				// Call GI (lightmaps/SH/reflections) lighting function
				UnityGIInput giInput;
				UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
				giInput.light = gi.light;
				giInput.worldPos = worldPos;
				giInput.atten = atten;
			#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
				giInput.lightmapUV = IN.lmap;
			#else
				giInput.lightmapUV = 0.0;
			#endif
			#if UNITY_SHOULD_SAMPLE_SH && LIGHTMAP_OFF
				giInput.ambient = IN.sh;
			#else
				giInput.ambient.rgb = 0.0;
			#endif
				giInput.probeHDR[0] = unity_SpecCube0_HDR;
				giInput.probeHDR[1] = unity_SpecCube1_HDR;
			#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
				giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
			#endif
			#if UNITY_SPECCUBE_BOX_PROJECTION
				giInput.boxMax[0] = unity_SpecCube0_BoxMax;
				giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
				giInput.boxMax[1] = unity_SpecCube1_BoxMax;
				giInput.boxMin[1] = unity_SpecCube1_BoxMin;
				giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
			#endif
				LightingLambert_GI(o, giInput, gi);

				c += LightingLambert(o, gi);

			#ifdef GLOBALSH_ENABLE
				c.xyz = c.xyz*max(fixed3(1.0,1.0,1.0),(IN.vlighting - UNITY_LIGHTMODEL_AMBIENT.xyz) * 2);
			#endif
				//UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog
				UNITY_OPAQUE_ALPHA(c.a);
				c *= zeroOrOne;
				//return c;
				
				fixed4 finalColor = 0;
				delta = -delta;
				float iceZero2One = saturate(delta + _DissoveRange);
				float iceZeroOrOne = ceil(iceZero2One);

				IN.worldPos = normalize(IN.worldPos);
				IN.worldNormal = normalize(IN.worldNormal);
				IN.worldTangent = normalize(IN.worldTangent);
				IN.worldBitangent = normalize(IN.worldBitangent);
				
				//注意:
				//UNITY_MATRIX_MVP 只是到裁剪完后的齐次裁剪空间 xy分量范围是-w,w 要想知道屏幕位置  需要
				//screenPosX = ((x / w) * 0.5 + 0.5) * width
				//screenPosY = ((y / w) * 0.5 + 0.5) * height
				
				float4 realScreenPos = float4(((IN.screenPos.x / IN.screenPos.w) *0.5 + 0.5)*_ProjectionParams.x,
					((IN.screenPos.y / IN.screenPos.w) *0.5 + 0.5)*_ProjectionParams.y, 0, 0);
				//法线贴图数值读取
				float3 normalMap = UnpackNormal(tex2D(_NormalTex, IN.pack0));
				float2 screenUV = realScreenPos + ((normalMap.rgb.rg + mul(UNITY_MATRIX_V, float4(IN.worldNormal, 0)).xy)*_RefrectionNoise);
				//float4 screenColor = tex2D(_GrabTexture, screenUV);

				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.worldPos);

				//构造切空间-世界矩阵
				float3x3 tangent2World = float3x3(IN.worldTangent, IN.worldBitangent, IN.worldNormal);
				//法线贴图(切空间)转世界
				float3 normalMapWorld = normalize(mul(normalMap, tangent2World));
				//根据法线贴图计算反射
				float3 viewReflectDir = reflect(-viewDir, normalMapWorld);
				//取主贴图颜色
				fixed4 iceTexColor = tex2D(_IceTexture, TRANSFORM_TEX(IN.pack0, _IceTexture));
				//取明暗图颜色
				fixed4 noiseTexColor = tex2D(_NoiseTexture, TRANSFORM_TEX(IN.pack0, _NoiseTexture));

				fixed4 screenColor = texCUBE(_Cube, realScreenPos + ((normalMap.rgb + mul(UNITY_MATRIX_V, float4(IN.worldNormal, 0)).xyz)*_RefrectionNoise));

				fixed attenuation = LIGHT_ATTENUATION(IN);
			#ifndef LIGHTMAP_OFF
				fixed4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.lmap.xy);
				fixed3 lightmap = DecodeLightmap(lmtex);
				fixed3 directDiffuse = min(lightmap.rgb, attenuation*lightmap.rgb);
			#endif

				lightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 lightColor = _LightColor0.rgb;

				fixed3 emissive = _IceBlendNoiseDegree * iceTexColor * noiseTexColor;
				//与光源夹角 这里乘平方为了让暗色更亮些
				float nDotL = saturate(pow(dot(normalMapWorld, lightDir) + _NDotLDrgree, 2));
				fixed3 diffuse = _DiffuseColor.rgb * nDotL;
				fixed3 specular1 = _SpecularDrgree * pow(max(0, dot(lightDir, viewReflectDir)), exp(_SpecularScatterArea));
				fixed3 specular2 = pow(1.0 - max(0, dot(normalMapWorld, viewDir)), _Specular2Drgree) * nDotL;

			#ifndef LIGHTMAP_OFF
				emissive *= directDiffuse * _Intensity;
			#endif
				fixed3 col = emissive + ((diffuse + specular1 + specular2) * lightColor);
				finalColor = fixed4(lerp(screenColor.rgb, col, _Lerp), 1);
				finalColor = fixed4(lerp(screenColor.rgb, col, _Lerp), 1);
				finalColor = fixed4(lerp(fixed4(0.0, 0.0, 0.0, 0.0), finalColor, _LerpAlpha));

				//显示溶解部分
				fixed4 dissolveColor = tex2D(_DissoveTex, TRANSFORM_TEX(IN.pack0, _DissoveTex));
				fixed dissolveZero2One = saturate(dissolveColor.r*_DissoveRange + delta);
				fixed dissolveZeroOrOne = ceil(dissolveZero2One);
				c *= (1 - dissolveZeroOrOne);

				//流光
				finalColor.rgb += GetGloss(worldPos.xz / 256);
				finalColor *= dissolveZeroOrOne * iceZeroOrOne;

				finalColor = finalColor + c;
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(IN.fogCoord, finalColor.rgb);
				}else
				{
					UNITY_APPLY_FOG(IN.fogCoord, finalColor);				
				}

				return finalColor;
			}
			ENDCG
		}
		
	}
	FallBack "TLStudio/Opaque/UnLit"
}
