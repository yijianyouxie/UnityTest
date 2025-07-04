// Simplified Specular shader. Differences from regular Specular one:
// - no Main Color nor Specular Color
// - specular lighting directions are approximated per vertex
// - writes zero to alpha channel
// - no Deferred Lighting support
// - no Lightmap support
// - fully supports only 1 directional light. Other lights can affect it, but it will be per-vertex/SH.

Shader "TLStudio/Transparent/Tree" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
        _Cutoff("Alpha cutoff", Range(0,1)) = 0.5
    }
        SubShader{
            Tags{ "Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout" }
            LOD 150
            Cull Off

            // ------------------------------------------------------------
            // Surface shader code generated out of a CGPROGRAM block:


            // ---- forward rendering base pass:
            Pass {
                Name "FORWARD"
                Tags { "LightMode" = "ForwardBase" }
                ColorMask RGB

        CGPROGRAM
        #pragma skip_variants FOG_EXP DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING VERTEXLIGHT_ON SHADOWS_CUBE SHADOWS_DEPTH POINT SPOT
            // compile directives
            #pragma vertex vert_surf
            #pragma fragment frag_surf
            //#pragma multi_compile_instancing

            //#pragma multi_compile _ INSTANCE_ENABLE
            #if defined(INSTANCE_ENABLE) && defined(LIGHTMAP_ON)
                #if defined(LIGHTPROBE_SH)
                    #undef LIGHTPROBE_SH
                #endif
            #endif

            #pragma multi_compile FOG_EXP2 FOG_LINEAR
            #pragma multi_compile_fwdbase
            #include "HLSLSupport.cginc"
            #include "UnityShaderVariables.cginc"
            #include "UnityShaderUtilities.cginc"

            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #include "Assets/TLS_Shaders/CGIncludes/Lighting.cginc"
            #include "Assets/TLS_Shaders/CGIncludes/AutoLight.cginc"

            #define INTERNAL_DATA
            #define WorldReflectionVector(data,normal) data.worldRefl
            #define WorldNormalVector(data,normal) normal

            // Original surface shader snippet:
            #line 16 ""
            #ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
            #endif
            /* UNITY: Original start of shader */
            //#pragma surface surf MobileBlinnPhong noforwardadd alphatest:_Cutoff

            inline fixed4 LightingMobileBlinnPhong(SurfaceOutput s, fixed3 lightDir, fixed3 halfDir, fixed atten)
            {
                fixed diff = max(0.3, dot(s.Normal, lightDir));

                fixed4 c;
                c.rgb = s.Albedo * _LightColor0.rgb * diff;
                c.a = s.Alpha;
                return c;
            }
            sampler2D _MainTex;
            struct Input {
                float2 uv_MainTex;
            };

            void surf(Input IN, inout SurfaceOutput o) {
                fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
                o.Albedo = tex.rgb;
                o.Alpha = tex.a;
            }


            // vertex-to-fragment interpolation data
            // no lightmaps:
            #ifndef LIGHTMAP_ON
            struct v2f_surf {
              UNITY_POSITION(pos);
              float2 pack0 : TEXCOORD0; // _MainTex
              float3 worldNormal : TEXCOORD1;
              float3 worldPos : TEXCOORD2;
              fixed3 vlight : TEXCOORD3; // ambient/SH/vertexlights
              UNITY_SHADOW_COORDS(4)
              UNITY_FOG_COORDS(5)
              #if SHADER_TARGET >= 30
              float4 lmap : TEXCOORD6;
              #endif
              UNITY_VERTEX_INPUT_INSTANCE_ID
              UNITY_VERTEX_OUTPUT_STEREO
            };
            #endif
            // with lightmaps:
            #ifdef LIGHTMAP_ON
            struct v2f_surf {
              UNITY_POSITION(pos);
              float2 pack0 : TEXCOORD0; // _MainTex
              float3 worldNormal : TEXCOORD1;
              float3 worldPos : TEXCOORD2;
              float4 lmap : TEXCOORD3;
              UNITY_SHADOW_COORDS(4)
              UNITY_FOG_COORDS(5)
              #ifdef DIRLIGHTMAP_COMBINED
              float3 tSpace0 : TEXCOORD6;
              float3 tSpace1 : TEXCOORD7;
              float3 tSpace2 : TEXCOORD8;
              #endif
              UNITY_VERTEX_INPUT_INSTANCE_ID
              UNITY_VERTEX_OUTPUT_STEREO
            };
            #endif
            float4 _MainTex_ST;

            #if defined(INSTANCE_ENABLE) && defined(UNITY_INSTANCING_ENABLED) && defined(LIGHTMAP_ON)
                UNITY_INSTANCING_BUFFER_START(Props)
                    UNITY_DEFINE_INSTANCED_PROP(fixed4, unity_LightmapST)
                UNITY_INSTANCING_BUFFER_END(Props)
            #endif

            // vertex shader
            v2f_surf vert_surf(appdata_full v) {
              UNITY_SETUP_INSTANCE_ID(v);
              v2f_surf o;
              UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
              UNITY_TRANSFER_INSTANCE_ID(v,o);
              UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
              o.pos = UnityObjectToClipPos(v.vertex);
              o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
              float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
              float3 worldNormal = UnityObjectToWorldNormal(v.normal);
              #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
              fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
              fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
              fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
              #endif
              #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
              o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
              o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
              o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
              #endif
              o.worldPos = worldPos;
              o.worldNormal = worldNormal;
              #ifdef DYNAMICLIGHTMAP_ON
              o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
              #endif
              #ifdef LIGHTMAP_ON
                #if defined(INSTANCE_ENABLE) && defined(UNITY_INSTANCING_ENABLED)
                    unity_LightmapST = UNITY_ACCESS_INSTANCED_PROP(Props, unity_LightmapST);
                #endif
              o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
              #endif

              // SH/ambient and vertex lights
              #ifndef LIGHTMAP_ON
              #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
              float3 shlight = ShadeSH9(float4(worldNormal,1.0));
              o.vlight = shlight;
              #else
              o.vlight = 0.0;
              #endif
              #ifdef VERTEXLIGHT_ON
              o.vlight += Shade4PointLights(
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, worldPos, worldNormal);
              #endif // VERTEXLIGHT_ON
              #endif // !LIGHTMAP_ON

              UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy); // pass shadow coordinates to pixel shader
              if(UseHeightFog > 0)
              {
              	TL_TRANSFER_FOG(o,o.pos, v.vertex);
              }else
              {
	              UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader              
              }
              return o;
            }
            fixed _Cutoff;

            // fragment shader
            fixed4 frag_surf(v2f_surf IN) : SV_Target {
              UNITY_SETUP_INSTANCE_ID(IN);
            // prepare and unpack data
            Input surfIN;
            UNITY_INITIALIZE_OUTPUT(Input,surfIN);
            surfIN.uv_MainTex.x = 1.0;
            surfIN.uv_MainTex = IN.pack0.xy;
            float3 worldPos = IN.worldPos;
            #ifndef USING_DIRECTIONAL_LIGHT
              fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
            #else
              fixed3 lightDir = _WorldSpaceLightPos0.xyz;
            #endif
            float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
            #ifdef UNITY_COMPILER_HLSL
            SurfaceOutput o = (SurfaceOutput)0;
            #else
            SurfaceOutput o;
            #endif
            o.Albedo = 0.0;
            o.Emission = 0.0;
            o.Specular = 0.0;
            o.Alpha = 0.0;
            o.Gloss = 0.0;
            fixed3 normalWorldVertex = fixed3(0,0,1);
            o.Normal = IN.worldNormal;
            normalWorldVertex = IN.worldNormal;

            // call surface function
            surf(surfIN, o);

            // alpha test
            clip(o.Alpha - _Cutoff);

            // compute lighting & shadowing factor
            UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
            fixed4 c = 0;
            #ifndef LIGHTMAP_ON
            c.rgb += o.Albedo * IN.vlight;
            #endif // !LIGHTMAP_ON

            // lightmaps
            #ifdef LIGHTMAP_ON
              #if DIRLIGHTMAP_COMBINED
                // directional lightmaps
                fixed4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.lmap.xy);
                half3 lm = DecodeLightmap(lmtex);
                lm = BlendLightmap(lm, IN.lmap.xy);
              #else
                // single lightmap
                fixed4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.lmap.xy);
                fixed3 lm = DecodeLightmap(lmtex);
                lm = BlendLightmap(lm, IN.lmap.xy);
              #endif

            #endif // LIGHTMAP_ON


                // realtime lighting: call lighting function
                #ifndef LIGHTMAP_ON
                c += LightingMobileBlinnPhong(o, lightDir, worldViewDir, atten);
                #else
                  c.a = o.Alpha;
                #endif

                #ifdef LIGHTMAP_ON
                  // combine lightmaps with realtime shadows
                  #ifdef SHADOWS_SCREEN
                    #if defined(UNITY_NO_RGBM)
                    c.rgb += o.Albedo * min(lm, atten * 2);
                    #else
                    c.rgb += o.Albedo * max(min(lm,(atten * 2) * lmtex.rgb), lm * atten);
                    #endif
                  #else // SHADOWS_SCREEN
                    c.rgb += o.Albedo * lm;
                  #endif // SHADOWS_SCREEN
                #endif // LIGHTMAP_ON

                #ifdef DYNAMICLIGHTMAP_ON
                fixed4 dynlmtex = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, IN.lmap.zw);
                c.rgb += o.Albedo * DecodeRealtimeLightmap(dynlmtex);
                #endif

                if(UseHeightFog > 0)
                {
                	TL_APPLY_FOG(IN.fogCoord, c.rgb);
                }else
                {
	                UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog                
                }
                return c;
              }





                  ENDCG

                  }

                      // ---- end of surface shader generated code

                  #LINE 40

        }

            FallBack "Transparent/Cutout/VertexLit"
}
