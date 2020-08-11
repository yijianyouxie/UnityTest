Shader "UnderWaterEffect/CausticEffect"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "black" {}
		_Color("Tint Color", Color) = (1,1,1,1)
	}
	
	SubShader
	{
        Tags {"Queue"="Geometry" "IgnoreProjector"="True" "RenderType"="Opaque"}
		LOD 100

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase"}
			
			CGPROGRAM
			
			#pragma target 3.0
			#include "UnityCG.cginc"
			#include "UnderWaterEffect.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityImageBasedLighting.cginc"
			#include "UnityGlobalIllumination.cginc"
			#include "AutoLight.cginc"		
			
			#pragma multi_compile_fwdbase
			//#pragma multi_compile_fog
			#pragma multi_compile __ CausticEffect
			#pragma multi_compile __ CY_FOG_ON
			
			#pragma vertex vert
			#pragma fragment frag

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_CY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
				float4 ambientOrLightmapUV : TEXCOORD4;
				//UNITY_FOG_COORDS(4)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			fixed4 _Color;
			
			inline half4 VertexGIForward(appdata_full v, float3 posWorld, half3 normalWorld)
			{
				
				half4 ambientOrLightmapUV = 0;
			// Static lightmaps
			#ifdef LIGHTMAP_ON
				ambientOrLightmapUV.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				ambientOrLightmapUV.zw = 0;
			// Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
			#elif UNITY_SHOULD_SAMPLE_SH
				#ifdef VERTEXLIGHT_ON
					// Approximated illumination from non-important point lights
					ambientOrLightmapUV.rgb = Shade4PointLights (
						unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
						unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
						unity_4LightAtten0, posWorld, normalWorld);
				#endif

				ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, ambientOrLightmapUV.rgb);
			#endif

			#ifdef DYNAMICLIGHTMAP_ON
				ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
			#endif

				return ambientOrLightmapUV;
			}
			
			v2f vert (appdata_full v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos =  mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.ambientOrLightmapUV = VertexGIForward(v, o.worldPos, o.worldNormal);
				float3 dis = o.worldPos - _WorldSpaceCameraPos;
				//UNITY_TRANSFER_FOG(o,o.vertex);
				UNITY_TRANSFER_CY_FOG(o, dis, o.worldPos.y);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 albedo = tex2D(_MainTex, i.uv) * _Color;
				fixed4 col = albedo;
				
			#ifndef USING_DIRECTIONAL_LIGHT
				float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
			#else
				float3 lightDir = _WorldSpaceLightPos0.xyz;
			#endif
			
				float3 normalDir = normalize(i.worldNormal);
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				half nl = saturate(dot(normalDir, lightDir));
				col.rgb = albedo.rgb * nl * _LightColor0.rgb;
				
				//测试，仅考虑GI Diffuse
				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
				gi.light.color = _LightColor0.rgb;
				gi.light.dir = lightDir;
				
				UnityGIInput giInput;
				UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
				giInput.light = gi.light;
				giInput.worldPos = i.worldPos;
				giInput.worldViewDir = viewDir;
				giInput.atten = 1.0;

			#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
				giInput.ambient = 0;
				giInput.lightmapUV = i.ambientOrLightmapUV;
			#else
				giInput.ambient = i.ambientOrLightmapUV.rgb;
				giInput.lightmapUV = 0;
			#endif
				gi = UnityGI_Base(giInput, 1.0, normalDir);
				col.rgb += gi.indirect.diffuse * albedo.rgb;
			
			#ifdef CausticEffect
				col = CaculateCausticsEffect(col, i.worldPos);
			#endif
				
				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				UNITY_APPLY_CY_FOG(i.cyFogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
