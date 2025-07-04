// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_LightmapInd', a built-in variable
// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D
// Upgrade NOTE: replaced tex2D unity_LightmapInd with UNITY_SAMPLE_TEX2D_SAMPLER

//Normal-SpeculaTerrain
//CopyRight: ruanzheng
//2015/1/29
Shader "TLStudio/Opaque/DiffuseNormal" {
    Properties {
        _MainTex ("MainTex", 2D) = "white" {}
        _NormalTex ("NormalTex", 2D) = "bump" {}
        _SpeculaColor ("SpeculaColor", color) =  (1,1,1,1)
        _LightPos ("SunDirectiion", Vector) = (1,1,1,2)
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        Pass {
            Name "ForwardBase"
            Tags {
                "LightMode"="ForwardBase"
            }
            LOD 500
            
            CGPROGRAM
            #pragma skip_variants FOG_EXP INSTANCING_ON LIGHTPROBE_SH VERTEXLIGHT_ON SHADOWS_CUBE DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING POINT SPOT
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #pragma multi_compile FOG_EXP2 FOG_LINEAR
            #include "UnityCG.cginc"
            #include "Assets/TLS_Shaders/CGIncludes/AutoLight.cginc"
            #include "Assets/TLS_Shaders/CGIncludes/Lighting.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma exclude_renderers xbox360 ps3 flash d3d11_9x
            #ifndef LIGHTMAP_OFF
                // float4 unity_LightmapST;
                // sampler2D unity_Lightmap;
                #ifndef DIRLIGHTMAP_OFF
                    // sampler2D unity_LightmapInd;
                #endif
            #endif
            uniform sampler2D _MainTex; uniform half4 _MainTex_ST;
            uniform sampler2D _NormalTex; uniform half4 _NormalTex_ST;
            uniform float4 _LightPos;
            uniform float4 _SpeculaColor;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                half2 texcoord0 : TEXCOORD0;
				half2 texcoord1 : TEXCOORD1;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
				half2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                fixed3 tangentDir : TEXCOORD3;
				fixed3 binormalDir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
                #ifndef LIGHTMAP_OFF
                    float2 uvLM : TEXCOORD7;
                #endif
                UNITY_FOG_COORDS(8)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);// mul(_Object2World, float4(v.normal,0)).xyz;
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.binormalDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos(v.vertex);
                #ifndef LIGHTMAP_OFF
                    o.uvLM = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw;
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
                float3x3 tangentTransform = float3x3( i.tangentDir, i.binormalDir, i.normalDir);
/////// Vectors:
				fixed3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				fixed3 _NormalTex_var = UnpackNormal(tex2D(_NormalTex,TRANSFORM_TEX(i.uv0, _NormalTex)));
				fixed3 normalLocal = _NormalTex_var.rgb;
				fixed3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
                #ifndef LIGHTMAP_OFF
					fixed4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap,i.uvLM);
                    #ifndef DIRLIGHTMAP_OFF
                        float3 lightmap = DecodeLightmap(lmtex);
                        lightmap = BlendLightmap(lightmap, i.uvLM);
                        float3 scalePerBasisVector = DecodeLightmap(UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd,unity_Lightmap,i.uvLM));
                        UNITY_DIRBASIS
                        half3 normalInRnmBasis = saturate (mul (unity_DirBasis, normalLocal));
                        lightmap *= dot (normalInRnmBasis, scalePerBasisVector);
                    #else
                        float3 lightmap = DecodeLightmap(lmtex);
                        lightmap = BlendLightmap(lightmap, i.uvLM);
                    #endif
                #endif
                #ifndef LIGHTMAP_OFF
                    #ifdef DIRLIGHTMAP_OFF
						fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                    #else
						fixed3 lightDirection = normalize (scalePerBasisVector.x * unity_DirBasis[0] + scalePerBasisVector.y * unity_DirBasis[1] + scalePerBasisVector.z * unity_DirBasis[2]);
                        lightDirection = mul(lightDirection,tangentTransform); // Tangent to world
                    #endif
                #else
						fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                #endif
				fixed3 lightColor = _LightColor0.rgb;
////// Lighting:
                fixed attenuation = LIGHT_ATTENUATION(i);
				fixed3 attenColor = attenuation * _LightColor0.xyz;
/////// Diffuse:
                fixed NdotL = max(0.0,dot( normalDirection, lightDirection ));
				fixed3 indirectDiffuse = fixed3(0,0,0);
                #ifndef LIGHTMAP_OFF
					fixed3 directDiffuse = fixed3(0,0,0);
                #else
					fixed3 directDiffuse = max( 0.0, NdotL) * attenColor;
                    indirectDiffuse += UNITY_LIGHTMODEL_AMBIENT.rgb; // Ambient Light
                #endif
                #ifndef LIGHTMAP_OFF
                    #ifdef SHADOWS_SCREEN
                        #if (defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)) && defined(SHADER_API_MOBILE)
                            directDiffuse += min(lightmap.rgb, attenuation);
                        #else
                            directDiffuse += max(min(lightmap.rgb,attenuation*lmtex.rgb), lightmap.rgb*attenuation);
                        #endif
                    #else
                        directDiffuse += lightmap.rgb;
                    #endif
                #endif
              
                fixed4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
				fixed3 diffuse = (directDiffuse + indirectDiffuse) * _MainTex_var.rgb;
////// Emissive:
				fixed3 sunDirectiion =normalize(_LightPos.xyz);
				fixed3 H = normalize(sunDirectiion+viewDirection);
                 float HxN = max(0,dot(H,normalDirection));
                 float LxN =min(1,max(0,dot(sunDirectiion,normalDirection))+0.5);
				 fixed3 emissive = _SpeculaColor.rgb*pow(HxN,_LightPos.w*128)*_MainTex_var.a;
/// Final Color:
				 fixed3 finalColor = diffuse*LxN + emissive;
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
    }
    FallBack "Mobile/Bumped Specular"
}
