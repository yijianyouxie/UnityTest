Shader "DynamicLight/PointLightPian"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_AlphaScale("AlphaScale", Range(0.1, 100)) = 10
		_Speed("Speed", Range(0, 1000)) = 0.1
		//_GlowFlow("_GlowFlow", Range(0,1)) = 0
		_TexScale("_TexScale", Range(0.01, 2)) = 1
		_TransScale("_TransScale", Range(0.01, 100)) = 1
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
			fixed4 DynamicPointColor2;//rgb颜色
			float _AlphaScale;
			float _Speed;
			//float _GlowFlow;
			float _TexScale;
			float _TransScale;
			
			float2 ProcessUV(float2 sourceUV, float rotate)
			{
				//定义旋转的轴心点Pivot
				float2 pivot = float2(0.5, 0.5);
				// 角度变弧度
				float glossTexAngle = rotate * 3.14 / 180;
				//Rotation Matrix
				float cosAngle = cos(glossTexAngle);
				float sinAngle = sin(glossTexAngle);
				//构造2维旋转矩阵，顺时针旋转
				float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
				//先移到中心旋转
				float2 targetUV = sourceUV - pivot;
				targetUV = mul(rot, targetUV);
				//再移回来
				targetUV += pivot;
				return targetUV;
			}

			v2f vert (appdata v)
			{
				v2f o;
				//o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertex = mul(UNITY_MATRIX_P,
					mul(UNITY_MATRIX_MV, float4(0.0, 0.0, 0.0, 1.0))
					+ float4(v.vertex.x*_TransScale, v.vertex.y*_TransScale, 0.0, 0.0));
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				//UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				//i.uv += float2(_Time.y, 0) * _Speed;
				i.uv = ProcessUV(i.uv, _Time.y * _Speed);
				i.uv = (i.uv - 0.5) / _TexScale + 0.5;
				fixed4 col = tex2D(_MainTex, i.uv) /** _GlowFlow*/;
				//col.a = 1;
				float3 dir = DynamicPointPos2.xyz - i.worldPos;
				float distance2 = dot(dir, dir);//距离的平方
				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				//return fixed4(DynamicPointColor.rgb * rsqrt(distance2), saturate(rsqrt(distance2))/4);
				return fixed4(DynamicPointColor2.rgb /** rcp(distance2)*/, /*saturate*//*(rcp(distance2)) * */saturate(1 - distance2/ DynamicPointColor2.w) / _AlphaScale*col.a);
				//return fixed4(DynamicPointColor.rgb, (1-distance2 / DynamicPointPos2.w) / _AlphaScale);
				//return fixed4(clamp(DynamicPointColor.rgb * rcp(distance2)+ 0.35, 0, 1), 1);
			}
			ENDCG
		}
	}
}
