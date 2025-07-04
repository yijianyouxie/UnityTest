	sampler2D _TailorTex;
	sampler2D _TailorGradientTex;
	float4 _TailorGradientTex_ST; 
	sampler2D _TailorGradientTex2;
	float4 _TailorGradientTex2_ST;
	sampler2D _TailorGradientTex3;
	float4 _TailorGradientTex3_ST;
	sampler2D _TailorGradientTex4;
	float4 _TailorGradientTex4_ST;

	float4 _TailorMaskChannel1;//第一层裁剪使用的通道
	float _TailorValue1;
	float _TailorGradientDis1;
	float4 _TailorMaskChannel2;//第二层裁剪使用的通道
	float _TailorValue2;
	float _TailorGradientDis2;
	float4 _TailorMaskChannel3;//第三层裁剪使用的通道
	float _TailorValue3;
	float _TailorGradientDis3;
	float4 _TailorMaskChannel4;//第四层裁剪使用的通道
	float _TailorValue4;
	float _TailorGradientDis4;
	float _TailorGradientDis;
	float _TailorRotate;
	float _XCenter;
	float _TalorGap;

    sampler2D _AllSpecialMaskTex;

// glitter
#if _Toggle_EnableGlitter
    float Roughness;
    float IndirLight;
    uniform sampler2D _GlitterSpecularTex; 
    #if _Toggle_EnableGlitterDynamicTex
        uniform sampler2D _GlitterTex;
    #endif

    float3 GlitterSpecularColor;
    float3 GlitterSpecularTilingScale;
    float GlitterSpecularPower;

    float3 GlitterColor;
    float3 GlitteryTilingScale;
    float GlitterPower;
    float GlitterySpeed;
    float GlitterRotateMaskScale;
    float GlitterParallaxRotate;
#endif

// gloss
#if _Toggle_EnableGloss
    float3 GlossColor;
    uniform sampler2D _GlossTex;
    float3 GlossTilingScale;
    float4 GlossSpeedXYTotalStop;
    float GlossStrength;
#endif

// matcap
#if _Toggle_EnableMatCap
    fixed MatCapMaskValue;

    fixed3 MatCapSpecColor1;
    uniform sampler2D _MatCapSpecTex1;
    fixed MatCapSpecValue1;
    fixed MatCapSpecOpposed1;
    fixed4 FresnelCol1;
    fixed FresnelBase1;
    fixed FresnelScale1;
    fixed FresnelIndensity1;

    #if _Toggle_EnableMatCap2
        fixed3 MatCapSpecColor2;
        uniform sampler2D _MatCapSpecTex2;
        fixed MatCapSpecValue2;
        fixed MatCapSpecOpposed2;
        fixed4 FresnelCol2;
        fixed FresnelBase2;
        fixed FresnelScale2;
        fixed FresnelIndensity2;
    #endif
#endif

#if _Toggle_EnableGlitter
float3 GetGlitterCol(float3 _LightColor0, float2 uv0, float3 worldPos, float3 normalDir, float3x3 matrixTBN, float mask){
    // float3x3 matrixTBN = float3x3(tangentDir, bitangentDir, normalDir);
    float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos.xyz);
    float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
    float3 hDir = normalize(viewDir + lightDir);

    // 底下一层specular
    float3 staticGlitter = GlitterSpecularColor * tex2D(_GlitterSpecularTex, uv0 * GlitterSpecularTilingScale.xy * GlitterSpecularTilingScale.z);
    staticGlitter = staticGlitter * GlitterSpecularPower;
    staticGlitter = lerp(0, staticGlitter, mask);

    // 视差偏移 = 切线空间视方向.xy(uv空间下视线方向) * height * 控制系数
    float2 tangentViewDir = mul(matrixTBN, viewDir).xy;
    float2 parallaxUVOffset = tangentViewDir * 0.05 * GlitterySpeed;
    // mask1
    float2 glitterUV1 = (uv0 + parallaxUVOffset) * (GlitterySpeed * 0.5 + 1) * GlitteryTilingScale.z;
    #if _Toggle_EnableGlitterDynamicTex
    float3 glitterCol1 = tex2D(_GlitterTex, glitterUV1 * GlitteryTilingScale.xy);
    #else
    float3 glitterCol1 = tex2D(_GlitterSpecularTex, glitterUV1 * GlitteryTilingScale.xy);
    #endif
    // 旋转一下uv，作为mask2
    float cosValue = cos(GlitterParallaxRotate);
    float sinValue = sin(GlitterParallaxRotate);
    float2 glitterRotateUV = mul(uv0 - parallaxUVOffset, float2x2(cosValue, -sinValue, sinValue, cosValue));
    float2 glitterUV2 = glitterRotateUV * (1 - (GlitterySpeed / GlitterParallaxRotate)) * GlitterRotateMaskScale * GlitteryTilingScale.z;
    #if _Toggle_EnableGlitterDynamicTex
    float3 glitterCol2 = tex2D(_GlitterTex, glitterUV2 * GlitteryTilingScale.xy);
    #else
    float3 glitterCol2 = tex2D(_GlitterSpecularTex, glitterUV2 * GlitteryTilingScale.xy);
    #endif
    // mask1 mask2 做闪烁效果
    float3 shiningGlitter = GlitterPower * GlitterColor * glitterCol1;
    shiningGlitter = lerp(0, shiningGlitter, min(glitterCol2, mask));

    // 底下的specular和闪烁的glitter 构成了整个高光反射
    float3 specular = staticGlitter + shiningGlitter;
    // 自发光 用来改善背光面
    float3 emissive = specular * IndirLight;

    // 光照 blinn phong
    float specPow = exp2(Roughness * 10.0 + 1.0);
    specular = _LightColor0.xyz * specular * pow(max(0, dot(hDir,normalDir)), specPow);

    return specular + emissive;
}
#endif

float3 GetGlitterGlossMatcap(float3 _LightColor0, float3 finalColor, float2 uv, float3 viewDir, float3 worldPos, float3 normalTangent, float3 normalDir, float3x3 matrixTBN, float3 TtoV0, float3 TtoV1, inout float tailorAlpha){
	float ratio = 0.2;
	tailorAlpha = 1.0;
	fixed4 tailorTexCol = tex2D(_TailorTex, uv);
	float texValue = _TailorMaskChannel1.r * tailorTexCol.r + _TailorMaskChannel1.g * tailorTexCol.g + _TailorMaskChannel1.b * tailorTexCol.b + _TailorMaskChannel1.a * tailorTexCol.a;
	if (texValue < _TailorValue1)
	{
		if (texValue < _TailorValue1 - _TailorGradientDis1)
		{
			discard;
		}
		else
		{
			tailorAlpha = 1 - (_TailorValue1 - texValue) / _TailorGradientDis1;
			//tailorAlpha = clamp(tailorAlpha, 0, 0.97);//消除接缝
			fixed4 tailorGradientTexCol = 0;
			if (_TalorGap > 0)
			{
				tailorGradientTexCol = tex2D(_TailorGradientTex, TRANSFORM_TEX(float2(ratio / _TailorGradientDis1 * uv.x, tailorAlpha), _TailorGradientTex));
			}
			else
			{
				tailorGradientTexCol = tex2D(_TailorGradientTex, TRANSFORM_TEX(float2(uv.x + _TailorValue1 / 5, tailorAlpha), _TailorGradientTex));
			}
			tailorAlpha = tailorGradientTexCol.r;
		}
	}

	texValue = _TailorMaskChannel2.r * tailorTexCol.r + _TailorMaskChannel2.g * tailorTexCol.g + _TailorMaskChannel2.b * tailorTexCol.b + _TailorMaskChannel2.a * tailorTexCol.a;
	if (texValue < 1)
	{
		// 角度变弧度
		float glossTexAngle = _TailorRotate * 3.14 / 180;
		//Rotation Matrix
		float tanAngle = tan(glossTexAngle);
		float deltaX = uv.x - _XCenter;
		float deltaY = deltaX * tanAngle;
		texValue = texValue + deltaY;
		if (texValue < _TailorValue2)
		{
			if (texValue < _TailorValue2 - _TailorGradientDis2)
			{
				discard;
			}
			else
			{
				tailorAlpha = 1 - (_TailorValue2 - texValue) / _TailorGradientDis2;
				//tailorAlpha = clamp(tailorAlpha, 0, 0.97);//消除接缝
				fixed4 tailorGradientTexCol = 0;
				if (_TalorGap > 0)
				{
					tailorGradientTexCol = tex2D(_TailorGradientTex2, TRANSFORM_TEX(float2(ratio / _TailorGradientDis2 * uv.x, tailorAlpha), _TailorGradientTex2));
				}
				else
				{
					tailorGradientTexCol = tex2D(_TailorGradientTex2, TRANSFORM_TEX(float2(uv.x + _TailorValue2 / 5, tailorAlpha), _TailorGradientTex2));
				}
				tailorAlpha = tailorGradientTexCol.r;
			}
		}
	}
	texValue = _TailorMaskChannel3.r * tailorTexCol.r + _TailorMaskChannel3.g * tailorTexCol.g + _TailorMaskChannel3.b * tailorTexCol.b + _TailorMaskChannel3.a * tailorTexCol.a;
	if (texValue < _TailorValue3)
	{
		if (texValue < _TailorValue3 - _TailorGradientDis3)
		{
			discard;
		}
		else
		{
			tailorAlpha = 1 - (_TailorValue3 - texValue) / _TailorGradientDis3;
			//tailorAlpha = clamp(tailorAlpha, 0, 0.97);//消除接缝
			fixed4 tailorGradientTexCol = 0;
			if (_TalorGap > 0)
			{
				tailorGradientTexCol = tex2D(_TailorGradientTex3, TRANSFORM_TEX(float2(ratio / _TailorGradientDis3 * uv.x, tailorAlpha), _TailorGradientTex3));
			}
			else
			{
				tailorGradientTexCol = tex2D(_TailorGradientTex3, TRANSFORM_TEX(float2(uv.x + _TailorValue3 / 5, tailorAlpha), _TailorGradientTex3));
			}
			tailorAlpha = tailorGradientTexCol.r;
		}
	}
	texValue = _TailorMaskChannel4.r * tailorTexCol.r + _TailorMaskChannel4.g * tailorTexCol.g + _TailorMaskChannel4.b * tailorTexCol.b + _TailorMaskChannel4.a * tailorTexCol.a;
	if (texValue < _TailorValue4)
	{
		if (texValue < _TailorValue4 - _TailorGradientDis)
		{
			discard;
		}
		else
		{
			tailorAlpha = 1 - (_TailorValue4 - texValue) / _TailorGradientDis;
			//tailorAlpha = clamp(tailorAlpha, 0, 0.97);//消除接缝
			fixed4 tailorGradientTexCol = 0;
			if (_TalorGap > 0)
			{
				tailorGradientTexCol = tex2D(_TailorGradientTex4, TRANSFORM_TEX(float2(ratio / _TailorGradientDis * uv.x, tailorAlpha), _TailorGradientTex4));
			}
			else
			{
				tailorGradientTexCol = tex2D(_TailorGradientTex4, TRANSFORM_TEX(float2(uv.x + _TailorValue4 / 5, tailorAlpha), _TailorGradientTex4));
			}
			tailorAlpha = tailorGradientTexCol.r;
		}
	}

	if (tailorAlpha <= 0.05)
	{
		discard;
	}

	fixed4 allMask = tex2D(_AllSpecialMaskTex, uv);

// glitter
#if _Toggle_EnableGlitter
    fixed3 glitter = GetGlitterCol(_LightColor0, uv, worldPos, normalDir, matrixTBN, allMask.r);
    
    finalColor.rgb += glitter;
#endif

// gloss
#if _Toggle_EnableGloss

    float2 glossUV = uv;
    // 角度变弧度
    float glossAngle = GlossSpeedXYTotalStop.y * 3.14 / 180;
    // 旋转
    glossUV.x = uv.x * sin(glossAngle) - uv.y * cos(glossAngle);
    glossUV.y = uv.x * cos(glossAngle) + uv.y * sin(glossAngle);

	#if _Toggle_GlossRepeat
		glossUV.x = glossUV.x + GlossSpeedXYTotalStop.x * _Time.y;
	#else
		// 每段间隔时间
		float glossAnimLength = 1 + GlossSpeedXYTotalStop.z;
		// 这段前进长度
		float glossCurAnimX = _Time.y % glossAnimLength;
		// 矫正
		glossUV.x = glossUV.x + glossCurAnimX * GlossSpeedXYTotalStop.x - GlossSpeedXYTotalStop.w;
	#endif
    
    fixed3 glossCol = tex2D(_GlossTex, glossUV * GlossTilingScale.xy * GlossTilingScale.z) * GlossColor;
    glossCol *= GlossStrength;

    finalColor.rgb += glossCol * allMask.g;
#endif

// MatCap:
#if _Toggle_EnableMatCap
    half2 vn;
    vn.x = dot(TtoV0, normalTangent);
    vn.y = dot(TtoV1, normalTangent);
    vn = vn * 0.5 + 0.5;

    float VDotN = abs(dot(viewDir, normalDir));

    fixed3 matcapSpec;

    // 区域1
    fixed mask1 = allMask.b;
    fixed3 matcapSpec1 = tex2D(_MatCapSpecTex1, vn) * MatCapSpecValue1;
    matcapSpec1 = MatCapSpecColor1 * matcapSpec1 * mask1;

    float fresnelValue1 = FresnelBase1 + FresnelScale1 * pow(1 - VDotN, FresnelIndensity1);
    float3 fresnel1 = FresnelCol1 * fresnelValue1 * mask1;

    finalColor = finalColor * (1 - mask1) + finalColor * mask1 * MatCapSpecOpposed1;
    matcapSpec = matcapSpec1 + fresnel1;

    // 区域2
#if _Toggle_EnableMatCap2
    fixed mask2 = allMask.a;

    fixed3 matcapSpec2 = tex2D(_MatCapSpecTex2, vn) * MatCapSpecValue2;
    matcapSpec2 = MatCapSpecColor2 * matcapSpec2 * mask2;

    float fresnelValue2 = FresnelBase2 + FresnelScale2 * pow(1 - VDotN, FresnelIndensity2);
    float3 fresnel2 = FresnelCol2 * fresnelValue2 * mask2;

    finalColor = finalColor * (1 - mask2) + finalColor * mask2 * MatCapSpecOpposed2;
    matcapSpec += matcapSpec2 + fresnel2;
#endif

    finalColor.rgb += matcapSpec;
#endif

    return finalColor;
}