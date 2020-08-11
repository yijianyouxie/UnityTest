Shader "CLX/HdrSky"
{
	Properties 
	{
		_SkydomeMieTex ("SkyMieTexture", 2D) = "white" {}
		_SkydomeRayleighTex("SkyRayleighTexture", 2D) = "white" {}
		_MoonMapTex("MoonMap", 2D) = "white" {}
		_PartialMieInScatteringConst("MieConstant", Vector) = (0, 0, 0, 0)
		_PartialRayleighInScatteringConst("RayleighConstant", Vector) = (0, 0, 0, 0)
		_PhaseFunctionConstants("PhaseFunctionConstants", Vector) = (0, 0, 0, 0)
		//_NightSkyColBase("NightSkyColBase", Vector) = (0, 0, 0, 0)
		//_NightSkyColDelta("NightSkyColDelta", Vector) = (0, 0, 0, 0)
		//_NightMoonDirSize("NightMoonDirSize", Vector) = (0, 0, 0, 0)
		//_NightMoonColor("NightMoonColor", Vector) = (0, 0, 0, 0)
		//_NightMoonInnerCoronaColorScale("NightMoonInnerCoronaColorScale", Vector) = (0, 0, 0, 0)
		//_NightMoonOuterCoronaColorScale("NightMoonOuterCoronaColorScale", Vector) = (0, 0, 0, 0)
	}

	SubShader
	{
		LOD 200
		Tags{ "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" }
		Cull Off ZWrite Off

		// 大气散射层
		Pass
		{
			CGPROGRAM
			  #pragma vertex vert
			  #pragma fragment fragSkyPS
			#include "UnityCG.cginc"
            #include "Lighting.cginc"
				#include "CYUnityCG.cginc"
				#pragma multi_compile_fog
				#pragma multi_compile __ CY_FOG_ON

		struct v2f_hdr
		{
			float4 Position:SV_Position;
			float4 packedTC:TEXCOORD0;
			float3 skyDir:TEXCOORD1;
			float2 mapTC:TEXCOORD2;
			float4 ViewDirection:TEXCOORD3;
			UNITY_FOG_COORDS(4)
				CY_FOG_COORDS(5)
		};

		float4 _PartialRayleighInScatteringConst;
		float4 _PartialMieInScatteringConst;
		float4 _PhaseFunctionConstants;
		//float4 _NightMoonColor;
		//float4 _NightMoonInnerCoronaColorScale;
		//float4 _NightMoonOuterCoronaColorScale;
		//float4 _NightSkyColBase;
		//float4 _NightSkyColDelta;
		//float4 _NightMoonDirSize;

		v2f_hdr vert(appdata_img v)
		{
			v2f_hdr OUT;
			(OUT) = ((v2f_hdr)0);

			float4 vPos = v.vertex;
			float4 worldPos = float4(mul(unity_ObjectToWorld, vPos).xyz,1);
			OUT.Position = UnityObjectToClipPos(v.vertex);

			float2 baseTC = v.texcoord.xy;
			float2 moonTC = float2(0.0,0.0);

#if 0	// night
			float3 NX = cross(float3(0,1,0),_NightMoonDirSize.xyz);
			float3 NY = cross(_NightMoonDirSize.xyz,NX);
			(NX) = (normalize((-(NX))));
			(NY) = (normalize((-(NY))));
			(moonTC) = (((float2(dot(NX,vPos),dot(NY,vPos)))*(_NightMoonDirSize.w)));
			(moonTC) = (((((moonTC)*(0.5))) + (0.5)));
			if (((dot(vPos,_NightMoonDirSize.xyz))<(0)))
				(moonTC) = ((-(100000.0)));
#endif

			(OUT.packedTC) = (float4(baseTC,moonTC.yx));
			(OUT.skyDir) = (vPos);
			(OUT.ViewDirection.xyz) = (((worldPos.xyz) - (_WorldSpaceCameraPos.xyz)));

			float3 dis = worldPos.xyz - _WorldSpaceCameraPos;
			CY_TRANSFER_FOG(OUT, dis.xyz, worldPos.y);
			UNITY_TRANSFER_FOG(OUT, OUT.Position);

			return OUT;
		}

		sampler2D _SkydomeMieTex;
		sampler2D _SkydomeRayleighTex;
		sampler2D _MoonMapTex;


		float4 fragSkyPS(v2f_hdr IN) : SV_Target
		{
			float2 baseTC = IN.packedTC.xy;
			float2 moonTC = IN.packedTC.wz;
			float3 skyDir = normalize(IN.skyDir);
			float3 V = normalize((-(IN.ViewDirection.xyz)));
			float4 OUT = float4(0,0,0,0);
			float Alpha = 0;
			{
				float4 ColorMie = tex2D(_SkydomeMieTex, baseTC.xy);
				float4 ColorRayleigh = tex2D(_SkydomeRayleighTex, baseTC.xy);
				{
					(ColorMie.xyz) = (((ColorMie.rgb)*(((((ColorMie.a)*(ColorMie.a)))*(_PartialRayleighInScatteringConst.w)))));
					(ColorRayleigh.xyz) = (((ColorRayleigh.rgb)*(((((ColorRayleigh.a)*(ColorRayleigh.a)))*(_PartialRayleighInScatteringConst.w)))));
				}
				float miePart_g_2 = _PhaseFunctionConstants.x;
				float miePart_g2_1 = _PhaseFunctionConstants.y;
				float cosine = dot(_WorldSpaceLightPos0.xyz,skyDir);
				float cosine2 = ((cosine)*(cosine));
				float miePhase = ((((1.0) + (cosine2)))*(pow(((miePart_g2_1)+(((miePart_g_2)*(cosine)))),(-(1.5)))));
				float rayleighPhase = ((0.75)*(((1.0) + (cosine2))));
				(OUT.xyz) += (((((ColorRayleigh.xyz)*(_PartialRayleighInScatteringConst.xyz)))*(rayleighPhase)));
				(OUT.xyz) += (((((ColorMie.xyz)*(_PartialMieInScatteringConst.xyz)))*(miePhase)));
			}

			// float gr = saturate(((((skyDir.y)*(_NightSkyColBase.w))) + (_NightSkyColDelta.w)));
			// (gr) *= (((2) - (gr)));
			// (gr) *= (((2) - (gr)));
			// (OUT.xyz) += (((_NightSkyColBase.xyz) + (((_NightSkyColDelta.xyz)*(gr)))));
			// float m = ((1) - (dot(skyDir, _NightMoonDirSize.xyz)));
			// float innerScale = ((1.0) / (((1.05) + (((m)*(_NightMoonInnerCoronaColorScale.w))))));
			// (innerScale) = (lerp(0.0, 1.0, max(0, ((innerScale)-(0.04)))));
			// (OUT.xyz) += (((_NightMoonInnerCoronaColorScale.xyz)*(innerScale)));
			// (OUT.xyz) += (((_NightMoonOuterCoronaColorScale.xyz)*(((1.0) / (((1.05) + (((m)*(_NightMoonOuterCoronaColorScale.w)))))))));
			// float4 moonAlbedo = tex2D(_MoonMapTex, moonTC.xy);
			//float3 moonLighting = ((_NightMoonColor.xyz)*(moonAlbedo.xyz));
			//(OUT.xyz) = (((((OUT.xyz)*(min(1.0, ((_NightMoonColor.w) - (moonAlbedo.a)))))) + (moonLighting)));

			(OUT.xyz) *= (_PhaseFunctionConstants.z);

			UNITY_APPLY_FOG(IN.fogCoord, OUT);
			CY_APPLY_FOG(IN.cyFogCoord, OUT);

			//float fogRate=saturate(((baseTC.y)-(SkyDome_MapAndFogParam.z)));
			//(fogRate)=(saturate(((((fogRate)*(fogRate)))*(SkyDome_MapAndFogParam.w))));
			//{
			//half3 fogColor=((((FogColor2.rgb)*(saturate(((((V.y)*(5)))+(1))))))+(FogColor));
			//half VoL=saturate(dot((-(V)),_WorldSpaceLightPos0.xyz));
			//(fogColor)+=(((FogColor3)*(((VoL)*(VoL)))));
			//(OUT.rgb)=(lerp(OUT.rgb,((((OUT.rgb)*(((1)-(fogRate)))))+(fogColor)),fogRate));
			//}
			//(OUT.xyz)*=(EnvInfo.z);
			//(OUT.rgb)=(lerp(OUT.rgb,ScreenColor.rgb,ScreenColor.a));
			//(OUT.a)=(dot(((OUT.rgb)/(4)),half3(0.3,0.59,0.11)));
			//(OUT.rgb)=(min(OUT.rgb,20.0));

			return OUT;
		}

			  ENDCG
		}
	}

	Fallback off
}


