#ifndef COMMON_CALCULATE_INCLUDE  
#define COMMON_CALCULATE_INCLUDE  	
	
	#include "Assets/TLS_Shaders/UnityCG.cginc"
	
	#ifdef COMMON_CAL_SPEC
		half _Shininess;
		fixed _SpecPower;
	#endif
	
	//#ifdef SNOW_RAIN_IN_SAME_MASKMAP
		sampler2D _TintMask_SnowR_RainR;
		uniform half _RainMaskPower = 1;
	//#endif
	
	#define VAR_COMMON_CALCULATE_NEED
		float3 _CenterWorldPos;		//记录渲染物体世界坐标，在没有UV的时候，用来算相对位置
	
	//output是最终的输出，lerpValue是变化的参数，在valueLow,valueHigh之间，低于valueLow输出valueOutLow，高于valueHigh输出output原本值，之间用插值
	//valueLow,valueHigh不可以相等
	#define GET_ATTEN_2_VALUE(output,lerpValue,valueLow,valueHigh,valueOutLow) output = Get_Atten_2_Value(output,lerpValue,valueLow,valueHigh,valueOutLow);
		float Get_Atten_2_Value(float finalOut,float lerpValue,float valueLow,float valueHigh,float valueOutLow)
		{
			finalOut = lerpValue > valueLow ? lerp(valueOutLow,finalOut,saturate((lerpValue - valueLow) / (valueHigh - valueLow))) : valueOutLow;
			finalOut = lerpValue < valueHigh ? lerp(valueOutLow,finalOut,saturate(lerpValue / valueHigh)) : finalOut;
			return finalOut;
		}
	
	#define GET_UV_WITH_POS_NOR_CENTER_POS(wPos,wNormal) GET_UV_CENTER_POS(wPos,wNormal);
		float2 GET_UV_CENTER_POS(float3 worldPos,float3 worldNormal) 
		{
			float2 uvTiling;
			float3 newPos = worldPos - _CenterWorldPos;
			uvTiling.y = newPos.y;
			uvTiling.x = abs(worldNormal.x) > abs(worldNormal.z) ?  newPos.z : newPos.x;	
			uvTiling = abs(worldNormal.y) > 0.99 ? newPos.xz : uvTiling;
			return uvTiling;
		}
	
	#define GET_UV_WITH_POS_NOR(wPos,wNormal) GET_UV(wPos,wNormal);
		float2 GET_UV(float3 worldPos,float3 worldNormal) 
		{
			float2 uvTiling;
			uvTiling.y = worldPos.y;
			uvTiling.x = abs(worldNormal.x) > abs(worldNormal.z) ?  worldPos.z : worldPos.x;	
			uvTiling = abs(worldNormal.y) > 0.95 ? worldPos.xz : uvTiling;
			return uvTiling;
		}
	
	#define GET_UV_WITH_POS_UP_2_DOWN(wPos) Get_UV_XOZ(wPos);
		float2 Get_UV_XOZ(float3 worldPos)
		{
			float2 uvTiling;
			uvTiling.x = worldPos.x;
			uvTiling.y = worldPos.z;
			return uvTiling;
		}
	
	//如果没有定义COMMON_CAL_SPEC高光返回的值为零
	#define CAL_DOT_SPEC(worPos,worNor,output) output = Cal_Dot_Spec(worPos,worNor);
		float2 Cal_Dot_Spec(float3 worPos,float3 worNor)
		{
			float2 dot_spec;
			float3 lightDir = normalize(UnityWorldSpaceLightDir(worPos));
			dot_spec.x = dot(worNor, lightDir);
			
			#ifdef COMMON_CAL_SPEC
				float3 viewDir = normalize(UnityWorldSpaceViewDir(worPos)); 
				float3 halfDir = normalize(lightDir + viewDir);
				float nh = max(0, dot(worNor, halfDir)); 
				dot_spec.y = pow(nh, _Shininess * 128) * _SpecPower;
			#else
				dot_spec.y = 0;
			#endif
			
			return dot_spec;
		}
	
	//获取环境光计算结果
	#define GET_AIMBIENT_LIGHT_RESULT_VS(worNor,output) output = Get_Aimbient_Light_Result_Vs(worNor);
		fixed3 Get_Aimbient_Light_Result_Vs(float3 worNor)
		{
			return saturate(ShadeSH9(half4(worNor, 1.0)));
		}
		
	//计算叠加了环境光颜色的结果
	#define GET_AIMBIENT_LIGHT_RESULT(worNor,baseColor) Get_Aimbient_Light_Result(worNor,baseColor);
		half3 Get_Aimbient_Light_Result(float3 worNor,half3 baseColor)
		{
			half3 aimColor = saturate(ShadeSH9(half4(worNor, 1.0)));
			return aimColor * baseColor;
		}
	
	
	fixed3 Shade4PointLights_Low (
    float4 lightPosX, float4 lightPosY, float4 lightPosZ,
    float3 lightColor0, float3 lightColor1, float3 lightColor2, float3 lightColor3,
    float4 lightAttenSq,
    float3 pos, float3 normal)
	{
		// to light vectors
		float4 toLightX = lightPosX - pos.x;
		float4 toLightY = lightPosY - pos.y;
		float4 toLightZ = lightPosZ - pos.z;
		// squared lengths
		float4 length = 0;
		length += toLightX * toLightX;
		length += toLightY * toLightY;
		length += toLightZ * toLightZ;
		// don't produce NaNs if some vertex position overlaps with the light
		length = max(length, 0.000001);

		// NdotL
		float4 ndotl = 0;
		ndotl += toLightX * normal.x;
		ndotl += toLightY * normal.y;
		ndotl += toLightZ * normal.z;
		// correct NdotL
		float4 corr = length;
		ndotl = max (float4(0,0,0,0), ndotl * corr);
		// attenuation
		float4 atten = 1.0 / (1.0 + length * lightAttenSq * lightAttenSq);
		float4 diff = ndotl * atten;
		// final color
		float3 col = 0;
		col += lightColor0 * diff.x;
		col += lightColor1 * diff.y;
		col += lightColor2 * diff.z;
		col += lightColor3 * diff.w;
		return col;
	}
	
	//点光源的结果计算
	#define GET_POINT_RESULT(worNor4Po,worPos4Po,output) output = Get_Point_Result(worNor4Po,worPos4Po);
		fixed3 Get_Point_Result(float3 worNorPo,float3 worPosPo)
		{
			fixed3 vLCol;
			half3 firstLightPos = float3(unity_4LightPosX0.x,unity_4LightPosY0.x,unity_4LightPosZ0.x);
			half3 dir2L = firstLightPos - worPosPo;
			half dis = dot(dir2L,dir2L);
			half attenVL = 1.0 / (1.0 + dis * unity_4LightAtten0.x * unity_4LightAtten0.x);
			half3 lightDirV = normalize(dir2L);
			half dotVL = saturate(dot(lightDirV,worNorPo));
			
			fixed vI = dotVL * attenVL; 
			vLCol = vI * unity_LightColor[0].rgb;
			return vLCol;
			
			/*fixed3 vLCol1;
			half3 firstLightPos1 = float3(unity_4LightPosX0.y,unity_4LightPosY0.y,unity_4LightPosZ0.y);
			half3 dir2L1 = firstLightPos1 - worPosPo;
			half dis1 = dot(dir2L1,dir2L1);
			half attenVL1 = 1.0 / (1.0 + dis1 * unity_4LightAtten0.y * unity_4LightAtten0.y);
			half3 lightDirV1 = normalize(dir2L1);
			half dotVL1 = saturate(dot(lightDirV1,worNorPo));
				
			fixed vI1 = dotVL1 * attenVL1; 
			vLCol1 = vI1 * unity_LightColor[1].rgb;
			return vLCol + vLCol1;*/
			
			
			/*return Shade4PointLights_Low(unity_4LightPosX0,unity_4LightPosY0,unity_4LightPosZ0,
			unity_LightColor[0].rgb,unity_LightColor[1].rgb,unity_LightColor[2].rgb,unity_LightColor[3].rgb,
			unity_4LightAtten0, worPosPo, worNorPo);*/
		}
		
		
#endif 