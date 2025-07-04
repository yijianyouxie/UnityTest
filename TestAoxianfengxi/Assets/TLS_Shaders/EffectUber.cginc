sampler2D _MainTex; float4 _MainTex_ST;
float _MainUWrapMode;
float _MainVWrapMode;
float4 _MainTexMaskChannel;
fixed4 _MainCol;
//float _MainColIntensity;
float4 _RepeateUV;
float4 _MainFlowSpeed;
float _UseCustomData;

float _Brightness;
float _Saturation;
float _Contrast;
float _Lightness;
float _BloomSwitch;
fixed4 _BloomColor;
float _BloomStrength;
float _Alpha;
float _Range;
float _Polar;
float _Rotate;

//相加，相乘贴图
fixed4 _GlossCol; float _GlossSpeedx; float _GlossSpeedy;
fixed4 _AdjustCol; float _AdjustSpeedx; float _AdjustSpeedy;
sampler2D _GlossTex; float4 _GlossTex_ST;
sampler2D _AdjustTex; float4 _AdjustTex_ST;

//扰动Disturb
//uniform float4 _TimeEditor;
float _NoisePower;
float _HorizontalSpeed, _VerticalSpeed;
float _Utiling, _Vtiling;
sampler2D _OffsetTexture; float4 _OffsetTexture_ST;
sampler2D _DistabilizationMask; float4 _DistabilizationMask_ST;
fixed _Intensity;
fixed _IntensityVertical;
sampler2D _MaskTex; float4 _MaskTex_ST;//扰动遮罩
float _MaskUWrapMode;
float _MaskVWrapMode;
float4 _MaskUVOffset;
fixed _IntensityMask;
fixed _IntensityMaskVertical;
sampler2D _MaskOffsetTexture; float4 _MaskOffsetTexture_ST;
float _MaskHorizontalSpeed;
float _MaskVerticalSpeed;

//溶解
sampler2D _DissoveTex; float4 _DissoveTex_ST;
float _AlphaCutoff;
float _DissoveWidth;
sampler2D _DissoveOffsetTexture; float4 _DissoveOffsetTexture_ST;
float _DissoveIntensity;
float _DissoveIntensityVertical;
float _DissoveHorizontalSpeed;
float _DissoveVerticalSpeed;
sampler2D _DissoveDirectionTex; float4 _DissoveDirectionTex_ST;
float _DissoveDirEdgeRange;
float _DissoveDirAngle;

//圆形遮罩
float4 _CircleMaskCenter;
float _CircleMaskRadius;
float _CircleFeatherWidth;

//扫描遮罩
float4 _ScanMaskCenter;
float _ScanRotateAngle;//也可作为基准旋转角度
float _ScanRangeAngle;
float _ScanFeatherWidth;

//菲涅尔
float _ApplyFresnel;
float4 _FresnelRimColor;
float _FresnelRimPower;
float4 _FresnelColor;

////羽化
//float _EdgeFeatherRange;

//贴图中心缩放
float _TexScale;
float _ApplyPolar;

sampler2D _FinalControlTex; float4 _FinalControlTex_ST;
sampler2D _FinalGradientTex; float4 _FinalGradientTex_ST;
float _FinalGradientUWrapMode;
float _FinalGradientVWrapMode;

//总遮罩
sampler2D _FinalMaskTex; float4 _FinalMaskTex_ST;

//明度
fixed3 Lightness(fixed3 color, float lightness) {

	float _R = color.r;
	float _G = color.g;
	float _B = color.b;

	_R = _R + (lightness - 0.5)*2.;
	_G = _G + (lightness - 0.5)*2.;
	_B = _B + (lightness - 0.5)*2.;

	_R = max(_R, 0.);
	_R = min(_R, 1.);

	_G = max(_G, 0.);
	_G = min(_G, 1.);

	_B = max(_B, 0.);
	_B = min(_B, 1.);
	return fixed3(_R, _G, _B);
}
//直角坐标系转极坐标
float2 Polar(float2 UV)
{
	//0-1的1象限转-0.5-0.5的四象限
	float2 uv = UV - 0.5;
	//d为各个象限坐标到0点距离，数值为0-0.5
	float distance = length(uv);
	//从0-0.5放大到0-1
	distance *= 2;
	distance *= _ApplyPolar * _TexScale + (1 - _ApplyPolar);
	//4象限坐标求弧度范围是[-pi,+pi]
	float angle = atan2(uv.x, uv.y);
	//把[-pi,+pi]转换为0-1
	float angle2 = angle / 3.14159 / 2 + 0.5;
	//输出角度与距离
	return float2(angle2, distance);
}

//返回旋转，极坐标，uv缩放和重复后的uv
void ProcessUV(inout float2 sourceUV, float rotate)
{
	//定义旋转的轴心点Pivot
	float2 pivot = float2(0.5, 0.5);
	// 角度变弧度
	float glossTexAngle = rotate * 3.14 / 180;
	//Rotation Matrix
	float cosAngle = cos(glossTexAngle);
	float sinAngle = sin(glossTexAngle);
	//构造2维旋转矩阵，顺时针旋转
	float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
	//先移到中心旋转
	float2 targetUV = sourceUV - pivot;
	targetUV = mul(rot, targetUV);
	//再移回来
	targetUV += pivot;
	//极坐标
	sourceUV = Polar(targetUV) * _Polar + (1 - _Polar)*targetUV;
	//主贴图缩放和重复
	sourceUV = sourceUV/* * _RepeateUV.xy + _RepeateUV.zw*_Time.y*/;
}

//fixed3 ProcessColor(fixed3 col)
//{
//	//brigtness亮度直接乘以一个系数，也就是RGB整体缩放，调整亮度
//	fixed3 finalColor = col.rgb * _Brightness;
//
//	//saturation饱和度：首先根据公式计算同等亮度情况下饱和度最低的值：
//	fixed gray = 0.2125 * col.r + 0.7154 * col.g + 0.0721 * col.b;
//	fixed3 grayColor = fixed3(gray, gray, gray);
//	//根据Saturation在饱和度最低的图像和原图之间差值
//	finalColor = lerp(grayColor, finalColor, _Saturation);
//
//	//contrast对比度
//	fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
//	finalColor = lerp(avgColor, finalColor, _Contrast);
//
//	//明度
//	finalColor = Lightness(finalColor, _Lightness);
//
//	//Bloom
//	float3 bloom = finalColor * _BloomColor;
//	float3 finalBloom = pow(bloom.rgb, _BloomStrength);
//	finalBloom *= bloom;
//	finalBloom += bloom;
//	finalColor = finalBloom * _BloomSwitch + (1 - _BloomSwitch)*finalColor;
//
//	return finalColor;
//}
fixed4 ProcessColor2(fixed4 col, fixed4 mainCol)
{
	float4 fanwei = _Range.xxxx;
	col = col * _Brightness - fanwei;
	float4 temp = col;
	float mainAlpha = _MainTexMaskChannel.x * col.r + _MainTexMaskChannel.y*col.g + _MainTexMaskChannel.z*col.b + _MainTexMaskChannel.w* col.a;
	col.rgb = _Lightness * temp.rgb;
	col.a = mainAlpha * _Alpha;

	col *= mainCol;

	//saturation饱和度：首先根据公式计算同等亮度情况下饱和度最低的值：
	fixed gray = 0.2125 * col.r + 0.7154 * col.g + 0.0721 * col.b;
	fixed3 grayColor = fixed3(gray, gray, gray);
	//根据Saturation在饱和度最低的图像和原图之间差值
	col.rgb = lerp(grayColor, col.rgb, _Saturation);

	//contrast对比度
	fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
	col.rgb = lerp(avgColor, col.rgb, _Contrast);

	//Bloom
	float3 bloom = col.rgb * _BloomColor;
	float3 finalBloom = pow(bloom.rgb, _BloomStrength);
	finalBloom *= bloom;
	finalBloom += bloom;
	col.rgb = finalBloom * _BloomSwitch + (1 - _BloomSwitch)*col.rgb;

	col = saturate(col);
	return col;
}

fixed4 ProcessUVColor(sampler2D sourceTexture, float2 sourceUV, float4 uv1, float2 uv2, float4 customUV2, float4 posWorld, float3 normalDir, fixed4 color)
{
	/*sourceUV = sourceUV.xy * _RepeateUV.xy + _RepeateUV.zw*_Time.y;
	float2 tempUV1 = sourceUV.xy * uv1.xy + uv1.zw*_Time.y;*/
	float2 mainUV = sourceUV;// _UseCustomData * tempUV1 + (1 - _UseCustomData) * sourceUV;
	ProcessUV(mainUV, _Rotate);//返回旋转，极坐标;uv缩放和重复后的uv放到下边处理

	//贴图中心缩放
	mainUV = (1 - _ApplyPolar) * ((mainUV - 0.5) / _TexScale + 0.5) + _ApplyPolar * mainUV;

	float2 tempUV1 = mainUV.xy * uv1.xy + uv1.zw;
	float2 tempSourceUV = mainUV.xy * _RepeateUV.xy + _RepeateUV.zw;
	float2 mainUVTime = _UseCustomData * tempUV1 + (1 - _UseCustomData) * tempSourceUV + float2(_MainFlowSpeed.xy) * _Time.y;
	
	//扰动模块
	//扰动的遮罩图
	fixed3 _DestMask_var = tex2D(_DistabilizationMask, TRANSFORM_TEX(mainUV, _DistabilizationMask));
	float destMaskRatio = _DestMask_var.r;

	float _noisepower_var = _NoisePower;
	float _uspeed_var = _HorizontalSpeed;
	float4 node_7158 = _Time;
	float _vspeed_var = _VerticalSpeed;
	float _utiling_var = _Utiling;
	float _Vtiling_var = _Vtiling;
	float2 node_2783 = (float2((_uspeed_var*node_7158.g), (node_7158.g*_vspeed_var)) + mainUV + (mainUV*(float2(_utiling_var, _Vtiling_var) - 1.0)));
	float4 _noise_var = tex2D(_OffsetTexture, TRANSFORM_TEX(node_2783, _OffsetTexture));
	float2 node_3927 = float2(((_noisepower_var*_noise_var.r*destMaskRatio) + mainUVTime.r), mainUVTime.g);
	//float4 _man_var = tex2D(_man, TRANSFORM_TEX(node_3927, _man));
	float2 finalSourceUV = node_3927;
	float colorRatio = 1.0;
	if (_MainUWrapMode > 0)
	{
		finalSourceUV.x = clamp(finalSourceUV.x, 0, 1);
		/*if (finalSourceUV.x <= 0.00001 || finalSourceUV.x >= 0.99999)
		{
			colorRatio = 0.0;
		}*/
	}
	if (_MainVWrapMode > 0)
	{
		finalSourceUV.y = clamp(finalSourceUV.y, 0, 1);
		/*if (finalSourceUV.y <= 0.00001 || finalSourceUV.y >= 0.99999)
		{
			colorRatio = 0.0;
		}*/
	}
	fixed4 col = tex2D(sourceTexture, finalSourceUV)/* * colorRatio*/;

	float2 speed = float2(_HorizontalSpeed, _VerticalSpeed);	
	float2 offsetTextureUV = (mainUV + _Time.y * speed);
	fixed3 _OffsetTexture_var = tex2D(_OffsetTexture, TRANSFORM_TEX(offsetTextureUV, _OffsetTexture)).rgb;//扭曲贴图
	float offsetTexGray = dot(_OffsetTexture_var, float3(0.299, 0.587, 0.114));
	//float2 mainTextureUV = lerp(mainUVTime, offsetTexGray.xx, float2(_Intensity, _IntensityVertical)*destMaskRatio);
	//float2 mainTextureUV = mainUVTime + offsetTexGray.xx *float2(_Intensity, _IntensityVertical)*destMaskRatio;
	//fixed4 col = tex2D(sourceTexture, mainTextureUV/* * _RepeateUV.xy + _RepeateUV.zw*/)/**_MainCol*/;
	col = ProcessColor2(col, _MainCol);
	float mainAlpha = col.a;
	//偏移遮罩
	speed = float2(_MaskHorizontalSpeed, _MaskVerticalSpeed);
	offsetTextureUV = (mainUV + _Time.y * speed);
	fixed3 _MaskOffsetTexture_var = tex2D(_MaskOffsetTexture, TRANSFORM_TEX(offsetTextureUV, _MaskOffsetTexture)).rgb;//mask扰动贴图
	float maskTexGray = dot(_MaskOffsetTexture_var, float3(0.299, 0.587, 0.114));

	float2 maskOffset = _UseCustomData * float2(customUV2.z, customUV2.z) + (1 - _UseCustomData) *  float2(_MaskUVOffset.xy);
	float2 noiseRepeat = _UseCustomData *customUV2.xy + (1 - _UseCustomData);
	float2 masktTextureUV = (mainUV * noiseRepeat + maskOffset);
	float2 finalTextureUV = lerp(masktTextureUV, maskTexGray.xx, float2(_IntensityMask, _IntensityMaskVertical)/**destMaskRatio*/);
	float2 maskUV = TRANSFORM_TEX(finalTextureUV, _MaskTex);
	colorRatio = 1.0;
	if (_MaskUWrapMode > 0)
	{
		maskUV.x = clamp(maskUV.x, 0, 1);
		if (maskUV.x <= 0.00001 || maskUV.x >= 0.99999)
		{
			colorRatio = 0.0;
		}
	}
	if (_MaskVWrapMode > 0)
	{
		maskUV.y = clamp(maskUV.y, 0, 1);
		if (maskUV.y <= 0.00001 || maskUV.y >= 0.99999)
		{
			colorRatio = 0.0;
		}
	}
	float4 _MaskTex_var = tex2D(_MaskTex, maskUV) * colorRatio;//扰动遮罩MaskTex

	fixed finalAlpha = mainAlpha * _MaskTex_var.r * _MaskTex_var.a;

	fixed3 finalColor = col.rgb;

	//_GlossTex
	//float2 glossTextureUV = lerp(mainUV, offsetTexGray.xx, float2(_Intensity, _IntensityVertical)*destMaskRatio);
	//float2 glossTextureUV = lerp(mainUV, offsetTexGray.xx, float2(_NoisePower, _NoisePower)*destMaskRatio);
	float4 _GlossTex_var = tex2D(_GlossTex, TRANSFORM_TEX(node_3927, _GlossTex) + _Time.y * float2(_GlossSpeedx, _GlossSpeedy));
	float3 glossFinalCol = _GlossTex_var.rgb * _GlossCol.rgb * _GlossCol.a;
	//glossFinalCol = ProcessColor(glossFinalCol);
	finalColor *= glossFinalCol;
	finalAlpha *= _GlossTex_var.r /** _GlossTex_var.a*/;

	//_AdjustTex
	//float2 adjustTextureUV = lerp(mainUV, offsetTexGray.xx, float2(_Intensity, _IntensityVertical)*destMaskRatio);
	//float2 adjustTextureUV = lerp(mainUV, offsetTexGray.xx, float2(_NoisePower, _NoisePower)*destMaskRatio);
	float4 _AdjustTex_var = tex2D(_AdjustTex, TRANSFORM_TEX(node_3927, _AdjustTex) + _Time.y * float2(_AdjustSpeedx, _AdjustSpeedy));
	float3 finalAdjustCol = _AdjustTex_var.rgb*_AdjustTex_var.a * _AdjustCol.rgb * _AdjustCol.a;
	//finalAdjustCol = ProcessColor(finalAdjustCol);
	finalColor += finalAdjustCol;

	//_DissoveTex
	_AlphaCutoff = _UseCustomData * customUV2.w + (1 - _UseCustomData) * _AlphaCutoff;
	_AlphaCutoff = clamp(_AlphaCutoff, 0.00001, 1);
	float2 dissoveSpeed = float2(_DissoveHorizontalSpeed, _DissoveVerticalSpeed);
	float2 dissoveOffsetTextureUV = (mainUV + _Time.y * dissoveSpeed);
	fixed3 _DissoveOffsetTexture_var = tex2D(_DissoveOffsetTexture, TRANSFORM_TEX(dissoveOffsetTextureUV, _DissoveOffsetTexture)).rgb;//扭曲贴图
	float dissoveOffsetTexGray = dot(_DissoveOffsetTexture_var, float3(0.299, 0.587, 0.114));
	float2 dissoveTextureUV = lerp(mainUV, dissoveOffsetTexGray.xx, float2(_DissoveIntensity, _DissoveIntensityVertical));
	float4 _DissoveTex_var = tex2D(_DissoveTex, TRANSFORM_TEX(dissoveTextureUV, _DissoveTex));
	//溶解使用r通道
	finalAlpha = finalAlpha * saturate((saturate(_DissoveTex_var.r + 0.0001) - _AlphaCutoff)/(_DissoveWidth*_AlphaCutoff));

	//定向溶解
	float2 dissoveDirUV = sourceUV;
	ProcessUV(dissoveDirUV, _DissoveDirAngle);//返回旋转，极坐标;uv缩放和重复后的uv放到下边处理
	//定向贴图中心缩放
	dissoveDirUV = (1 - _ApplyPolar) * ((dissoveDirUV - 0.5) / _TexScale + 0.5) + _ApplyPolar * dissoveDirUV;
	//return fixed4(dissoveDirUV,0,1);
	float2 dissoveDirTextureUV = dissoveDirUV;
	float4 _DissoveDirTex_var = tex2D(_DissoveDirectionTex, TRANSFORM_TEX(dissoveDirTextureUV, _DissoveDirectionTex));
	//定向溶解使用r通道
	finalAlpha = finalAlpha * saturate((saturate(_DissoveDirTex_var.r + 0.0001) - _AlphaCutoff) / (_DissoveDirEdgeRange*_AlphaCutoff));

	//圆形遮罩
	float2 center = float2(_CircleMaskCenter.x, _CircleMaskCenter.y);
	//使用原始sourceUV
	float2 tempUV = sourceUV - center;
	float dis = length(tempUV);
	float radio = saturate((dis - _CircleMaskRadius) / (_CircleFeatherWidth*_CircleMaskRadius));
	finalAlpha = finalAlpha * radio;

	//扫描遮罩，简化if判断
	center = float2(_ScanMaskCenter.x, _ScanMaskCenter.y);
	float2 baseDir = normalize( float2(-1, _ScanMaskCenter.y) - center);
	tempUV = sourceUV - center;
	float at2 = atan2(tempUV.y, tempUV.x)+ 3.14;//0-2pi
	float endValue = _ScanRotateAngle - _ScanRangeAngle;
	_ScanFeatherWidth = pow(_ScanFeatherWidth, 4);
	if (endValue <= 0)
	{
		if ((at2 >= _ScanRotateAngle && at2 <= endValue + 6.28))
		{
			finalAlpha = finalAlpha * 0;
		}
		else
		{
			if (at2 < _ScanRotateAngle)
			{
				radio = 1 - saturate(abs(at2 - ((endValue + 6.28 + _ScanRotateAngle) / 2 - 3.14)) * (_ScanFeatherWidth));
				finalAlpha = finalAlpha * radio;
			}
			else
			{
				radio = 1 - saturate(abs(-6.28 + at2 - ((endValue + 6.28 + _ScanRotateAngle) / 2 - 3.14)) * (_ScanFeatherWidth));
				finalAlpha = finalAlpha * radio;
			}
		}
	}
	else
	{
		if (at2 >= _ScanRotateAngle || at2 <= _ScanRotateAngle - _ScanRangeAngle)
		{
			finalAlpha = finalAlpha * 0;
		}
		else
		{
			radio = 1 - saturate(abs(at2 - (endValue + _ScanRotateAngle)/2) * (_ScanFeatherWidth));
			finalAlpha = finalAlpha * radio;
		}
	}

	//菲涅尔
	if (_ApplyFresnel > 0)
	{
		float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - posWorld.xyz);
		float3 normalDirection = normalize(normalDir);
		fixed rim = pow((1.0 - max(0, dot(normalDirection, viewDirection))), _FresnelRimPower) * 2;
		finalColor = finalColor * _FresnelColor + rim *_FresnelRimColor.rgb;
		finalAlpha = finalAlpha * max(_FresnelColor.a, rim*_FresnelRimColor.a);
	}

	////羽化
	//float dx = sourceUV.x - 0.5;
	//float dy = sourceUV.y - 0.5;
	//float dstSq = pow(dx, 2.0) + pow(dy, 2.0);
	//float v = (dstSq / _EdgeFeatherRange);
	//finalAlpha = finalAlpha * saturate(1-v);
	//return fixed4(finalColor, finalAlpha);

	fixed4 fcCol = tex2D(_FinalControlTex, TRANSFORM_TEX(sourceUV, _FinalControlTex));
	finalColor.rgb *= fcCol.rgb;
	finalAlpha *= fcCol.r * fcCol.a;

	float2 finalGradientUV = TRANSFORM_TEX(sourceUV, _FinalGradientTex);
	colorRatio = 1.0;
	if (_FinalGradientUWrapMode > 0)
	{
		finalGradientUV.x = clamp(finalGradientUV.x, 0, 1);
		if (finalGradientUV.x <= 0.00001 || finalGradientUV.x >= 0.99999)
		{
			colorRatio = 0.0;
		}
	}
	if (_FinalGradientVWrapMode > 0)
	{
		finalGradientUV.y = clamp(finalGradientUV.y, 0, 1);
		if (finalGradientUV.y <= 0.00001 || finalGradientUV.y >= 0.99999)
		{
			colorRatio = 0.0;
		}
	}
	fixed4 gradientCol = tex2D(_FinalGradientTex, finalGradientUV) * colorRatio;
	finalColor.rgb *= gradientCol.rgb;
	finalAlpha *= gradientCol.r * gradientCol.a;

	//总遮罩
	float4 _FinalMaskTex_var = tex2D(_FinalMaskTex, TRANSFORM_TEX(sourceUV, _FinalMaskTex));
	finalAlpha = (finalAlpha * _FinalMaskTex_var.r * _FinalMaskTex_var.a);

	return fixed4(finalColor, finalAlpha) * color;
}