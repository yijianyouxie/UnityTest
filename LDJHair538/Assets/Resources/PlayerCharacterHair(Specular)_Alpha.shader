﻿Shader "TLStudio/Character/PlayerCharacterHair(Specular)_Alpha" {
	Properties{
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
		_Specular2("高光强度2", Range(0, 5)) = 0.65
		_Specular3("高光强度3", Range(0, 5)) = 0.65
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
		Tags {"Queue"="Transparent" "RenderType"="Transparent" "ShadowProjector" = "true" }
		LOD 150	
	
		Pass{
			ZWrite On
			ColorMask 0

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			//#pragma only_renderers gles3 metal d3d11
		       
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
   
			};

			sampler2D _MainTex;
			half4 _MainTex_ST;
			float _Cutoff;
			v2f vert(appdata_full v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
				
				return o;
			}
				
			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.texcoord.xy);
				clip(col.b - _Cutoff);
				return half4(0, 0, 0, 1);
			}
			ENDCG
		}
		Pass {  
			Tags { "LightMode" = "ForwardBase" }
			Offset -1,-1//一个大于0的offset值会吧模型推离摄像机更远的位置。相反小于0的offset会拉近模型。
			cull back
			ZWrite off
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			//#pragma only_renderers gles3 metal d3d11
			#pragma multi_compile_fwdbase nolightmap nodynlightmap noshadow nodirlightmap
			#pragma skip_variants  DIRLIGHTMAP_SEPARATE VERTEXLIGHT_ON  DIRLIGHTMAP_COMBINE 
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"	
			struct v2f {
				float4 vertex : SV_POSITION;
				half4 texcoord : TEXCOORD0;		
				float3 viewDirection : TEXCOORD1;			
				fixed3 SHLighting : COLOR0;
             
				float4 TtoW0 : TEXCOORD2;  
				float4 TtoW1 : TEXCOORD3;  
				float4 TtoW2 : TEXCOORD4;
			};

			sampler2D _MainTex;
			half4 _MainTex_ST;
			sampler2D _NormalTex;
			float4 _NormalTex_ST;
			half _NormalScale;
			fixed4 _ColorA;
			fixed4 _ColorB;

			float _Cutoff;
			fixed4 _RimColor;
			float _RimWidth; 
			float _AmbientColor;
			sampler2D _AnisoDir;
			float4 _AnisoDir_ST;
			
			//高光强度
			half _Specular, _Specular2, _Specular3;
			//高光颜色
			half4 _SpecularColor, _SpecularColor2, _SpecularColor3;
			//高光范围
			half _SpecularMultiplier, _SpecularMultiplier2, _SpecularMultiplier3;
			//高光偏移
			half _PrimaryShift, _SecondaryShift, _ThirdShift;

			sampler2D _Reflection;
			half4 _Reflection_ST;
			fixed _ReflectionIntension;

			sampler2D _ColorMaskTex;
			half4 _ColorMaskTex_ST;

			//获取头发高光
			fixed StrandSpecular ( fixed3 T, fixed3 V, fixed3 L, fixed exponent)
			{
				fixed3 H = normalize(L + V);
				fixed dotTH = dot(T, H);
				fixed sinTH = sqrt(1 - dotTH * dotTH);
				fixed dirAtten = smoothstep(-1, 0, dotTH);
				return dirAtten * pow(sinTH, exponent);
			}
			
			//沿着法线方向调整Tangent方向
			fixed3 ShiftTangent ( fixed3 T, fixed3 N, fixed shift)
			{
				return normalize(T + shift * N);
			}
			v2f vert (appdata_full v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.texcoord.xy = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
				o.texcoord.zw = TRANSFORM_TEX(v.texcoord.xy, _NormalTex);
				float3 normal =  UnityObjectToWorldNormal(v.normal);  
				float3 worldPos = mul(_Object2World, v.vertex);  
				o.viewDirection = normalize(WorldSpaceViewDir(float4(v.vertex.xyz, 1)));	
				o.SHLighting= ShadeSH9(float4(normal,1)) ;                    
				float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(normal, worldTangent) * v.tangent.w;
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, normal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, normal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, normal.z, worldPos.z);  
				return o;
			}
				
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.texcoord.xy);	              
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 lightDirection =  normalize(UnityWorldSpaceLightDir(worldPos));
                
				float3x3 matrixTBN = float3x3(i.TtoW0.xyz, i.TtoW1.xyz, i.TtoW2.xyz);
				float3 normalTangent = UnpackNormal(tex2D(_NormalTex, i.texcoord.zw));
				normalTangent.xy = normalTangent.xy * _NormalScale;
				normalTangent.z = sqrt(1 - saturate(dot(normalTangent.xy, normalTangent.xy)));
				float3 worldNormal0 = mul(matrixTBN, normalTangent);

				fixed3 worldNormal = normalize(half3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z));    
				fixed3 worldTangent = normalize(half3(i.TtoW0.x, i.TtoW1.x, i.TtoW2.x));
				fixed3 worldBinormal = normalize(half3(i.TtoW0.y, i.TtoW1.y, i.TtoW2.y));
			
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float dotProduct = 1 - max(0, dot(worldNormal, worldViewDir));
				fixed rim = smoothstep(1 - _RimWidth, 1.0, dotProduct);					
				//fixed diffLight = max(0, (dot(worldNormal0, lightDirection))) * _LightColor0.rgb;
				fixed diffLight = dot(worldNormal0, lightDirection) * _LightColor0.rgb;
				fixed4 hairColor = lerp(_ColorB, _ColorA, col.r) * col.g;
				fixed4 Albedo = lerp(hairColor, col, col.a);
				fixed3 ambient = i.SHLighting * Albedo * _AmbientColor;

				fixed3 spec = tex2D(_AnisoDir, i.texcoord.xy).rgb;
				//计算切线方向的偏移度
				half shiftTex = spec.g;
				half3 t1 = ShiftTangent(worldTangent, worldNormal, _PrimaryShift + shiftTex);
				half3 t2 = ShiftTangent(worldTangent, worldNormal, _SecondaryShift + shiftTex);
				half3 t3 = ShiftTangent(worldTangent, worldNormal, _ThirdShift + shiftTex);

				//计算高光强度
				half3 spec1 = StrandSpecular(t1, worldViewDir, lightDirection, _SpecularMultiplier)* _SpecularColor;
				half3 spec2 = StrandSpecular(t2, worldViewDir, lightDirection, _SpecularMultiplier2)* _SpecularColor2;
				half3 spec3 = StrandSpecular(t3, worldViewDir, lightDirection, _SpecularMultiplier3)* _SpecularColor3;

				fixed4 finalSpec = 0;
				finalSpec.rgb = spec1 * _Specular;//第一层高光
				finalSpec.rgb += spec2 * spec.b * _Specular2;//第二层高光，spec.b用于添加噪点
				finalSpec.rgb += spec3 * spec.b * _Specular3;//第三层高光，spec.b用于添加噪点
				finalSpec.rgb *= _LightColor0.rgb;//受灯光影响

				half2 ReflUV = mul(UNITY_MATRIX_V, float4(worldNormal, 0)).rg*0.5 + 0.5;
				fixed4 _Reflection_var = tex2D(_Reflection, TRANSFORM_TEX(ReflUV, _Reflection));
				fixed4 emissive = _Reflection_var*_ReflectionIntension;

				//颜色遮罩
				fixed4 colorMaskCol = tex2D(_ColorMaskTex, TRANSFORM_TEX(i.texcoord.xy, _ColorMaskTex));
                    
				fixed4 final = diffLight * Albedo * colorMaskCol + finalSpec + half4(ambient, 1) + rim * _RimColor + emissive;
    
				return half4(final.rgb, col.b);
			}
			ENDCG
		}
		Pass
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

			half4 _MainTex_ST;
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
		}
	}
	FallBack off
}
