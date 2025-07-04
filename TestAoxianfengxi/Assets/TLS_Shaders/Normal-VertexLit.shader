﻿Shader "VertexLit" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecColor ("Spec Color", Color) = (1,1,1,1)
		_Emission ("Emissive Color", Color) = (0,0,0,0)
		_Shininess ("Shininess", Range (0.01, 1)) = 0.7
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}

	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100
		Fog{ Mode Off }
		// Non-lightmapped
		Pass {
			Tags { "LightMode" = "Vertex" }
		
			Material {
				Diffuse [_Color]
				Ambient [_Color]
				Shininess [_Shininess]
				Specular [_SpecColor]
				Emission [_Emission]
			} 
			/*Lighting On
			SeparateSpecular On*/
			SetTexture [_MainTex] {
				Combine texture * primary DOUBLE, texture * primary
			} 
		}
	
		// Lightmapped, encoded as dLDR
		Pass {
			Tags { "LightMode" = "VertexLM" }
			Fog{ Mode Off }
			BindChannels {
				Bind "Vertex", vertex
				Bind "normal", normal
				Bind "texcoord1", texcoord0 // lightmap uses 2nd uv
				Bind "texcoord", texcoord1 // main uses 1st uv
			}
		
			SetTexture [unity_Lightmap] {
				matrix [unity_LightmapMatrix]
				constantColor [_Color]
				combine texture * constant
			}
			SetTexture [_MainTex] {
				combine texture * previous DOUBLE, texture * primary
			}
		}
	
		// Lightmapped, encoded as RGBM
		Pass {
			Tags { "LightMode" = "VertexLMRGBM" }
			Fog{ Mode Off }
			BindChannels {
				Bind "Vertex", vertex
				Bind "normal", normal
				Bind "texcoord1", texcoord0 // lightmap uses 2nd uv
				Bind "texcoord1", texcoord1 // unused
				Bind "texcoord", texcoord2 // main uses 1st uv
			}
		
			SetTexture [unity_Lightmap] {
				matrix [unity_LightmapMatrix]
				combine texture * texture alpha DOUBLE
			}
			SetTexture [unity_Lightmap] {
				constantColor [_Color]
				combine previous * constant
			}
			SetTexture [_MainTex] {
				combine texture * previous QUAD, texture * primary
			}
		}
	
		// Pass to render object as a shadow caster
		/*Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
		
			Fog {Mode Off}
			ZWrite On ZTest LEqual Cull Off
			Offset 1, 1

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"

			struct v2f { 
				V2F_SHADOW_CASTER;
			};

			v2f vert( appdata_base v )
			{
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			fixed4 frag( v2f i ) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG

		}*/
	
	
	}

}
