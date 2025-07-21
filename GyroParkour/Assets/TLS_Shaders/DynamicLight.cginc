//Virtual Dynamic Light
int DynamicPointLightNum = 0;
float4 DynamicPointPos[10];//xyz位置
fixed4 DynamicPointColor[10];//rgb颜色
float4 DynamicPointDir[10];//朝向
float4 DynamicPointRight[10];//spot灯的右朝向
float4 DynamicCharaterUV[10];//单个字的uv信息
sampler2D DynamicLightTexture_1;
//sampler2D DynamicLightTexture_2;
//sampler2D DynamicLightTexture_3;
sampler2D DynamicFontTexture;

fixed3 GetDynamicPointLightColor(fixed3 sColor, float3 worldPos, float3 worldNormal)
{
	fixed4 color = 0;
	for (int i = 0; i < 10; i++)
	{
		if(i < DynamicPointLightNum)
		{
			float3 dir = DynamicPointPos[i].xyz - worldPos;
			//spot
			float angle = dot(normalize(DynamicPointDir[i].xyz), normalize(dir));
			if (angle >= DynamicPointDir[i].w)
			{
				float distance2 = dot(dir, dir);//距离的平方
				if (distance2 < DynamicPointPos[i].w)
				{
					float nl = 0;
					float3 lineStart = DynamicPointPos[i].xyz;
					float3 lineDirection = normalize(DynamicPointDir[i].xyz);
					// 计算向量v，w和投影长度dParallel
					float3 v = worldPos - lineStart;
					float dParallel = dot(v, lineDirection) /*/ dot(lineDirection, lineDirection)*/;
					//w是当前像素点到spot发射方向上的投影点到像素点的向量
					float3 w = v - dParallel * lineDirection;
					//w = normalize(w);
					//图集列数
					float atlasColumn = floor(DynamicPointRight[i].w / 1000);
					float atlasColumn2 = atlasColumn * atlasColumn;
					//动画类型
					float aniType = floor((DynamicPointRight[i].w - atlasColumn * 1000) / 100);
					float textureIndex = floor((DynamicPointRight[i].w - atlasColumn * 1000 - aniType * 100) / 10);
					fixed4 maskCol = fixed4(1, 1, 1, 0);
					float atten = lerp(0, 1, saturate((angle - DynamicPointDir[i].w) / (1 - DynamicPointDir[i].w)));
					if (textureIndex > 0)
					{
						//计算当前位置的圆半径
						float radius = sqrt(pow(dParallel / DynamicPointDir[i].w, 2) - pow(dParallel, 2));
						//cos的值是x坐标的值
						float x = dot(w, DynamicPointRight[i].xyz);
						//计算y坐标
						float3 lightUp = cross(DynamicPointRight[i].xyz, DynamicPointDir[i].xyz);
						float y = dot(w, lightUp);
						float u = x / (2 * radius) + 0.5;
						float v = y / (2 * radius) + 0.5;
						float uv_u = u;
						float uv_v = v;

						//float uv_u = currRadius / radius;
						//float uv_v = sqrt(dot(w, w) - currRadius*currRadius) / radius;
						//float3 crossAB = cross(w, DynamicPointRight[i].xyz);
						//if (uv_u > 0)
						//{
						//	if (crossAB.y > 0)
						//	{
						//		//第一象限
						//		uv_u = 0.5 + uv_u * 0.5;
						//		uv_v = 0.5 + uv_v * 0.5;
						//	}
						//	else
						//	{
						//		//第四象限
						//		uv_u = 0.5 + uv_u * 0.5;
						//		uv_v = (1 - uv_v) * 0.5;
						//	}
						//}
						//else
						//{
						//	if (crossAB.y > 0)
						//	{
						//		//第二象限
						//		uv_u = (1 + uv_u) * 0.5;
						//		uv_v = (1 + uv_v) * 0.5;
						//	}
						//	else
						//	{
						//		//第三象限
						//		uv_u = (1 + uv_u) * 0.5;
						//		uv_v = 0.5 - uv_v * 0.5;
						//	}
						//}

						float2 maskUV = float2(uv_u, uv_v);
						//maskUV = maskUV - float2(0.5, 0.5);
						float maskUVScale = DynamicPointRight[i].w % 10;
						//float textureIndex = (DynamicPointRight[i].w - maskUVScale) / 10;//这种写法存在精度问题
						/*maskUV *= maskUVScale;
						maskUV += float2(0.5, 0.5);*/
						//至此maskUV得到的是0-1的uv信息
						float4 uv = DynamicCharaterUV[i];
						float uScale = 1.0;
						float vScale = 1.0;
						float uWidth = floor(uv.z);// abs(uv.x % 10 - uv.z);
						float vWidth = floor(uv.w);//abs(uv.y - uv.w);

						float alphaRatio = 0;
						if (aniType != 7)
						{
							if (uWidth >= vWidth)
							{
								uScale = 1.0;
								vScale = uWidth / vWidth;
							}
							else
							{
								uScale = vWidth / uWidth;
								vScale = 1.0;
							}

							maskUV = maskUV - float2(0.5, 0.5);
							maskUV *= float2(uScale, vScale);
							maskUV *= maskUVScale;
							maskUV += float2(0.5, 0.5);
							if (aniType == 1)
							{
								//disturb
								maskUV.y = maskUV.y + sin(_Time.y * 5 + maskUV.x * 5)*0.1;
								maskUV += float2(_Time.y / 2, 0);
							}
							else if (aniType == 2)
							{
								//UVFLOW_1
								maskUV += float2(_Time.y / 10, 0);
							}
							else if (aniType == 3)
							{
								//UVFLOW_2
								maskUV += float2(_Time.y / 5, 0);
							}
							else if (aniType == 4)
							{
								//alpha center
								float value = length(maskUV - float2(0.5, 0.5)) * 2 - (_Time.y % 5) / 5;
								alphaRatio = saturate(saturate(sign(value)) * value / 0.3);
							}
							else if (aniType == 5)
							{
								//top alpha
								float value = maskUV.y - (_Time.y % 5) / 5;
								alphaRatio = saturate(saturate(sign(value)) * value / 0.3);
							}
							else if (aniType == 6)
							{
								//读图集
								float atlasIndex = floor(_Time.y * 10 % atlasColumn2);
								float lineIndex = atlasColumn - floor(atlasIndex / atlasColumn) - 1;
								float columnIndex = atlasIndex % atlasColumn;
								maskUV.x = maskUV.x / atlasColumn + columnIndex * 1 / atlasColumn;
								maskUV.y = maskUV.y / atlasColumn + lineIndex * 1 / atlasColumn;
							}
							maskUV = clamp(maskUV, 0, 1);
							maskCol = tex2D(DynamicLightTexture_1, maskUV);
						}
						else
						{
							//读取动态字体
							maskUV.y = 1 - maskUV.y;//这一步转换后，字的旋转信息与贴图中的一致
												//接下来，判断旋转方向，目前看只有朝右和倒置
							//float4 uv = DynamicCharaterUV[i];
							float topDir = floor(uv.x / 10);
							if (topDir == 2)
							{
								//垂直镜像
								maskUV.y = 1 - maskUV.y;
							}
							else if (topDir == 1)
							{
								//朝右
								//定义旋转的轴心点Pivot
								float2 pivot = float2(0.5, 0.5);
								// 角度变弧度
								float glossTexAngle = 90 * 3.14 / 180;
								//Rotation Matrix
								float cosAngle = cos(glossTexAngle);
								float sinAngle = sin(glossTexAngle);
								//构造2维旋转矩阵，顺时针旋转
								float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
								//先移到中心旋转
								float2 targetUV = maskUV - pivot;
								targetUV = mul(rot, targetUV);
								//再移回来
								targetUV += pivot;
								maskUV = targetUV;
							}

							//maskUV = saturate(maskUV);
							//加入判断，是否需要缩放水平或垂直uv值，因为有些字是扁的，不能等比缩放到正方形里
							//float uScale = 1.0;
							//float vScale = 1.0;
							//float uWidth = floor(uv.z);// abs(uv.x % 10 - uv.z);
							//float vWidth = floor(uv.w);//abs(uv.y - uv.w);
							if (uWidth >= vWidth)
							{
								uScale = uWidth / vWidth;
								vScale = 1.0;
							}
							else
							{
								uScale = 1.0;
								vScale = uWidth / vWidth;

								if (topDir == 2)
								{
									uScale = vWidth / uWidth;
									vScale = 1.0;
								}
							}
							maskUV = maskUV - float2(0.5, 0.5);
							maskUV *= float2(uScale, vScale);
							maskUV *= maskUVScale;
							maskUV += float2(0.5, 0.5);
							maskUV = saturate(maskUV);
							//大于1的值代表在这个方向上缩小；小于1的值代表在这个方向上放大
							maskCol = tex2D(DynamicFontTexture, float2(lerp(uv.x % 10, uv.z%1.0, maskUV.x),
								lerp(uv.y, uv.w%1.0, maskUV.y)));

							maskCol.rgb = fixed3(1, 1, 1)*maskCol.a;
							/*color.rgb = fixed3(float2(lerp(uv.x % 10, uv.z, maskUV.x),
								lerp(uv.y, uv.w, maskUV.y)).x,0,0);*/
						}
						/*else if (textureIndex == 2)
						{
							maskCol = tex2D(DynamicLightTexture_2, maskUV);
						}*/
						/*else if (textureIndex == 3)
						{
							maskCol = tex2D(DynamicLightTexture_3, maskUV);
						}*/

						maskCol.a *= (1 - alphaRatio);

						nl = /*saturate*/(dot(normalize(dir), worldNormal));
						color.rgb = maskCol.rgb*maskCol.a*DynamicPointColor[i].rgb + (color.rgb /*+ DynamicPointColor[i].rgb * nl * atten*/) * (1 - maskCol.a);
						color.a += maskCol.a * atten * 0.8;
					}
					else
					{
						nl = /*saturate*/(dot(normalize(dir), worldNormal));
						color.rgb += DynamicPointColor[i].rgb * nl * atten;
					}
				}
			}
		}		
	}
	
	color = clamp(color, 0,1);
	sColor = (sColor.rgb + color.rgb)*(1 - color.a) + color.rgb * color.a;
	return sColor;
}
