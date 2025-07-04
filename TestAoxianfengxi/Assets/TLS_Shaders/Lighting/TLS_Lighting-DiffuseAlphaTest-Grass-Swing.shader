// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Lighting/Transparent/Cutout_Ani"
{
	Properties{
		//_Color("Color", Color) = (1,1,1,1)
		_MainTex ("MainTex", 2D) = "white" {}
		_MinIntensity("_MinIntensity", Range (0, 5)) = 0.2
		//_LightIntensity("光照强度", Range(1, 2)) = 1.7
		_CutOff("Alpha cutoff", Range(0,1)) = 0.5
		_Wind("Wind params",Vector) = (0,0,0,0.1)
		_WindEdgeFlutter("Wind edge fultter factor", float) = 3
		_WindEdgeFlutterFreqScale("Wind edge fultter freq scale",float) = 0.5
	}
 
	SubShader
	{
		Tags{  "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"  }
		Pass 
		{
			Cull Off
            Name "ForwardBase"
            Tags {"LightMode"="Vertex"}
            CGPROGRAM
            #pragma skip_variants SHADOWS_CUBE
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
			#pragma multi_compile FOG_EXP2 FOG_LINEAR
            #include "Assets/TLS_Shaders/UnityCG.cginc"
            #include "AutoLight.cginc"
			#include "TerrainEngine.cginc"
            uniform fixed4 _LightColor0;
			uniform fixed _MinIntensity;
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			//uniform fixed _LightIntensity;
            uniform sampler2D _MainTex; uniform half4 _MainTex_ST;
			uniform fixed _CutOff;
			uniform float _WindEdgeFlutter;
			uniform float _WindEdgeFlutterFreqScale;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                half2 texcoord0 : TEXCOORD0;
				fixed4 color:COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                half2 uv0 : TEXCOORD0;
                fixed3 viewDirection : TEXCOORD1;
                fixed3 normalDir : TEXCOORD2;
                LIGHTING_COORDS(3,4)
                //float3 shLight : TEXCOORD5;
				UNITY_FOG_COORDS(6)
            };

			inline float4 AnimateVertex2(float4 pos, float3 normal, float4 animParams,float4 wind,float2 time)
			{	
				float fDetailAmp = 0.1f;
				float fBranchAmp = 0.3f;
	
				float fVtxPhase = dot(pos.xyz, animParams.y + animParams.x);
	
				float2 vWavesIn = time  + float2(fVtxPhase,animParams.x );
	
				float4 vWaves = (frac( vWavesIn.xxyy * float4(1.975, 0.793, 0.375, 0.193) ) * 2.0 - 1.0);
	
				vWaves = SmoothTriangleWave( vWaves );
				float2 vWavesSum = vWaves.xz + vWaves.yw;

				float3 bend = animParams.y * fDetailAmp * normal.xyz;
				bend.y = animParams.w * fBranchAmp;
				pos.xyz += ((vWavesSum.xyx * bend) + (wind.xyz * vWavesSum.y * animParams.w)) * wind.w; 

				pos.xyz += animParams.z * wind.xyz;
	
				return pos;
			}
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);// mul(_Object2World, float4(v.normal,0)).xyz;
                //o.shLight = ShadeSH9(float4(o.normalDir * 1.0,1))- UNITY_LIGHTMODEL_AMBIENT.rgb;
                o.viewDirection = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);

				float4 wind;
				float	bendingFact= v.color.a;
				wind.xyz	= mul((float3x3)unity_WorldToObject,_Wind.xyz);
				wind.w		= _Wind.w  * bendingFact;
				float4	windParams	= float4(0,_WindEdgeFlutter,bendingFact.xx);
				float 	windTime = _Time.y * float2(_WindEdgeFlutterFreqScale,1);
				float4	mdlPos= AnimateVertex2(v.vertex,v.normal,windParams,wind,windTime);

                o.pos = UnityObjectToClipPos(mdlPos);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
				if(UseHeightFog > 0)
				{
					TL_TRANSFER_FOG(o,o.pos, v.vertex);
				}else
				{
					UNITY_TRANSFER_FOG(o,o.pos);				
				}
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR {
				fixed4 _MainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
				clip((half)(_MainTexColor.a - _CutOff));
				//if(tex.a - _CutOff < 0)
                //    discard;
				i.normalDir = normalize(i.normalDir);
                fixed3 normalDirection = i.normalDir;
                fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                //fixed3 attenColor = _LightColor0.xyz;
				fixed3 attenColor = unity_LightColor[0];
                fixed NdotL = max(_MinIntensity,dot( normalDirection, lightDirection ));
                fixed3 directDiffuse =NdotL* attenColor;
                //fixed3 indirectDiffuse = i.shLight;
                //fixed3 diff = (directDiffuse + indirectDiffuse) * _MainTexColor.rgb;
				fixed3 diff = directDiffuse  * _MainTexColor.rgb;
				if(UseHeightFog > 0)
				{
					TL_APPLY_FOG(i.fogCoord, diff.rgb);
				}else
				{
					UNITY_APPLY_FOG(i.fogCoord, diff);				
				}
                return fixed4(diff,1.0);
            }
            ENDCG
        }

		Pass 
		{
			Name "Caster"
			Tags { "LightMode" = "ShadowCaster" }
			Offset 1, 1
		
			Fog {Mode Off}
			ZWrite On ZTest LEqual Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#include "Assets/TLS_Shaders/UnityCG.cginc"
			#include "TerrainEngine.cginc"

			struct a2v
			{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
				fixed4 color:COLOR;
				float3 normal : NORMAL;
			};

			struct v2f { 
				V2F_SHADOW_CASTER;
				half2  uv : TEXCOORD1;
			};

			uniform sampler2D _MainTex; uniform half4 _MainTex_ST;
			uniform fixed _CutOff;
			uniform float _WindEdgeFlutter;
			uniform float _WindEdgeFlutterFreqScale;

			inline float4 AnimateVertex2(float4 pos, float3 normal, float4 animParams,float4 wind,float2 time)
			{	
				float fDetailAmp = 0.1f;
				float fBranchAmp = 0.3f;
	
				float fVtxPhase = dot(pos.xyz, animParams.y + animParams.x);
	
				float2 vWavesIn = time  + float2(fVtxPhase,animParams.x );
	
				float4 vWaves = (frac( vWavesIn.xxyy * float4(1.975, 0.793, 0.375, 0.193) ) * 2.0 - 1.0);
	
				vWaves = SmoothTriangleWave( vWaves );
				float2 vWavesSum = vWaves.xz + vWaves.yw;

				float3 bend = animParams.y * fDetailAmp * normal.xyz;
				bend.y = animParams.w * fBranchAmp;
				pos.xyz += ((vWavesSum.xyx * bend) + (wind.xyz * vWavesSum.y * animParams.w)) * wind.w; 

				pos.xyz += animParams.z * wind.xyz;
	
				return pos;
			}

			v2f vert( a2v v )
			{
				v2f o;
				float4 wind;
				float	bendingFact= v.color.a;
				wind.xyz	= mul((float3x3)unity_WorldToObject,_Wind.xyz);
				wind.w		= _Wind.w  * bendingFact;
				float4	windParams	= float4(0,_WindEdgeFlutter,bendingFact.xx);
				float 	windTime = _Time.y * float2(_WindEdgeFlutterFreqScale,1);
				v.vertex = AnimateVertex2(v.vertex,v.normal,windParams,wind,windTime);
				TRANSFER_SHADOW_CASTER(o)
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			fixed4 frag( v2f i ) : SV_Target
			{
				fixed4 tex= tex2D(_MainTex, i.uv);
				clip((half)(tex.a - _CutOff));
				//if(tex.a - _CutOff < 0)
                //    discard;
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
}
