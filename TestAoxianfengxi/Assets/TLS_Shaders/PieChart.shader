Shader "UI/PieChart"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_SlicesCount("Slices Count", Int) = 3
		_Color0("Color 0", Color) = (1,0,0,1)
		_Color1("Color 1", Color) = (0,1,0,1)
		_Color2("Color 2", Color) = (0,0,1,1)
		_Color3("Color 3", Color) = (1,1,0,1)
		_Color4("Color 4", Color) = (1,0,1,1)
	}
		SubShader
	{
		Tags
		{
			"RenderType" = "Transparent" 
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
		}
		LOD 100
			
		Pass
	{
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"

		struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
	};

	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;
		return o;
	}
	sampler2D _MainTex;
	fixed4 _Color0;
	fixed4 _Color1;
	fixed4 _Color2;
	fixed4 _Color3;
	fixed4 _Color4;
	int _SlicesCount;

	fixed4 frag(v2f i) : SV_Target
	{
		float totalAngle = 360.0 / _SlicesCount;
		float angle = atan2(i.uv.x - 0.5 , i.uv.y - 0.5) * (180 / 3.14159f) + totalAngle; // 转换到Unity坐标系
		angle = angle < 0 ? angle + 360 : angle; // 确保角度在0-360范围内

		
		int sliceIndex = floor(angle / totalAngle);

		if (sliceIndex >= _SlicesCount)
			sliceIndex = _SlicesCount - 1; // 防止越界
		fixed4 MainCol = tex2D(_MainTex, i.uv);
		fixed4 col;
		//switch (sliceIndex)
		//{
		//	case 0: col = _Color0; break;
		//	case 1: col = _Color1; break;
		//	case 2: 
		//		float2 uv = i.uv * 2.0 - 1.0; // 将uv从[0,1]转换到[-1,1]
		//		float2 center = (0.5, 0.5);
		//		float distToCenter = distance(i.uv , center);
		//		
		//		float index = step(0.2f, distToCenter) + step(0.35f, distToCenter); // 生成0, 1, 或 2基于distToCenter的值
		//		col = _Color2 * (index == 0 ? 1 : 0) + _Color3 * (index == 1 ? 1 : 0) + _Color4 * (index == 2 ? 1 : 0);

		//		break;
		//	default: col = fixed4(0, 0, 0, 0); break; // 防御性编程
		//}


		float2 uv = i.uv;
		// 对于 sliceIndex 为 0 和 1 的情况，直接赋值颜色
		if (sliceIndex == 0) {
			col = _Color0;
		}
		else if (sliceIndex == 1) {
			col = _Color1;
		}
		else if (sliceIndex == 2) { // 处理 sliceIndex 为 2 的特殊情况
			float2 uvTransformed = uv * 2.0 - 1.0; // 将uv从 [0,1] 转换到 [-1,1]
			float2 center = float2(0.5, 0.5);
			float distToCenter = distance(uv, center);

			// 生成 0, 1, 或 2 基于 distToCenter 的值
			float index = step(0.2f, distToCenter) + step(0.35f, distToCenter);

			// 根据 index 的值选择颜色
			col = _Color2 * (index == 0 ? 1 : 0) + _Color3 * (index == 1 ? 1 : 0) + _Color4 * (index == 2 ? 1 : 0);
		}
		else {
			col = fixed4(0, 0, 0, 0); // 防御性编程
		}
		col.a = MainCol.a;
		return col ;
	}
		ENDCG
	}
	}
		FallBack "Diffuse"
}