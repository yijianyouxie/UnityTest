//Virtual Dynamic Light
int DynamicPointLightNum = 0;
float4 DynamicPointPos[10];//xyzλ��
fixed4 DynamicPointColor[10];//rgb��ɫ
float4 DynamicPointDir[10];//����
float4 DynamicPointRight[10];//spot�Ƶ��ҳ���
float4 DynamicCharaterUV[10];//�����ֵ�uv��Ϣ
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
				float distance2 = dot(dir, dir);//�����ƽ��
				if (distance2 < DynamicPointPos[i].w)
				{
					float nl = 0;
					float3 lineStart = DynamicPointPos[i].xyz;
					float3 lineDirection = normalize(DynamicPointDir[i].xyz);
					// ��������v��w��ͶӰ����dParallel
					float3 v = worldPos - lineStart;
					float dParallel = dot(v, lineDirection) /*/ dot(lineDirection, lineDirection)*/;
					//w�ǵ�ǰ���ص㵽spot���䷽���ϵ�ͶӰ�㵽���ص������
					float3 w = v - dParallel * lineDirection;
					//w = normalize(w);
					//ͼ������
					float atlasColumn = floor(DynamicPointRight[i].w / 1000);
					float atlasColumn2 = atlasColumn * atlasColumn;
					//��������
					float aniType = floor((DynamicPointRight[i].w - atlasColumn * 1000) / 100);
					float textureIndex = floor((DynamicPointRight[i].w - atlasColumn * 1000 - aniType * 100) / 10);
					fixed4 maskCol = fixed4(1, 1, 1, 0);
					float atten = lerp(0, 1, saturate((angle - DynamicPointDir[i].w) / (1 - DynamicPointDir[i].w)));
					if (textureIndex > 0)
					{
						//���㵱ǰλ�õ�Բ�뾶
						float radius = sqrt(pow(dParallel / DynamicPointDir[i].w, 2) - pow(dParallel, 2));
						//cos��ֵ��x�����ֵ
						float x = dot(w, DynamicPointRight[i].xyz);
						//����y����
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
						//		//��һ����
						//		uv_u = 0.5 + uv_u * 0.5;
						//		uv_v = 0.5 + uv_v * 0.5;
						//	}
						//	else
						//	{
						//		//��������
						//		uv_u = 0.5 + uv_u * 0.5;
						//		uv_v = (1 - uv_v) * 0.5;
						//	}
						//}
						//else
						//{
						//	if (crossAB.y > 0)
						//	{
						//		//�ڶ�����
						//		uv_u = (1 + uv_u) * 0.5;
						//		uv_v = (1 + uv_v) * 0.5;
						//	}
						//	else
						//	{
						//		//��������
						//		uv_u = (1 + uv_u) * 0.5;
						//		uv_v = 0.5 - uv_v * 0.5;
						//	}
						//}

						float2 maskUV = float2(uv_u, uv_v);
						//maskUV = maskUV - float2(0.5, 0.5);
						float maskUVScale = DynamicPointRight[i].w % 10;
						//float textureIndex = (DynamicPointRight[i].w - maskUVScale) / 10;//����д�����ھ�������
						/*maskUV *= maskUVScale;
						maskUV += float2(0.5, 0.5);*/
						//����maskUV�õ�����0-1��uv��Ϣ
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
								//��ͼ��
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
							//��ȡ��̬����
							maskUV.y = 1 - maskUV.y;//��һ��ת�����ֵ���ת��Ϣ����ͼ�е�һ��
												//���������ж���ת����Ŀǰ��ֻ�г��Һ͵���
							//float4 uv = DynamicCharaterUV[i];
							float topDir = floor(uv.x / 10);
							if (topDir == 2)
							{
								//��ֱ����
								maskUV.y = 1 - maskUV.y;
							}
							else if (topDir == 1)
							{
								//����
								//������ת�����ĵ�Pivot
								float2 pivot = float2(0.5, 0.5);
								// �Ƕȱ仡��
								float glossTexAngle = 90 * 3.14 / 180;
								//Rotation Matrix
								float cosAngle = cos(glossTexAngle);
								float sinAngle = sin(glossTexAngle);
								//����2ά��ת����˳ʱ����ת
								float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
								//���Ƶ�������ת
								float2 targetUV = maskUV - pivot;
								targetUV = mul(rot, targetUV);
								//���ƻ���
								targetUV += pivot;
								maskUV = targetUV;
							}

							//maskUV = saturate(maskUV);
							//�����жϣ��Ƿ���Ҫ����ˮƽ��ֱuvֵ����Ϊ��Щ���Ǳ�ģ����ܵȱ����ŵ���������
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
							//����1��ֵ�����������������С��С��1��ֵ��������������ϷŴ�
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
