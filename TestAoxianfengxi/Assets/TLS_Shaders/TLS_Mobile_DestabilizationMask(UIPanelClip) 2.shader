// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Effect/DestabilizationMask(UIPanelClip) 2" {
    Properties {
        _MainTexture ("MainTexture", 2D) = "white" {}
         _Mask ("Mask", 2D) = "white" {}
        _OffsetTexture ("NoiseTexture", 2D) = "bump" {}
        _Offset ("Intensity", Range(0, 1)) = 0
        _horizontal("HorizontalSpeed",float) = 0
        _vertical("VerticalSpeed",float) = 0
		_ClipRange0("_ClipRange0", Vector) = (0.0, 0.0, 1.0, 1.0)
		_ClipArgs0("_ClipArgs0", Vector) = (1000.0, 1000.0, 0.0, 1.0)
		_ClipRange1("_ClipRange1", Vector) = (0.0, 0.0, 1.0, 1.0)
		_ClipArgs1("_ClipArgs1", Vector) = (1000.0, 1000.0, 0.0, 1.0)
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        Pass {
			Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            uniform float4 _TimeEditor;
            uniform float  _horizontal,_vertical;
            uniform sampler2D _MainTexture; uniform half4 _MainTexture_ST;
            uniform sampler2D _Mask; uniform half4 _Mask_ST;
            uniform sampler2D _OffsetTexture; uniform half4 _OffsetTexture_ST;
            uniform fixed _Offset;

			float4 _ClipRange0;
			float4 _ClipArgs0;
			float4 _ClipRange1;
			float4 _ClipArgs1;

            struct VertexInput {
                float4 vertex : POSITION;
                half2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                half2 uv0 : TEXCOORD0;
				half2 uv1 : TEXCOORD1;
				float4 worldPos : TEXCOORD2;
            };

			float2 Rotate(float2 v, float2 rot)
			{
				float2 ret;
				ret.x = v.x * rot.y - v.y * rot.x;
				ret.y = v.x * rot.x + v.y * rot.y;
				return ret;
			}

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos(v.vertex);
				//float timer = _Time.g;  
				half2 speed= half2(_horizontal,_vertical);
				o.uv1 = v.texcoord0+half2((sin(_Time.y*speed.x)+1)/2,(sin(_Time.y*speed.y)+1)/2);

				float2 clipSpace = o.pos.xy / o.pos.w;
				clipSpace = (clipSpace.xy + 1) * 0.5;
				o.worldPos.xy = clipSpace * _ClipRange0.zw + _ClipRange0.xy;
				o.worldPos.zw = Rotate(clipSpace, _ClipArgs1.zw) * _ClipRange1.zw + _ClipRange1.xy;
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR {
				fixed3 _Mask_var = tex2D(_Mask,TRANSFORM_TEX(i.uv0, _Mask));
				fixed3 _OffsetTexture_var = tex2D(_OffsetTexture,TRANSFORM_TEX(i.uv1, _OffsetTexture)) * 2 - 1;
				half2 mainTextureUV = (i.uv0 + _OffsetTexture_var.rg*_Offset*_Mask_var.r);
				fixed4 _MainTexture_var = tex2D(_MainTexture,TRANSFORM_TEX(mainTextureUV, _MainTexture));
				//_MainTexture_var.rgb = _MainTexture_var.rgb*_MainTexture_var.a;

				float2 factor = (float2(1.0, 1.0) - abs(i.worldPos.xy)) * _ClipArgs0.xy;
				float f = min(factor.x, factor.y);
				factor = (float2(1.0, 1.0) - abs(i.worldPos.zw)) * _ClipArgs1.xy;
				f = min(f, min(factor.x, factor.y));
				_MainTexture_var.a *= clamp(f, 0.0, 1.0);
				return _MainTexture_var;
                
            }
            ENDCG
        }
    }
}
