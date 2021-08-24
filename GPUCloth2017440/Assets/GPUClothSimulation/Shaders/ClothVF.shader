Shader "Unlit/ClothVF"
{
	Properties
	{
		_Color("Color", Color) = (0,0,0,1)
		_MainTex ("Texture", 2D) = "white" {}
		_PositionTex("_PositionTex", 2D) = "black" {}
		_NormalTex("NormalTex", 2D) = "bump" {}
		_NormalScale("NormalScale", Range(1,3)) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 lightDir : TEXCOORD1;
			};

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _PositionTex;
			float4 _PositionTex_ST;
			sampler2D _NormalTex;
			float4 _NormalTex_ST;
			float _NormalScale;
			
			v2f vert (appdata_tan v)
			{
				v2f o;
				//这里修改的都是模型的顶点位置和模型的顶点法线，是模型坐标系
				// 获取位置信息
				v.vertex.xyz = tex2Dlod(_PositionTex, float4(v.texcoord.xy, 0.0, 0.0)).xyz;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				//这个宏为我们定义好了模型空间到切线空间的转换矩阵rotation
				TANGENT_SPACE_ROTATION;
				//ObjectSpaceLightDir可以把光线方向转化到模型空间，然后通过rotation再转化到切线空间
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);

				float3 tangentNormal = UnpackNormal(tex2D(_NormalTex, i.uv));
				tangentNormal.xy = tangentNormal.xy * _NormalScale;
				float3 tangentLightDir = normalize(i.lightDir);
				//fixed3 lambert = 0.5 * dot(tangentNormal, tangentLightDir) + 0.5;
				fixed3 lambert = max(0, dot(tangentNormal, tangentLightDir));
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 diffuse = lambert * _Color.xyz * _LightColor0.xyz + ambient*_Color.xyz;

				return fixed4(col.rgb * diffuse, 1);
			}
			ENDCG
		}
	}
}
