
//#if !defined(INSTANCING_ON)

#ifndef UNITY_PASS_FORWARDBASE
	#define UNITY_PASS_FORWARDBASE
#endif
		
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"
#include "HLSLSupport.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityShaderUtilities.cginc"
sampler2D _MainTex;
sampler2D _FurControlTex;
fixed4 _MainTex_ST;
				

//UNITY_DECLARE_DEPTH_TEXTURE(_ClothFurControlTex);
sampler2D _ControlAddTex;
sampler2D _FurNoiseTex;

struct Input 
{
    fixed alpha;
    float4 uv;
    float3 worldRefl;
    fixed3 viewDir;
	float3 uv_MainTex1;
};

fixed4 _FurColor;
fixed4 _BaseColor;
fixed _MaxHairLength;		

half _RimPower;
fixed _RimStrength;

fixed		_DissolveAmount;
fixed4		_DissolveInfo;
fixed4		_DissolveColor;
sampler2D	_DissolveSrc;
		
fixed4		_ExtraControl;
		
sampler2D	_DecalTex;
fixed4 		_DecalColor;


fixed4 _FurNoiseTex_ST;
sampler2D _FlowMap;
fixed _FlowMapStrength;
fixed _UVOffset;
float _Thickness;
float _FurDensity;
fixed _TotalLightControl;
fixed _EnvironmentLightControl;
		
fixed _Debug_Fur_Control;
		
//CGINCLUDE
fixed4 Dissolve( fixed4 c, Input surfIN)
{
	fixed ClipTex2 = tex2D (_DissolveSrc, (surfIN.uv_MainTex1.xy+_DissolveInfo.y)/_DissolveInfo.z).r;
	fixed ClipTex3 = tex2D (_DissolveSrc, (surfIN.uv_MainTex1.yz+_DissolveInfo.y)/_DissolveInfo.z).r;
			
	fixed ClipTex = ( ClipTex2 + ClipTex3 )* 0.5;
	ClipTex -= surfIN.uv_MainTex1.z * _DissolveInfo.w;
	fixed ClipAmount = max(ClipTex - _DissolveAmount,0);
	ClipAmount = min( ClipAmount, _DissolveInfo.x);
	c.xyzw = lerp(c.xyzw, c.xyzw*_DissolveColor*ClipTex, ClipAmount);
			
	return c;
}	

	struct v2f_surf 
	{
		UNITY_POSITION(pos);
		float4 uv : TEXCOORD0; // _MainTex
		half3 worldNormal : TEXCOORD1;
		float3 worldPos : TEXCOORD2;
		half custompack0 : TEXCOORD3; // alpha
	#if UNITY_SHOULD_SAMPLE_SH
		half3 sh : TEXCOORD4; // SH
	#endif
		UNITY_FOG_COORDS(5)
	/*#if SHADER_TARGET >= 30
		float4 lmap : TEXCOORD6;
	#endif*/
		float4 pack1: TEXCOORD6;
	//	UNITY_VERTEX_INPUT_INSTANCE_ID
	//	UNITY_VERTEX_OUTPUT_STEREO
	//#ifdef ENABLECLOTHFURCONTROLTEX
	//	  float4 projPos : TEXCOORD10;
	//#endif
	};

	v2f_surf vert_surf_simplified (appdata_full v) 
	{
		v2f_surf o;
		UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
		
		float2 uvoffset = FURSTEP * FURSTEP * float2(0.1, 0.1);
		o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
		o.uv.zw = TRANSFORM_TEX(v.texcoord, _FurNoiseTex) + uvoffset * _UVOffset;
		o.pack1.xy = v.texcoord1.xy;
		o.pack1.zw = v.texcoord2.xy;
		
		//变胖效果
		v.vertex.xyz += v.normal * v.color.x * _ExtraControl.x * 0.1f;
	
		float4 c = tex2Dlod (_FurControlTex, float4(v.texcoord.xy,0,0));
        float4 c2 = tex2Dlod (_ControlAddTex, float4(v.texcoord.xy,0,0));	
		c.rb = c.rb * c2.r;
		o.uv.zw *= c.g;
		
		float3 worldNormal = UnityObjectToWorldNormal(v.normal);
		float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
		float3 tangentSign = v.tangent.w * unity_WorldTransformParams.w;
		float3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
		float3 flowdir = tex2Dlod(_FlowMap, float4(v.texcoord.x, v.texcoord.y, 0, 0)).xyz * 2 - 1;
		flowdir = worldTangent * flowdir.x + worldBinormal * flowdir.y + worldNormal * flowdir.z;
		float3 furVertexOffset = normalize(mul(unity_WorldToObject, flowdir)) * _FlowMapStrength * c.b * c.r;
		
		float hairLength = _MaxHairLength * FURSTEP * c.r;
	#ifdef DEBUG_FUR
		//v.vertex.xyz += (normalize(v.normal + furVertexOffset) * hairLength);
	#else
		v.vertex.xyz += (normalize(v.normal + furVertexOffset) * hairLength);
	#endif

		o.pos = UnityObjectToClipPos(v.vertex);
		float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
		o.worldPos = worldPos;
		o.worldNormal = worldNormal;

	#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
		o.sh = 0;
		#ifdef VERTEXLIGHT_ON
			o.sh += Shade4PointLights (
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, worldPos, worldNormal);
		#endif
		o.sh = ShadeSHPerVertex (worldNormal, o.sh);
	#endif
	
		UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
		return o;
	}

	// fragment shader
	fixed4 frag_surf_simplified (v2f_surf IN) : SV_Target
	{
		//UNITY_SETUP_INSTANCE_ID(IN);
		// prepare and unpack data
		Input surfIN;
		UNITY_INITIALIZE_OUTPUT(Input,surfIN);

		surfIN.uv_MainTex1.xyz = IN.pack1.xyz;

		float3 worldPos = IN.worldPos;
	#ifndef USING_DIRECTIONAL_LIGHT
		fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	#else
		fixed3 lightDir = _WorldSpaceLightPos0.xyz;
	#endif
		fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
		fixed3 viewDir = worldViewDir;
		surfIN.viewDir = viewDir;
	#ifdef UNITY_COMPILER_HLSL
		SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
	#else
		SurfaceOutputStandardSpecular o;
	#endif
		o.Albedo = 1.0;
		o.Emission = 0.0;
		o.Specular = 0.0;
		o.Alpha = 0.00;
		o.Occlusion = 1.0;
		fixed3 normalWorldVertex = fixed3(0,0,1);
		o.Normal = IN.worldNormal;
		normalWorldVertex = IN.worldNormal;
		
		//#include "IFCommonClothCommandMask.cginc"
	
		float2 uvMain = IN.uv.xy;
		float2 uvNoise = IN.uv.zw;
	
		fixed4 mainTex = tex2D (_MainTex, uvMain);
		fixed4 decalTex = tex2D (_DecalTex, uvMain) * _DecalColor;
		//mainTex.rgb = lerp(decalTex.rgb, mainTex.rgb, decalTex.a);
		mainTex.rgb = lerp(mainTex.rgb, decalTex.rgb, decalTex.a);
		//fixed4 controlTex = tex2D (_FurControlTex, uvMain);
		mainTex *= lerp(_BaseColor, _FurColor, pow(FURSTEP, 2));
		
		fixed alpha = tex2D (_FurNoiseTex, uvNoise).r;			
		o.Albedo = mainTex.rgb;					
		alpha = saturate(alpha - (FURSTEP * FURSTEP) * _FurDensity + _Thickness);
		//fixed alphaFactor = pow(controlTex.r, 0.5);
			
		half rim = 1.0 - saturate(dot (normalize(viewDir), o.Normal));
		float3 rimLighting = o.Albedo * pow (rim, _RimPower) * _RimStrength;   
		
		//UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
		
		fixed4 c = 0;
		fixed NdL = saturate(max(0.1, dot(lightDir, o.Normal.xyz)));
		//fixed NdL = (dot(lightDir, o.Normal.xyz)) * 0.5 ;
		c.rgb += _LightColor0.rgb * o.Albedo * NdL + UNITY_LIGHTMODEL_AMBIENT.rgb * _EnvironmentLightControl * o.Albedo;
		c.rgb *= _TotalLightControl;
		c.rgb += rimLighting;
		c.a = alpha;
		c  = Dissolve(c, surfIN);
		
	#ifdef DEBUG_FUR
		fixed4 controlTex = tex2D (_FurControlTex, uvMain);
		switch(_Debug_Fur_Control)
		{
			case 0:
				return c;
			case 1:
				return controlTex.rrrr;
			case 2:
				return controlTex.gggg;
			case 3:
				return controlTex.bbbb;
		}
	#endif
						
		UNITY_APPLY_FOG(IN.fogCoord, c); 
		return c;
	}

//#endif
