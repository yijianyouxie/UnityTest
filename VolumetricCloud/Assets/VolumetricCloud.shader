Shader "WalkingFat/VolumetricCloud"
{
	Properties
	{
		_NoiseTex("Noise Texture", 2D) = "white" {}
		_MainColor("Main Color", Color) = (1,1,1,1)

		_midYValue("Mid Y Value", float) = 0.9
		_cloudHeight("Cloud Height", float) = 2.95
		_TaperPower("Taper Power", float) = 1.26
		_Cutoff("Cutoff", range(0,1)) = 0.5

		_CloudSpeed("Cloud Speed", float) = 0.5
		_NoiseScale1("Noise Scale 1", range(0.1, 2.0)) = 0.53
		_NoiseScale2("Noise Scale 2", range(0.1, 2.0)) = 1.32
		_CloudSize("Cloud Size", range(0.01, 3.0)) = 0.2
		_CloudDirX("Cloud Direction X", float) = 1
		_CloudDirZ("Cloud Direction Z", float) = 0

		_SssPower("SSS Power", range(0.01,10)) = 4.5
		_SssStrength("SSS Strength", range(0.0,2.0)) = 0.22
		_OffsetDistance("Offset Distance", range(0,1)) = 0.1
		_LitStrength("Light Strength", range(0.1,20)) = 5
		_BackLitStrength("BackLight Strength", range(0.1,20)) = 5
		_EdgeLitPower("Edge Power", range(0.1,10)) = 1
		_EdgeLitStrength("Edge Light Strength", range(0.1,20)) = 1

	}
	SubShader
	{
		Tags{ "RenderType" = "Opaque" "LightMode" = "ForwardBase" }
		LOD 100

		Pass
		{
			Cull Off

			CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
			// make fog work
	#pragma multi_compile_fog

	#include "UnityCG.cginc"
	#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv1 : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float4 posWorld : TEXCOORD2;
				float3 lightDir : TEXCOORD3;
				float3 viewDir  : TEXCOORD4;
				float3 tangentWorld  : TEXCOORD5;
				float2 uvOffset1 : TEXCOORD6;
				float2 uvOffset2 : TEXCOORD7;
				float2 uvOffset3 : TEXCOORD8;
				float2 uvOffset4 : TEXCOORD9;
				UNITY_FOG_COORDS(10)
			};

			sampler2D _NoiseTex;
			float4 _NoiseTex_ST, _MainColor;
			float _midYValue, _cloudHeight, _TaperPower, _Cutoff;
			float _CloudSpeed, _NoiseScale1, _NoiseScale2, _CloudSize, _CloudDirX, _CloudDirZ;
			float _SssPower, _SssStrength, _OffsetDistance, _LitStrength, _BackLitStrength, _EdgeLitPower, _EdgeLitStrength;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.lightDir = WorldSpaceLightDir(v.vertex);
				o.viewDir = WorldSpaceViewDir(v.vertex);
				o.tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);

				// uv panner
				float2 uv = TRANSFORM_TEX(v.uv, _NoiseTex);
				//                o.uv2 = TRANSFORM_TEX(v.uv, _MainTex);
				float2 uvPanner1 = uv + _CloudSpeed * float2 (_CloudDirX + 0.02, _CloudDirZ + 0.02) * _Time * _NoiseScale1;
				float2 uvPanner2 = uv + _CloudSpeed * float2 (_CloudDirX - 0.02, _CloudDirZ - 0.02) * _Time * _NoiseScale2;
				o.uv1 = uvPanner1 * (_CloudSize + 0.13);
				o.uv2 = uvPanner2 * _CloudSize;

				// offset
				float3 litOffset = o.lightDir * o.tangentWorld * _OffsetDistance;
				o.uvOffset1 = o.uv1 + litOffset;
				o.uvOffset2 = o.uv2 + litOffset;

				o.uvOffset3 = o.uv1 - litOffset;
				o.uvOffset4 = o.uv2 - litOffset;

				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{

				// sample the texture
				fixed4 texCol1 = tex2D(_NoiseTex, i.uv1);
				fixed4 texCol2 = tex2D(_NoiseTex, i.uv2);
				fixed4 col = texCol1 * texCol2;

				// get light value
				fixed4 texColOffset1 = tex2D(_NoiseTex, i.uvOffset1);
				fixed4 texColOffset2 = tex2D(_NoiseTex, i.uvOffset2);
				fixed light = saturate(texCol1.r + texCol2.r - texColOffset1.r - texColOffset2.r) * _LitStrength;
				// backlight value
				fixed4 texColOffset3 = tex2D(_NoiseTex, i.uvOffset3);
				fixed4 texColOffset4 = tex2D(_NoiseTex, i.uvOffset4);
				fixed backLight = saturate(texCol1.r + texCol2.r - texColOffset3.r - texColOffset4.r) * _BackLitStrength;

				fixed edgeLight = pow((1 - col.r), _EdgeLitPower) * _EdgeLitStrength;

				fixed finalLit = light + backLight + edgeLight;

				// get value to taper top and bottom
				float vFalloff = pow(saturate(abs(_midYValue - i.posWorld.y) / (_cloudHeight * 0.25)), _TaperPower);

				// Subsurface Scatterting
				fixed3 sssCol = pow(saturate(dot(i.viewDir, i.lightDir)), _SssPower) * _SssStrength * _LightColor0;

				clip(col.r - vFalloff - _Cutoff);

				// get cloud color
				fixed4 finalCol = lerp(_MainColor, _LightColor0, finalLit);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, finalCol);

				return finalCol;
			}
			ENDCG
		}
	}
}