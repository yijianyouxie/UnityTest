// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/BillBoard1"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
        _size ("size",float) = 1
        _growRate ("GrowRate",float) = 1
        _limitationValue("Limitation Value",float) = 1
        _offset("Offset",float) = 1
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "RenderType"="Transparent" }
		LOD 100
		cull off
		Pass
		{
             blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
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

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _size,_growRate;
			float _limitationValue;
			float _offset;
			
			v2f vert (appdata v)
			{
				v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				float4 GeomPoint = UnityObjectToClipPos(float4(0,0,0,1));
				//o.vertex = v.vertex*float4(1,_ScreenParams.x/_ScreenParams.y,1,1)*float4(_size*max(1,GeomPoint.w*_growRate/10),_size*max(1,GeomPoint.w*_growRate/10),1,1)+float4(GeomPoint.x/GeomPoint.w,GeomPoint.y/GeomPoint.w,0.01,0);

				//o.vertex = v.vertex*float4(1,_ScreenParams.x/_ScreenParams.y,1,1)*float4(_size*min(_limitationValue,max(1,GeomPoint.w*_growRate/10)),_size*min(_limitationValue,max(1,GeomPoint.w*_growRate/10)),1,1)+float4(GeomPoint.x/GeomPoint.w,GeomPoint.y/GeomPoint.w,0.1,0);
				float value = min(_limitationValue,max(1,GeomPoint.w*_growRate/10));
				o.vertex = v.vertex*float4(1,_ScreenParams.x/_ScreenParams.y,1,1)*float4(_size*value,_size*value,1,1)+float4(GeomPoint.x/GeomPoint.w,GeomPoint.y/GeomPoint.w,0.1,0);
				//o.vertex.y = o.vertex.y + _offset*_limitationValue/value;
				o.vertex.y = o.vertex.y + _offset*GeomPoint.w*0.1;
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
				fixed4 col = tex2D(_MainTex,i.uv);
				//clip(col.a -0.8);
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
