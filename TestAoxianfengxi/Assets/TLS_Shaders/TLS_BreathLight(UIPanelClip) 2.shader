Shader "TLStudio/Effect/BreathLight(UIPanelClip) 2"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
        _Color("Color",Color) = (1,1,1,1)
      	_frequency("Frequency",float) = 1
		_ClipRange0("_ClipRange0", Vector) = (0.0, 0.0, 1.0, 1.0)
		_ClipArgs0("_ClipArgs0", Vector) = (1000.0, 1000.0, 0.0, 1.0)
		_ClipRange1("_ClipRange1", Vector) = (0.0, 0.0, 1.0, 1.0)
		_ClipArgs1("_ClipArgs1", Vector) = (1000.0, 1000.0, 0.0, 1.0)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
		LOD 100
		ZWrite Off
		Cull Off
		Blend SrcAlpha One
		Pass
		{
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
				float4 worldPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
            fixed4 _Color;
			float _frequency;
			float4 _ClipRange0;
			float4 _ClipArgs0;
			float4 _ClipRange1;
			float4 _ClipArgs1;

			float2 Rotate(float2 v, float2 rot)
			{
				float2 ret;
				ret.x = v.x * rot.y - v.y * rot.x;
				ret.y = v.x * rot.x + v.y * rot.y;
				return ret;
			}
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				float2 clipSpace = o.vertex.xy / o.vertex.w;
				clipSpace = (clipSpace.xy + 1) * 0.5;
				o.worldPos.xy = clipSpace * _ClipRange0.zw + _ClipRange0.xy;
				o.worldPos.zw = Rotate(clipSpace, _ClipArgs1.zw) * _ClipRange1.zw + _ClipRange1.xy;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
                col = col*((sin(_Time.w*_frequency)+3)*0.5)*col.a*_Color;
				float2 factor = (float2(1.0, 1.0) - abs(i.worldPos.xy)) * _ClipArgs0.xy;
				float f = min(factor.x, factor.y);
				factor = (float2(1.0, 1.0) - abs(i.worldPos.zw)) * _ClipArgs1.xy;
				f = min(f, min(factor.x, factor.y));
				col.a *= clamp(f, 0.0, 1.0);
				return col;
			}
			ENDCG
		}
	}
}
