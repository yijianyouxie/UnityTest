#ifndef TINT_COLOR_INCLUDE  
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
//#pragma exclude_renderers d3d11
#define TINT_COLOR_INCLUDE  	
	
	#include "Assets/TLS_Shaders/Weather/Include/CommonCal.cginc"
float TINT_ENABLE;
float RAIN_ENABLE;

	
	#define VAR_TINT_COLOR_NEED 
		sampler2D _TintMask;	//need setting in properties
		float4 _TintMask_ST;
		half _TintPowerMaxRange = 2;//need setting in properties
		//half _TintPowerSpeed;	//need setting in properties
		half _TintNormalEx;		//need setting in properties
		half _MaskMapTiling;	//need setting in properties
		uniform int	_RandomValue = 0;
		struct STRUCT_TINT
		{
			fixed3 tintColor;
			float3 tintNormal;
		};
	
		uniform fixed3 _TintWeatherColor = fixed3(0.5,0.5,0.5);
		uniform float _TintWeatherPower = 0;
	
	#ifdef VAR_TINT_COLOR_FAKENOR
		sampler2D _TintColorFakeNorMap;//need setting in properties
		float4 _TintMaskNorMap_ST;
		float _TintMaskNorMapTiling;	//need setting in properties
	#endif
	
	#ifdef VAR_TINT_TEX
		sampler2D _TintTex;	//need setting in properties
		float4 _TintTex_ST;
		half _TintTexTiling; //need setting in properties
	#endif
	
	#ifdef VAR_TINT_COLOR_NEED_4_PBR
		sampler2D _TintMaskNorMap;//need setting in properties
		float4 _TintMaskNorMap_ST;
		half _TintMetallic;		//need setting in properties
		half _TintSmoothness;	//need setting in properties
		struct STRUCT_TINT_4_PBR
		{
			fixed3 finalColorPBR;
			half2 metallicAndSmoothness;
			float3 tintNormal;
			half4 tangentToWorld4Tint[3];
		};
	#endif
	
	float3 FinalColorCal(float3 colorSrc, float3 colorDec, fixed value)
	{
		colorSrc = saturate(lerp(colorSrc, colorDec, saturate(value)));
		return colorSrc;
	}
	
	float DotWithDir(float3 dirRef,float3 normalCal, half normalEx)
	{
		return saturate((dot(normalCal, dirRef) + normalEx) / (1 + normalEx));  
	}	
	
	float FixTintMask(float tintMaskValue,float upDot)
	{
		float outValue = tintMaskValue * pow(1 + _TintWeatherPower,2);
		outValue += _TintWeatherPower - 1;
		outValue = upDot > 0.05 ? outValue : 0;
		return saturate(outValue);
	}
	
	float FixTintMaskWithRange(float tintMaskValue,float upDot)
	{
		float tintPower = min(_TintWeatherPower,_TintPowerMaxRange);
		float outValue = tintMaskValue * pow(1 + tintPower,2);
		outValue += tintPower - 1;
		outValue = upDot > 0.05 ? outValue : 0;
		return saturate(outValue);
	}
	
	float CalGrayScale(float3 inputColor)
	{
		return inputColor.r * 0.299 + inputColor.g * 0.587 + inputColor.b * 0.114;
	}
	
	float3 BlendColor(float3 inputColor,float3 tempColor,float valueHight,float valueLow)
	{
		return saturate(valueHight - valueLow < 0.1 ? lerp(inputColor,tempColor, saturate(valueHight - valueLow) * 10) : tempColor);
	}
	
	float CalMaskValue4ChannelMapwithDot(float3 worldPosition,float3 wN)
	{
		int mapArr[12] = {0,1,2,3,1,2,3,0,2,3,0,1};
		
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx); 
		float2 autoUV = GET_UV_WITH_POS_NOR_CENTER_POS(worldPosition,wN)
		autoUV = autoUV * (1 / _MaskMapTiling);
		autoUV -= float2(-1000,-1000);
		float tempX = abs(autoUV.x) / 5.0;
		float tempY = abs(autoUV.y) / 5.0;
		int indexX = fmod(autoUV.x ,5);
		int indexY = fmod(autoUV.y ,5);
		int index = indexX * 5 + indexY;
		int indexFinal = fmod(index,12);
		int finalIntValue = mapArr[indexFinal];
		
		float4 sampTintMask = tex2D(_TintMask,autoUV);	
		
		float finalMaskValue = sampTintMask.r;
		finalMaskValue = finalIntValue == 1 ? sampTintMask.g : finalMaskValue;
		finalMaskValue = finalIntValue == 2 ? sampTintMask.b : finalMaskValue;
		finalMaskValue = finalIntValue == 3 ? sampTintMask.a : finalMaskValue;
		
		return finalMaskValue;
	}
	
	float3 CalFinalColor(float3 inputColor, float grayscaleSrc,float grayscaleDes)
	{
		float3 tempColor = grayscaleSrc > grayscaleDes ? inputColor : _TintWeatherColor.rgb;
		return grayscaleSrc > grayscaleDes ? BlendColor(inputColor,tempColor,grayscaleSrc,grayscaleDes) : BlendColor(inputColor,tempColor,grayscaleDes,grayscaleSrc);
		
		//return saturate(grayscaleSrc - grayscaleDes < 0.1 ? lerp(inputColor,tempColor, saturate(grayscaleDes - grayscaleSrc) * 10) : tempColor);
	}
	
	float3 CalFinalColorBlend(float3 inputColor, float grayscaleSrc,float grayscaleDes)
	{
		float3 tempColor = grayscaleSrc > grayscaleDes ? inputColor : _TintWeatherColor.rgb;
		return saturate(lerp(inputColor,_TintWeatherColor.rgb,grayscaleDes));
	}
	
	#define TINT_VERTEX(output,texcoordX) output = CalUV_SMM(texcoordX);
	
	float2 CalUV_SMM(float4 texcoordX) 
	{
		float2 uv_SMM;
		uv_SMM = TRANSFORM_TEX(texcoordX, _TintMask);
		return uv_SMM;
	}
		
	
	#define TINT_CAL_COLOR(uv,norInW,output) output = CalTintColor(output,uv,norInW);
	
	float3 CalTintColor(float3 tintFinalColor,float2 uv,float3 wN)
	{
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx);//saturate((dot(wN, float3(0,1,0)) + _TintNormalEx) / (1 + _TintNormalEx));  	
		float sampTintMask = tex2D(_TintMask,uv.xy).r;
		fixed multi = _TintWeatherPower > 1 ? _TintWeatherPower * _TintWeatherPower : _TintWeatherPower;
		
		fixed power = (updot + sampTintMask) * multi;
		
		tintFinalColor.rgb = FinalColorCal(tintFinalColor.rgb ,_TintWeatherColor,power);
		return tintFinalColor;
	}
	
	#define TINT_CAL_COLOR_MASK(uv,norInW,output) output = CalTintColorMask(output,uv,norInW);
	
	float3 CalTintColorMask(float3 tintFinalColor,float2 uv,float3 wN)
	{
		float sampTintMask = tex2D(_TintMask,uv.xy).r;	
		fixed multi = _TintWeatherPower > 1 ? _TintWeatherPower * _TintWeatherPower : _TintWeatherPower;
		fixed power = sampTintMask * multi;
		
		tintFinalColor.rgb = FinalColorCal(tintFinalColor.rgb ,_TintWeatherColor,power);
		return tintFinalColor;
	}
	
	#define TINT_CAL_COLOR_MASK_1(uv,norInW,output) output = CalTintColorMask_1(output,uv,norInW);
	
	float3 CalTintColorMask_1(float3 tintFinalColor,float2 uv,float3 wN)
	{
		float4 sampTintMask = tex2D(_TintMask,uv.xy);	
		
		//float grayscale = sampTintMask.r * 0.299 + sampTintMask.g * 0.587 + sampTintMask.b * 0.114 + sampTintMask.a * saturate(_TintWeatherPower - 1);//_TintWeatherPower;
		
		float grayscale = sampTintMask.r + sampTintMask.a * saturate(_TintWeatherPower - 1);
		grayscale = grayscale * grayscale * grayscale;
		
		float3 maskFinal = float3(grayscale,grayscale,grayscale);
		tintFinalColor.rgb = saturate(tintFinalColor.rgb + maskFinal * saturate(_TintWeatherPower));
		return tintFinalColor.rgb;
	}
	
	#define TINT_CAL_COLOR_MASK_UP(uv,norInW,output) output = CalTintColorMask_up(output,uv,norInW);
	float3 CalTintColorMask_up(float3 tintFinalColor,float2 uv,float3 wN)
	{
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx);  
		float4 sampTintMask = tex2D(_TintMask,uv.xy);	
		
		//float grayscale = sampTintMask.r * 0.299 + sampTintMask.g * 0.587 + sampTintMask.b * 0.114 + sampTintMask.a * saturate(_TintWeatherPower - 1);//_TintWeatherPower;
		
		float grayscale = sampTintMask.r + saturate(_TintWeatherPower - 1);
		//grayscale = grayscale * grayscale * grayscale;
		
		grayscale = updot > 0.05 ? grayscale : 0;
		
		float3 maskFinal = float3(grayscale,grayscale,grayscale) * _TintWeatherColor.rgb;
		tintFinalColor.rgb = saturate(tintFinalColor.rgb + maskFinal * saturate(_TintWeatherPower));
		return tintFinalColor.rgb;
	}
	
	#define TINT_CAL_COLOR_MASK_UP_BLEND(uv,norInW,output) output = Tint_Cal_Color_Mask_Up_Blend(output,uv,norInW);
	float3 Tint_Cal_Color_Mask_Up_Blend(float3 tintFinalColor,float2 uv,float3 wN)
	{
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx); 
		float finalMaskValue = tex2D(_TintMask,uv.xy).r;		
		float grayscale = FixTintMask(finalMaskValue,updot);	
		float grayscaleInputColor = CalGrayScale(tintFinalColor);	
		
		return CalFinalColorBlend(tintFinalColor.rgb, grayscaleInputColor,grayscale);
	}
	
	#define TINT_CAL_COLOR_MASK_UP_BLEND_ALPHA(uv,norInW,output) output = Tint_Cal_Color_Mask_Up_Blend_Alpha(output,uv,norInW);
	float3 Tint_Cal_Color_Mask_Up_Blend_Alpha(float3 tintFinalColor,float2 uv,float3 wN)
	{
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx); 
		float4 finalMaskValue = tex2D(_TintMask,uv.xy);
		
		float maskValue = min(finalMaskValue.r,finalMaskValue.a);
		
		float tintPower = min(_TintWeatherPower,_TintPowerMaxRange);
		float outValue = maskValue * pow(1 + tintPower,2);
		outValue += tintPower - 1;
		
		//outValue = updot > 0.05 ? outValue * updot : 0;
		outValue = saturate(outValue * updot);
		
		//float grayscale = FixTintMask(maskValue,updot);	
		float grayscaleInputColor = CalGrayScale(tintFinalColor);	

		return CalFinalColorBlend(tintFinalColor.rgb, grayscaleInputColor,outValue);
	}
	
#ifdef VAR_TINT_COLOR_FAKENOR
	float3 Get_Nor_NormalMap(half3x3 tanData ,float2 uv)
	{
		half3 tangent = tanData[0].xyz;
		half3 binormal = tanData[1].xyz;
		half3 normal = tanData[2].xyz;

		float3 norTan = tex2D(_TintColorFakeNorMap,uv * _TintMaskNorMapTiling).rgb * 2 - 1;
		float3 normalWorld = normalize(tangent * norTan.x + binormal * norTan.y + normal * norTan.z);
		return normalWorld;
	}
	
	#define TINT_CAL_COLOR_MASK_UP_BLEND_ALPHA_FAKENOR(uv,posInW,output) output = Tint_Cal_Color_Mask_Up_Blend_Alpha_Fakenor(output,uv,posInW);
	STRUCT_TINT Tint_Cal_Color_Mask_Up_Blend_Alpha_Fakenor(STRUCT_TINT tintInput,float2 uv,float3 worldPosition)
	{
		float2 uvTiling = GET_UV_WITH_POS_NOR_CENTER_POS(worldPosition,tintInput.tintNormal);
		float3 norTan = tex2D(_TintColorFakeNorMap,uvTiling * (1 / _TintMaskNorMapTiling)).rgb;
		
		float updot = DotWithDir(float3(0,1,0),tintInput.tintNormal,_TintNormalEx); 
		float4 finalMaskValue = tex2D(_TintMask,uv.xy);
		
		float maskValue = min(finalMaskValue.r,finalMaskValue.a);
		
		float tintPower = min(_TintWeatherPower,_TintPowerMaxRange);
		float outValue = maskValue * pow(1 + tintPower,2);
		outValue += tintPower - 1;
		
		//outValue = updot > 0.05 ? outValue * updot : 0;
		outValue = saturate(outValue * updot);
		
		//float grayscale = FixTintMask(maskValue,updot);	
		float grayscaleInputColor = CalGrayScale(tintInput.tintColor);	

		tintInput.tintColor = CalFinalColorBlend(tintInput.tintColor.rgb, grayscaleInputColor,outValue);
		float2 tempNor = normalize(float2(norTan.x,norTan.y));
		tintInput.tintNormal = normalize(lerp(tintInput.tintNormal,float3(tempNor.x + tintInput.tintNormal.x,tintInput.tintNormal.y,tempNor.y + tintInput.tintNormal.z),outValue));
		return tintInput;
	}
	
	#define TINT_CAL_COLOR_MASK_DOT_GRAYSCALE_AUTO_UV_FAKENOR(worPos,tanData,input1,input2,output1,output2) Tint_Cal_Color_Mask_Dot_Grayscale_Auto_UV_FakeNor(worPos,tanData,input1,input2,output1,output2);
	void Tint_Cal_Color_Mask_Dot_Grayscale_Auto_UV_FakeNor(float3 worldPosition,half3x3 tanData,float3 inputColor,float3 inputNormalW,out float3 onputColor,out float3 onputNormalW) 
	{			
		float2 uvTiling = GET_UV_WITH_POS_NOR_CENTER_POS(worldPosition,inputNormalW);
		float3 norFromMap = Get_Nor_NormalMap(tanData , uvTiling);
		
		float updot = DotWithDir(float3(0,1,0),inputNormalW,_TintNormalEx); 
		float finalMaskValue = CalMaskValue4ChannelMapwithDot(worldPosition,inputNormalW);		
		float grayscale = FixTintMaskWithRange(finalMaskValue,updot);	
		float grayscaleInputColor = CalGrayScale(inputColor);	
		
		onputColor = CalFinalColorBlend(inputColor, grayscaleInputColor,grayscale);
		onputNormalW = normalize(lerp(inputNormalW,norFromMap,grayscale));
	}
	
	#define TINT_CAL_COLOR_DOT_NOMASKMAP_FAKENOR_T4M_2PARAMS(uv,tanData,input1,input2,output1,output2) Tint_Cal_Color_Dot_NoMaskmap_Fakenor_T4m_2Params(uv,tanData,input1,input2,output1,output2);
	void Tint_Cal_Color_Dot_NoMaskmap_Fakenor_T4m_2Params(float2 uv,half3x3 tanData,float3 inputColor,float3 inputNormalW,out float3 onputColor,out float3 onputNormalW)
	{
		float3 norFromMap = Get_Nor_NormalMap(tanData , uv);
		float finalMaskValue = tex2D(_TintMask,uv).r;
		float grayscaleInputColor = CalGrayScale(inputColor);
		
		float tintPower = min(_TintWeatherPower,_TintPowerMaxRange);		
		float updot = DotWithDir(float3(0,1,0),inputNormalW,_TintNormalEx);
		float grayscale = updot;
		grayscale = grayscale * tintPower * finalMaskValue;
		
		onputColor = CalFinalColorBlend(inputColor, grayscaleInputColor,grayscale);//float3(grayscale,grayscale,grayscale);//
		onputNormalW = normalize(lerp(inputNormalW,norFromMap,grayscale));
	}
	
	#define TINT_CAL_COLOR_DOT_FAKENOR_T4M_2PARAMS(uv,tanData,input1,input2,output1,output2) Tint_Cal_Color_Dot_Fakenor_T4m_2Params(uv,tanData,input1,input2,output1,output2);
	void Tint_Cal_Color_Dot_Fakenor_T4m_2Params(float2 uv,half3x3 tanData,float3 inputColor,float3 inputNormalW,out float3 onputColor,out float3 onputNormalW)
	{
		float3 norFromMap = Get_Nor_NormalMap(tanData , uv);
		//float finalMaskValue = tex2D(_TintMask,uv).r;
		float grayscaleInputColor = CalGrayScale(inputColor);
		
		float tintPower = min(_TintWeatherPower,_TintPowerMaxRange);		
		float updot = DotWithDir(float3(0,1,0),inputNormalW,_TintNormalEx);
		float grayscale = updot;
		grayscale = grayscale * tintPower;// * finalMaskValue;
		
		onputColor = CalFinalColorBlend(inputColor, grayscaleInputColor,grayscale);//float3(grayscale,grayscale,grayscale);//
		onputNormalW = normalize(lerp(inputNormalW,norFromMap,grayscale));
	}
#endif

	#ifdef TINT_PBR
	#include "UnityStandardCore.cginc"
	
	half3 PerPixelWorldNormal_Weather(float2 uv, half3x3 tangentToWorld)
	{
		#ifdef _NORMALMAP
			half3 tangent = tangentToWorld[0].xyz;
			half3 binormal = tangentToWorld[1].xyz;
			half3 normal = tangentToWorld[2].xyz;

			#if UNITY_TANGENT_ORTHONORMALIZE
				normal = NormalizePerPixelNormal(normal);

				// ortho-normalize Tangent
				tangent = normalize (tangent - normal * dot(tangent, normal));

				// recalculate Binormal
				half3 newB = cross(normal, tangent);
				binormal = newB * sign (dot (newB, binormal));
			#endif

			half3 normalTangent = tex2D (_TintMaskNorMap, uv).xyz * 2 - 1;//UnpackScaleNormal(tex2D (_TintMaskNorMap, uv), 1);
			//half3 normalTangent = NormalInTangentSpace(i_tex);
			half3 normalWorld = NormalizePerPixelNormal(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
		#else
			half3 normalWorld = normalize(tangentToWorld[2].xyz);
		#endif
			return normalWorld;
	}
	
	#define TINT_CAL_COLOR_MASK_UP_BLEND_ALPHA_4_PBR(uv,norInW,output) output = Tint_Cal_Color_Mask_Up_Blend_Alpha_4_PBR(output,uv,norInW);
	STRUCT_TINT_4_PBR Tint_Cal_Color_Mask_Up_Blend_Alpha_4_PBR(STRUCT_TINT_4_PBR str4PBRInput,float2 uv,float3 wN)
	{
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx); 
		float4 finalMaskValue = tex2D(_TintMask,uv.xy);
		
		float maskValue = min(finalMaskValue.r,finalMaskValue.a);
		
		float tintPower = min(_TintWeatherPower,_TintPowerMaxRange);
		float outValue = maskValue * pow(1 + tintPower,2);
		outValue += tintPower - 1;
		
		//outValue = updot > 0.05 ? outValue * updot : 0;
		outValue = saturate(outValue * updot);
		
		//float grayscale = FixTintMask(maskValue,updot);	
		float grayscaleInputColor = CalGrayScale(str4PBRInput.finalColorPBR.rgb);	
		str4PBRInput.finalColorPBR.rgb = CalFinalColorBlend(str4PBRInput.finalColorPBR.rgb, grayscaleInputColor,outValue);
		str4PBRInput.metallicAndSmoothness.x = lerp(str4PBRInput.metallicAndSmoothness.x, _TintMetallic, outValue);
		str4PBRInput.metallicAndSmoothness.y = lerp(str4PBRInput.metallicAndSmoothness.y, _TintSmoothness, outValue);
		return str4PBRInput;
	}
	
	#define TINT_CAL_COLOR_MASK_UP_BLEND_ALPHA_4_PBR_NOR(uv,tanData,inMetallic,inGlossiness,inColor,inNormal,oMetallic,oGlossiness,oColor,oNormal) Tint_Cal_Color_Mask_Up_Blend_Alpha_4_PBR_Nor(uv,tanData,inMetallic,inGlossiness,inColor,inNormal,oMetallic,oGlossiness,oColor,oNormal);
	void Tint_Cal_Color_Mask_Up_Blend_Alpha_4_PBR_Nor(float2 uv,half3x3 tanData,float inMetallic,float inGlossiness,float3 inColor,float3 inNormal,out float oMetallic,out float oGlossiness,out float3 oColor,out float3 oNormal)
	{		
		half3 normalWorld = PerPixelWorldNormal_Weather(uv,tanData);
		float3 wN = inNormal;
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx); 
		float4 finalMaskValue = tex2D(_TintMask,uv.xy);
		
		float maskValue = min(finalMaskValue.r,finalMaskValue.a);
	
	#ifdef TINT_FINISH
		float tintPower = _TintPowerMaxRange;
	#else
		float tintPower = min(_TintWeatherPower,_TintPowerMaxRange);
	#endif
		float outValue = maskValue * pow(1 + tintPower,2);
		outValue += tintPower - 1;

		outValue = saturate(outValue * updot);
		
	#ifdef TINT_FINISH
		oColor.rgb = lerp(inColor.rgb, _TintWeatherColor,outValue);
	#else
		float grayscaleInputColor = CalGrayScale(inColor.rgb);
		oColor.rgb = CalFinalColorBlend(inColor.rgb, grayscaleInputColor,outValue);
	#endif
		oMetallic = lerp(inMetallic, _TintMetallic, outValue);
		oGlossiness = lerp(inGlossiness, _TintSmoothness, outValue);
		oNormal = lerp(wN, normalWorld, outValue);
	}
	
	#endif
	
	#define TINT_TEX_MASKMAP_BASECOLOR_NODOT_AUTO_UV(worPos,uv,output) output = Tint_Tex_MaskMap_BaseColor_NoDot_Auto_UV(output,worPos,uv);
	float3 Tint_Tex_MaskMap_BaseColor_NoDot_Auto_UV(float3 tintFinalColor,float3 worldPosition ,float2 uv_MaskMap) 
	{
		float finalMaskValue = tex2D(_TintMask_SnowR_RainR,uv_MaskMap).r;	
		
		float grayscaleInputColor = CalGrayScale(tintFinalColor);
		
		#ifdef VAR_TINT_TEX
			float2 autoUV = GET_UV_WITH_POS_UP_2_DOWN(worldPosition)		
			float3 tintTex = tex2D(_TintTex,autoUV * (1 / _TintTexTiling)).rgb;	
		#else
			float3 tintTex = _TintWeatherColor;
		#endif
		
		#ifdef TINT_FINISH
			float tintPower = _TintPowerMaxRange;
		#else
			float tintPower = min(_TintWeatherPower,_TintPowerMaxRange);
		#endif
		
		float grayscale = tintPower * finalMaskValue;
		float3 tempColor = grayscaleInputColor > grayscale ? tintFinalColor : tintTex * _TintWeatherColor.rgb;
		tempColor = grayscaleInputColor > grayscale ? BlendColor(tintFinalColor,tempColor,grayscaleInputColor,grayscale) : BlendColor(tintFinalColor,tempColor,grayscale,grayscaleInputColor);
		return tempColor;
	}
	
	#define TINT_TEX_NOMASK_BASECOLOR_DOT_AUTO_UV(worPos,norInW,output) output = Tint_Tex_NoMask_BaseColor_Dot_Auto_UV(output,worPos,norInW);
	float3 Tint_Tex_NoMask_BaseColor_Dot_Auto_UV(float3 tintFinalColor,float3 worldPosition ,float3 wN) 
	{
		//float3 finalMaskValue = tex2D(_TintMask,uv_MaskMap).rgb;	
		
		float grayscaleInputColor = CalGrayScale(tintFinalColor);

		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx);
		
		#ifdef VAR_TINT_TEX
			float2 autoUV = GET_UV_WITH_POS_UP_2_DOWN(worldPosition)		
			float3 tintTex = tex2D(_TintTex,autoUV * (1 / _TintTexTiling)).rgb;	
		#else
			float3 tintTex = _TintWeatherColor;
		#endif
		
		#ifdef TINT_FINISH
			float tintPower = _TintPowerMaxRange;
		#else
			float tintPower = min(_TintWeatherPower,_TintPowerMaxRange);
		#endif
		
		float grayscale = updot * tintPower;// * finalMaskValue;
		float3 tempColor = grayscaleInputColor > grayscale ? tintFinalColor : tintTex * _TintWeatherColor.rgb;
		tempColor = grayscaleInputColor > grayscale ? BlendColor(tintFinalColor,tempColor,grayscaleInputColor,grayscale) : BlendColor(tintFinalColor,tempColor,grayscale,grayscaleInputColor);
		return tempColor;
	}
	
	#define TINT_TEX_MASKMAP_BASECOLOR_DOT_AUTO_UV(worPos,norInW,uv,output) output = Tint_Tex_MaskMap_BaseColor_Dot_Auto_UV(output,worPos,norInW,uv);
	float3 Tint_Tex_MaskMap_BaseColor_Dot_Auto_UV(float3 tintFinalColor,float3 worldPosition ,float3 wN,float2 uv_MaskMap) 
	{
		float finalMaskValue = tex2D(_TintMask_SnowR_RainR,uv_MaskMap).r;	
		
		float grayscaleInputColor = CalGrayScale(tintFinalColor);

		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx);
		
		#ifdef VAR_TINT_TEX
			float2 autoUV = GET_UV_WITH_POS_UP_2_DOWN(worldPosition)		
			float3 tintTex = tex2D(_TintTex,autoUV * (1 / _TintTexTiling)).rgb;	
		#else
			float3 tintTex = _TintWeatherColor;
		#endif
		
		#ifdef TINT_FINISH
			float tintPower = _TintPowerMaxRange;
		#else
			float tintPower = min(_TintWeatherPower,_TintPowerMaxRange);
		#endif
		
		float grayscale = updot * tintPower * finalMaskValue;
		float3 tempColor = grayscaleInputColor > grayscale ? tintFinalColor : tintTex * _TintWeatherColor.rgb;
		tempColor = grayscaleInputColor > grayscale ? BlendColor(tintFinalColor,tempColor,grayscaleInputColor,grayscale) : BlendColor(tintFinalColor,tempColor,grayscale,grayscaleInputColor);
		return tempColor;
	}
	
	#define TINT_TEX_DOT_AUTO_UV(worPos,norInW,output) output = Tint_Tex_Dot_Auto_UV(output,worPos,norInW);
	float3 Tint_Tex_Dot_Auto_UV(float3 tintFinalColor,float3 worldPosition ,float3 wN) 
	{
		
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx);
		
		#ifdef VAR_TINT_TEX
			float2 autoUV = GET_UV_WITH_POS_UP_2_DOWN(worldPosition)		
			float3 tintTex = tex2D(_TintTex,autoUV * (1 / _TintTexTiling)).rgb;	
		#else
			float3 tintTex = _TintWeatherColor;
		#endif
		
		#ifdef TINT_FINISH
			float tintPower = _TintPowerMaxRange;
		#else
			float tintPower = min(_TintWeatherPower,_TintPowerMaxRange);
		#endif
		
		float outValue = 1 * pow(1 + tintPower,2);
		outValue += tintPower - 1;

		outValue = saturate(outValue * updot);
		
		return lerp(tintFinalColor,tintTex * _TintWeatherColor.rgb,outValue);
	}
	
#ifdef TINT_FINISH
	//Tint过程已经结束，只返回按照法线计算的结果颜色	
	#define TINT_TEX_DOT_FINISH_AUTO_UV(worPos,norInW,output) output = Tint_Tex_Dot_Finish_Auto_UV(output,worPos,norInW);
	float3 Tint_Tex_Dot_Finish_Auto_UV(float3 tintFinalColor,float3 worldPosition ,float3 wN) 
	{
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx);
		
		#ifdef VAR_TINT_TEX
			float2 autoUV = GET_UV_WITH_POS_UP_2_DOWN(worldPosition)		
			float3 tintTex = tex2D(_TintTex,autoUV * (1 / _TintTexTiling)).rgb;	
		#else
			float3 tintTex = _TintWeatherColor;
		#endif	
		
		float tintPower = _TintPowerMaxRange;
		float outValue = 1 * pow(1 + tintPower,2);
		outValue += tintPower - 1;

		outValue = saturate(outValue * updot);
		
		return lerp(tintFinalColor,tintTex,outValue);
	}
#endif
	
	#define TINT_CAL_COLOR_MASK_UP_TEST(uv,norInW,output) output = TINT_CAL_COLOR_MASK_UP_Test(output,uv,norInW);
	float3 TINT_CAL_COLOR_MASK_UP_Test(float3 tintFinalColor,float2 uv,float3 wN)
	{
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx);  
		float4 sampTintMask = tex2D(_TintMask,uv.xy);	
		float grayscale = sampTintMask.r;//saturate(sampTintMask.r + _TintWeatherPower);//sampTintMask.r + saturate(_TintWeatherPower - 1);
		//grayscale = grayscale * pow(1 + max(_TintWeatherPower,1),2);
		grayscale = grayscale * pow(1 + _TintWeatherPower,2);
		grayscale += _TintWeatherPower - 1;
		grayscale = updot > 0.05 ? grayscale : 0;
		grayscale = saturate(grayscale);
		float3 maskFinal = grayscale * _TintWeatherColor.rgb;
		
		//float3 tempColor = max(maskFinal , tintFinalColor.rgb);
		//tintFinalColor.rgb = tempColor;
		float grayscaleInputColor = tintFinalColor.r * 0.299 + tintFinalColor.g * 0.587 + tintFinalColor.b * 0.114;
		//float grayscaleTempColor = tempColor.r * 0.299 + tempColor.g * 0.587 + tempColor.b * 0.114;
		//tintFinalColor.rgb = grayscaleInputColor > grayscaleTempColor ? tintFinalColor.rgb : tempColor;
		
		//tintFinalColor.rgb = _TintWeatherPower > 1 ? ExceedOne(tintFinalColor,grayscale) : UnderOne(tintFinalColor,grayscale);		
		
		//float grayscaleInputColor = tintFinalColor.r * 0.299 + tintFinalColor.g * 0.587 + tintFinalColor.b * 0.114;
		tintFinalColor.rgb = grayscaleInputColor > grayscale ? tintFinalColor.rgb : _TintWeatherColor.rgb;//max(_TintWeatherColor.rgb , tintFinalColor.rgb);
		
		//float3 maskFinal = float3(grayscale,grayscale,grayscale) * _TintWeatherColor.rgb;
		//tintFinalColor.rgb = saturate(max(tintFinalColor.rgb , maskFinal * saturate(_TintWeatherPower)));	
		return tintFinalColor.rgb;
	}
	
	#define TINT_CAL_COLOR_MASK_DOT_GRAYSCALE_AUTO_UV(worPos,norInW,output) output = TINT_CAL_COLOR_MASK_Dot_Grayscale_Auto_UV(output,worPos,norInW);
	float3 TINT_CAL_COLOR_MASK_Dot_Grayscale_Auto_UV(float3 tintFinalColor,float3 worldPosition ,float3 wN) 
	{
		
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx);
		float2 autoUV = GET_UV_WITH_POS_NOR(worldPosition,wN)		
		float4 sampTintMask = tex2D(_TintMask,autoUV * (1 / _MaskMapTiling));	
		float grayscale = FixTintMask(sampTintMask.r,updot);	
		float grayscaleInputColor = CalGrayScale(tintFinalColor);		
		return CalFinalColor(tintFinalColor.rgb, grayscaleInputColor,grayscale);
				
		//return CalFinalColor(tintFinalColor.rgb, CalGrayScale(tintFinalColor),FixTintMask(tex2D(_TintMask,autoUV * (1 / _MaskMapTiling)).r,DotWithDir(float3(0,1,0),wN,_TintNormalEx)));
	}
	
	#define TINT_CAL_COLOR_MASK_DOT_GRAYSCALE_AUTO_UV_CENTER_POS(worPos,norInW,output) output = TINT_CAL_COLOR_MASK_Dot_Grayscale_Auto_UV_CENTER_POS(output,worPos,norInW);
	float3 TINT_CAL_COLOR_MASK_Dot_Grayscale_Auto_UV_CENTER_POS(float3 tintFinalColor,float3 worldPosition ,float3 wN) 
	{
		/*
		//int mapArr[12] = {0,2,11,3,1,7,5,9,4,6,8,10}; 
		int mapArr[12] = {0,1,2,3,1,2,3,0,2,3,0,1};
		//int mapArr[12] = {0,1,2,3,2,1,3,0,1,3,2,0};
		
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx); 
		float2 autoUV = GET_UV_WITH_POS_NOR_CENTER_POS(worldPosition,wN)
		autoUV = autoUV * (1 / _MaskMapTiling);
		autoUV -= float2(-1000,-1000);
		float tempX = abs(autoUV.x) / 5.0;
		float tempY = abs(autoUV.y) / 5.0;
		int indexX = fmod(autoUV.x ,5);
		int indexY = fmod(autoUV.y ,5);
		int index = indexX * 5 + indexY;
		int indexFinal = fmod(index,12);
		int finalIntValue = mapArr[indexFinal];
		
		float4 sampTintMask = tex2D(_TintMask,autoUV);	
		
		float finalMaskValue = sampTintMask.r;
		finalMaskValue = finalIntValue == 1 ? sampTintMask.g : finalMaskValue;
		finalMaskValue = finalIntValue == 2 ? sampTintMask.b : finalMaskValue;
		finalMaskValue = finalIntValue == 3 ? sampTintMask.a : finalMaskValue;*/
		
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx); 
		float finalMaskValue = CalMaskValue4ChannelMapwithDot(worldPosition,wN);
		float grayscale = FixTintMask(finalMaskValue,updot);	
		float grayscaleInputColor = CalGrayScale(tintFinalColor);		
		
		return CalFinalColor(tintFinalColor.rgb, grayscaleInputColor,grayscale);
		
		
		
		//return CalFinalColor(tintFinalColor.rgb, CalGrayScale(tintFinalColor),FixTintMask(tex2D(_TintMask,autoUV).r,DotWithDir(float3(0,1,0),wN,_TintNormalEx)));
	}
	
	#define TINT_CAL_COLOR_MASK_DOT_GRAYSCALE_AUTO_UV_CENTER_POS_BLEND(worPos,norInW,output) output = TINT_CAL_COLOR_MASK_Dot_Grayscale_Auto_UV_CENTER_POS_BLEND(output,worPos,norInW);
	float3 TINT_CAL_COLOR_MASK_Dot_Grayscale_Auto_UV_CENTER_POS_BLEND(float3 tintFinalColor,float3 worldPosition ,float3 wN) 
	{			
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx); 
		float finalMaskValue = CalMaskValue4ChannelMapwithDot(worldPosition,wN);		
		float grayscale = FixTintMask(finalMaskValue,updot);	
		float grayscaleInputColor = CalGrayScale(tintFinalColor);	
		
		return CalFinalColorBlend(tintFinalColor.rgb, grayscaleInputColor,grayscale);
	}
	
	#define TINT_CAL_COLOR_MASK_DOT_GRAYSCALE_AUTO_UV_CENTER_POS_BLEND_POWER_RANGE(worPos,norInW,output) output = TINT_CAL_COLOR_MASK_Dot_Grayscale_Auto_UV_CENTER_POS_BLEND_POWER_RANGE(output,worPos,norInW);
	float3 TINT_CAL_COLOR_MASK_Dot_Grayscale_Auto_UV_CENTER_POS_BLEND_POWER_RANGE(float3 tintFinalColor,float3 worldPosition ,float3 wN) 
	{			
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx); 
		float finalMaskValue = CalMaskValue4ChannelMapwithDot(worldPosition,wN);		
		float grayscale = FixTintMaskWithRange(finalMaskValue,updot);	
		float grayscaleInputColor = CalGrayScale(tintFinalColor);	
		
		return CalFinalColorBlend(tintFinalColor.rgb, grayscaleInputColor,grayscale);
	}

#ifdef VAR_TINT_COLOR_FAKENOR
	#define TINT_CAL_COLOR_MASK_DOT_GRAYSCALE_AUTO_UV_CENTER_POS_BLEND_POWER_RANGE_FAKENOR(worPos,norInW,output) output = TINT_CAL_COLOR_MASK_Dot_Grayscale_Auto_UV_CENTER_POS_BLEND_POWER_RANGE_FAKENOR(output,worPos,norInW);
	STRUCT_TINT TINT_CAL_COLOR_MASK_Dot_Grayscale_Auto_UV_CENTER_POS_BLEND_POWER_RANGE_FAKENOR(STRUCT_TINT tintInput,float3 worldPosition ,float3 wN) 
	{			
		float2 uvTiling = GET_UV_WITH_POS_NOR_CENTER_POS(worldPosition,wN);
		float3 norTan = tex2D(_TintColorFakeNorMap,uvTiling * (1 / _TintMaskNorMapTiling)).rgb;
		
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx); 
		float finalMaskValue = CalMaskValue4ChannelMapwithDot(worldPosition,wN);		
		float grayscale = FixTintMaskWithRange(finalMaskValue,updot);	
		float grayscaleInputColor = CalGrayScale(tintInput.tintColor);	
		
		tintInput.tintColor = CalFinalColorBlend(tintInput.tintColor.rgb, grayscaleInputColor,grayscale);
		tintInput.tintNormal = normalize(lerp(wN,float3(norTan.x - 0.5,norTan.z - 0.5,norTan.y - 0.5),grayscale));
		
		return tintInput;
	}
#endif
	
	#define TINT_CAL_COLOR_MASK_DOT_GRAYSCALE(uv,norInW,output) output = TINT_CAL_COLOR_MASK_Dot_Grayscale(output,uv,norInW);
	float3 TINT_CAL_COLOR_MASK_Dot_Grayscale(float3 tintFinalColor,float2 uv,float3 wN) 
	{
		/*
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx);  
		float4 sampTintMask = tex2D(_TintMask,uv.xy);	
		float grayscale = FixTintMask(sampTintMask.r,updot);	
		float grayscaleInputColor = CalGrayScale(tintFinalColor);		
		return CalFinalColor(tintFinalColor.rgb, grayscaleInputColor,grayscale);*/
		
		return CalFinalColor(tintFinalColor.rgb, CalGrayScale(tintFinalColor),FixTintMask(tex2D(_TintMask,uv.xy).r,DotWithDir(float3(0,1,0),wN,_TintNormalEx)));
	}
	
	#define TINT_CAL_COLOR_MASK_GRAYSCALE(uv,norInW,output) output = TINT_CAL_COLOR_MASK_Grayscale(output,uv,norInW);
	float3 TINT_CAL_COLOR_MASK_Grayscale(float3 tintFinalColor,float2 uv,float3 wN)
	{
		/*
		float4 sampTintMask = tex2D(_TintMask,uv.xy);	
		float grayscale = FixTintMask(sampTintMask.r,1.0);	

		float grayscaleInputColor = tintFinalColor.r * 0.299 + tintFinalColor.g * 0.587 + tintFinalColor.b * 0.114;
		float3 tempColor = grayscaleInputColor > grayscale ? tintFinalColor.rgb : _TintWeatherColor.rgb;
		tintFinalColor.rgb = grayscaleInputColor - grayscale < 0.5 ? lerp(tintFinalColor.rgb,tempColor, saturate(grayscale - grayscaleInputColor) * 2) : tempColor;
		*/
		return CalFinalColor(tintFinalColor.rgb, CalGrayScale(tintFinalColor),FixTintMask(tex2D(_TintMask,uv.xy).r,1.0));
	}
	
	#define TINT_CAL_COLOR_MASK_UP_TEST_CURVE(uv,norInW,output) output = TINT_CAL_COLOR_MASK_UP_Curve(output,uv,norInW);
	float3 TINT_CAL_COLOR_MASK_UP_Curve(float3 tintFinalColor,float2 uv,float3 wN)
	{
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx);  
		float4 sampTintMask = tex2D(_TintMask,uv.xy);	
		float grayscale = sampTintMask.r;
		grayscale = grayscale * pow(1 + _TintWeatherPower,2);
		grayscale += _TintWeatherPower - 1;
		grayscale = updot > 0.05 ? grayscale : 0;
		grayscale = saturate(grayscale);
		float3 maskFinal = grayscale * _TintWeatherColor.rgb;

		return max(maskFinal , tintFinalColor.rgb);;
	}
	
	#define TINT_CAL_COLOR_MASK_UP_SameSubstance(uv,norInW,output) output = CalTintColorMask_up_SameSubstance(output,uv,norInW);
	float3 CalTintColorMask_up_SameSubstance(float3 tintFinalColor,float2 uv,float3 wN)
	{
		float updot = DotWithDir(float3(0,1,0),wN,_TintNormalEx);  
		float4 sampTintMask = tex2D(_TintMask,uv.xy);	
		
		float grayscale = sampTintMask.r + saturate(_TintWeatherPower - 1);	
		grayscale = updot > 0.05 ? grayscale : 0;
		
		float3 maskFinal = float3(grayscale,grayscale,grayscale) * _TintWeatherColor.rgb;
		tintFinalColor.rgb = saturate(max(tintFinalColor.rgb , maskFinal * saturate(_TintWeatherPower)));	
		return tintFinalColor.rgb;
	}
	
	#define TINT_SCALE_Y_VALUE(input,output) output = ChangeYValue(input);
	
	float4 ChangeYValue(float4 posInW)
	{
		float4x4 scaleY = float4x4(1,0,0,0,
								0,_TintWeatherPower / 40.0 + 1,0,0,
								0,0,1,0,
								0,0,0,1);
		
		return mul(scaleY,posInW);	
	}
#endif 