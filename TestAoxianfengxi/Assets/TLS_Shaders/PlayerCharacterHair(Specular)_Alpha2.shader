Shader "TLStudio/Character/PlayerCharacterHair(Specular)_Alpha2" {
	Properties{
		_StencilValue("StencilValue", Int) = 2
		[HideInInspector]
		_OffsetM("_OffsetM", float) = 0
		[HideInInspector]
		_OffsetR("_OffsetR", float) = 0
		[Header(xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_ColorA("颜色1",Color) = (1,1,1,1)
		_ColorB("颜色2",Color) = (1,1,1,1)
		_MainTex("r:混合颜色2和颜色1;g:乘上前边混合出来的颜色;b:透明度;a:混合前边的颜色", 2D) = "white" {}
		[Space]
		[Header(xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_RimColor("边缘光颜色",Color) = (1,1,1,1)
		_RimWidth("边缘光范围", Range(0,1)) = 0.6
		
		[Space]
		[Header(xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_NormalTex("法线贴图", 2D) = "bump" {}
		_NormalScale("法线强度", Range(0,10)) = 1

		[Space]
		[Header(xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_Cutoff("透明度裁剪", Range(0,1)) = 0.5
		_AmbientColor("环境光强度", Range(0, 5)) = 0

		[Space]
		[Header(xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_Specular("高光强度", Range(0, 5)) = 0.65
		_Specular2("高光强度2", Range(0, 15)) = 0.65
		_Specular3("高光强度3", Range(0, 15)) = 0.65
		_BackSpecular("背光面高光系数最小值", Range(0, 1)) = 0.2
		_BackSpecular2("背光面高光2系数最小值", Range(0, 1)) = 0.2
		_BackSpecular3("背光面高光3系数最小值", Range(0, 1)) = 0.2
		_SpecularColor("高光颜色1", Color) = (0.2156,0.2156,0.2156,1)
		_SpecularColor2("高光颜色2", Color) = (0.2666,0.2666,0.2666,1)
		_SpecularColor3("高光颜色3", Color) = (0.2666,0.2666,0.2666,1)
		_SpecularMultiplier("高光1幂次方，控制范围", float) = 200.0
		_SpecularMultiplier2("高光2幂次方，控制范围", float) = 250.0
		_SpecularMultiplier3("高光3幂次方，控制范围", float) = 250.0
		_PrimaryShift("高光偏移1", float) = -0.6
		_SecondaryShift("高光偏移2", float) = -0.3
		_ThirdShift("高光偏移3", float) = -0.3
		_AnisoDir("g:高光偏移;b:高光2,3遮罩", 2D) = "white" {}

		[Space]
		[Header(xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_Reflection("反射贴图", 2D) = "white" {}
		_ReflectionIntension("反射强度",Range(0,3)) = 0.5

		[Space]
		[Header(xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_ColorMaskTex("颜色遮罩", 2D) = "white" {}
	}
	SubShader {
		Tags {"Queue"="Transparent+10" "RenderType"="Transparent" "ShadowProjector" = "true" }
		LOD 150	
	
		//此pass主要是写入一个深度。
		//如果没有此pass，有可能会出现，接近摄像机的mesh先渲染了，然后远离摄像机的mesh后被渲染后冲掉了前面渲染的那个。
		//pass的结果是保留离摄像机最近的面。
		Pass{
			ZWrite On
			ColorMask 0
			Stencil
			{
				Ref[_StencilValue]         // 写入Stencil的值为1
				Comp always   // 总是写入
				Pass replace  // 替换现有Stencil值
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			//#pragma only_renderers gles3 metal d3d11
		       
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 texcoord : TEXCOORD0;
   
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Cutoff;
			v2f vert(appdata_full v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
				
				return o;
			}
				
			float4 frag(v2f i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.texcoord.xy);
				clip(col.b - _Cutoff);
				return float4(0, 0, 0, 1);
			}
			ENDCG
		}
		Pass {  
			Tags { "LightMode" = "ForwardBase" }
			Offset [_OffsetM],[_OffsetR]//一个大于0的offset值会吧模型推离摄像机更远的位置。相反小于0的offset会拉近模型。
			cull back
			ZWrite off
			Blend SrcAlpha OneMinusSrcAlpha
			Stencil
			{
				Ref[_StencilValue]         // 写入Stencil的值为1
				Comp always   // 总是写入
				Pass replace  // 替换现有Stencil值
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			//#pragma only_renderers gles3 metal d3d11
			#pragma multi_compile_fwdbase nolightmap nodynlightmap noshadow nodirlightmap
			#pragma skip_variants  DIRLIGHTMAP_SEPARATE VERTEXLIGHT_ON  DIRLIGHTMAP_COMBINE 
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"	
			struct v2f {
				float4 vertex : SV_POSITION;
				float4 texcoord : TEXCOORD0;		
				float3 viewDirection : TEXCOORD1;			
				float3 SHLighting : COLOR0;
             
				float4 TtoW0 : TEXCOORD2;  
				float4 TtoW1 : TEXCOORD3;  
				float4 TtoW2 : TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NormalTex;
			float4 _NormalTex_ST;
			float _NormalScale;
			float4 _ColorA;
			float4 _ColorB;

			float _Cutoff;
			float4 _RimColor;
			float _RimWidth; 
			float _AmbientColor;
			sampler2D _AnisoDir;
			float4 _AnisoDir_ST;
			
			//高光强度
			float _Specular, _Specular2, _Specular3;
			//背面高光系数
			float _BackSpecular, _BackSpecular2, _BackSpecular3;
			//高光颜色
			float4 _SpecularColor, _SpecularColor2, _SpecularColor3;
			//高光范围
			float _SpecularMultiplier, _SpecularMultiplier2, _SpecularMultiplier3;
			//高光偏移
			float _PrimaryShift, _SecondaryShift, _ThirdShift;

			sampler2D _Reflection;
			float4 _Reflection_ST;
			float _ReflectionIntension;

			sampler2D _ColorMaskTex;
			float4 _ColorMaskTex_ST;

			//获取头发高光
			float StrandSpecular ( float3 T, float3 V, float3 L, float exponent)
			{
				float3 H = normalize(L + V);
				float dotTH = dot(T, H);
				float sinTH = sqrt(1 - dotTH * dotTH);
				float dirAtten = smoothstep(-1, 0, dotTH);
				return dirAtten * pow(sinTH, exponent);
			}
			
			//沿着法线方向调整Tangent方向
			float3 ShiftTangent ( float3 T, float3 N, float shift)
			{
				return normalize(T + shift * N);
			}
			v2f vert (appdata_full v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord.xy = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
				o.texcoord.zw = TRANSFORM_TEX(v.texcoord.xy, _NormalTex);
				float3 normal =  UnityObjectToWorldNormal(v.normal);  
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex);  
				o.viewDirection = normalize(WorldSpaceViewDir(float4(v.vertex.xyz, 1)));	
				o.SHLighting= ShadeSH9(float4(normal,1)) ;                    
				float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				float3 worldBinormal = cross(normal, worldTangent) * v.tangent.w;
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, normal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, normal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, normal.z, worldPos.z);  
				return o;
			}
				
			float4 frag (v2f i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.texcoord.xy);	              
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				float3 lightDirection =  normalize(UnityWorldSpaceLightDir(worldPos));
                
				float3x3 matrixTBN = float3x3(i.TtoW0.xyz, i.TtoW1.xyz, i.TtoW2.xyz);
				float3 normalTangent = UnpackNormal(tex2D(_NormalTex, i.texcoord.zw));
				normalTangent.xy = normalTangent.xy * _NormalScale;
				normalTangent.z = sqrt(1 - saturate(dot(normalTangent.xy, normalTangent.xy)));
				float3 worldNormal0 = mul(matrixTBN, normalTangent);

				float3 worldNormal = normalize(float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z));    
				float3 worldTangent = normalize(float3(i.TtoW0.x, i.TtoW1.x, i.TtoW2.x));
				float3 worldBinormal = normalize(float3(i.TtoW0.y, i.TtoW1.y, i.TtoW2.y));
			
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float dotProduct = 1 - max(0, dot(worldNormal, worldViewDir));
				float rim = smoothstep(1 - _RimWidth, 1.0, dotProduct);					
				float diffLight = max(0, (dot(worldNormal0, lightDirection))) * _LightColor0.rgb;
				//float diffLight = dot(worldNormal0, lightDirection) * _LightColor0.rgb;
				float4 hairColor = lerp(_ColorB, _ColorA, col.r) * col.g;
				float4 Albedo = hairColor;// lerp(hairColor, col, col.a);
				float3 ambient = i.SHLighting * Albedo * _AmbientColor;

				float3 spec = tex2D(_AnisoDir, i.texcoord.xy).rgb;
				//计算切线方向的偏移度
				float shiftTex = spec.g;
				float3 t1 = ShiftTangent(worldTangent, worldNormal0, _PrimaryShift + shiftTex);
				float3 t2 = ShiftTangent(worldTangent, worldNormal0, _SecondaryShift + shiftTex);
				float3 t3 = ShiftTangent(worldTangent, worldNormal0, _ThirdShift + shiftTex);

				//计算高光强度
				float3 spec1 = StrandSpecular(t1, worldViewDir, lightDirection, _SpecularMultiplier)* _SpecularColor;
				float3 spec2 = StrandSpecular(t2, worldViewDir, lightDirection, _SpecularMultiplier2)* _SpecularColor2;
				float3 spec3 = StrandSpecular(t3, worldViewDir, lightDirection, _SpecularMultiplier3)* _SpecularColor3;

				float NDotD = dot(worldNormal, lightDirection);
				float back = clamp(NDotD, _BackSpecular, 1);
				float back2 = clamp(NDotD, _BackSpecular2, 1);
				float back3 = clamp(NDotD, _BackSpecular3, 1);

				float4 finalSpec = 0;
				finalSpec.rgb = spec1 * _Specular * back;//第一层高光
				finalSpec.rgb += spec2 * spec.b * _Specular2 * back2;//第二层高光，spec.b用于添加噪点
				finalSpec.rgb += spec3 * spec.b * _Specular3 * back3;//第三层高光，spec.b用于添加噪点
				finalSpec.rgb *= _LightColor0.rgb;//受灯光影响

				float2 ReflUV = mul(UNITY_MATRIX_V, float4(worldNormal, 0)).rg*0.5 + 0.5;
				float4 _Reflection_var = tex2D(_Reflection, TRANSFORM_TEX(ReflUV, _Reflection));
				float4 emissive = _Reflection_var*_ReflectionIntension;

				//颜色遮罩
				float4 colorMaskCol = tex2D(_ColorMaskTex, TRANSFORM_TEX(i.texcoord.xy, _ColorMaskTex));
                    
				float4 final = /*diffLight * Albedo * colorMaskCol +*/ finalSpec * 0.7 + float4(ambient, 1) + rim * _RimColor + emissive;
    
				return float4(final.rgb, col.b);
			}
			ENDCG
		}
		/*Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#pragma skip_variants SHADOWS_DEPTH SHADOWS_CUBE

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f {
				V2F_SHADOW_CASTER;
			};

			float4 _MainTex_ST;
			v2f vert(appdata v)
			{
				v2f o;
				TRANSFER_SHADOW_CASTER(o);
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}*/
	}
	FallBack off
}
