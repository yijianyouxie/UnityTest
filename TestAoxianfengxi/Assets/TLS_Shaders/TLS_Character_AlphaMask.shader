// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/FX/Character_AlphaMask" {
	Properties {
        _MainTex ("MainTex", 2D) = "white" {}
		_Mask ("Mask", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,0.5)
       // _Brightness("Brightness",float) =1
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        LOD 200
        Pass {
            ZWrite On
            ColorMask 0
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;

            };
            VertexOutput vert (VertexInput v) {
            	VertexOutput o;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
			uniform sampler2D _Mask; uniform float4 _Mask_ST;
            fixed4 frag(VertexOutput i) : COLOR {
                fixed3 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
				fixed4 _Mask_var = tex2D(_Mask, TRANSFORM_TEX(i.uv0, _Mask));
				fixed4 _finalRGBA = fixed4(_MainTex_var, _Mask_var.r);

                clip(_finalRGBA.a - 0.5);
                return 0;
            }
            ENDCG
        }
        Pass {
            Blend SrcAlpha one 
            
            ZWrite Off  
            ZTest Equal
            Cull Back
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            uniform float4 _LightColor0;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
			uniform sampler2D _Mask; uniform float4 _Mask_ST;
            uniform fixed4 _Color;
           // uniform float _Brightness;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                half2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                half2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                fixed3 normalDir : TEXCOORD2;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);// mul(_Object2World, float4(v.normal,0)).xyz;
                //o.normalDir = normalize(o.normalDir);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                fixed3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR {
                //fixed3 normalDirection = i.normalDir;
                fixed3 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
				fixed4 _Mask_var = tex2D(_Mask, TRANSFORM_TEX(i.uv0, _Mask));
				fixed4 _finalRGBA = fixed4(_MainTex_var, _Mask_var.r);

                //fixed3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
                //fixed3 lightColor = _LightColor0.rgb;
                //fixed attenuation = LIGHT_ATTENUATION(i);
                //fixed3 attenColor = attenuation * _LightColor0.xyz*2;
                //fixed NdotL = max(0.4,dot( normalDirection, lightDirection ));
                //fixed3 directDiffuse = max( 0.0, NdotL) * attenColor;
                //fixed3 finalColor = directDiffuse * (_finalRGBA.rgb*_Color.rgb);
		//云投影会导致directDiffuse变得非常暗，所以最后就没有颜色了。所以半透的时候就不要打光了
		fixed3 finalColor = 0.6*(_finalRGBA.rgb*_Color.rgb);
                return fixed4(finalColor,_Color.a);
            }
            ENDCG
        }
    }
    FallBack "Transparent/Cutout/Diffuse"
}