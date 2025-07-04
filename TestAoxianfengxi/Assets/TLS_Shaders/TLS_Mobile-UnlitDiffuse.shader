// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Unlit shader. Simplest possible textured shader.
// - no lighting
// - no lightmap support
// - no per-material color

Shader "TLStudio/Opaque/UnLit" {
Properties {
	_MainTex ("Base (RGB)", 2D) = "white" {}
}

SubShader {
	Tags { "RenderType"="Opaque" }
	LOD 100
	
	Pass {  
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			
			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
				UNITY_FOG_COORDS(1)
			};

			sampler2D _MainTex;
			half4 _MainTex_ST;
			
			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
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
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(i.fogCoord, col.rgb);
				}else
				{
					UNITY_APPLY_FOG(i.fogCoord, col);				
				}
				UNITY_OPAQUE_ALPHA(col.a);
				return col;
			}
		ENDCG
	}
}
}
