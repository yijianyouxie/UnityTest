// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Consume/Leaf Swing"
{
	Properties {
	    _Color ("Main Color", Color) = (1,1,1,1)
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_WindDirectionX("WindDirectionX",float) = 1
		_WindDirectionZ("WindDirectionZ",float) = 0.1
		_GlobalMoveFrequency("GlobalMoveFrequency",float) = 0.1
		_GlobalMoveFactor("GlobalMoveFactor",float) = 0
		_GlobalMovePower("GlobalMovePower",float) = 1.0
		_BranchMoveFrequency("BranchMoveFrequency",float) = 1
		_BranchMoveFactor("BranchMoveFactor",float) = 0.2
		_BranchMovePower("BranchMovePower",float) = 1.0
		_EnvInfo("EnvInfo",float) = 0.2
	}
	SubShader
	{
		LOD 200
		Tags
		{
			"RenderType"="TransparentCutout"
			"Queue"="AlphaTest"
		}
		//Cull off

		CGPROGRAM
		#pragma surface surf Lambert vertex:vert_custom finalcolor:finalcustomcolor alphatest:_Cutoff
		#include "CYUnityCG.cginc"
		#pragma multi_compile __ CY_FOG_ON

		sampler2D _MainTex;
		fixed4 _Color;
		float _WindDirectionX;
		float _WindDirectionZ;
		float _GlobalMoveFrequency;
		float _GlobalMoveFactor;
		float _GlobalMovePower;
		float _BranchMoveFrequency;
		float _BranchMoveFactor;
		float _BranchMovePower;
		float _EnvInfo;

		struct Input
		{
			half2 uv_MainTex;
			CY_FOG_COORDS(1)
		};

		void surf (Input IN, inout SurfaceOutput o)
		{
			half4 c = tex2D (_MainTex, IN.uv_MainTex)* _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}

		void vert_custom(inout appdata_full v, out Input o)
		{  
			UNITY_INITIALIZE_OUTPUT(Input, o);

			float4 WorldPosition_1;
			float4 tmpvar_3;
			tmpvar_3.w = 1.0;
			tmpvar_3.xyz = v.vertex.xyz;

			float4 tmpvar_4;
			tmpvar_4.w = 1.0;
			tmpvar_4.xyz = tmpvar_3.xyz;

			float4 tmpvar_5;
			tmpvar_5.w = 1.0;
			tmpvar_5.xyz = mul(unity_ObjectToWorld, tmpvar_4).xyz;
			WorldPosition_1.w = tmpvar_5.w;

			float3 WorldNormal_7;
			WorldNormal_7 = normalize(mul(unity_ObjectToWorld, v.normal.xyz));

			float3 x_9;
			x_9 = mul(unity_ObjectToWorld, float3(1.0, 0.0, 0.0));

			float3 tmpvar_10;
			tmpvar_10.y = 0.0;
			tmpvar_10.x = _WindDirectionX;
			tmpvar_10.z = _WindDirectionZ;

			float tmpvar_11;
			float tmpvar_12;
			tmpvar_12 = (1.0 + _EnvInfo);
			tmpvar_11 = _Time.y * _GlobalMoveFrequency * tmpvar_12;

			float tmpvar_13;
			tmpvar_13 = abs(((frac(((tmpvar_5.x + tmpvar_11) + 0.5))* 2.0) - 1.0));

			float tmpvar_14;
			float tmpvar_15;
			tmpvar_15 = abs(((frac(((tmpvar_5.z + (tmpvar_11 * 0.65)) + 0.5))* 2.0) - 1.0));
			tmpvar_14 = ((((tmpvar_15 * tmpvar_15)*(3.0 - (2.0 * tmpvar_15))) - 0.5) * 2.0);

			float tmpvar_16;
			tmpvar_16 = _Time.y * _BranchMoveFrequency * (1.0 + (_EnvInfo * 0.5));

			float tmpvar_17;
			tmpvar_17 = abs(((frac(((tmpvar_5.x + tmpvar_16) + 0.5))* 2.0) - 1.0));

			float tmpvar_18;
			float tmpvar_19;

			tmpvar_19 = abs(((frac(((tmpvar_5.z + (tmpvar_16 * 0.72)) + 0.5))* 2.0) - 1.0));

			tmpvar_18 = ((tmpvar_19 * tmpvar_19 * (3.0 - (2.0 * tmpvar_19))) - 0.5) * 2.0;


			v.vertex.xyz = (tmpvar_5.xyz + ((
				((tmpvar_10 * ((
					((((
						(tmpvar_13 * tmpvar_13)
						*
						(3.0 - (2.0 * tmpvar_13))
						) - 0.5) * 2.0) + (tmpvar_14 * tmpvar_14))
					+ 0.5) * (1.0 +
						(2.0 * _EnvInfo)
						))) * pow(clamp((v.vertex.y * _GlobalMoveFactor), 0.0, 1.0), _GlobalMovePower))
				+
				(((dot(tmpvar_10, WorldNormal_7) * WorldNormal_7) * ((
					((((tmpvar_17 * tmpvar_17) * (3.0 -
						(2.0 * tmpvar_17)
						)) - 0.5) * 2.0)
					+
					(tmpvar_18 * tmpvar_18)
					) * tmpvar_12)) * pow(_BranchMoveFactor, _BranchMovePower))
				) * (
					sqrt(dot(x_9, x_9)))));
			
			v.vertex.w = 1.0f;
			v.vertex = mul(unity_WorldToObject, v.vertex);

			float4 posW = mul(unity_ObjectToWorld, v.vertex);
			float3 dis = posW.xyz - _WorldSpaceCameraPos;
			CY_TRANSFER_FOG(o, dis.xyz, posW.y);
		}

		void finalcustomcolor(Input IN, SurfaceOutput o, inout fixed4 color)
		{
			CY_APPLY_FOG(IN.cyFogCoord, color);
		}

		ENDCG
	}

	FallBack "Transparent/Cutout/VertexLit"
}


