Shader "DynamicLight/LightCylinderPian"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_AlphaScale("AlphaScale", Range(0.1, 100)) = 10
		_CylinderHalfHeight("_CylinderHeight", float) = 2
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" }
		LOD 100

		Pass
		{
			//Blend SrcColor OneMinusSrcColor
			Blend SrcAlpha One/*MinusSrcAlpha*/
			ZWrite Off
			Cull Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			//#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				//UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			half4 DynamicPointPos2;//xyz位置
			half4 DynamicPointDir2;//方向
			fixed4 DynamicPointColor2;//rgb颜色
			float _AlphaScale;
			float _CylinderHalfHeight;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				//UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				float3 p = i.worldPos;
				float3 lineStart = DynamicPointPos2.xyz;
				float3 lineDirection = normalize(DynamicPointDir2.xyz);
				// 计算向量v，w和投影长度dParallel
				float3 v = p - lineStart;
				float dParallel = dot(v, lineDirection) / dot(lineDirection, lineDirection);
				float3 w = v - dParallel * lineDirection;
				// 计算距离d，即向量w的长度
				float distance2 = dot(w,w);
				if (abs(dParallel) >= _CylinderHalfHeight)
				{
					float3 dir = DynamicPointPos2.xyz + sign(dParallel) * lineDirection * _CylinderHalfHeight - p;
					float distance2_2 = dot(dir, dir);//距离的平方
					return fixed4(DynamicPointColor2.rgb, 1/(distance2_2)* saturate(1 - distance2_2 / (DynamicPointColor2.w)) / _AlphaScale*col.r);
					//return fixed4(abs(dParallel), 0, 0, 1);
					//if (distance2 < 0.25)
					//{
					//	return fixed4(DynamicPointColor2.rgb, rcp(distance2)* saturate(1 - distance2 / DynamicPointColor2.w /*+ 3*/) / _AlphaScale);
					//}
					//else
					{
					//return fixed4(lerp(1, 0, sqrt(distance2) /0.5), 0, 0, 1);
						return fixed4(DynamicPointColor2.rgb, 1/(pow(sqrt(distance2_2) + lerp(0.1, 0, sqrt(distance2) / 0.5), 2))* saturate(1 - distance2_2 / (DynamicPointColor2.w + 3)) / _AlphaScale);
					}
					/*else
					{
						return(0,0,0,0);
					}*/
				}
				else
				{
					return fixed4(DynamicPointColor2.rgb, 1/(distance2)* saturate(1 - distance2 / DynamicPointColor2.w) / _AlphaScale*col.r);
				}
			}
			ENDCG
		}
	}
}
