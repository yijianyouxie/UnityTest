// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Unlit alpha-blended shader.
// - no lighting
// - no lightmap support
// - no per-material color

Shader "TLStudio/Unlit/Transparent(UIPanelClip)" {
Properties {
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	_ClipRange0 ("_ClipRange0", Vector) = (0.0, 0.0, 1.0, 1.0)
	_ClipArgs0 ("_ClipArgs0", Vector) = (1000.0, 1000.0, 1.0, 1.0)
}

SubShader {
	Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
	LOD 100
	
	ZWrite Off
	Blend SrcAlpha OneMinusSrcAlpha 
	
	Pass {  
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			
			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
				float2 worldPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _ClipRange0;
            float2 _ClipArgs0;
            
			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				float2 clipSpace = o.vertex.xy / o.vertex.w;
				clipSpace = (clipSpace.xy + 1) * 0.5;
				o.worldPos = clipSpace * _ClipRange0.zw + _ClipRange0.xy;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.texcoord);
				float2 factor = (float2(1.0, 1.0) - abs(i.worldPos)) * _ClipArgs0;
				col.a *= clamp( min(factor.x, factor.y), 0.0, 1.0);
				return col;
			}
		ENDCG
	}
}

}
