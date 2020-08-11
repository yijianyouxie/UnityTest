
#ifndef UNDER_WATER_EFFECT
#define UNDER_WATER_EFFECT

	#ifdef CY_FOG_ON

	float4 FogInfo;
	float4 FogColor;
	float4 FogColor2;
	float4 FogColor3;
	float4 FogInfo2;

	#define UNITY_CY_FOG_COORDS_PACKED(idx, vectype) vectype cyFogCoord : TEXCOORD##idx;
	#define UNITY_CY_FOG_COORDS(idx) UNITY_CY_FOG_COORDS_PACKED(idx, float4)

	#define UNITY_TRANSFER_CY_FOG(o, camToWorldDis, posWorldY)    \
		o.cyFogCoord.xyz = camToWorldDis.xyz; \
		float tmpvar_1 = clamp(((posWorldY * FogInfo.z) + FogInfo.w), 0.0, 1.0); \
		float fHeightCoef = (tmpvar_1 * tmpvar_1); \
		fHeightCoef = (fHeightCoef * fHeightCoef); \
		float tmpvar_2 = (1.0 - exp((-(max(0.0, (sqrt(dot(o.cyFogCoord.xyz, o.cyFogCoord.xyz)) - FogInfo.x)))* FogInfo.y * fHeightCoef))); \
		o.cyFogCoord.w = (tmpvar_2 * tmpvar_2);
		//o.cyFogCoord.w = (o.cyFogCoord.w * o.cyFogCoord.w);

	#define UNITY_APPLY_CY_FOG_COLOR(coord,col,col1,col2,col3) \
		float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz); \
		float3 DisVal = (normalize(-coord.xyz)); \
		float fogFactor3 = clamp(dot(-DisVal, lightDirection.xyz), 0.0, 1.0); \
		fogFactor3 = fogFactor3*fogFactor3; \
		float fogFactor2 = clamp((DisVal.y * FogInfo2.y + FogInfo2.z), 0.0, 1.0); \
		float3 finalC = col.xyz; \
		col.xyz = lerp(col.xyz, (((col.xyz * (1.0 - coord.w)) + col1.xyz) + ((fogFactor3 * col3).xyz + (col2.xyz * fogFactor2))), coord.w); \
		col.xyz = col.xyz * float3(col1.w, col2.w, col3.w); \
		col.xyz = ((col.xyz / (col.xyz + 0.187)) * 1.035); \
		fixed finalFactor = saturate(coord.w+FogInfo2.w); \
		col.xyz = lerp(finalC, col.xyz, FogInfo2.x*finalFactor);


	#define UNITY_APPLY_CY_FOG_ADDPASS(coord,col) UNITY_APPLY_CY_FOG_COLOR(coord,col,fixed4(0,0,0,FogColor.w),fixed4(0,0,0,FogColor2.w),fixed4(0,0,0,FogColor3.w))

	#ifdef UNITY_PASS_FORWARDADD
	#define UNITY_APPLY_CY_FOG(coord,col) UNITY_APPLY_CY_FOG_COLOR(coord,col,fixed4(0,0,0,FogColor.w),fixed4(0,0,0,FogColor2.w),fixed4(0,0,0,FogColor3.w))
	#else
	#define UNITY_APPLY_CY_FOG(coord,col) UNITY_APPLY_CY_FOG_COLOR(coord,col,FogColor,FogColor2,FogColor3)
	#endif

	#else
	#define UNITY_CY_FOG_COORDS(idx)
	#define UNITY_TRANSFER_CY_FOG(o,dis, posWorldY)
	#define UNITY_APPLY_CY_FOG(coord,col)
	#define UNITY_APPLY_CY_FOG_ADDPASS(coord,col)
	#endif
	
	#ifdef CausticEffect
	sampler2D _CausticsTex;
	//x:size, y: speed, z: intensity
	float4 _CausticParam;
	
	inline fixed4 CaculateCausticsEffect(fixed4 color, float3 worldPos)
	{
		float c = floor(_Time.y * _CausticParam.y / 8.0);
		float r = floor(fmod(_Time.y * _CausticParam.y, 8.0));
		float speed = 1.0 / 8;
		
		float2 uv = fmod(abs(worldPos.xz + worldPos.yy) * _CausticParam.x, speed);
		
		uv.x += r * speed;
		uv.y = 1.0 - c * speed - uv.y;
	
		fixed4 caustic = tex2D(_CausticsTex, uv);
		color.rgb += caustic.rgb * _CausticParam.z;
		
		return color;
	}
	#endif

#endif // UNDER_WATER_EFFECT
