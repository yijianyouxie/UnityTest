// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Effect/MultiUVFlow-Blend(UIPanelClip)"
{
	Properties{
		[MaterialEnum(UnityEngine.Rendering.CullMode)] _Cull("裁剪模式", Int) = 0
		[Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 0
		[Header(Tips begain)]
		[Header(Add UVFlowController Componet to use.)]
		[Header(Tips end)]
		[Header(bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb)]
		_MainTex("MainTex", 2D) = "black" {}
		_MainTexMaskChannel("主贴图透明使用的通道rgba(值是0或1)", vector) = (0, 0, 0 ,1)
		_MainCol("_MainCol", Color) = (1,1,1,1)
		_MainColIntensity("MainColIntensity", Range(0, 20)) = 1
		
		[Space(20)]
		[Header(bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb)]
		_GlossTex("相乘GlossTex", 2D) = "white" {}
		_GlossCol("_GlossCol", Color) = (1,1,1,1)

		[Space(20)]
		[Header(bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb)]
		_AdjustTex("相加AdjustTex", 2D) = "black" {}
		_AdjustCol("_AdjustCol", Color) = (1,1,1,1)

		[Space(20)]
		[HideInInspector]_AlphaCutoff("Alpha cutoff", Range(0,1)) = 0
		[Header(bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb)]
		_DissoveTex("溶解DissoveTex", 2D) = "white" {}

		[Space(20)]
		[Header(bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb)]
		_MaskTex("遮罩MaskTex", 2D) = "white" {}

		[Space(20)]
		[Header(bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb)]
		_OffsetTexture("扭曲贴图NoiseTexture", 2D) = "white" {}
		_DistabilizationMask("扭曲Mask(黑白图)", 2D) = "white" {}
		_Intensity("主贴图水平扭曲强度", Range(-1, 1)) = 0
		_IntensityVertical("主贴图垂直扭曲强度", Range(-1, 1)) = 0
		_IntensityMask("Mask贴图水平扭曲强度", Range(-1, 1)) = 0
		_IntensityMaskVertical("Mask贴图垂直扭曲强度", Range(-1, 1)) = 0
		_HorizontalSpeed("水平速度HorizontalSpeed",float) = 0
		_VerticalSpeed("垂直速度VerticalSpeed",float) = 0

		[Space(20)]
		[Header(bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb)]
		_FinalMaskTex("总遮罩MaskTex", 2D) = "white" {}

		_ClipRange0 ("_ClipRange0", Vector) = (0.0, 0.0, 1.0, 1.0)
		_ClipArgs0 ("_ClipArgs0", Vector) = (1000.0, 1000.0, 1.0, 1.0)
	}
	SubShader{
		Tags{
			"IgnoreProjector" = "True"
			"Queue" = "Transparent"
			"RenderType" = "Transparent"
		}
		Pass{
			Name "FORWARD"
			Tags{
				"LightMode" = "ForwardBase"
			}
			Blend SrcAlpha OneMinusSrcAlpha
			Cull [_Cull]
			Lighting Off
			ZWrite [_ZWrite]
			LOD 150

			CGPROGRAM
			#pragma skip_variants SHADOWS_CUBE SHADOWS_DEPTH FOG_EXP INSTANCING_ON DIRECTIONAL DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SHADOWS_SCREEN SHADOWS_SHADOWMASK VERTEXLIGHT_ON DIRECTIONAL_COOKIE POINT POINT_COOKIE SPOT UNITY_HDR_ON
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
			float4 _MainTexMaskChannel;
			float4 _MainCol;
			float _MainColIntensity;
			float4 _GlossCol;
			float4 _AdjustCol;
			uniform sampler2D _GlossTex; uniform float4 _GlossTex_ST;
			uniform sampler2D _AdjustTex; uniform float4 _AdjustTex_ST;
			uniform sampler2D _MaskTex; uniform float4 _MaskTex_ST;
			uniform float _AlphaCutoff;
			uniform sampler2D _DissoveTex; uniform float4 _DissoveTex_ST;

			uniform float4 _TimeEditor;
			uniform float _HorizontalSpeed, _VerticalSpeed;
			uniform sampler2D _OffsetTexture; uniform float4 _OffsetTexture_ST;
			uniform sampler2D _DistabilizationMask; uniform float4 _DistabilizationMask_ST;
			uniform float _Intensity;
			uniform float _IntensityVertical;
			uniform float _IntensityMask;
			uniform float _IntensityMaskVertical;
			uniform sampler2D _FinalMaskTex; uniform float4 _FinalMaskTex_ST;

			float4 _ClipRange0;
            float2 _ClipArgs0;

			struct VertexInput {
				float4 vertex : POSITION;
				float2 texcoord0 : TEXCOORD0;
				float4 vertexColor : COLOR;
			};
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float4 vertexColor : COLOR;
				float2 worldPos : TEXCOORD1;
			};
			VertexOutput vert(VertexInput v) {
				VertexOutput o = (VertexOutput)0;
				o.uv0 = v.texcoord0;
				o.vertexColor = v.vertexColor;
				o.pos = UnityObjectToClipPos(v.vertex);

				float2 clipSpace = o.pos.xy / o.pos.w;
				clipSpace = (clipSpace.xy + 1) * 0.5;
				o.worldPos = clipSpace * _ClipRange0.zw + _ClipRange0.xy;
				return o;
			}
			float4 frag(VertexOutput i) : COLOR{
				//MainTex
				float3 _DestMask_var = tex2D(_DistabilizationMask, TRANSFORM_TEX(i.uv0, _DistabilizationMask));
				float4 timer = _Time + _TimeEditor;
				float2 speed = float2(_HorizontalSpeed, _VerticalSpeed);
				float2 offsetTextureUV = (i.uv0 + timer.g*speed);
				float3 _OffsetTexture_var = tex2D(_OffsetTexture,TRANSFORM_TEX(offsetTextureUV, _OffsetTexture));
				float2 preOffset = float2((_Intensity*i.uv0.r), (_IntensityVertical*i.uv0.g))*_OffsetTexture_var.r*_DestMask_var.r;
				float2 mainTextureUV = i.uv0 + preOffset;

				float4 _MainTex_var = tex2D(_MainTex, TRANSFORM_TEX(mainTextureUV, _MainTex));
				float3 emissive = (_MainTex_var.rgb*i.vertexColor.rgb*_MainCol.rgb);
				float3 finalColor = emissive * _MainColIntensity;
				float mainAlpha = _MainTexMaskChannel.x * _MainTex_var.r + _MainTexMaskChannel.y*_MainTex_var.g + _MainTexMaskChannel.z*_MainTex_var.b + _MainTexMaskChannel.w* _MainTex_var.a;
				float finalAlpha = mainAlpha * _MainCol.a * i.vertexColor.a;

				//_GlossTex
				float4 _GlossTex_var = tex2D(_GlossTex, TRANSFORM_TEX(i.uv0, _GlossTex));
				float3 glossFinalCol = _GlossTex_var.rgb * _GlossCol.rgb * _GlossCol.a;
				finalColor *= glossFinalCol;
				//finalAlpha = (finalAlpha + (1 - finalAlpha)*_GlossTex_var.a);

				//_AdjustTex
				float4 _AdjustTex_var = tex2D(_AdjustTex, TRANSFORM_TEX(i.uv0, _AdjustTex));
				float3 finalAdjustCol = _AdjustTex_var.rgb*_AdjustTex_var.a * _AdjustCol.rgb * _AdjustCol.a;
				finalColor += finalAdjustCol;
				//finalAlpha = (finalAlpha + (1 - finalAlpha)*_AdjustTex_var.a);

				//_MaskTex
				float2 preOffset2 = float2((_IntensityMask*i.uv0.r), (_IntensityMaskVertical*i.uv0.g))*_OffsetTexture_var.r*_DestMask_var.r;
				float2 maskTextureUV = i.uv0 + preOffset2;
				float4 _MaskTex_var = tex2D(_MaskTex, TRANSFORM_TEX(maskTextureUV, _MaskTex));
				finalAlpha = (finalAlpha * _MaskTex_var.r * _MaskTex_var.a * _GlossTex_var.r * _GlossTex_var.a);

				//_DissoveTex
				float4 _DissoveTex_var = tex2D(_DissoveTex, TRANSFORM_TEX(i.uv0, _DissoveTex));
				//溶解使用r通道
				clip(_DissoveTex_var.r - _AlphaCutoff);

				//总遮罩
				float4 _FinalMaskTex_var = tex2D(_FinalMaskTex, TRANSFORM_TEX(i.uv0, _FinalMaskTex));
				finalAlpha = (finalAlpha * _FinalMaskTex_var.r * _FinalMaskTex_var.a);

				float2 factor = (float2(1.0, 1.0) - abs(i.worldPos)) * _ClipArgs0;
                finalAlpha *= clamp( min(factor.x, factor.y), 0.0, 1.0);

				return float4(finalColor.rgb, finalAlpha);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
