// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Unlit alpha-cutout shader.
// - no lighting
// - no lightmap support
// - no per-material color

Shader "TLStudio/Transparent/UnLit Cutout" {
Properties {
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
	_ColorIntensity("ColorIntensity", Range(0,5)) = 1

	//使用第二套uv作为动画的采样坐标
	_AniAtlas("AniAtlas", 2D) = "black" {}
	_AniAtlasMask("AniAtlasMask", 2D) = "black" {}
	_RangeUV("RangeUV", Vector) = (0,0,0,0)
	_TexScale("_TexScale", Range(0.01,0.98)) = 0.98
}
SubShader {
	Tags {"Queue"="AlphaTest+40" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
	LOD 100

	Lighting Off

	Pass {  
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
				half2 uv2 : TEXCOORD2;
				UNITY_FOG_COORDS(1)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;
			half _ColorIntensity;
			fixed _LightingScaleNew;

			sampler2D _AniAtlas;
			sampler2D _AniAtlasMask;
			float4 _RangeUV;
			half _TexScale;

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv2 = v.uv2;
				if(UseHeightFog > 0)
				{
					TL_TRANSFER_FOG(o,o.vertex, v.vertex);
				}else
				{
					UNITY_TRANSFER_FOG(o,o.vertex);				
				}
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.texcoord);
				clip(col.a - _Cutoff);

				fixed newLightScale = step(0.5, _LightingScaleNew);
				float lightScale = lerp(_ColorIntensity, _LightingScaleNew, newLightScale);
				
				col = col * lightScale;

				float centerUV2 = float2(0.5, 0.5);
				i.uv2 = (i.uv2 - centerUV2) / _TexScale + centerUV2;
				float2 uv2 = float2(clamp(lerp(_RangeUV.x, _RangeUV.y, i.uv2.x), _RangeUV.x, _RangeUV.y), 
									clamp(lerp(1 - _RangeUV.w, 1 - _RangeUV.z, i.uv2.y), 1 - _RangeUV.w, 1 - _RangeUV.z));
				//uv2 = saturate(uv2);
				fixed4 aniCol = tex2D(_AniAtlas, uv2);
				fixed4 aniColMask = tex2D(_AniAtlasMask, uv2);
				aniColMask.r = aniColMask.r;
				if (uv2.x <= _RangeUV.x || uv2.x >= _RangeUV.y || uv2.y <= 1 - _RangeUV.w || uv2.y >= 1 - _RangeUV.z)
				{
					aniColMask.r = 0;
				}

				col = aniColMask.r * aniCol + (1 - aniColMask.r)*col;
				
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(i.fogCoord,col.rgb);
				}else
				{
					UNITY_APPLY_FOG(i.fogCoord,col);				
				}
				return col;
			}
		ENDCG
	}
}

}
