// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable
// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

Shader "TLStudio/Opaque/LightMapSpecular_Bump" {
    Properties {
        _MainColor ("Main Color", Color) = (0.5,0.5,0.5,1)
        _SpecularColor ("SpecularColor", Color) = (0.5,0.5,0.5,1)
        _Shine ("Shine", Range(1, 128)) = 1
        _MainTex ("MainTex", 2D) = "white" {}
		_LightPos ("???��??", Vector) = (100,100,100,100)
		//????��?�Q?????
		_NormalMap("Normal Map", 2D) = "bump"{}
		_NormalScale("NormalScale", Range(0.03, 10)) = 1

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
			//#pragma multi_compile GLOBALSH_DISABLE GLOBALSH_ENABLE
            #pragma multi_compile FOG_EXP2 FOG_LINEAR
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma exclude_renderers xbox360 ps3 flash d3d11_9x 
            #pragma exclude_renderers xbox360 ps3 flash d3d11_9x
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
			uniform sampler2D _NormalMap; uniform half4 _NormalMap_ST;
			fixed _NormalScale;

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

				// ???????????��??????
				float3 lightDir:TEXCOORD9;
				float3 tViewLightDir:TEXCOORD10;
            };
			inline float3 ObjSpaceLightDirCustom(in float4 v)
			{
				float3 objSpaceLightPos = mul(unity_WorldToObject, _LightPos).xyz;
#ifndef USING_LIGHT_MULTI_COMPILE
				return objSpaceLightPos.xyz - v.xyz * _LightPos.w;
#else
#ifndef USING_DIRECTIONAL_LIGHT
				return objSpaceLightPos.xyz - v.xyz;
#else
				return objSpaceLightPos.xyz;
#endif
#endif
			}
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0.xy = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);// mul(_Object2World, float4(v.normal,0)).xyz;
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.binormalDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos(v.vertex);

				// ??????????????????????rotation????????????????????????????????????
				TANGENT_SPACE_ROTATION; 
				// ???????????��??????
				o.lightDir = mul(rotation, ObjSpaceLightDirCustom(v.vertex));
				o.tViewLightDir = mul(rotation, ObjSpaceViewDir(v.vertex));

                #ifndef LIGHTMAP_OFF
					o.uv0.zw = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
				#ifdef GLOBALSH_ENABLE
				o.vlighting = ShadeSH9 (float4(o.normalDir, 1.0));
				#endif
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                if(UseHeightFog > 0)
                {
                	TL_TRANSFER_FOG(o,o.pos, v.vertex);
                }else
                {
	                UNITY_TRANSFER_FOG(o,o.pos);                
                }
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR {
				//???????
				fixed4 normalColor = tex2D(_NormalMap, i.uv0.xy);
				// ???Unity????????????????????????????????????
				fixed3 tangentNormal = UnpackNormal(normalColor); 
				tangentNormal.xy = tangentNormal.xy * _NormalScale; // ?????????
				tangentNormal = normalize(tangentNormal);
				fixed3 lightDir = normalize(i.lightDir); // ???????????????
				fixed3 tViewLightDir = normalize(i.tViewLightDir);
				fixed3 tHalf = normalize(tViewLightDir + lightDir);
				fixed3 diffuseParam = max(0, dot(tangentNormal, lightDir));

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
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+lightDirection);
////// Lighting:
                float attenuation = LIGHT_ATTENUATION(i);
                float3 attenColor = attenuation;
///////// Gloss:
                float gloss = _Shine;
                float specPow = gloss;
////// Specular:
                float NdotL = max(0, dot( normalDirection, lightDirection ));
                float3 specularColor = _SpecularColor.rgb;
				float3 directSpecular = pow(max(0, dot(halfDirection, normalDirection)), specPow);
				float3 directSpecular2 = pow(max(0, dot(tHalf, tangentNormal)), specPow);
				//directSpecular = directSpecular2*0.3 + directSpecular*0.7;//??????+???????????
                float3 specular = directSpecular2 * specularColor;
                #ifndef LIGHTMAP_OFF
                  specular *= lightmap;
                #else
                    specular *= (floor(attenuation) * _LightColor0.xyz);
                #endif
/////// Diffuse:
                NdotL = max(0.0,dot( normalDirection, lightDirection ));
                float3 indirectDiffuse = float3(0,0,0);
                #ifndef LIGHTMAP_OFF
				float3 directDiffuse = diffuseParam;// float3(0, 0, 0);
                #else
				//float3 directDiffuse = max(0.0, NdotL) * attenColor;
				float3 directDiffuse = diffuseParam * attenColor;
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
                float3 diffuse = (directDiffuse + indirectDiffuse) * (_MainTex_var.rgb*_MainColor.rgb);
/// Final Color:
                float3 finalColor = diffuse + specular*_MainTex_var.a ;
				#ifdef GLOBALSH_ENABLE
				finalColor.xyz = finalColor.xyz*max(fixed3(1.0,1.0,1.0),(i.vlighting - UNITY_LIGHTMODEL_AMBIENT.xyz)*2);
				#endif
				finalColor = finalColor + specularColor*max(_MainTex_var.a - 0.5, 0);
                if(UseHeightFog > 0)
                {
                	TL_APPLY_FOG(i.fogCoord,finalColor.rgb);
                }else
                {
	                UNITY_APPLY_FOG(i.fogCoord,finalColor);                
                }
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

    	
    }
    FallBack "TLStudio/Opaque/UnLit"
}
