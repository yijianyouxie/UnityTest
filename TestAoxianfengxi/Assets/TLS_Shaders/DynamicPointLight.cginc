//Virtual Dynamic Point Light
half DynamicLightDistance = 5;
int DynamicPointLightNum = 0;
half4 DynamicPointPos_1;//xyzλ��
fixed4 DynamicPointColor_1;//rgb��ɫ
half4 DynamicPointPos_2;//xyzλ��
fixed4 DynamicPointColor_2;//rgb��ɫ
half4 DynamicPointPos_3;//xyzλ��
fixed4 DynamicPointColor_3;//rgb��ɫ
half4 DynamicPointPos_4;//xyzλ��
fixed4 DynamicPointColor_4;//rgb��ɫ
half4 DynamicPointPos_5;//xyzλ��
fixed4 DynamicPointColor_5;//rgb��ɫ
half4 DynamicPointPos_6;//xyzλ��
fixed4 DynamicPointColor_6;//rgb��ɫ
half4 DynamicPointPos_7;//xyzλ��
fixed4 DynamicPointColor_7;//rgb��ɫ
half4 DynamicPointPos_8;//xyzλ��
fixed4 DynamicPointColor_8;//rgb��ɫ
half4 DynamicPointPos_9;//xyzλ��
fixed4 DynamicPointColor_9;//rgb��ɫ
half4 DynamicPointPos_10;//xyzλ��
fixed4 DynamicPointColor_10;//rgb��ɫ
half4 DynamicPointPos_11;//xyzλ��
fixed4 DynamicPointColor_11;//rgb��ɫ
half4 DynamicPointPos_12;//xyzλ��
fixed4 DynamicPointColor_12;//rgb��ɫ
half4 DynamicPointPos_13;//xyzλ��
fixed4 DynamicPointColor_13;//rgb��ɫ
half4 DynamicPointPos_14;//xyzλ��
fixed4 DynamicPointColor_14;//rgb��ɫ
half4 DynamicPointPos_15;//xyzλ��
fixed4 DynamicPointColor_15;//rgb��ɫ
half4 DynamicPointPos_16;//xyzλ��
fixed4 DynamicPointColor_16;//rgb��ɫ
half4 DynamicPointPos_17;//xyzλ��
fixed4 DynamicPointColor_17;//rgb��ɫ
half4 DynamicPointPos_18;//xyzλ��
fixed4 DynamicPointColor_18;//rgb��ɫ
half4 DynamicPointPos_19;//xyzλ��
fixed4 DynamicPointColor_19;//rgb��ɫ
half4 DynamicPointPos_20;//xyzλ��
fixed4 DynamicPointColor_20;//rgb��ɫ
half4 DynamicPointPos_21;//xyzλ��
fixed4 DynamicPointColor_21;//rgb��ɫ
half4 DynamicPointPos_22;//xyzλ��
fixed4 DynamicPointColor_22;//rgb��ɫ
half4 DynamicPointPos_23;//xyzλ��
fixed4 DynamicPointColor_23;//rgb��ɫ
half4 DynamicPointPos_24;//xyzλ��
fixed4 DynamicPointColor_24;//rgb��ɫ
half4 DynamicPointPos_25;//xyzλ��
fixed4 DynamicPointColor_25;//rgb��ɫ
half4 DynamicPointPos_26;//xyzλ��
fixed4 DynamicPointColor_26;//rgb��ɫ
half4 DynamicPointPos_27;//xyzλ��
fixed4 DynamicPointColor_27;//rgb��ɫ
half4 DynamicPointPos_28;//xyzλ��
fixed4 DynamicPointColor_28;//rgb��ɫ
half4 DynamicPointPos_29;//xyzλ��
fixed4 DynamicPointColor_29;//rgb��ɫ
half4 DynamicPointPos_30;//xyzλ��
fixed4 DynamicPointColor_30;//rgb��ɫ
half4 DynamicPointPos_31;//xyzλ��
fixed4 DynamicPointColor_31;//rgb��ɫ
half4 DynamicPointPos_32;//xyzλ��
fixed4 DynamicPointColor_32;//rgb��ɫ
half4 DynamicPointPos_33;//xyzλ��
fixed4 DynamicPointColor_33;//rgb��ɫ
half4 DynamicPointPos_34;//xyzλ��
fixed4 DynamicPointColor_34;//rgb��ɫ
half4 DynamicPointPos_35;//xyzλ��
fixed4 DynamicPointColor_35;//rgb��ɫ
half4 DynamicPointPos_36;//xyzλ��
fixed4 DynamicPointColor_36;//rgb��ɫ
half4 DynamicPointPos_37;//xyzλ��
fixed4 DynamicPointColor_37;//rgb��ɫ
half4 DynamicPointPos_38;//xyzλ��
fixed4 DynamicPointColor_38;//rgb��ɫ
half4 DynamicPointPos_39;//xyzλ��
fixed4 DynamicPointColor_39;//rgb��ɫ
half4 DynamicPointPos_40;//xyzλ��
fixed4 DynamicPointColor_40;//rgb��ɫ

fixed3 GetDynamicPointLightColor(float3 worldPos, float3 worldNormal)
{
	half3 color = 0;
	half3 dir = 0;
	half distance2 = 0;
	half nl = 0;
	dir = DynamicPointPos_1.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_1.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_2.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_2.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_3.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_3.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_4.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_4.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_5.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_5.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_6.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_6.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_7.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_7.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_8.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_8.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_9.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_9.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_10.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_10.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_11.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_11.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_12.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_12.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_13.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_13.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_14.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_14.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_15.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_15.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_16.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_16.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_17.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_17.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_18.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_18.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_19.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_19.rgb * nl * rcp(distance2);

	dir = DynamicPointPos_20.xyz - worldPos;
	distance2 = dot(dir, dir);//�����ƽ��
	nl = /*saturate*/(dot(normalize(dir), worldNormal));
	color += DynamicPointColor_20.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_21.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_21.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_22.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_22.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_23.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_23.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_24.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_24.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_25.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_25.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_26.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_26.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_27.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_27.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_28.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_28.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_29.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_29.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_30.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_30.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_31.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_31.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_32.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_32.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_33.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_33.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_34.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_34.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_35.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_35.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_36.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_36.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_37.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_37.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_38.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_38.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_39.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_39.rgb * nl * rcp(distance2);

	//dir = DynamicPointPos_40.xyz - worldPos;
	//distance2 = dot(dir, dir);//�����ƽ��
	//nl = /*saturate*/(dot(normalize(dir), worldNormal));
	//color += DynamicPointColor_40.rgb * nl * rcp(distance2);
	
	//color = clamp(color, 0,1);
	return color;
}
