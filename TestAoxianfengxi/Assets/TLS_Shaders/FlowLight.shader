// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Effect/FlowLight2"
{
		Properties
		{
			_MainTex("Main_Texture", 2D) = "white" {}
			_Flow_Texture("Flow_Texture", 2D) = "white" {}
			_Color("Color", Color) = (1,1,1,1)
			_SpeedX("SpeedX", Float) = 1
			_SpeedY("SpeedY", Float) = 1
			//_Vis("Visiable" , Range(0,1)) = 0.1
		}
		SubShader
		{
				Tags
				{
					"Queue" = "Transparent"
					"IgnoreProjector" = "False"
					"RenderType" = "Transparent"
					"ShadowProjector" = "true"
				}
				LOD 150
				Cull Back
				//zwrite off
				Blend SrcAlpha OneMinusSrcAlpha
				Pass
				{
					CGPROGRAM
					#pragma vertex vert
					#pragma fragment frag
					#pragma fragmentoption ARB_precision_hint_fastest
					#include "UnityCG.cginc"          
					sampler2D _MainTex;
					sampler2D _Flow_Texture;
					fixed4	_MainTex_ST;
					fixed4	_Flow_Texture_ST;

					fixed4	_Color;
					fixed	_SpeedX;
					fixed	_SpeedY;
					//fixed	_Vis;


					struct vertOut
					{
						fixed4 pos	: SV_POSITION;
						fixed2 uv	: TEXCOORD0;
						fixed2 uv2	: TEXCOORD1;
					};

					vertOut vert(appdata_base v)
					{
						vertOut o;
						o.pos = UnityObjectToClipPos(v.vertex);
						o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
						fixed2 uv2 = TRANSFORM_TEX(v.texcoord, _Flow_Texture);
						//if (_Vis>=0.1)
						//{
							fixed modtime = fmod(_Time.x,60) ; 
							o.uv2.x = uv2.x + modtime * _SpeedX;
							o.uv2.y = uv2.y + modtime * _SpeedY;
						//}
						//else
						//{
						//	o.uv2.x = uv2.x;
						//	o.uv2.y = uv2.y;
						//}
						return o;
					}

					fixed4 frag(vertOut i) : COLOR
					{
						fixed4 c;
						fixed4 Tex2D0 = tex2D(_MainTex, i.uv);
						fixed4 Tex2D1 = tex2D(_Flow_Texture, i.uv2);
						fixed4 Multiply6 = _Color * Tex2D1;
						//fixed4 Add0 = Multiply6*Tex2D1.a * _Vis + Tex2D0;
						fixed4 Add0 = Multiply6*Tex2D1.a + Tex2D0;
						c.a		= Tex2D0.a;
						c.rgb	= Add0.rgb;
						return c;
					}
					ENDCG
				}
		}
		//fallback "Mobile/Unlit (Supports Lightmap)"
}