// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable
// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

Shader "TLStudio/T4Map" {
    Properties {
        _Splat0 ("Layer1", 2D) = "white" {}
        _Splat1 ("Layer2", 2D) = "white" {}
        _Splat2 ("Layer3", 2D) = "white" {}
        _Splat3 ("Layer4", 2D) = "white" {}
        _Control ("Control", 2D) = "white" {}
    }
    SubShader {
        Tags {
            "Queue" = "Geometry+500"
            "SplatCount" = "4"
            "RenderType"="Opaque"
        }
        LOD 200
        Pass {
            Name "ForwardBase"
            Tags {
                "LightMode"="ForwardBase"
            } 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile FOG_EXP2 FOG_LINEAR
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma exclude_renderers xbox360 ps3 flash d3d11_9x
            uniform sampler2D _Splat0; uniform float4 _Splat0_ST;
            uniform sampler2D _Splat1; uniform float4 _Splat1_ST;
            uniform sampler2D _Splat2; uniform float4 _Splat2_ST;
            uniform sampler2D _Splat3; uniform float4 _Splat3_ST;
            uniform sampler2D _Control; uniform float4 _Control_ST;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float2 uv4 : TEXCOORD4;
                float3 normalDir : TEXCOORD8;
                float2 uvLM : TEXCOORD7;
                LIGHTING_COORDS(5,6)
                UNITY_FOG_COORDS(9)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _Splat0);
                o.uv1 = TRANSFORM_TEX(v.texcoord0, _Splat1);
                o.uv2 = TRANSFORM_TEX(v.texcoord0, _Splat2);
                o.uv3 = TRANSFORM_TEX(v.texcoord0, _Splat3);
                o.uv4 =TRANSFORM_TEX(v.texcoord0, _Control);
                o.normalDir = v.normal;
                o.pos = UnityObjectToClipPos(v.vertex);
                #ifndef LIGHTMAP_OFF
                    o.uvLM = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw;
                #else
                 	float3 lightColor = _LightColor0.rgb;
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
                float3 normalDirection =normalize(i.normalDir);
                float attenuation = LIGHT_ATTENUATION(i);
                #ifndef LIGHTMAP_OFF
	                float4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap,i.uvLM);
	                float3 lightmap = DecodeLightmap(lmtex);
	                //float3 directDiffuse =min (lightmap.rgb,attenuation*lightmap.rgb);
                    float3 directDiffuse =lightmap.rgb;
	                float3 indirectDiffuse = float3(0,0,0);
                #else
                    float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                    float3 attenColor = attenuation * _LightColor0.xyz;
                    float3 lightColor = _LightColor0.rgb;
                    float NdotL = max(0.0,dot( normalDirection, lightDirection ));
                    float3 directDiffuse = max( 0.0, NdotL) * attenColor;
                    float3 indirectDiffuse = UNITY_LIGHTMODEL_AMBIENT.rgb; // Ambient Light
                #endif
                
                float4 _Control_var = tex2D(_Control,i.uv4);
                float4 _Splat0_var = tex2D(_Splat0,i.uv0);
                float4 _Splat1_var = tex2D(_Splat1,i.uv1);
                float4 _Splat2_var = tex2D(_Splat2,i.uv2);
                float4 _Splat3_var = tex2D(_Splat3,i.uv3);
                float3 finalColor = (directDiffuse + indirectDiffuse) * ((_Control_var.r*_Splat0_var.rgb)+(_Control_var.g*_Splat1_var.rgb)+(_Control_var.b*_Splat2_var.rgb)+(_Control_var.a*_Splat3_var.rgb));
                if(UseHeightFog > 0)
                {
                	TL_APPLY_FOG(i.fogCoord, finalColor.rgb);
                }else
                {
	                UNITY_APPLY_FOG(i.fogCoord, finalColor);                 
                }
                return fixed4(finalColor,1);
            }
            ENDCG
        }
 
    }
    FallBack "TLStudio/T4Map_Unlit"
}
