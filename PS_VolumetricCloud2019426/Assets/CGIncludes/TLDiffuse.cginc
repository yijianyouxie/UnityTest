#ifndef TL_DIFFUSE
#define TL_DIFFUSE

#include "TLVertexAnimation.cginc"

sampler2D _MainTex;
fixed4 _Color;
fixed4 _EmissionColor;
//添加Env里对Emission强度的控制
float _EmissionIntensityMax;			
//fixed _GIScale;

struct Input
{
	float2 uv_MainTex;
	half4 fogCoord;
};

void finalColor(Input IN, SurfaceOutput o, inout fixed4 color)
{
	TL_APPLY_FOG(IN.fogCoord, color.rgb);
}

inline fixed4 LightingLambertLeaf(SurfaceOutput s, UnityGI gi)
{
	fixed4 c;
	c = UnityLambertLight (s, gi.light);

	#ifdef LIGHTMAP_ON
	//	gi.indirect.diffuse += (1 - gi.indirect.diffuse) * _GIScale;
	#endif

	#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
		c.rgb += s.Albedo * gi.indirect.diffuse;
	#endif

	return c;
}

inline void LightingLambertLeaf_GI (
	SurfaceOutput s,
	UnityGIInput data,
	inout UnityGI gi)
{
	gi = UnityGlobalIllumination (data, 1.0, s.Normal);
}

void surf(Input IN, inout SurfaceOutput o)
{
	fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
	o.Albedo = c.rgb;
	o.Alpha = c.a;
	//#if defined(_ALPHATEST_ON)
	//    o.Alpha = c.a;
	//#else
	//	o.Alpha = 1.0;	
	//#endif
}

void surf_hlod(Input IN, inout SurfaceOutput o)
{
	fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
	o.Albedo = c.rgb;
	o.Emission = c.a * _EmissionColor.rgb * _EmissionIntensityMax;


}

// Transfer the vertex normal to the Input structure
void vert (inout appdata_full v, out Input o) 
{
	UNITY_INITIALIZE_OUTPUT(Input,o);
	o.uv_MainTex = v.texcoord;

	#if defined(_LEAF_ON)
		float2 animParams = float2(v.color.y, v.color.z);
		v.vertex = AnimateVertex(v.vertex, v.normal, animParams);
	#endif

	float4 outPos = 0;//outPos在TL_TRANSFER_FOG里没有用
	TL_TRANSFER_FOG(o, outPos, v.vertex);
}


#endif
