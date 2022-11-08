Shader "CE/PlaneShadow" {
	Properties {
		_lightDir("Light Info",Vector) = (0,-2,1, 0) 
		_intensity("Shadow Intensity", Range(0,1)) = 0.7
	}
	SubShader {
 	    Tags { "Queue" = "Geometry+1" "RenderType"="AlphaTest" }
		Pass{
	 
		LOD 200
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off
		Offset -22, 1
  		Stencil {
                Ref 142
                Comp NotEqual
                Pass Replace
                ZFail Keep
                Fail Keep
                }

		CGPROGRAM
 		#include "UnityCG.cginc"
		#include "Lighting.cginc"
 		#pragma vertex vert
		#pragma fragment frag
 

 		float4 _lightDir;
		float  _intensity;
		struct v2f 
		{
			float4 pos : SV_POSITION;
			float2 uv_MainTex: TEXCOORD0;
		};

		v2f vert(appdata_base v)
		{
			v2f o;
			float4 loc1  = mul(unity_ObjectToWorld, v.vertex);
 		 	float loc13  = _lightDir.w - loc1.y;
		 	float loc14  = loc13/ _lightDir.y;
		 	float2 loc16 =  float2(_lightDir.x,_lightDir.z) * loc14;
		 	float2 loc17 = loc16 + float2(loc1.x, loc1.z);
		 	float4 loc20 = float4(loc17.x,_lightDir.w,loc17.y,1.0);
   		 	o.pos = mul (UNITY_MATRIX_VP, loc20);
  			o.uv_MainTex = float2(loc1.y, _lightDir.w);
  			return o;
   		}
	 
		float4 frag( v2f i ) : SV_Target
		{
            float local_2 = _intensity * step(i.uv_MainTex.y, i.uv_MainTex.x) * 0.66;
 	  		return float4(0, 0, 0, local_2);
   		}
		ENDCG
		}
	} 
	FallBack "Diffuse"
}
