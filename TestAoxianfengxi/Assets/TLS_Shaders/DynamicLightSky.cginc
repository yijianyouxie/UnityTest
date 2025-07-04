//Virtual Dynamic Light
int DynamicPointLightNum = 0;
float4 DynamicPointPos[10];//xyz位置
fixed4 DynamicPointColor[10];//rgb颜色
float4 DynamicPointDir[10];//朝向
float4 DynamicPointRight[10];//spot灯的右朝向
//fixed4 DynamicPointInflunceScope[10];//影响的对象类型x：地面 y:人物 z:地上物体
float4 DynamicCharaterUV[10];//单个字的uv信息
sampler2D DynamicLightTexture_1;
sampler2D DynamicFontTexture;

fixed4 GetDynamicPointLightColor(float3 worldPos, float3 worldNormal, inout float _atten)
{
	fixed4 color = 0;
	for (int i = 0; i < 10; i++)
	{
		if (i < DynamicPointLightNum)
		{
			float3 dir = DynamicPointPos[i].xyz - worldPos;
			//spot
			float angle = dot(normalize(DynamicPointDir[i].xyz), normalize(dir));
			if (angle >= DynamicPointDir[i].w)
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
					float currRadius = dot(w, DynamicPointRight[i].xyz);
					float uv_u = currRadius / radius;
					float uv_v = sqrt(dot(w, w) - currRadius*currRadius) / radius;
					float3 crossAB = cross(w, DynamicPointRight[i].xyz);
					if (uv_u > 0)
					{
						if (crossAB.y > 0)
						{
							//第一象限
							uv_u = 0.5 + uv_u * 0.5;
							uv_v = 0.5 + uv_v * 0.5;
						}
						else
						{
							//第四象限
							uv_u = 0.5 + uv_u * 0.5;
							uv_v = (1 - uv_v) * 0.5;
						}
					}
					else
					{
						if (crossAB.y > 0)
						{
							//第二象限
							uv_u = (1 + uv_u) * 0.5;
							uv_v = (1 + uv_v) * 0.5;
						}
						else
						{
							//第三象限
							uv_u = (1 + uv_u) * 0.5;
							uv_v = 0.5 - uv_v * 0.5;
						}
					}

					float2 maskUV = float2(uv_u, uv_v);
					maskUV = maskUV - float2(0.5, 0.5);
					atten = 1 - sqrt(maskUV.x * maskUV.x + maskUV.y * maskUV.y) / 0.5;
					atten = atten * 0.5;
					float maskUVScale = DynamicPointRight[i].w % 10;
					//half textureIndex = (DynamicPointRight[i].w - maskUVScale) / 10;//这种写法存在精度问题
					maskUV *= maskUVScale;
					maskUV += float2(0.5, 0.5);
					//至此maskUV得到的是0-1的uv信息

					float alphaRatio = 0;
					if (aniType == 6)
					{
						//读图集
						float atlasIndex = floor(_Time.y * 10 % atlasColumn2);
						float lineIndex = atlasColumn - floor(atlasIndex / atlasColumn) - 1;
						float columnIndex = atlasIndex % atlasColumn;
						maskUV.x = maskUV.x / atlasColumn + columnIndex * 1 / atlasColumn;
						maskUV.y = maskUV.y / atlasColumn + lineIndex * 1 / atlasColumn;
					}
					else if (aniType == 7)
					{
						//读取动态字体
						maskUV = 1 - maskUV;//这一步转换后，字的旋转信息与贴图中的一致
											//接下来，判断旋转方向，目前看只有朝右和倒置
						float4 uv = DynamicCharaterUV[i];
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

						maskUV = saturate(maskUV);
						maskCol = tex2D(DynamicFontTexture, float2(lerp(uv.x % 10, uv.z % 1.0, maskUV.x),
							lerp(uv.y, uv.w % 1.0, maskUV.y)));

						maskCol.rgb = fixed3(1, 1, 1)*maskCol.a;
						/*color.rgb = fixed3(float2(lerp(uv.x % 10, uv.z, maskUV.x),
						lerp(uv.y, uv.w, maskUV.y)).x,0,0);*/
					}

					maskCol.a *= (1-alphaRatio);

					nl = /*saturate*/(dot(normalize(dir), worldNormal));
					color.rgb += /*maskCol.rgb**/maskCol.a*DynamicPointColor[i].rgb + (DynamicPointColor[i].rgb * /*nl **/ atten) * (1 - maskCol.a);
					color.a += maskCol.a;
					_atten += atten;
				}
				else
				{
					nl = /*saturate*/(dot(normalize(dir), worldNormal));
					color.rgb += DynamicPointColor[i].rgb * nl * atten;
				}
			}
		}
	}
	
	color = clamp(color, 0,1);
	return color;
}
