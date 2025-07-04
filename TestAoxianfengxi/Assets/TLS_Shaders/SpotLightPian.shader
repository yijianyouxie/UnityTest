Shader "DynamicLight/SpotLightPian"
{
	Properties
	{
		[MaterialEnum(UnityEngine.Rendering.BlendMode)] _SrcBlend("源混合因子SrcBlend", Float) = 1
		[MaterialEnum(UnityEngine.Rendering.BlendMode)] _DstBlend("目标混合因子DestBlend", Int) = 10
		_MainTex ("Texture", 2D) = "white" {}
		_AlphaScale("AlphaScale", Range(0.1, 10)) = 10
		_Speed("Speed", Range(0, 10)) = 0.1
		//_GlowFlow("_GlowFlow", Range(0,1)) = 0
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" }
		LOD 100

		Pass
		{
			//Blend SrcColor OneMinusSrcColor
			//Blend One OneMinusSrcAlpha
			Blend[_SrcBlend][_DstBlend]
			//Blend SrcAlpha one
			Cull Off
			ZWrite Off
			//ZTest Always
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
			half4 DynamicPointDir2;//xyz方向
			half4 DynamicPointPos2;//xyz位置
			fixed4 DynamicPointColor2;//rgb颜色
			float _AlphaScale;
			float _Speed;
			//float _GlowFlow;
			
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
				// sample the texture
				float2 topCenter = float2(0.5, 0);
				i.uv -= topCenter;
				i.uv.x /= (1 - i.uv.y + 0.0001);
				i.uv += topCenter;
				i.uv += float2(_Time.y, 0) * _Speed;
				fixed4 col = tex2D(_MainTex, i.uv);
				//col.a = _GlowFlow <= 0 ? 1 : col.a;
				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				float3 dir = DynamicPointPos2.xyz - i.worldPos;
				float distance2 = dot(dir, dir);//距离的平方
				fixed nearClipAlpha = (1 - saturate(DynamicPointPos2.w - distance2)*3);
				//spot
				half angle = dot(normalize(DynamicPointDir2.xyz), normalize(dir));
				fixed3 color = 0;
				if (angle >= DynamicPointDir2.w)
				{
					color += DynamicPointColor2.rgb /** lerp(0,1,saturate((angle - DynamicPointDir2.w) / (1 - DynamicPointDir2.w)))*/;
					//return fixed4(color, 0);
				}
				//else
				{
					//return fixed4(color, lerp(0, 1, saturate((angle - DynamicPointDir2.w) / (1 - DynamicPointDir2.w))) / _AlphaScale*rsqrt(distance2));
					fixed4 finalColor = fixed4(color, lerp(0, 1, saturate((angle - DynamicPointDir2.w) / (1 - DynamicPointDir2.w))) / _AlphaScale * saturate(1 - distance2 / DynamicPointColor2.w)*nearClipAlpha*col.a);

					return fixed4(finalColor.rgb*finalColor.a, finalColor.a);
				}
			}
			ENDCG
		}
	}
}
