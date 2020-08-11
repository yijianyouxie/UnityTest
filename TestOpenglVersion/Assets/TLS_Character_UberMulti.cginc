
    sampler2D _AllSpecialMaskTex;

// glitter
#if _Toggle_EnableGlitter
    float Roughness;
    float IndirLight;
	float4 _GlitterMaskChannel;
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
	float4 _GlossDirection;
    float GlossStrength;
	float4 _GlosslMaskChannel1;
	//#if _Toggle_EnableGloss2
	float _Toggle_EnableGloss2;
	float _Toggle_GlossRepeat2;
	float3 GlossColor2;
	uniform sampler2D _GlossTex2;
	float3 GlossTilingScale2;
	float4 GlossSpeedXYTotalStop2;
	float4 _GlossDirection2;
	float GlossStrength2;
	float4 _GlosslMaskChannel2;
	//#endif
#endif

// matcap
#if _Toggle_EnableMatCap
    fixed3 MatCapSpecColor1;
    uniform sampler2D _MatCapSpecTex1;
    fixed MatCapSpecValue1;
    fixed MatCapSpecOpposed1;
    fixed4 FresnelCol1;
    fixed FresnelBase1;
    fixed FresnelScale1;
    fixed FresnelIndensity1;
	float4 _FresnelMaskChannel1;

    #if _Toggle_EnableMatCap2
        fixed3 MatCapSpecColor2;
        uniform sampler2D _MatCapSpecTex2;
        fixed MatCapSpecValue2;
        fixed MatCapSpecOpposed2;
        fixed4 FresnelCol2;
        fixed FresnelBase2;
        fixed FresnelScale2;
        fixed FresnelIndensity2;
		float4 _FresnelMaskChannel2;
    #endif
	//#if _Toggle_EnableMatCap3
		float _Toggle_EnableMatCap3;
		fixed3 MatCapSpecColor3;
		uniform sampler2D _MatCapSpecTex3;
		fixed MatCapSpecValue3;
		fixed MatCapSpecOpposed3;
		fixed4 FresnelCol3;
		fixed FresnelBase3;
		fixed FresnelScale3;
		fixed FresnelIndensity3;
		float4 _FresnelMaskChannel3;
	//#endif
#endif

//纹理细节
#if _Toggle_Detail1
	fixed3 _DetailColor1;
	uniform sampler2D _DetailTex1;
	half _DetailBlendType1;
	half _DetailIntensity1;
	float4 _DetailScale1;
	float4 _DetailRotate1;
	float4 _DetailMaskChannel1;
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

float3 GetGlitterGlossMatcap(float3 _LightColor0, float3 finalColor, float2 uv, float3 viewDir, float3 worldPos, float3 normalTangent, float3 normalDir, float3x3 matrixTBN, float3 TtoV0, float3 TtoV1){

    fixed4 allMask = tex2D(_AllSpecialMaskTex, uv);

// glitter
#if _Toggle_EnableGlitter
	fixed glitterMask = _GlitterMaskChannel.r * allMask.r + _GlitterMaskChannel.g * allMask.g + _GlitterMaskChannel.b * allMask.b + _GlitterMaskChannel.a * allMask.a;
    fixed3 glitter = GetGlitterCol(_LightColor0, uv, worldPos, normalDir, matrixTBN, glitterMask);
    
    finalColor.rgb += glitter;
#endif

// gloss
#if _Toggle_EnableGloss

	//定义旋转的轴心点Pivot
	float2 pivot = float2(0.5, 0.5);	
	// 角度变弧度
	float glossTexAngle = GlossSpeedXYTotalStop.y * 3.14 / 180;
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

    //float2 glossUV = uv;
    //// 角度变弧度
    //float glossAngle = GlossSpeedXYTotalStop.y * 3.14 / 180;
    //// 旋转
    //glossUV.x = uv.x * sin(glossAngle) - uv.y * cos(glossAngle);
    //glossUV.y = uv.x * cos(glossAngle) + uv.y * sin(glossAngle);
	//顺时针旋转
	float dir = (360 - _GlossDirection.x) * 3.14 / 180;
	float u = cos(dir);
	float v = sin(dir);
	float2 glossUV = float2(0, 0);

	#if _Toggle_GlossRepeat
		//glossUV.x = glossUV.x + GlossSpeedXYTotalStop.x * _Time.y;
		glossUV = targetUV + (GlossSpeedXYTotalStop.x * _Time.y) * float2(u, v) - float2(_GlossDirection.y, _GlossDirection.z);
	#else
		// 每段间隔时间
		float glossAnimLength = 1 + GlossSpeedXYTotalStop.z;
		// 这段前进长度
		float glossCurAnimX = _Time.y % glossAnimLength;
		// 矫正
		//glossUV.x = glossUV.x + glossCurAnimX * GlossSpeedXYTotalStop.x - GlossSpeedXYTotalStop.w;
		glossUV = targetUV + glossCurAnimX * GlossSpeedXYTotalStop.x * float2(u, v) - float2(_GlossDirection.y, _GlossDirection.z);
	#endif
    
    fixed3 glossCol = tex2D(_GlossTex, glossUV * GlossTilingScale.xy * GlossTilingScale.z) * GlossColor;
    glossCol *= GlossStrength;

	fixed glossMask1 = _GlosslMaskChannel1.r * allMask.r + _GlosslMaskChannel1.g * allMask.g + _GlosslMaskChannel1.b * allMask.b + _GlosslMaskChannel1.a * allMask.a;
    finalColor.rgb += glossCol * glossMask1;

	//#if _Toggle_EnableGloss2
	//定义旋转的轴心点Pivot
	float2 pivot2 = float2(0.5, 0.5);
	// 角度变弧度
	float glossTexAngle2 = GlossSpeedXYTotalStop2.y * 3.14 / 180;
	//Rotation Matrix
	float cosAngle2 = cos(glossTexAngle2);
	float sinAngle2 = sin(glossTexAngle2);
	//构造2维旋转矩阵，顺时针旋转
	float2x2 rot2 = float2x2(cosAngle2, -sinAngle2, sinAngle2, cosAngle2);
	//先移到中心旋转
	float2 targetUV2 = uv - pivot2;
	targetUV2 = mul(rot2, targetUV2);
	//再移回来
	targetUV2 += pivot2;

	//float2 glossUV = uv;
	//// 角度变弧度
	//float glossAngle = GlossSpeedXYTotalStop.y * 3.14 / 180;
	//// 旋转
	//glossUV.x = uv.x * sin(glossAngle) - uv.y * cos(glossAngle);
	//glossUV.y = uv.x * cos(glossAngle) + uv.y * sin(glossAngle);
	//顺时针旋转
	float dir2 = (360 - _GlossDirection2.x) * 3.14 / 180;
	float u2 = cos(dir2);
	float v2 = sin(dir2);
	float2 glossUV2 = float2(0, 0);

	//#if _Toggle_GlossRepeat2
	//glossUV.x = glossUV.x + GlossSpeedXYTotalStop.x * _Time.y;
	float2 uvReapeat = targetUV2 + (GlossSpeedXYTotalStop2.x * _Time.y) * float2(u2, v2) - float2(_GlossDirection2.y, _GlossDirection2.z);
	//#else
	// 每段间隔时间
	float glossAnimLength2 = 1 + GlossSpeedXYTotalStop2.z;
	// 这段前进长度
	float glossCurAnimX2 = _Time.y % glossAnimLength2;
	// 矫正
	//glossUV.x = glossUV.x + glossCurAnimX * GlossSpeedXYTotalStop.x - GlossSpeedXYTotalStop.w;
	float2 uvNoRepeat = targetUV2 + glossCurAnimX2 * GlossSpeedXYTotalStop2.x * float2(u2, v2) - float2(_GlossDirection2.y, _GlossDirection2.z);
	//#endif
	glossUV2 = _Toggle_GlossRepeat2 * uvReapeat + (1 - _Toggle_GlossRepeat2)*uvNoRepeat;

	fixed3 glossCol2 = tex2D(_GlossTex2, glossUV2 * GlossTilingScale2.xy * GlossTilingScale2.z) * GlossColor2;
	glossCol2 *= GlossStrength2;

	fixed glossMask2 = _GlosslMaskChannel2.r * allMask.r + _GlosslMaskChannel2.g * allMask.g + _GlosslMaskChannel2.b * allMask.b + _GlosslMaskChannel2.a * allMask.a;
	finalColor.rgb += glossCol2 * glossMask2 * _Toggle_EnableGloss2;
	//#endif
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
    fixed mask1 = _FresnelMaskChannel1.r * allMask.r + _FresnelMaskChannel1.g * allMask.g + _FresnelMaskChannel1.b * allMask.b + _FresnelMaskChannel1.a * allMask.a;
    fixed3 matcapSpec1 = tex2D(_MatCapSpecTex1, vn) * MatCapSpecValue1;
    matcapSpec1 = MatCapSpecColor1 * matcapSpec1 * mask1;

    float fresnelValue1 = FresnelBase1 + FresnelScale1 * pow(1 - VDotN, FresnelIndensity1);
    float3 fresnel1 = FresnelCol1 * fresnelValue1 * mask1;

    finalColor = finalColor * (1 - mask1) + finalColor * mask1 * MatCapSpecOpposed1;
    matcapSpec = matcapSpec1 + fresnel1;

    // 区域2
#if _Toggle_EnableMatCap2
    fixed mask2 = _FresnelMaskChannel2.r * allMask.r + _FresnelMaskChannel2.g * allMask.g + _FresnelMaskChannel2.b * allMask.b + _FresnelMaskChannel2.a * allMask.a;

    fixed3 matcapSpec2 = tex2D(_MatCapSpecTex2, vn) * MatCapSpecValue2;
    matcapSpec2 = MatCapSpecColor2 * matcapSpec2 * mask2;

    float fresnelValue2 = FresnelBase2 + FresnelScale2 * pow(1 - VDotN, FresnelIndensity2);
    float3 fresnel2 = FresnelCol2 * fresnelValue2 * mask2;

    finalColor = finalColor * (1 - mask2) + finalColor * mask2 * MatCapSpecOpposed2;
    matcapSpec += matcapSpec2 + fresnel2;
#endif
	// 区域3
//#if _Toggle_EnableMatCap3
	fixed mask3 = _FresnelMaskChannel3.r * allMask.r + _FresnelMaskChannel3.g * allMask.g + _FresnelMaskChannel3.b * allMask.b + _FresnelMaskChannel3.a * allMask.a;

	fixed3 matcapSpec3 = tex2D(_MatCapSpecTex3, vn) * MatCapSpecValue3;
	matcapSpec3 = MatCapSpecColor3 * matcapSpec3 * mask3;

	float fresnelValue3 = FresnelBase3 + FresnelScale3 * pow(1 - VDotN, FresnelIndensity3);
	float3 fresnel3 = FresnelCol3 * fresnelValue3 * mask3;

	finalColor = finalColor * (1 - mask3) + finalColor * mask3 * MatCapSpecOpposed3;
	matcapSpec += (matcapSpec3 + fresnel3)*_Toggle_EnableMatCap3;
//#endif

    finalColor.rgb += matcapSpec;
#endif

//纹理细节
#if _Toggle_Detail1
	float2 detailPivot = float2(0.5, 0.5);
	float detailTexAngle = _DetailRotate1.x * 3.14 / 180;
	float detailCosAngle = cos(detailTexAngle);
	float detailSinAngle = sin(detailTexAngle);
	float2x2 detailRot = float2x2(detailCosAngle, -detailSinAngle, detailSinAngle, detailCosAngle);
	float2 detailTargetUV = uv - detailPivot;
	detailTargetUV = mul(detailRot, detailTargetUV);
	detailTargetUV += detailPivot;
	detailTargetUV -= float2(_DetailRotate1.y, _DetailRotate1.z);

	fixed4 detailCol1 = tex2D(_DetailTex1, detailTargetUV * _DetailScale1.xy * _DetailScale1.z);
	detailCol1.rgb *= _DetailColor1;
	detailCol1 *= _DetailIntensity1;
	float mask = _DetailMaskChannel1.r * allMask.r + _DetailMaskChannel1.g * allMask.g + _DetailMaskChannel1.b * allMask.b + _DetailMaskChannel1.a * allMask.a;
	detailCol1 *= saturate(mask);

	//区分混合类型
	//可折叠枚举的索引从0开始
	fixed t1_1 = step(_DetailBlendType1, 0);//if(a<=b) 1, else 0
	fixed t1_2 = step(_DetailBlendType1, 1);
	fixed t1_3 = step(_DetailBlendType1, 2);
	fixed3 f1_1 = (detailCol1.rgb * detailCol1.a) + (1 - detailCol1.a)*finalColor.rgb;
	fixed3 f1_2 = (detailCol1.rgb * detailCol1.a * (1 - finalColor.rgb)) + finalColor.rgb;
	fixed3 f1_3 = fixed3(max(finalColor.r, detailCol1.r), max(finalColor.g, detailCol1.g), max(finalColor.b, detailCol1.b));
	finalColor.rgb = t1_1*f1_1 + (1- t1_1)*t1_2*f1_2 + (1 - t1_1)*(1 - t1_2)*t1_3*f1_3;
#endif
    return finalColor;
}