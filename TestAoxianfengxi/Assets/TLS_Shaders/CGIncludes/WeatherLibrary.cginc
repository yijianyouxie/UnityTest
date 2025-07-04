#ifndef WEATHER_LIBRARY_INCLUDED
#define WEATHER_LIBRARY_INCLUDED

#define RAIN_RENDER_LEVEL 1

#include "UnityCG.cginc"
#include "UnityStandardUtils.cginc"
#include "Assets/TLS_Shaders/Weather/Include/TintColor.cginc"

float _RainIntensity;
sampler2D _RainRipple;
float _RainFlowRate;
float _RainTiling;
//地面雨水涟漪强度，由于T4M 4 Textures、LightMapSpecular、GI(Diffuse、Cutout、IlluminCutout)光照计算有所差异，导致效果不统一，所以对每一类shader进行单独的参数控制
float _RainRipple_T4M;
float _RainRipple_LightMapSpecular;
float _RainRipple_GI;

float _SnowIntensity;
float _SnowCoverage;
sampler2D _SnowTex;
float2 _SnowTexTiling;
//sampler2D _SnowMask;
fixed4 _SnowColorNew;
fixed4 _SnowColorNew4LightMapSpecular;//LightMapSpecular.shader的光照计算和其他的不一样，导致输出颜色有偏差，所以单独为它配置颜色
fixed4 _SnowColorNew4T4M;//T4M专用雪颜色
fixed4 _WhereHasSnow;
float _SnowNormalEx;//法线偏移值，墙的侧面由于法线方向是水平的，不会有积雪，所以加一个偏移值来做一些调节
fixed4 _SnowColorTree;

float3 NormalizePerPixelNormal (float3 n)
{
    #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        return n;
    #else
        return normalize((float3)n); // takes float to avoid overflow
    #endif
}

float hash(float2 p) 
{
    float h = dot(p, float2(127.1, 311.7));
    return frac(sin(h)*43758.5453123);
}
            
float GetNoise(float2 p) 
{
    float2 i = floor(p);
    float2 f = frac(p);
    float2 u = f*f*(3.0 - 2.0*f);
    float n = lerp(lerp(hash(i),hash(i + float2(1.0, 0.0)), u.x),lerp(hash(i + float2(0.0, 1.0)),hash(i + 1), u.x), u.y);
    //float2 k = 1 - abs(sin(n + p/3));
    return n;
    //return lerp(k.x + k.y, 0,n);
}

float2 Filpbook(float2 uv, float4 config)
{
    // *** BEGIN Flipbook UV Animation vars ***
    // Total tiles of Flipbook Texture
    float totalTiles = config.x * config.y;
    // Offsets for cols and rows of Flipbook Texture
    float colsOffset = 1.0f / config.x;
    float rowsOffset = 1.0f / config.y;
    // Speed of animation
    float speed = _Time.y * 20.0;
    // UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
    // Calculate current tile linear index
    float currentTileIndex = round( fmod( speed, totalTiles) );
    currentTileIndex += ( currentTileIndex < 0) ? totalTiles : 0;
    // Obtain Offset X coordinate from current tile linear index
    float linearIndexToX = round ( fmod ( currentTileIndex, config.x ) );
    // Multiply Offset X by coloffset
    float offsetX = linearIndexToX * colsOffset;
    // Obtain Offset Y coordinate from current tile linear index
    float linearIndexToY = round( fmod( ( currentTileIndex - linearIndexToX ) / config.x, config.y ) );
    // Reverse Y to get tiles from Top to Bottom
    linearIndexToY = (int)(config.y-1) - linearIndexToY;
    // Multiply Offset Y by rowoffset
    float offsetY = linearIndexToY * rowsOffset;
    // UV Offset
    float2 offsetXY = float2(offsetX, offsetY);
    // Flipbook UV
    half2 finalUV = frac( uv ) * float2(colsOffset, rowsOffset) + offsetXY;
    // *** END Flipbook UV Animation vars ***
    return finalUV;
}

float3 RainBubbleNormal(float3 worldPos, float3 worldNormal, float3 worldTangent, float3 worldBinormal, float rainRipple)
{
    // 在target3.0以下，超过一定距离后，会显示异常，因为在UnpackScaleNormal中target3.0以下不支持bumpScale
    // 因为远处看不到法线细节，所以远处的直接用原法线处理
    float dis = length(UnityWorldSpaceViewDir(worldPos));
    float calNormal = step(dis, 30);
    
    half3 tangent = worldTangent;
    half3 binormal = worldBinormal;
    half3 normal = worldNormal;
    
	float up = saturate(dot(normal, float3(0, 1, 0)));
    // 雨水涟漪
	float intensity = _RainIntensity * up + float3(0, 0, 1);
    float4 rippleConfig = float4(3, 3, 0.3, rainRipple);
    float4 RainRippleA = tex2D(_RainRipple, Filpbook(worldPos.xz * rippleConfig.z, rippleConfig));
    RainRippleA.rgb = UnpackScaleNormal(RainRippleA, rippleConfig.w);
    float3 rippleNormal = RainRippleA.rgb;
    #if RAIN_RENDER_LEVEL == 2 //最高级别有2个法线波纹效果
        float4 RainRippleB = tex2D(_RainRipple, Filpbook(worldPos.xz * rippleConfig.z + float2(0.3, 0.6), rippleConfig));
        RainRippleB.rgb = UnpackScaleNormal(RainRippleB, rippleConfig.w);
        rippleNormal = BlendNormals(RainRippleA.rgb, RainRippleB.rgb);
    #endif

    // 雨水流动
    float signU = sign(dot(normal, normalize(float3(-1, 0, 0))));
    float signV = sign(dot(normal, normalize(float3(0, 0, -1))));
    float2 speed = lerp(float2(signU, signV), float2(0.4, 0.4), floor(up + 0.01)) * 30;
    float normalScale = lerp(0.6, 0.3, floor(up + 0.01))*0.3;
    float mip = smoothstep(50, 30, length(worldPos - _WorldSpaceCameraPos));
    float noise2 = GetNoise(worldPos.xz*_RainTiling*float2(10, 20) + (speed*_Time.x*_RainFlowRate));
    float4 RainNormal = float4(noise2, noise2, 1, 1);
    #if RAIN_RENDER_LEVEL == 2 //最高级别会考虑第二个噪声,效果不是很明显
        float noise1 = GetNoise(worldPos.xz*_RainTiling*float2(20, 40) + (speed*_Time.x*_RainFlowRate));
        RainNormal.x = noise1;
    #endif
    float3 RainNormalBlend = UnpackScaleNormal(RainNormal, normalScale*mip);
    // RainNormalBlend = BlendNormals(normalTangent, RainNormalBlend);
    rippleNormal = normalize(lerp(RainNormalBlend, rippleNormal, smoothstep(0.85, 1, up)));
    
    float3 rippleWorldNormal = NormalizePerPixelNormal(tangent * rippleNormal.x + binormal * rippleNormal.y + normal * rippleNormal.z);
    return lerp(normal, rippleWorldNormal, intensity * calNormal);
}

// 雪的覆盖因素有三点：1.法线方向，越朝上，覆盖率越大 2.材质面板上可以手动调节的覆盖率 3.遮罩图的r通道值越大覆盖率越大
float3 BlendSnow(float3 tintFinalColor, float3 worldPosition, float3 worldNormal,float2 uvMaskMap) 
{
	float finalMaskValue = 1;// tex2D(_SnowMask, uvMaskMap).r;
		
    float grayscaleInputColor = CalGrayScale(tintFinalColor);

    float updot = DotWithDir(float3(0,1,0),worldNormal,_SnowNormalEx);
		
    float2 autoUV = float2(worldPosition.x, worldPosition.z) * _SnowTexTiling;
    float3 tintTex = tex2D(_SnowTex, autoUV).rgb;	

    // 过渡时变化一致
    float speed = 1 / clamp(0.001, 1, _SnowCoverage);
    _SnowIntensity = _SnowIntensity * speed;
    _SnowIntensity = clamp(0,1,_SnowIntensity);
    
    float tintPower = _SnowIntensity * _SnowCoverage;

    #if SNOW_COLOR_TYPE == 1
        fixed4 snowColor = _SnowColorNew4LightMapSpecular;
    #elif SNOW_COLOR_TYPE == 2
        fixed4 snowColor = _SnowColorNew4T4M;
    #else
        fixed4 snowColor = _SnowColorNew;
    #endif
    
    float grayscale = updot * tintPower * finalMaskValue;
    float3 tempColor = grayscaleInputColor > grayscale ? tintFinalColor : tintTex * snowColor.rgb;
    tempColor = grayscaleInputColor > grayscale ? BlendColor(tintFinalColor,tempColor,grayscaleInputColor,grayscale) : BlendColor(tintFinalColor,tempColor,grayscale,grayscaleInputColor);
    return tempColor;
}

float3 BlendSnowTree(float3 tintFinalColor, float3 worldNormal)
{
    // float up = dot(worldNormal, float3(0, 1, 0));
    //
    // #ifdef _LEAF_ON
    //     up = up*0.5 + 0.5;
    //     up = smoothstep(0.1, 0.2, up);
    // #else
    //     up = saturate(up);
    //     up = smoothstep(0.2, 0.4, up);//模型法线的哪些部分盖雪
    // #endif
    //
    // float tintPower = _SnowIntensity;
    // up = saturate(up - 1 + tintPower * 2);

    fixed snow = dot(tintFinalColor, _WhereHasSnow.rgb);
    // fixed3 snowcolor = lerp(tintFinalColor, _SnowColorTree.rgb, up);
    fixed3 snowcolor = lerp(tintFinalColor, _SnowColorTree.rgb, _SnowIntensity);//树的底部法线基本是水平的，导致底部和上边的渐变不一致，所以不计算法线了
    float3 tempColor = snow > 0.02 ? snowcolor : tintFinalColor;
    return tempColor;
}


#endif
