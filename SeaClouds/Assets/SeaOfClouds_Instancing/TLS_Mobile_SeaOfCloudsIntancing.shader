Shader "TLStudio/Effect/SeaOfCloudsIntancing"
{
    Properties
    {
        [HDR]_Color("Color", Color) = (1, 1, 1, 1)
        _DownColor("Down Color",color) = (1, 1, 1, 1)
        _3DNoise("3D Noise", 3D) = "white" {}
        _tiling("Tiling", Range(0,2)) = 1
        [HideInInspector]_dither("dither", Range(0,0.2)) = 0.1

		_CloudDensity("Cloud Density", Range(0,2)) = 0.8
		_CloudPower("Cloud Power",Range(0,2)) = 1
        _FogIntensity("Fog Intensity", Range(0,1)) = 1
        _InvFade("Soft Particles Factor", Range(0.01,2.0)) = 0.1
    }

        SubShader
    {
        Tags {"Queue"="Transparent"  "RenderType" = "Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        cull off
		ZWrite off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            //#pragma shader_feature INSTANCING_ON
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            //#include "CGIncludes/TLStudioCG.cginc"
            //#pragma multi_compile_fwdbase
            #define TLSOFTPARTICLES_ON

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
				float4 tangent : TANGENT;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 color : COLOR;
                float3 uv1 : TEXCOORD0;
				float3 uv2: TEXCOORD6;
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 worldLightDir : TEXCOORD3;
                float3 worldViewDir : TEXCOORD4;
				float3 worldTangent : TEXCOORD7;
				float3 worldBitangent : TEXCOORD8;
                //SHADOW_COORDS(5)
                UNITY_FOG_COORDS(9)
                #ifdef TLSOFTPARTICLES_ON
					float4 projPos : TEXCOORD5;
				#endif
                UNITY_VERTEX_INPUT_INSTANCE_ID // necessary only if you want to access instanced properties in fragment Shader.
            };

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _color)
                UNITY_DEFINE_INSTANCED_PROP(float, _offset)
                UNITY_DEFINE_INSTANCED_PROP(float, _clip)
            UNITY_INSTANCING_BUFFER_END(Props)


            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler3D _3DNoise;
            float _tiling, _dither;
            float4 _DownColor;
			float4 _Color;

			fixed _CloudDensity,_CloudPower,_FogIntensity;

            v2f vert(appdata v)
            {
                v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o); // necessary only if you want to access instanced properties in the fragment Shader.
				

                

                o.uv1 = v.vertex.xyz * _tiling * 0.1  + float3(_Time.y * 0.01,0,0);
				o.uv2 = v.vertex.xyz * _tiling * 0.05 + float3(_Time.y * 0.02,0,0);
                v.vertex.xyz += UNITY_ACCESS_INSTANCED_PROP(Props, _offset) * v.normal;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                //o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                //o.worldLightDir = normalize(UnityWorldSpaceLightDir(o.worldPos));
                //o.worldViewDir = normalize(UnityWorldSpaceViewDir(o.worldPos));

				//world to tangent 变换矩阵
				//o.worldTangent = UnityObjectToWorldDir(v.tangent);
				//o.worldNormal = UnityObjectToWorldNormal(v.normal);
				//o.worldBitangent = cross(o.worldNormal, o.worldTangent) * v.tangent.w * unity_WorldTransformParams.w;
                
                o.pos = UnityObjectToClipPos(v.vertex);
                //TRANSFER_SHADOW(o);
                //TL_TRANSFER_FOG(o,o.pos,v.vertex);
                #ifdef TLSOFTPARTICLES_ON
					o.projPos = ComputeScreenPos(o.pos);
					COMPUTE_EYEDEPTH(o.projPos.z);
				#endif
                o.color = v.color;
                return o;
            }

            UNITY_DECLARE_DEPTH_TEXTURE(_SceneDepthTexLowRes);
			float _InvFade;

            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i); // necessary only if any instanced properties are going to be accessed in the fragment Shader.

				//float3x3 worldToTangent = float3x3(i.worldTangent, i.worldBitangent, i.worldNormal);

                //half NdotL = max(0, dot(i.worldNormal, i.worldLightDir));
                //half smoothNdotL = saturate(pow(NdotL, 2 - UNITY_ACCESS_INSTANCED_PROP(Props, _offset)));

                //half3 backLitDir = i.worldNormal * 1 + i.worldLightDir;
                //half backSSS = saturate(dot(i.worldViewDir, -backLitDir));
                //backSSS = saturate(pow(backSSS, 2 + UNITY_ACCESS_INSTANCED_PROP(Props, _offset) * 2) * 1.5);

                //half NdotV = max(0, dot(i.worldNormal, i.worldViewDir));
                //half smoothNdotV = saturate(pow(NdotV, 2 - UNITY_ACCESS_INSTANCED_PROP(Props, _offset)));

                //half shadow = saturate(lerp(SHADOW_ATTENUATION(i), 1, (distance(i.worldPos.xyz, _WorldSpaceCameraPos.xyz) - 100) * 0.1));

                //half finalLit = saturate(smoothNdotV * 0.5 + shadow * saturate(smoothNdotL + backSSS) * (1 - NdotV * 0.5));

                #ifdef TLSOFTPARTICLES_ON
					float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_SceneDepthTexLowRes, UNITY_PROJ_COORD(i.projPos)));
					float partZ = i.projPos.z;
					float fade = saturate(_InvFade * (sceneZ - partZ));
					i.color.a *= fade;
				#endif

				fixed4 col3 = tex3D(_3DNoise, i.uv2);
				//return col3;

                fixed4 col  = tex3D(_3DNoise, i.uv1 + col3.b * 0.2);
				fixed4 col2 = tex3D(_3DNoise, i.uv2);

                col.rgb = col.rrr + col2.ggg;

				float alpha = col.r + col.g;

                half dither = frac((sin(i.worldPos.x + i.worldPos.y) * 99 + 11) * 99);

                

                col.rgb = lerp(_DownColor.rgb, 1, col.r);
                //col.rgb *= finalLit ;
				col.rgb = min(0.99,col.rgb);

				//clip(alpha * smoothstep(_ccc,_ddd,col.b) - UNITY_ACCESS_INSTANCED_PROP(Props, _clip) + dither * _dither- _aaa);

				col.a = saturate(alpha - UNITY_ACCESS_INSTANCED_PROP(Props, _clip) + dither * _dither - _CloudDensity);
				
				col.a = smoothstep(0, 2, col.a) * smoothstep(0,0.8,col.b);

				//float3 ddxddy = float3(ddx(col.r), ddy(col.r),0)+dither * _dither;
				//float3 halfLV = normalize(i.worldLightDir + i.worldViewDir);
				//float lit = dot(mul(worldToTangent,halfLV), normalize(ddxddy));
				//lit = lit * 0.5 +0.5;
				//lit = max(lit, 0.3);
				//float4 aaa = float4(lit.xxx, col.a);
				//return aaa;
                col = col * float4(pow(UNITY_ACCESS_INSTANCED_PROP(Props, _color).rgb,_CloudPower),1) * _Color/**i.color*/;
                //TL_APPLY_WATER_FOG(i.fogCoord*_FogIntensity, col.rgb);
				return col;
				//return col2.gggg;
            }
            ENDCG
        }
    }
}
