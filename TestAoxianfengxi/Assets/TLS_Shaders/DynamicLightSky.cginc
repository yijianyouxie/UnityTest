//Virtual Dynamic Light
int DynamicPointLightNum = 0;
float4 DynamicPointPos[10];//xyzλ��
fixed4 DynamicPointColor[10];//rgb��ɫ
float4 DynamicPointDir[10];//����
float4 DynamicPointRight[10];//spot�Ƶ��ҳ���
//fixed4 DynamicPointInflunceScope[10];//Ӱ��Ķ�������x������ y:���� z:��������
float4 DynamicCharaterUV[10];//�����ֵ�uv��Ϣ
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
					float currRadius = dot(w, DynamicPointRight[i].xyz);
					float uv_u = currRadius / radius;
					float uv_v = sqrt(dot(w, w) - currRadius*currRadius) / radius;
					float3 crossAB = cross(w, DynamicPointRight[i].xyz);
					if (uv_u > 0)
					{
						if (crossAB.y > 0)
						{
							//��һ����
							uv_u = 0.5 + uv_u * 0.5;
							uv_v = 0.5 + uv_v * 0.5;
						}
						else
						{
							//��������
							uv_u = 0.5 + uv_u * 0.5;
							uv_v = (1 - uv_v) * 0.5;
						}
					}
					else
					{
						if (crossAB.y > 0)
						{
							//�ڶ�����
							uv_u = (1 + uv_u) * 0.5;
							uv_v = (1 + uv_v) * 0.5;
						}
						else
						{
							//��������
							uv_u = (1 + uv_u) * 0.5;
							uv_v = 0.5 - uv_v * 0.5;
						}
					}

					float2 maskUV = float2(uv_u, uv_v);
					maskUV = maskUV - float2(0.5, 0.5);
					atten = 1 - sqrt(maskUV.x * maskUV.x + maskUV.y * maskUV.y) / 0.5;
					atten = atten * 0.5;
					float maskUVScale = DynamicPointRight[i].w % 10;
					//half textureIndex = (DynamicPointRight[i].w - maskUVScale) / 10;//����д�����ھ�������
					maskUV *= maskUVScale;
					maskUV += float2(0.5, 0.5);
					//����maskUV�õ�����0-1��uv��Ϣ

					float alphaRatio = 0;
					if (aniType == 6)
					{
						//��ͼ��
						float atlasIndex = floor(_Time.y * 10 % atlasColumn2);
						float lineIndex = atlasColumn - floor(atlasIndex / atlasColumn) - 1;
						float columnIndex = atlasIndex % atlasColumn;
						maskUV.x = maskUV.x / atlasColumn + columnIndex * 1 / atlasColumn;
						maskUV.y = maskUV.y / atlasColumn + lineIndex * 1 / atlasColumn;
					}
					else if (aniType == 7)
					{
						//��ȡ��̬����
						maskUV = 1 - maskUV;//��һ��ת�����ֵ���ת��Ϣ����ͼ�е�һ��
											//���������ж���ת����Ŀǰ��ֻ�г��Һ͵���
						float4 uv = DynamicCharaterUV[i];
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
