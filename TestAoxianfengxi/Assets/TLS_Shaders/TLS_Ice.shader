// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "TLStudio/FX/ICE" {
    Properties {
        _MainTexture ("MainTexture", 2D) = "white" {}
        _SpecularColor ("SpecularColor", Color) = (0.5,0.5,0.5,1)
        _Color1 ("Color1", Color) = (0.5,0.5,0.5,1)
        _Color2 ("Color2", Color) = (0.5,0.5,0.5,1)
        _IceDepth ("IceDepth", Range(0, -2)) = 0
        _ReflectMap ("ReflectMap", Cube) = "_Skybox" {}
        _NormalMapUP ("NormalMapUP", 2D) = "bump" {}
        _NormalMapDown ("NormalMapDown", 2D) = "bump" {}
        _UPReflection ("UPReflection", Range(0.2, 1)) = 0.7052907
        _DownReflection ("DownReflection", Range(0.2, 1)) = 1
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
            
            CGPROGRAM
            #pragma skip_variants FOG_EXP INSTANCING_ON DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING VERTEXLIGHT_ON SHADOWS_CUBE SHADOWS_DEPTH DIRECTIONAL_COOKIE POINT POINT_COOKIE SPOT UNITY_HDR_ON
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile FOG_EXP2 FOG_LINEAR
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma exclude_renderers xbox360 ps3  d3d11_9x 
            #pragma exclude_renderers xbox360 ps3 flash d3d11_9x
            uniform fixed4 _LightColor0;
            uniform samplerCUBE _ReflectMap;
            uniform sampler2D _NormalMapDown; uniform half4 _NormalMapDown_ST;
            uniform float _IceDepth;
            uniform fixed4 _Color1;
            uniform sampler2D _NormalMapUP; uniform half4 _NormalMapUP_ST;
            uniform sampler2D _MainTexture; uniform half4 _MainTexture_ST;
            uniform fixed4 _SpecularColor;
            uniform fixed4 _Color2;
            uniform fixed _UPReflection;
            uniform fixed _DownReflection;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                half2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
				half2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                fixed3 tangentDir : TEXCOORD3;
                fixed3 binormalDir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
                UNITY_FOG_COORDS(7)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);// mul(_Object2World, float4(v.normal,0)).xyz;
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.binormalDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                fixed3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos(v.vertex);
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
                i.normalDir = normalize(i.normalDir);
                float3x3 tangentTransform = float3x3( i.tangentDir, i.binormalDir, i.normalDir);
/////// Vectors:
                fixed3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                fixed3 _NormalMapUP_var = UnpackNormal(tex2D(_NormalMapUP,TRANSFORM_TEX(i.uv0, _NormalMapUP)));
                float2 Depth = (0.05*(_IceDepth - 0.5)*mul(tangentTransform, viewDirection).xy + i.uv0);
                fixed3 _NormalMapDown_var = UnpackNormal(tex2D(_NormalMapDown,TRANSFORM_TEX(Depth.rg, _NormalMapDown)));
                fixed3 normalLocal = ((_NormalMapUP_var.rgb*0.7)+(_NormalMapDown_var.rgb*0.3));
                fixed3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
                float3 viewReflectDirection = reflect( -viewDirection, normalDirection );
                fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 lightColor = _LightColor0.rgb;
				fixed3 halfDirection = normalize(viewDirection+lightDirection);
////// Lighting:
                fixed attenuation = LIGHT_ATTENUATION(i);
                fixed3 attenColor = attenuation * _LightColor0.xyz;
///////// Gloss:
                float gloss = 0.8;
                float specPow = exp2( gloss * 10.0+1.0);
////// Specular:
                fixed NdotL = max(0, dot( normalDirection, lightDirection ));
                fixed4 _MainTexture_var = tex2D(_MainTexture,TRANSFORM_TEX(i.uv0, _MainTexture));
                fixed3 specularColor = (_SpecularColor.rgb*lerp(3.0,_DownReflection,_MainTexture_var.rgb));
				fixed3 directSpecular = (floor(attenuation) * _LightColor0.xyz) * pow(max(0,dot(halfDirection,normalDirection)),specPow);
				fixed3 specular = directSpecular * specularColor;
/////// Diffuse:
                NdotL = max(0.0,dot( normalDirection, lightDirection ));
                fixed3 indirectDiffuse = fixed3(0,0,0);
				fixed3 directDiffuse = max( 0.0, NdotL) * attenColor;
                indirectDiffuse += UNITY_LIGHTMODEL_AMBIENT.rgb; // Ambient Light
				fixed3 diffuse = (directDiffuse + indirectDiffuse) * (lerp(_Color2.rgb,_Color1.rgb,_MainTexture_var.r));
////// Emissive:
                fixed relf = lerp(_DownReflection,_UPReflection,_MainTexture_var.r);
                fixed3 emissive = (texCUBE(_ReflectMap,viewReflectDirection).rgb*relf);
/// Final Color:
                fixed4 finalColor = fixed4(diffuse + specular + emissive,1);
                if(UseHeightFog > 0)
                {
                	TL_APPLY_FOG(i.fogCoord, finalColor.rgb);
                }else
                {
	                UNITY_APPLY_FOG(i.fogCoord, finalColor);                
                }
                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
