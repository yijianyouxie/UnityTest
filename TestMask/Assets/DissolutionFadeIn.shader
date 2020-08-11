//#warning Upgrade NOTE : unity_Scale shader variable was removed; replaced 'unity_Scale.w' with '1.0'

Shader "TLStudio/Character/Character1\4_DissolutionFadeIn2" 
{
	Properties
	{
		_Color("Color", Color) = (0,0,0,1)
		_MainTex("MainTex", 2D) = "white" {}
		_Reflection("Reflection", 2D) = "white" {}
		_RimColor("RimColor", Color) = (1,1,1,1)
		_ShadeColor("Shade Color", Color) = (0.7, 0.3, 0.6, 1)

		_DissolveText("DissolveTex", 2D) = "white" {} // 溶解贴图 
		_Tile("Tile", Range(0, 1)) = 1 // 平铺值,设置溶解贴图大小 
		_DissolveSpeed("DissolveSpeed", Float) = 0.1 //速度
		//_SpeedAlpha("alphaShowSpeed", Float) = 0.1 //显现速度
		//_HiddenSpeedAlpha("alphaHideSpeed", Float) = 0.1 //消失速度
		//_Amount("DissolveLevel", Range(0, 1)) = 0 // 溶解度 
		_DisappearOffset("DisappearOffset", Range(-10, 10)) = 0  //控制真身 多久显示出来  初始值越小  越慢出来
		//_DisappearOffset2("alphaHiddenBeginOffset(DissolveRebuildBeginOffset-0.15)", Range(-10, 10)) = -0.15  //控制半透 多久消失  需要配合offset1 基本相差0.15左右的值  
		_DissSize("DissSize", Range(0, 1)) = 0.1 // 溶解范围大小 
		_DissColor("DissColor", Color) = (1,1,1,1) // 溶解颜色 
		_AddColor("AddColor", Color) = (1,1,1,1) // 改色与溶解色融合形成开始色 

		/*_AlphaRimColor("Rim Color", Color) = (0.5,0.5,0.5,0.5)
		_InnerColor("Inner Color", Color) = (0.5,0.5,0.5,0.5)
		_InnerColorPower("Inner Color Power", Range(0.0,1.0)) = 0.5
		_RimPower("Rim Power", Range(0.0,5.0)) = 2.5
		_AlphaPower("Alpha Rim Power", Range(0.0,8.0)) = 4.0
		_AllPower("All Power", Range(-10.0, 1.0)) = 0*/
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent-100"
			"RenderType" = "TransparentCutout"
			"ShadowProjector" = "true"
		}
		LOD 150

		Pass
		{
			Name "ForwardBase"
			Tags
			{
				"LightMode" = "ForwardBase"
			}
			ColorMask RGBA
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define UNITY_PASS_FORWARDBASE
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			uniform fixed4 _LightColor0;
			uniform sampler2D _Reflection; uniform half4 _Reflection_ST;
			uniform sampler2D _MainTex; uniform half4 _MainTex_ST;
			uniform fixed4 _Color;
			uniform fixed4 _RimColor;

			//溶解重塑部分
			sampler2D _DissolveText;
			float4 _DissolveText_ST;
			half _Tile; // 平铺值 
			half _Amount; // 溶解度 
			half _DissSize; // 溶解范围 
			half4 _DissColor; // 溶解颜色 
			half4 _AddColor; // 叠加色 
			float _DissolveSpeed;
			float _DisappearOffset;
			float _TimeSinceLevelLoad = 0;
			fixed3 finalColor = fixed3(1, 1, 1);

			struct VertexInput 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				half2 texcoord0 : TEXCOORD0;
			};

			struct VertexOutput
			{
				float4 pos : SV_POSITION;
				half3 uv0 : TEXCOORD0;
				half2 uv1: TEXCOORD6;
				fixed3 viewDirection : TEXCOORD1;
				fixed3 normalDir : TEXCOORD2;
				LIGHTING_COORDS(3,4)
				float3 shLight : TEXCOORD5;
			};

			VertexOutput vert(VertexInput v) 
			{
				VertexOutput o = (VertexOutput)0;
				o.uv0.xy = v.texcoord0;
				o.uv1 = ((v.texcoord0*0.4375) + 0.53135);
				o.normalDir = UnityObjectToWorldNormal(v.normal);// mul(_Object2World, float4(v.normal,0)).xyz;
				o.shLight = ShadeSH9(float4(o.normalDir * 1.0,1));
				o.viewDirection = normalize(_WorldSpaceCameraPos.xyz - mul(_Object2World, v.vertex).xyz);
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				//溶解重塑部分
				_DisappearOffset += _DissolveSpeed * (_Time.x- _TimeSinceLevelLoad);
				o.uv0.z = _DisappearOffset - (-v.vertex.x / v.vertex.w*0.5 + 0.5);  //(vertex -1,1)
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
			}

			fixed4 frag(VertexOutput i) : COLOR
			{
				i.normalDir = normalize(i.normalDir);
				/////// Vectors:
				fixed3 normalDirection = i.normalDir;
				fixed4 CtrlTex = tex2D(_MainTex,TRANSFORM_TEX(i.uv1, _MainTex));

				fixed4 _MainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
				
				fixed3 col = _MainTexColor.rgb;
				// 对裁剪材质进行采样，取R色值 
				fixed ClipTex = tex2D(_DissolveText, i.uv0 / _Tile).b;
				_Amount = i.uv0.z;
				fixed ClipAmount = ClipTex - (1 - _Amount);
				clip(ClipTex - (1 - _Amount));

				clip(_Color.a - CtrlTex.g);
				fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				////// Lighting:
				fixed attenuation = LIGHT_ATTENUATION(i)*0.9;
				fixed3 attenColor = attenuation * _LightColor0.xyz;
				/////// Diffuse:
				fixed NdotL = max(0.2, dot(normalDirection, lightDirection));
				//fixed3 indirectDiffuse = UNITY_LIGHTMODEL_AMBIENT.rgb*2;
				fixed3 directDiffuse = NdotL* attenColor*(1 - CtrlTex.b);
				fixed3 indirectDiffuse = i.shLight;
				fixed3 diffuse = (directDiffuse + indirectDiffuse) * _MainTexColor.rgb;
				////// Emissive:
				fixed rimRange = 1 - abs(dot(i.viewDirection, normalDirection));
				fixed2 ReflUV = mul(UNITY_MATRIX_V, float4(normalDirection, 0)).rg*0.5 + 0.5;
				fixed4 _Reflection_var = tex2D(_Reflection, TRANSFORM_TEX(ReflUV, _Reflection));
				//fixed ReflectionRange = tex2D(_Reflection, TRANSFORM_TEX(i.uv0, _MainTex));
				fixed3 emissive = _Color.rgb + _Reflection_var.rgb*CtrlTex.r + rimRange*rimRange*_RimColor + _MainTexColor.rgb * CtrlTex.b*0.5;

				//float3 emissive = _Color.rgb + _Reflection_var.rgb*ReflectionRange;
				fixed3 colFinal = emissive + diffuse;

				if (ClipAmount > 0)
				{
					/// Final Color:

					// 针对没有被裁剪的点，【裁剪量】小于【裁剪大小】的做处理 
					// 如果设置了叠加色，那么该色为ClipAmount/_DissSize(这样会形成渐变效果) 

					//finalColor = diffuse + emissive;

					if (ClipAmount < _DissSize)
					{
						if (_AddColor.x == 0)
							finalColor.x = _DissColor.x;
						else
							finalColor.x = ClipAmount / _DissSize;

						if (_AddColor.y == 0)
							finalColor.y = _DissColor.y;
						else
							finalColor.y = ClipAmount / _DissSize;

						if (_AddColor.z == 0)
							finalColor.z = _DissColor.z;
						else
							finalColor.z = ClipAmount / _DissSize;
						// 融合 
						//colFinal = colFinal * finalColor * 2;
						colFinal = colFinal * finalColor;
						//finalColor = (diffuse + emissive)* finalColor * 2;
					}
				}

				return fixed4(colFinal, 1);

			}
			ENDCG
		}


		Pass
		{
			Name "Caster"
			Tags{ "LightMode" = "ShadowCaster" }
			Offset 1, 1

			Fog{ Mode Off }
			ZWrite On ZTest LEqual Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"

			struct v2f 
			{
				V2F_SHADOW_CASTER;
				half2  uv : TEXCOORD1;
			};

			uniform half4 _MainTex_ST;

			v2f vert(appdata_base v)
			{
				v2f o;
				TRANSFER_SHADOW_CASTER(o)

				half2 uvTemp = ((v.texcoord*0.4375) + 0.53135);
				o.uv = TRANSFORM_TEX(uvTemp, _MainTex);
				return o;
			}

			uniform sampler2D _MainTex;
			uniform fixed _Cutoff;
			uniform fixed4 _Color;

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 texcol = tex2D(_MainTex, i.uv);
				clip(_Color.a - texcol.g);

				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}


	}
}
