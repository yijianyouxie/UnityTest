#ifndef NOISE_DECAL_INCLUDE  
#define NOISE_DECAL_INCLUDE  	
	
	#include "../../TLS_Shaders/Weather/Include/CommonCal.cginc"
	#include "../../TLS_Shaders/Weather/Include/TintColor.cginc"
	
	#define VAR_NOISE_DECAL_NEED
		sampler2D _NormalNoiseMap;
		float4 _NormalNoiseMap_ST;
		uniform half _NormalNoisePower;
		half _NormalNoiseSpeed;
		fixed _NormalNoiseTiling;
		uniform half _NormalNoiseMapPower;
		fixed _NormalNoiseSpecGloss;
		fixed _NormalNoiseSpecPower;
		uniform half _DecalPower;
		uniform half _Decal2Tiling;

		#define DECAL_COLOR_MASKMAP_S_R_WORLD_CENTER(wPos,wNormal,maskUV,output) output = CAL_DECAL_COLOR_MaskMap_S_R_WORLD_CENTER(output,wPos,wNormal,maskUV);
		float3 CAL_DECAL_COLOR_MaskMap_S_R_WORLD_CENTER(float3 withDecalColor,float3 wPos,float3 wNormal,float2 uv) 
		{
			float rainMask = 1;
			//#ifdef SNOW_RAIN_IN_SAME_MASKMAP
				rainMask = tex2D(_TintMask_SnowR_RainR,uv).g * _RainMaskPower;
			//#endif
			
			float2 uvTiling = GET_UV_WITH_POS_NOR_CENTER_POS(wPos,wNormal);
			uvTiling.y += _Time.y * _NormalNoiseSpeed;
			float3 decalColor1 = tex2D(_NormalNoiseMap,uvTiling * _NormalNoiseTiling);
			uvTiling.y += _Time.y * _NormalNoiseSpeed;
			float3 decalColor2 = tex2D(_NormalNoiseMap,uvTiling * _NormalNoiseTiling * _Decal2Tiling);

			withDecalColor.rgb += lerp(float3(0,0,0),(decalColor1 * decalColor2 * _DecalPower) * rainMask,_NormalNoisePower);
			return withDecalColor;
		}
		
		#define DECAL_COLOR_WORLD_CENTER(wPos,wNormal,output) output = CAL_DECAL_COLOR_WORLD_CENTER(output,wPos,wNormal);
		float3 CAL_DECAL_COLOR_WORLD_CENTER(float3 withDecalColor,float3 wPos,float3 wNormal) 
		{
			float2 uvTiling = GET_UV_WITH_POS_NOR_CENTER_POS(wPos,wNormal);
			uvTiling.y += _Time.y * _NormalNoiseSpeed;
			float3 decalColor1 = tex2D(_NormalNoiseMap,uvTiling * _NormalNoiseTiling);
			uvTiling.y += _Time.y * _NormalNoiseSpeed;
			float3 decalColor2 = tex2D(_NormalNoiseMap,uvTiling * _NormalNoiseTiling * _Decal2Tiling);

			withDecalColor.rgb += lerp(float3(0,0,0),(decalColor1 * decalColor2 * _DecalPower),_NormalNoisePower);
			return withDecalColor;
		}
		
		#define DECAL_COLOR(wPos,wNormal,output) output = CAL_DECAL_COLOR(output,wPos,wNormal);
		float3 CAL_DECAL_COLOR(float3 withDecalColor,float3 wPos,float3 wNormal) 
		{
			float2 uvTiling = GET_UV_WITH_POS_NOR_CENTER_POS(wPos,wNormal);
			uvTiling.y += _Time.y * _NormalNoiseSpeed;
			float3 decalColor1 = tex2D(_NormalNoiseMap,uvTiling * _NormalNoiseTiling);
			uvTiling.y += _Time.y * _NormalNoiseSpeed;
			float3 decalColor2 = tex2D(_NormalNoiseMap,uvTiling * _NormalNoiseTiling * _Decal2Tiling);

			withDecalColor.rgb += lerp(float3(0,0,0),(decalColor1 * decalColor2 * _DecalPower),_NormalNoisePower);
			return withDecalColor;
		}

		#define DECAL_SPEC(nhVar,shininessVar,outputSpec) outputSpec = CAL_DECAL_SPEC(outputSpec,nhVar,shininessVar);
		float CAL_DECAL_SPEC(float finalSpec,float nh,half shiVar)
		{
			finalSpec = pow(nh, shiVar * 128) * (lerp(1,_NormalNoiseSpecPower,_NormalNoisePower));
			return finalSpec;
		}

		#define NOISE_NOR_RECAL(uvNoise, outputNor) outputNor = EXC_NOISE_NOR_RECAL(outputNor,uvNoise);
		float3 EXC_NOISE_NOR_RECAL(float3 noiseFinalNor,float2 noiseUV)
		{
			float2 noiseNormal1 = tex2D(_NormalNoiseMap,noiseUV * _NormalNoiseTiling +  0.1 * _Time.y * _NormalNoiseSpeed).rg;
			float2 noiseNormal2 = tex2D(_NormalNoiseMap,noiseUV * _NormalNoiseTiling -  0.1 * _Time.y * _NormalNoiseSpeed).rg;
			
			noiseNormal1 = (noiseNormal1 - 0.5) * 2;
			noiseNormal2 = (noiseNormal2 - 0.5) * 2;
			
			float3 noiseNor1 = normalize(float3(noiseNormal1.x * _DecalPower + noiseFinalNor.x,noiseFinalNor.y,noiseNormal1.y * _DecalPower + noiseFinalNor.z));
			float3 noiseNor2 = normalize(float3(noiseNormal2.x * _DecalPower + noiseFinalNor.x,noiseFinalNor.y,noiseNormal2.y * _DecalPower + noiseFinalNor.z));
			
			float3 finalNormal = noiseNor1 + noiseNor2;
			noiseFinalNor = normalize(lerp(noiseFinalNor,finalNormal + noiseFinalNor,_NormalNoisePower));
			return noiseFinalNor;
		}
		
		half _AttenHigh = 0.95;
		half _AttenRange = 0.1;
		half _LowValue = 0;
		sampler2D _TexRollMap;
		half _TexRollMapPower;
		half _TexRollMapTiling;
		half _TexRollMapSpeed;
		half _TexRollAttenHigh = 0.85;
		half _TexRollAttenRange = 0.2;
		half _TexRollLowValue = 0;
		#define NOISE_NOR_RECAL_SNOWMASK_4TERRAIN(wPos,uvNoise,inNor,inColor, outputNor,outColor) EXC_NOISE_NOR_RECAL_4Terr(uvNoise,wPos,inNor,inColor,outputNor,outColor);
		void EXC_NOISE_NOR_RECAL_4Terr(float2 noiseUV,float3 worldPos,float3 inNor,float3 inColor,out float4 noiseFinalNor,out fixed3 finalColor)
		{
			//积水的mask图
			float maskValue = 1;
			//#ifdef SNOW_RAIN_IN_SAME_MASKMAP
				maskValue = tex2D(_TintMask_SnowR_RainR,noiseUV).g * _RainMaskPower;
			//#endif
			
			//根据法线朝向的衰减计算，大于_AttenHigh值返回1 小于_AttenHigh - _AttenRange返回_LowValue，处于之间，lerp
			float updot = saturate(dot(inNor,float3(0,1,0)));
			float finalNoiseFix = 1.0;			
			GET_ATTEN_2_VALUE(finalNoiseFix,updot,_AttenHigh - _AttenRange,_AttenHigh,_LowValue)
			
			//两个法线扰动图的采样
			float2 noiseNormal1 = tex2D(_NormalNoiseMap,noiseUV * _NormalNoiseTiling +  0.1 * _Time.y * _NormalNoiseSpeed).rg;
			float2 noiseNormal2 = tex2D(_NormalNoiseMap,noiseUV * _NormalNoiseTiling -  0.1 * _Time.y * _NormalNoiseSpeed).rg;			
			noiseNormal1 = (noiseNormal1 - 0.5) * 2;
			noiseNormal2 = (noiseNormal2 - 0.5) * 2;
			
			//扰动的power值
			float finalDecalPower = _NormalNoiseMapPower;		
			float3 noiseNor1 = normalize(float3(noiseNormal1.x * finalDecalPower + inNor.x,inNor.y,noiseNormal1.y * finalDecalPower + inNor.z));
			float3 noiseNor2 = normalize(float3(noiseNormal2.x * finalDecalPower + inNor.x,inNor.y,noiseNormal2.y * finalDecalPower + inNor.z));
			
			//扰动的法线值
			float3 finalNormal = noiseNor1 + noiseNor2;
			float3 tempNor = normalize(lerp(inNor,finalNormal + inNor,finalNoiseFix));
			//最终结果的计算
			noiseFinalNor.xyz = normalize(lerp(inNor,tempNor,(min(maskValue ,_NormalNoisePower ))));//maskValue * _NormalNoisePower//min(_NormalNoisePower,saturate(maskValue - _NormalNoiseMapPower))
			noiseFinalNor.w = finalNoiseFix;
			//流水纹理的采样
			float2 uvTiling = GET_UV_WITH_POS_NOR_CENTER_POS(worldPos,inNor);
			uvTiling.y += _Time.y * _TexRollMapSpeed;
			float3 decalColor1 = tex2D(_TexRollMap,uvTiling * _TexRollMapTiling);
			uvTiling.y += _Time.y * _TexRollMapSpeed;
			float3 decalColor2 = tex2D(_TexRollMap,uvTiling * _TexRollMapTiling * _Decal2Tiling);
			finalColor.rgb = inColor.rgb;
			
			//流水纹理的衰减计算，法线与Y轴夹角Dot小于TexRollAttenHigh - _TexRollAttenRange的，最终结果为1，大于_TexRollAttenHigh的，结果为0，中间结果为lerp
			float finalColorFix = 1.0;			
			GET_ATTEN_2_VALUE(finalColorFix,updot,_TexRollAttenHigh - _TexRollAttenRange,_TexRollAttenHigh,_TexRollLowValue)
			finalColorFix = 1- finalColorFix;
			
			//根据衰减计算的流水纹理结果
			fixed3 tempColor = saturate(lerp(float3(0,0,0),decalColor1 * decalColor2,finalColorFix)) * _TexRollMapPower;
			//最终结果的混合
			finalColor.rgb += lerp(float3(0,0,0),tempColor,_NormalNoisePower);//fixed3(finalColorFix,finalColorFix,finalColorFix);
		}
		
		#define RECAL_SNOWMASK_4TERRAIN(wPos,uvNoise,inNor,inColor,outColor) EXC_RECAL_4Terr(uvNoise,wPos,inNor,inColor,outColor);
		void EXC_RECAL_4Terr(float2 noiseUV,float3 worldPos,float3 inNor,float3 inColor,out fixed3 finalColor)
		{
			//积水的mask图
			float maskValue = 1;
			//#ifdef SNOW_RAIN_IN_SAME_MASKMAP
				maskValue = tex2D(_TintMask_SnowR_RainR,noiseUV).g * _RainMaskPower;
			//#endif
			
			//根据法线朝向的衰减计算，大于_AttenHigh值返回1 小于_AttenHigh - _AttenRange返回_LowValue，处于之间，lerp
			float updot = saturate(dot(inNor,float3(0,1,0)));
			float finalNoiseFix = 1.0;			
			GET_ATTEN_2_VALUE(finalNoiseFix,updot,_AttenHigh - _AttenRange,_AttenHigh,_LowValue)
			
			//流水纹理的采样
			float2 uvTiling = GET_UV_WITH_POS_NOR_CENTER_POS(worldPos,inNor);
			uvTiling.y += _Time.y * _TexRollMapSpeed;
			float3 decalColor1 = tex2D(_TexRollMap,uvTiling * _TexRollMapTiling);
			uvTiling.y += _Time.y * _TexRollMapSpeed;
			float3 decalColor2 = tex2D(_TexRollMap,uvTiling * _TexRollMapTiling * _Decal2Tiling);
			finalColor.rgb = inColor.rgb;
			
			//流水纹理的衰减计算，法线与Y轴夹角Dot小于TexRollAttenHigh - _TexRollAttenRange的，最终结果为1，大于_TexRollAttenHigh的，结果为0，中间结果为lerp
			float finalColorFix = 1.0;			
			GET_ATTEN_2_VALUE(finalColorFix,updot,_TexRollAttenHigh - _TexRollAttenRange,_TexRollAttenHigh,_TexRollLowValue)
			finalColorFix = 1- finalColorFix;
			
			//根据衰减计算的流水纹理结果
			fixed3 tempColor = saturate(lerp(float3(0,0,0),decalColor1 * decalColor2,finalColorFix)) * _TexRollMapPower;
			//最终结果的混合
			finalColor.rgb += lerp(float3(0,0,0),tempColor,maskValue);//fixed3(finalColorFix,finalColorFix,finalColorFix);
		}
		
		#define NOISE_TEX_4TERRAIN(wPos,uvNoise,inNor,outUVNoise) EXC_Noise_Tex_4Terr(uvNoise,wPos,inNor,outUVNoise);
		void EXC_Noise_Tex_4Terr(float2 noiseUV,float3 worldPos,float3 inNor,out float2 outUVNoise)
		{
			//积水的mask图
			float maskValue = 1;
			#ifdef SNOW_RAIN_IN_SAME_MASKMAP
				maskValue = tex2D(_TintMask_SnowR_RainR,noiseUV).g * _RainMaskPower;
			#endif
			
			//根据法线朝向的衰减计算，大于_AttenHigh值返回1 小于_AttenHigh - _AttenRange返回_LowValue，处于之间，lerp
			float updot = saturate(dot(inNor,float3(0,1,0)));
			float finalNoiseFix = 1.0;			
			GET_ATTEN_2_VALUE(finalNoiseFix,updot,_AttenHigh - _AttenRange,_AttenHigh,_LowValue)
			
			//两个法线扰动图的采样
			float2 noiseNormal1 = tex2D(_NormalNoiseMap,noiseUV * _NormalNoiseTiling + 0.1 * _Time.y * _NormalNoiseSpeed).rg;// * _NormalNoiseTiling +  0.1 * _Time.y * _NormalNoiseSpeed
			float2 noiseNormal2 = tex2D(_NormalNoiseMap,noiseUV * _NormalNoiseTiling - 0.1 * _Time.y * _NormalNoiseSpeed).rg;// * _NormalNoiseTiling -  0.1 * _Time.y * _NormalNoiseSpeed			
			noiseNormal1 = (noiseNormal1 - 0.5) * 2;
			noiseNormal2 = (noiseNormal2 - 0.5) * 2;
			
			//扰动的power值
			float finalDecalPower = _NormalNoiseMapPower;		
			float2 noiseUV1 = (noiseNormal1 * finalDecalPower);//float2(noiseNormal1.x * finalDecalPower,noiseNormal1.y * finalDecalPower)
			float2 noiseUV2 = (noiseNormal2 * finalDecalPower);//float2(noiseNormal2.x * finalDecalPower,noiseNormal2.y * finalDecalPower)
			
			//扰动的法线值
			float2 finalUV = noiseUV1 + noiseUV2;
			float2 tempUV = (lerp(float2(0,0),finalUV + float2(0,0),finalNoiseFix));
			//最终结果的计算
			outUVNoise.xy = (lerp(float2(0,0),tempUV,(min(maskValue ,_NormalNoisePower ))));
		}
		
		#define TWO_RECAL_SNOWMASK_4TERRAIN(wPos,uvNoise,inNor,inColor,outColor) EXC_TWO_RECAL_4Terr(uvNoise,wPos,inNor,inColor,outColor);
		void EXC_TWO_RECAL_4Terr(float2 noiseUV,float3 worldPos,float3 inNor,float3 inColor,out fixed3 finalColor)
		{
			//积水的mask图
			float maskValue = 1;
			#ifdef SNOW_RAIN_IN_SAME_MASKMAP
				maskValue = tex2D(_TintMask_SnowR_RainR,noiseUV).g * _RainMaskPower;
			#endif
			
			//根据法线朝向的衰减计算，大于_AttenHigh值返回1 小于_AttenHigh - _AttenRange返回_LowValue，处于之间，lerp
			float updot = saturate(dot(inNor,float3(0,1,0)));
			float finalNoiseFix = 1.0;			
			GET_ATTEN_2_VALUE(finalNoiseFix,updot,_AttenHigh - _AttenRange,_AttenHigh,_LowValue)
			
			//两个法线扰动图的采样
			float3 noiseNormal1 = tex2D(_TexRollMap,noiseUV * _NormalNoiseTiling +  0.1 * _Time.y * _NormalNoiseSpeed).rgb;
			float3 noiseNormal2 = tex2D(_TexRollMap,noiseUV * _NormalNoiseTiling -  0.1 * _Time.y * _NormalNoiseSpeed).rgb;			
			//noiseNormal1 = (noiseNormal1 - 0.5) * 2;
			//noiseNormal2 = (noiseNormal2 - 0.5) * 2;
			
			//扰动的power值
			//float finalDecalPower = _NormalNoiseMapPower;		
			//float3 noiseNor1 = normalize(float3(noiseNormal1.x * finalDecalPower + inNor.x,inNor.y,noiseNormal1.y * finalDecalPower + inNor.z));
			//float3 noiseNor2 = normalize(float3(noiseNormal2.x * finalDecalPower + inNor.x,inNor.y,noiseNormal2.y * finalDecalPower + inNor.z));
			
			//扰动的法线值
			float3 finalNormal = noiseNormal1 * noiseNormal2;
			//float3 tempNor = normalize(lerp(inNor,finalNormal + inNor,finalNoiseFix));
			//最终结果的计算
			//noiseFinalNor.xyz = normalize(lerp(inNor,tempNor,(min(maskValue ,_NormalNoisePower ))));//maskValue * _NormalNoisePower//min(_NormalNoisePower,saturate(maskValue - _NormalNoiseMapPower))
			//noiseFinalNor.w = finalNoiseFix;
			//流水纹理的采样
			float2 uvTiling = GET_UV_WITH_POS_NOR_CENTER_POS(worldPos,inNor);
			uvTiling.y += _Time.y * _TexRollMapSpeed;
			float3 decalColor1 = tex2D(_TexRollMap,uvTiling * _TexRollMapTiling);
			uvTiling.y += _Time.y * _TexRollMapSpeed;
			float3 decalColor2 = tex2D(_TexRollMap,uvTiling * _TexRollMapTiling * _Decal2Tiling);
			finalColor.rgb = inColor.rgb;
			
			//流水纹理的衰减计算，法线与Y轴夹角Dot小于TexRollAttenHigh - _TexRollAttenRange的，最终结果为1，大于_TexRollAttenHigh的，结果为0，中间结果为lerp
			float finalColorFix = 1.0;			
			GET_ATTEN_2_VALUE(finalColorFix,updot,_TexRollAttenHigh - _TexRollAttenRange,_TexRollAttenHigh,_TexRollLowValue)
			finalColorFix = 1- finalColorFix;
			
			//根据衰减计算的流水纹理结果
			fixed3 tempColor = saturate(lerp(finalNormal,decalColor1 * decalColor2,finalColorFix)) * _TexRollMapPower;
			//最终结果的混合
			finalColor.rgb += lerp(finalNormal,tempColor,_NormalNoisePower);//fixed3(finalColorFix,finalColorFix,finalColorFix);
		}
		
		#define NOISE_NOR_RECAL_SNOWMASK(wPos,uvNoise, outputNor) outputNor = EXC_NOISE_NOR_RECAL(outputNor,uvNoise,wPos);
		float3 EXC_NOISE_NOR_RECAL(float3 noiseFinalNor,float2 noiseUV,float3 worldPos)
		{
			float maskValue = CalMaskValue4ChannelMapwithDot(worldPos,noiseFinalNor);
			
			float2 noiseNormal1 = tex2D(_NormalNoiseMap,noiseUV * _NormalNoiseTiling +  0.1 * _Time.y * _NormalNoiseSpeed).rg;
			float2 noiseNormal2 = tex2D(_NormalNoiseMap,noiseUV * _NormalNoiseTiling -  0.1 * _Time.y * _NormalNoiseSpeed).rg;
			
			noiseNormal1 = (noiseNormal1 - 0.5) * 2;
			noiseNormal2 = (noiseNormal2 - 0.5) * 2;
			
			float3 noiseNor1 = normalize(float3(noiseNormal1.x * _DecalPower + noiseFinalNor.x,noiseFinalNor.y,noiseNormal1.y * _DecalPower + noiseFinalNor.z));
			float3 noiseNor2 = normalize(float3(noiseNormal2.x * _DecalPower + noiseFinalNor.x,noiseFinalNor.y,noiseNormal2.y * _DecalPower + noiseFinalNor.z));
			
			float3 finalNormal = noiseNor1 + noiseNor2;
			noiseFinalNor = normalize(lerp(noiseFinalNor,finalNormal + noiseFinalNor,min(_NormalNoisePower,saturate(maskValue - _NormalNoiseMapPower))));
			return noiseFinalNor;
			//return float3(min(_NormalNoisePower,maskValue),min(_NormalNoisePower,maskValue),min(_NormalNoisePower,maskValue));//noiseFinalNor;
		}

		#define NOISE_NOR_RECAL_UP_2_DOWN(wPos,wNor) EXC_NOISE_NOR_RECAL_UP_2_DOWN(wNor,wPos);
		float3 EXC_NOISE_NOR_RECAL_UP_2_DOWN(float3 noiseFinalNor,float3 wPos)
		{
			float2 uvTiling = GET_UV_WITH_POS_NOR_CENTER_POS(wPos,noiseFinalNor);
			uvTiling.y += _Time.y * _NormalNoiseSpeed;
			
			float2 noiseNormal1 = tex2D(_NormalNoiseMap,uvTiling * _NormalNoiseTiling).rg;
			uvTiling.y += _Time.y * _NormalNoiseSpeed;
			float2 noiseNormal2 = tex2D(_NormalNoiseMap,uvTiling * _NormalNoiseTiling * _Decal2Tiling).rg;
			
			noiseNormal1 = (noiseNormal1 - 0.5) * 2;
			noiseNormal2 = (noiseNormal2 - 0.5) * 2;

			float3 noiseNor1 = normalize(float3(noiseNormal1.x * _DecalPower + noiseFinalNor.x,noiseFinalNor.y,noiseNormal1.y * _DecalPower + noiseFinalNor.z));
			float3 noiseNor2 = normalize(float3(noiseNormal2.x * _DecalPower + noiseFinalNor.x,noiseFinalNor.y,noiseNormal2.y * _DecalPower + noiseFinalNor.z));
			
			float3 finalNormal = noiseNor1 + noiseNor2;
			noiseFinalNor = normalize(lerp(noiseFinalNor,finalNormal + noiseFinalNor,_NormalNoisePower));
			return noiseFinalNor;
		}
		
		#define NOISE_SPEC(nhVar,shininessVar,outputSpec) outputSpec = CAL_NOISE_SPEC(outputSpec,nhVar,shininessVar);
		float CAL_NOISE_SPEC(float finalSpec,float nh,half shiVar)
		{
			float specWet = pow(nh, (shiVar * 128) + _NormalNoiseSpecGloss) * _NormalNoiseSpecPower;
			finalSpec = lerp(finalSpec,specWet,_NormalNoisePower);
			return finalSpec;
		}

#endif 