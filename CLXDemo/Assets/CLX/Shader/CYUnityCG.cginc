#ifndef CY_UNITY_CG_INCLUDED
#define CY_UNITY_CG_INCLUDED


#ifdef CY_FOG_ON

float4 FogInfo;
float4 FogColor;
float4 FogColor2;
float4 FogColor3;
float4 FogInfo2;


#define CY_FOG_COORDS_PACKED(idx, vectype) vectype cyFogCoord : TEXCOORD##idx;
#define CY_FOG_COORDS(idx) CY_FOG_COORDS_PACKED(idx, float4)

#define CY_TRANSFER_FOG(o, camToWorldDis, posWorldY)    \
    o.cyFogCoord.xyz = camToWorldDis.xyz; \
	float tmpvar_1 = clamp(((posWorldY * FogInfo.z) + FogInfo.w), 0.0, 1.0); \
	float fHeightCoef = (tmpvar_1 * tmpvar_1); \
	fHeightCoef = (fHeightCoef * fHeightCoef); \
	float tmpvar_2 = (1.0 - exp((-(max(0.0, (sqrt(dot(o.cyFogCoord.xyz, o.cyFogCoord.xyz)) - FogInfo.x)))* FogInfo.y * fHeightCoef))); \
	o.cyFogCoord.w = (tmpvar_2 * tmpvar_2);

#define CY_APPLY_FOG_COLOR(coord,col,col1,col2,col3) \
	float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz); \
	float3 DisVal = (normalize(-coord.xyz)); \
	float fogFactor3 = clamp(dot(-DisVal, lightDirection.xyz), 0.0, 1.0); \
	fogFactor3 = fogFactor3*fogFactor3; \
	float fogFactor2 = clamp((DisVal.y * FogInfo2.y + FogInfo2.z), 0.0, 1.0); \
	float3 finalC = col.xyz; \
	col.xyz = lerp(col.xyz, (((col.xyz * (1.0 - coord.w)) + col1.xyz) + ((fogFactor3 * col3).xyz + (col2.xyz * fogFactor2))), coord.w); \
	col.xyz = col.xyz * float3(col1.w, col2.w, col3.w); \
	col.xyz = (col.xyz / ((col.xyz * 0.9661836) + 0.180676)); \
	fixed finalFactor = saturate(coord.w*1000.0f+FogInfo2.w); \
	col.xyz = lerp(finalC, col.xyz, FogInfo2.x*finalFactor);


#define CY_APPLY_FOG_ADDPASS(coord,col) CY_APPLY_FOG_COLOR(coord,col,fixed4(0,0,0,FogColor.w),fixed4(0,0,0,FogColor2.w),fixed4(0,0,0,FogColor3.w))

#ifdef UNITY_PASS_FORWARDADD
#define CY_APPLY_FOG(coord,col) CY_APPLY_FOG_COLOR(coord,col,fixed4(0,0,0,FogColor.w),fixed4(0,0,0,FogColor2.w),fixed4(0,0,0,FogColor3.w))
#else
#define CY_APPLY_FOG(coord,col) CY_APPLY_FOG_COLOR(coord,col,FogColor,FogColor2,FogColor3)
#endif

#else
#define CY_FOG_COORDS(idx)
#define CY_TRANSFER_FOG(o,dis, posWorldY)
#define CY_APPLY_FOG(coord,col)
#define CY_APPLY_FOG_ADDPASS(coord,col)
#endif


#endif // CY_UNITY_CG_INCLUDED
