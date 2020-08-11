// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/TerrainEngine/Splatmap/Standard-Base" {
    Properties {
        _MainTex ("Base (RGB) Smoothness (A)", 2D) = "white" {}
        _MetallicTex ("Metallic (R)", 2D) = "white" {}

        // used in fallback on old cards
        _Color ("Main Color", Color) = (1,1,1,1)
    }

    SubShader {
        Tags {
            "RenderType" = "Opaque"
            "Queue" = "Geometry-100"
        }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert_custom finalcolor:finalcustomcolor
		#pragma multi_compile_fog
		#pragma multi_compile __ CY_FOG_ON
        #pragma target 3.0
        // needs more than 8 texcoords
        #pragma exclude_renderers gles
        #include "UnityPBSLighting.cginc"

        sampler2D _MainTex;
        sampler2D _MetallicTex;

#ifdef CY_FOG_ON
		float4 FogInfo;
		float4 FogColor;
		float4 FogColor2;
		float4 FogColor3;
		float4 FogInfo2;
#endif

        struct Input {
            float2 uv_MainTex;
			UNITY_FOG_COORDS(1)
			UNITY_CY_FOG_COORDS(2)
        };

		void vert_custom(inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);

			float4 oPos = UnityObjectToClipPos(v.vertex);
			UNITY_TRANSFER_FOG(o, oPos);

			float4 posW = mul(unity_ObjectToWorld, v.vertex);
			float3 dis = posW.xyz - _WorldSpaceCameraPos;
			UNITY_TRANSFER_CY_FOG(o, dis.xyz, posW.y);
		}

        void surf (Input IN, inout SurfaceOutputStandard o) {
            half4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Albedo = c.rgb;
            o.Alpha = 1;
            o.Smoothness = c.a;
            o.Metallic = tex2D (_MetallicTex, IN.uv_MainTex).r;
        }

		void finalcustomcolor(Input IN, SurfaceOutputStandard o, inout fixed4 color)
		{
			UNITY_APPLY_FOG(IN.fogCoord, color);

			UNITY_APPLY_CY_FOG(IN.cyFogCoord, color);

		}

        ENDCG
    }

    FallBack "Diffuse"
}
