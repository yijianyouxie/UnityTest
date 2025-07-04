Shader "TLStudio/Transparent/FlagAni_SelfLuminus"
{
	Properties
	{
		_Color("Color。a通道控制透明",Color) = (1.0, 1.0, 1.0, 1.0)
		_MainTex("Base (RGB).a通道控制是否晃动", 2D) = "white" {}
		_Mask("Mask (R)", 2D) = "white" {}
		_Illumin("自发光的强度",float) = 0
		_IlluminColor("自发光颜色", Color) = (1,1,1,1)
		_Frequence("频率",Float) = 1
		_Amplitude("振幅",Float) = 0.3
		_Speed("速度",Float) = 3
	}
	SubShader
	{
		Tags{ "Queue" = "AlphaTest+50" "IgnoreProjector" = "False" "RenderType" = "TransparentCutout" }
		LOD 200
		Cull Off

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma skip_variants FOG_EXP
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			fixed4 _Color;
			sampler2D _MainTex , _Mask;
			float4 _MainTex_ST;
			fixed4 _IlluminColor;
			float _Illumin;
			uniform float _Frequence;
			uniform float _Amplitude;
			uniform float _Speed;

			float4 vertFlagAni(float4 vertex, float a)
			{
				vertex.y = vertex.y + a*sin((vertex.z - _Time.y * _Speed) * _Frequence) * (vertex.z * _Amplitude);

				return vertex;
			}
			
			v2f vert (appdata v)
			{
				v2f o;

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				fixed4 n = tex2Dlod(_MainTex, half4(o.uv, 0, 0));
				v.vertex = vertFlagAni(v.vertex, n.a);

				o.vertex = UnityObjectToClipPos(v.vertex);
				if(UseHeightFog > 0)
				{
					TL_TRANSFER_FOG(o,o.vertex, v.vertex);
				}else
				{
					UNITY_TRANSFER_FOG(o,o.vertex);				
				}
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv)*_Color.rgba;
				fixed4 e = tex2D(_Mask, i.uv);
				col.rgb = col.rgb*_Color.rgb + _Illumin*e.rgb*col.rgb*_IlluminColor.rgb;
				col.a = _Color.a;
				// apply fog
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(i.fogCoord, col.rgb);
				}else
				{
					UNITY_APPLY_FOG(i.fogCoord, col);				
				}
				return col;
			}
			ENDCG
		}
	}
}
