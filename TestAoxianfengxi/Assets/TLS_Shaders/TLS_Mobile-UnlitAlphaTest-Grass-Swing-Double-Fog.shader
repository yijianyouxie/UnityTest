// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Unlit alpha-cutout shader.
// - no lighting
// - no lightmap support
// - no per-material color

Shader "TLStudio/Transparent/UnLit Cutout_Ani Double-Fog" {
Properties {
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
	_Range("Range" , Range(0,0.1)) = 0.05
	_LightingScale("LightScale(fake)",Range(0.5,1.5)) = 1

		_WhereHasSnow("Where Has Snow", Color) = (1,1,1,1)
}
SubShader {
	Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
	LOD 100
	Cull Off

	Lighting Off

	Pass {  
		CGPROGRAM
		#pragma skip_variants SHADOWS_CUBE
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			
			#include "UnityCG.cginc"
			#include "Assets/TLS_Shaders/CGIncludes/WeatherLibrary.cginc"
			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				UNITY_FOG_COORDS(3)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;
			fixed _LightingScale;
			fixed _LightingScaleNew;
			half	_Range;
			v2f vert (appdata_full v)
			{
				half4	finalpos = mul(unity_ObjectToWorld,v.vertex);
				half3	dist =	_WorldSpaceCameraPos.xyz - finalpos.xyz;
				half4	mdlPos;
				if(length(dist) < 25)
				{
					float 	finalbias = fmod(finalpos.x*finalpos.x + finalpos.y*finalpos.y + finalpos.z*finalpos.z,4);
					if(v.color.r == 0)
					{
						mdlPos	= v.vertex;
					}
					else
					{
						half st = 0;
						if(finalbias < 1) st = max(_CosTime.w + 0.3, -0.5);
						else if(finalbias >= 1 && finalbias < 2) st = min(_SinTime.w, 0.8) * finalbias;
						else if(finalbias >= 2 && finalbias < 3) st = min(_CosTime.w, 0.9) * finalbias;
						else if(finalbias >= 3 && finalbias < 4) st = max(_SinTime.w + 0.8, -0.8) * finalbias;
						mdlPos.xyz = v.vertex.xyz + v.tangent * st * _Range ;
						mdlPos.w = v.vertex.w;
					}
				}
				else
				{
					mdlPos = v.vertex;
				}

				v2f o;
				o.vertex = UnityObjectToClipPos(mdlPos);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.worldPosition = finalpos;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				if(UseHeightFog > 0)
				{
					TL_TRANSFER_FOG(o, o.vertex, v.vertex);
				}else
				{
					UNITY_TRANSFER_FOG(o, o.vertex);				
				}
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.texcoord);
				clip(col.a - _Cutoff);
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(i.fogCoord, col.rgb);
				}else
				{
					UNITY_APPLY_FOG(i.fogCoord, col);				
				}
				
				// 天气系统控制_LightingScaleNew，用来替代_LightingScale；没有天气系统的话_LightingScaleNew为0，则使用_LightingScale
				// 没有直接修改_LightingScale，是因为Properties中声明_LightingScale后，c#中修改是不生效的，但如果不声明，在一些非天气系统控制的场景该值就变成了0
				fixed newLightScale = step(0.5, _LightingScaleNew);
				float lightScale = lerp(_LightingScale, _LightingScaleNew, newLightScale);
				
				fixed3 finalColor = col*lightScale;
				if (_SnowIntensity > 0)
				{
					finalColor = BlendSnowTree(finalColor, i.worldNormal);
				}
				return fixed4(finalColor,col.a);
			}
		ENDCG
	}
		Pass
			{
				//??pass???? ??????fallBack??????? "LightMode" = "ShadowCaster" ?????????Pass
				Tags{ "LightMode" = "ShadowCaster" }

				CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#pragma multi_compile_shadowcaster
//#pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
#pragma shader_feature _RENDERING_CUTOUT
#pragma shader_feature _SMOOTHNESS_ALBEDO
#include "UnityCG.cginc"
				sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;
			struct v2f {
				V2F_SHADOW_CASTER;
				float2 uv : TEXCOORD1;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
					return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				fixed4 testColor = tex2D(_MainTex, i.uv);
				clip(testColor.a - _Cutoff);
				SHADOW_CASTER_FRAGMENT(i)
			}
				ENDCG

			}
}

}
