// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// - Unlit
// - Per-vertex (virtual) camera space specular light
// - DONT SUPPORTS lightmap

//说明/////////////////////////////////////////////////////////////////////
//
//本shader用于需要与旗帜类似的物体，通过改变顶点实现，对材质所对应的模型有特别要求。
//当前shader使用的是ShadowGun原本的旗帜模型，随后若有改动会在此处列出。
//
//说明----------END/////////////////////////////////////////////////////////////////////


Shader "TLStudio/NoLightmap + Wind" {
Properties {
	_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
	_Wind("Wind params",Vector) = (1,1,1,1)
	_WindEdgeFlutter("Wind edge fultter factor", float) = 0.5
	_WindEdgeFlutterFreqScale("Wind edge fultter freq scale",float) = 0.5
	_AlphaCutOut("Alpha Cut Out " , Range(0 , 1)) = 0.5
}

SubShader {
	Tags {"Queue"="Transparent-450" "RenderType"="Transparent" "LightMode"="Always"}
	LOD 100
	
	Cull Off
	
	
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "TerrainEngine.cginc"
	sampler2D _MainTex;
	half4 _MainTex_ST;
	//samplerCUBE _ReflTex;	
	half _AlphaCutOut ;
	
	
	half _WindEdgeFlutter;
	half _WindEdgeFlutterFreqScale;
	

	struct v2f {
		half4 pos : SV_POSITION;
		half2 uv : TEXCOORD0;
		fixed3 spec : TEXCOORD2;
	};

inline float4 AnimateVertex2(half4 pos, half3 normal, half4 animParams,half4 wind,half2 time)
{	
	// animParams stored in color
	// animParams.x = branch phase
	// animParams.y = edge flutter factor
	// animParams.z = primary factor
	// animParams.w = secondary factor

	half fDetailAmp = 0.1f;
	half fBranchAmp = 0.3f;
	
	// Phases (object, vertex, branch)
	half fObjPhase = dot(unity_ObjectToWorld[3].xyz, 1);
	half fBranchPhase = fObjPhase + animParams.x;
	
	half fVtxPhase = dot(pos.xyz, animParams.y + fBranchPhase);
	
	// x is used for edges; y is used for branches
	//half2 vWavesIn = time  + half2(fVtxPhase, fBranchPhase );
	
	// 1.975, 0.793, 0.375, 0.193 are good frequencies
	//half4 vWaves = (frac( vWavesIn.xxyy * half4(1.975, 0.793, 0.375, 0.193) ) * 2.0 - 1.0);
	half4 vWaves = frac((((_Time.yyyy) * float4(_WindEdgeFlutterFreqScale,_WindEdgeFlutterFreqScale,1,1))+ float4(fVtxPhase,fVtxPhase,fBranchPhase,fBranchPhase))*float4(1.975,0.793,0.375,0.193))*2.0-1.0;
	
	vWaves = SmoothTriangleWave( vWaves );
	half2 vWavesSum = vWaves.xz + vWaves.yw;

	// Edge (xz) and branch bending (y)
	half3 bend = animParams.y * fDetailAmp * normal.xyz;
	bend.y = animParams.w * fBranchAmp;
	pos.xyz += ((vWavesSum.xyx * bend) + (wind.xyz * vWavesSum.y * animParams.w)) * wind.w; 

	// Primary bending
	// Displace position
	pos.xyz += animParams.z * wind.xyz;
	
	return pos;
}


	
	v2f vert (appdata_full v)
	{
		v2f o;
		
		half4	wind;
		
		half			bendingFact	= v.color.a;
		
		wind.xyz	= mul((float3x3)unity_WorldToObject,_Wind.xyz);
		wind.w		= _Wind.w  * bendingFact;
		
		
		half4	windParams	= half4(0,_WindEdgeFlutter,bendingFact.xx);
		half2 	windTime 		= 0;
		half4	mdlPos			= AnimateVertex2(v.vertex,v.normal,windParams,wind,windTime);
		
		o.pos = UnityObjectToClipPos(mdlPos);
		o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
		
		o.spec = v.color;
		
		
		
		return o;
	}
	ENDCG


	Pass {
		//Alphatest Greater [x]
		CGPROGRAM
		//#pragma debug
		#pragma vertex vert
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest		
		fixed4 frag (v2f i) : COLOR
		{
			fixed4 tex = tex2D (_MainTex, half2(i.uv.x*2,i.uv.y));//修改了UV，与模型的UV有关。
			
			fixed4 c;
			c.rgb = tex.rgb;
			c.a = tex.a;			
			clip(c.a - _AlphaCutOut);
			return c;
		}
		ENDCG 
	}	
}
}


