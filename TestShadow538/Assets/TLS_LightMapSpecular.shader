﻿// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable
// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

Shader "TLStudio/Opaque/LightMapSpecular" {
    Properties {
        _MainColor ("Main Color", Color) = (0.5,0.5,0.5,1)
        _SpecularColor ("SpecularColor", Color) = (0.5,0.5,0.5,1)
        _Shine ("Shine", Range(1, 128)) = 1
        _MainTex ("MainTex", 2D) = "white" {}
		_LightPos ("主光源位置", Vector) = (100,100,100,100)

		[Space(20)]
		[Header(Extra Light)]
		[Toggle]
		_LightPos2Enable("光源2开启", float) = 0
		_LightPos2("光源2位置", Vector) = (100,100,100,100)
		_SpecularIntensity2("光源2强度", Range(0,1)) = 0.5

		[Space(20)]
		[Toggle]
		_LightPos3Enable("光源3开启", float) = 0
		_LightPos3("光源3位置", Vector) = (100,100,100,100)
		_SpecularIntensity3("光源3强度", Range(0,1)) = 0.5
		_SpecularBackPow("额外光Shine", Range(1, 128)) = 1
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
		LOD 200
        Pass {
            Name "ForwardBase"
            Tags {
                "LightMode"="ForwardBase"
            }
            ColorMask RGBA
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile GLOBALSH_DISABLE GLOBALSH_ENABLE
            #pragma multi_compile_fog
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
			
			
            #pragma multi_compile_fwdbase_fullshadows
            #pragma exclude_renderers xbox360 ps3 flash d3d11_9x 
            #pragma target 3.0
            #ifndef LIGHTMAP_OFF
                #ifndef DIRLIGHTMAP_OFF
                #endif
            #endif
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            // uniform sampler2D unity_Lightmap;
            // uniform float4 unity_LightmapST;
            uniform fixed4 _MainColor;
            uniform fixed4 _SpecularColor;
            uniform fixed _Shine;
			uniform fixed4 _LightPos;

			uniform fixed _LightPos2Enable;
			uniform fixed4 _LightPos2;
			fixed _SpecularIntensity2;
			half _SpecularBackPow;

			uniform fixed _LightPos3Enable;
			uniform fixed4 _LightPos3;
			fixed _SpecularIntensity3;

            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float4 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 binormalDir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
				#ifdef GLOBALSH_ENABLE
				float3 vlighting : TEXCOORD7;
				#else
				#endif
                UNITY_FOG_COORDS(8)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0.xy = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);// mul(_Object2World, float4(v.normal,0)).xyz;
                o.tangentDir = normalize( mul( _Object2World, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.binormalDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(_Object2World, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
            #ifndef LIGHTMAP_OFF
					o.uv0.zw = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw;
            #endif
			#ifdef GLOBALSH_ENABLE
				o.vlighting = ShadeSH9 (float4(o.normalDir, 1.0));
			#endif
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR {
                i.normalDir = normalize(i.normalDir);
                float3x3 tangentTransform = float3x3( i.tangentDir, i.binormalDir, i.normalDir);
/////// Vectors:
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 normalDirection = i.normalDir;
            #ifndef LIGHTMAP_OFF
                    float4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap,i.uv0.zw);
                    float3 lightmap = DecodeLightmap(lmtex);
            #endif
                float3 lightDirection = normalize(_LightPos.xyz);
				
////Weather
			#ifdef CYWEATHER_COMMON
				half horizon = HandleBubbleDistort(i.posWorld.xz, normalDirection);
				lightDirection = lerp(lightDirection, normalize(_CustomLightDir), _WeatherEffectControl.g);
				_Shine = lerp(_Shine, 128.0 * _RainEffectParams.g, _WeatherEffectControl.g);
				_SpecularColor *= lerp(1.0, _RainEffectParams.b, _WeatherEffectControl.g);
			#endif
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+lightDirection);
////// Lighting:
                float attenuation = LIGHT_ATTENUATION(i);
                float3 attenColor = attenuation;
///////// Gloss:
                float gloss = _Shine;
                float specPow = gloss;
////// Specular:
                float3 specularColor = _SpecularColor.rgb;
                float3 directSpecular = pow(max(0,dot(halfDirection,normalDirection)),specPow);

				float3 halfDirection2 = normalize(viewDirection + normalize(_LightPos2.xyz));
				float3 directSpecular2 = pow(max(0, dot(halfDirection2, normalDirection)), _SpecularBackPow);

				float3 halfDirection3 = normalize(viewDirection + normalize(_LightPos3.xyz));
				float3 directSpecular3 = pow(max(0, dot(halfDirection3, normalDirection)), _SpecularBackPow);

                float3 specular = (directSpecular + directSpecular2*_LightPos2Enable*_SpecularIntensity2 + directSpecular3*_LightPos3Enable*_SpecularIntensity3) * specularColor;
            #ifndef LIGHTMAP_OFF
                  specular *= lightmap;
            #else
                    specular *= (floor(attenuation) * _LightColor0.xyz);
            #endif
/////// Diffuse:
				float NdotL = max(0.0,dot( normalDirection, lightDirection ));
                float3 indirectDiffuse = float3(0,0,0);
            #ifndef LIGHTMAP_OFF
                    float3 directDiffuse = float3(0,0,0);
            #else
                    float3 directDiffuse = max( 0.0, NdotL) * attenColor;
            #endif
            #ifndef LIGHTMAP_OFF
                #ifdef SHADOWS_SCREEN
                    #if (defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)) && defined(SHADER_API_MOBILE)
                        directDiffuse += min(lightmap.rgb, attenuation);
                    #else
                        directDiffuse += max(min(lightmap.rgb,attenuation*2), lightmap.rgb*attenuation);
                    #endif
                #else
                        directDiffuse += lightmap.rgb;
                #endif
            #endif
            #ifdef LIGHTMAP_OFF
                indirectDiffuse += UNITY_LIGHTMODEL_AMBIENT.rgb; // Ambient Light
            #endif
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0.xy, _MainTex));
			
			#ifdef CYWEATHER_COMMON
				// HandleAlbedoDiffuse(_MainTex_var.rgb, indirectDiffuse, viewDirection, normalDirection);
                HandleAlbedoScale(_MainTex_var.rgb);
				half3 reflectionCol = CaculateReflection(viewDirection, normalDirection, horizon, _MainTex_var.rgb);
                float3 diffuse = (directDiffuse + indirectDiffuse) * (_MainTex_var.rgb*_MainColor.rgb);

                // normalDirection.rb *= 2;
                // normalDirection.g = sqrt(1 - dot(normalDirection.rb, normalDirection.rb));
                fixed NdotUp = dot(normalDirection, float3(0,1,0));
                NdotUp = NdotUp <= 0.001 ? 1 : NdotUp;
                fixed rainCol = (1 - NdotUp) * NdotUp;
                diffuse *= NdotUp;

                float3 finalColor = diffuse +/*specular*_MainTex_var.a +*/ reflectionCol + rainCol * RainGroundIntensity;
				#ifdef CYWEATHER_SNOW
				finalColor = HandleSnowEffect(finalColor, horizon, i.posWorld.xz);
				#endif
			#else
				float3 diffuse = (directDiffuse + indirectDiffuse) * (_MainTex_var.rgb*_MainColor.rgb);
                float3 finalColor = diffuse +specular*_MainTex_var.a;
			#endif
			
			#ifdef GLOBALSH_ENABLE
				finalColor.xyz = finalColor.xyz*max(fixed3(1.0,1.0,1.0),(i.vlighting - UNITY_LIGHTMODEL_AMBIENT.xyz)*2);
			#endif
                UNITY_APPLY_FOG(i.fogCoord,finalColor);
                return fixed4(finalColor,1);
            }
            ENDCG
        }

	//Pass {
	//	Name "FORWARD"
	//	Tags { "LightMode" = "ForwardAdd" }
	//	ZWrite Off Blend SrcAlpha OneMinusSrcAlpha Fog { Color (0,0,0,0) }

	//	CGPROGRAM

	//	#pragma vertex vert_add
	//	#pragma fragment frag_add
	//	#pragma multi_compile_fwdadds
	//	#define UNITY_PASS_FORWARDADD
	//	#include "UnityCG.cginc"
	//	#include "Lighting.cginc"
	//	#include "AutoLight.cginc"


	//	struct v2f_surf {
	//	  float4 pos : SV_POSITION;
	//	  LIGHTING_COORDS(0,1)
	//	};

	//	v2f_surf vert_add (appdata_full v) {
	//	  v2f_surf o;
	//	  o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
	//	  TRANSFER_VERTEX_TO_FRAGMENT(o);
	//	  return o;
	//	}

	//	fixed4 frag_add (v2f_surf IN) : SV_Target {
	//		fixed4 c;
	//		fixed4 c1;
	//		c1.rgb = _LightColor0.rgb * (LIGHT_ATTENUATION(IN));
	//		c.rgb = c1.rgb * 0.4;
	//		c.a = c1.r;
	//		return c;
	//	}
	//	ENDCG
	//}

    	Pass
	{
		Name "ShadowCollector"
		Tags { "LightMode" = "ShadowCollector" }
		
		Fog {Mode Off}
		ZWrite On ZTest LEqual

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_shadowcollector

		#define SHADOW_COLLECTOR_PASS
		#include "UnityCG.cginc"

		struct appdata {
			float4 vertex : POSITION;
		};

		struct v2f {
			V2F_SHADOW_COLLECTOR;
		};

		v2f vert (appdata v)
		{
			v2f o;
			TRANSFER_SHADOW_COLLECTOR(o)
			return o;
		}

		fixed4 frag (v2f i) : SV_Target
		{
			SHADOW_COLLECTOR_FRAGMENT(i)
		}
		ENDCG
	}
    }
    FallBack "TLStudio/Opaque/UnLit"
}
