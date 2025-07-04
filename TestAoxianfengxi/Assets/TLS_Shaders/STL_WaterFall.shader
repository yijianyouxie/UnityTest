// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "TLStudio/STL_WaterFall" {
    Properties {
        _UPTexture ("UPTexture", 2D) = "Black" {}
        _MiddleTexture ("MiddleTexture", 2D) = "Black" {}
        _MainTex ("DownTexture", 2D) = "white" {}
        _UpUSpeed ("UpUSpeed", Float ) = 0
        _UpVSpeed ("UpVSpeed", Float ) = 0.7
        _MiddleUSpeed ("MiddleUSpeed", Float ) = 0
        _MiddleVSpeed ("MiddleVSpeed", Float ) = 0.3
        _DownUSpeed ("DownUSpeed", Float ) = 0
        _DownVSpeed ("DownVSpeed", Float ) = 0.4
        _UpColor ("UpColor", Color) = (1,1,1,1)
        _UpBrightness ("UPBrightness", Range(1,2) ) = 1
        _MiddleColor ("MiddleColor", Color) = (1,1,1,1)
        _MiddleBrightness ("MiddleBrightness", Range(1,2) ) = 1
        _Color ("DownColor", Color) = (1,1,1,1)
        _DownBrightness ("DownBrightness", Range(1,2) ) = 1
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            Lighting Off
            Cull Off
            ZWrite Off
 
            CGPROGRAM
            #pragma multi_compile FOG_EXP2 FOG_LINEAR
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma exclude_renderers xbox360 ps3 flash d3d11_9x
            uniform float4 _TimeEditor;
            uniform sampler2D _UPTexture; uniform half4 _UPTexture_ST;
            uniform sampler2D _MiddleTexture; uniform half4 _MiddleTexture_ST;
            uniform sampler2D _MainTex; uniform half4 _MainTex_ST;
            uniform fixed _UpUSpeed;
            uniform fixed _UpVSpeed;
            uniform fixed _MiddleUSpeed;
            uniform fixed _MiddleVSpeed;
            uniform fixed _DownUSpeed;
            uniform fixed _DownVSpeed;
            uniform fixed4 _UpColor;
			uniform fixed4 _MiddleColor;
            uniform fixed4 _Color;
            uniform fixed _UpBrightness;
			uniform fixed _MiddleBrightness;
            uniform fixed _DownBrightness;
            struct VertexInput {
                float4 vertex : POSITION;
                half2 texcoord0 : TEXCOORD0;
                fixed4 color:COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
				half2 uv0 : TEXCOORD0;
				half2 uv1 : TEXCOORD1;
				half2 uv2 : TEXCOORD2;
                fixed4 color :COLOR;
                UNITY_FOG_COORDS(3)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.pos = UnityObjectToClipPos(v.vertex );
                o.color = v.color;
                float4 time = _Time + _TimeEditor;
                o.uv0 = (v.texcoord0+frac((time.g*float2(_UpUSpeed,_UpVSpeed))));
                o. uv1 = (v.texcoord0+frac((time.g*float2(_DownUSpeed,_DownVSpeed))));
                o. uv2 =  (v.texcoord0+frac((time.g*float2(_MiddleUSpeed,_MiddleVSpeed))));
                if(UseHeightFog > 0)
                {
                	TL_TRANSFER_FOG(o,o.pos, v.vertex);
                }else
                {
	                UNITY_TRANSFER_FOG(o,o.pos);                
                }
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                fixed4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv1, _MainTex));
                fixed4 _UPTexture_var = tex2D(_UPTexture,TRANSFORM_TEX(i.uv0, _UPTexture));
                fixed4 _MiddleTexture_var = tex2D(_MiddleTexture,TRANSFORM_TEX(i.uv2, _MiddleTexture));
                fixed3 DownFinal = (_MainTex_var.rgb*_Color.rgb)*_DownBrightness;
                fixed3 UpFinal = (_UPTexture_var.rgb*_UpColor.rgb)*_UpBrightness;
                fixed UpAlpha = (_UpColor.a*_UPTexture_var.a);
                fixed3 MiddleFinal = (_MiddleTexture_var.rgb*_MiddleColor.rgb)*_MiddleBrightness;
                fixed MiddleAlpha = (_MiddleColor.a*_MiddleTexture_var.a);
                fixed3 finalColor = DownFinal+UpFinal*UpAlpha+MiddleFinal*MiddleAlpha;
                if(UseHeightFog > 0)
                {
                	TL_APPLY_FOG(i.fogCoord,finalColor.rgb);
                }else
                {
	                UNITY_APPLY_FOG(i.fogCoord,finalColor);                 
                }
                return fixed4(finalColor,(_Color.a*_MainTex_var.a*i.color.a));
            }
            ENDCG
        }
    }
}
