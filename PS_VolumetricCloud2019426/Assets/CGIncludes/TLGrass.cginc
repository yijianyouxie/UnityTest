#ifndef TL_GRASS
#define TL_GRASS

//#include "TLVertexAnimation.cginc"

sampler2D _MainTex;
UNITY_INSTANCING_BUFFER_START(Props)
    UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
UNITY_INSTANCING_BUFFER_END(Props)

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

void surf(Input IN, inout SurfaceOutput o)
{
    fixed4 c = tex2Dbias(_MainTex, float4(IN.uv_MainTex, 0, -1));
	o.Alpha = c.a;
	//c *= UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
	o.Albedo = c.rgb;
	
	//#if defined(_ALPHATEST_ON)
	//    o.Alpha = c.a;
	//#else
	//	o.Alpha = 1.0;	
	//#endif
}

// Transfer the vertex normal to the Input structure
void vert (inout appdata_full v, out Input o) 
{
	UNITY_INITIALIZE_OUTPUT(Input,o);
	o.uv_MainTex = v.texcoord;
	//#if defined(_LEAF_ON)
	//float2 animParams = float2(v.color.y, v.color.z);
	//v.vertex = AnimateVertex(v.vertex, v.normal,animParams);
	//#endif
	float4 outPos = UnityObjectToClipPos(v.vertex);
	TL_TRANSFER_FOG(o, outPos, v.vertex);
}


#endif
