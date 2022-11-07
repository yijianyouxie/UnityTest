Shader "FurShader/FurShader_MultiPass"
{
    Properties
    {
        //基本颜色
        _MainTex ("Texture", 2D) = "white" { }
        _Color ("FurColor", Color) = (1, 1, 1, 1)
        _RootColor ("FurRootColor", Color) = (0.5, 0.5, 0.5, 1)

        //光照相关参数
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Shininess ("Shininess", Range(0.01, 256.0)) = 8.0       
        _RimColor ("Rim Color", Color) = (0, 0, 0, 1)
        _RimPower ("Rim Power", Range(0.0, 8.0)) = 6.0

        //毛发参数
        _FurTex ("Fur Pattern", 2D) = "white" { }     
        _FurLength ("Fur Length", Range(0.0, 1)) = 0.5
        _FurShadow ("Fur Shadow Intensity", Range(0.0, 1)) = 0.25     

		_LayerCount("LayerCount", Range(0, 50)) = 10
		_FurOffset("_FurOffset", vector) = (0, -0.2, 0, 0)
		_FurTenacity("FurTenacity韧性", Range(0, 10)) = 4
    }

	CGINCLUDE
	#include "Lighting.cginc"   
	#include "UnityCG.cginc"

	sampler2D _MainTex;
	half4 _MainTex_ST;
	fixed4 _Color;
	fixed4 _RootColor;
	fixed4 _Specular;
	fixed _Shininess;

	sampler2D _FurTex;
	half4 _FurTex_ST;
	fixed _FurLength;
	fixed _FurShadow;

	float3 _FurOffset;
	float _FurTenacity;

	fixed4 _RimColor;
	half _RimPower;

	//float _LayerOffset;
	float _LayerCount;

	float FurMask;
	float _tming;

	struct a2v {
		float4 vertex : POSITION;//顶点位置
		float3 normal : NORMAL;//发现
		float4 texcoord : TEXCOORD0;//纹理坐标
		float4 texcoord2 : TEXCOORD1;//纹理坐标
	};

	struct v2f
	{
		float4 pos: SV_POSITION;
		half4 uv: TEXCOORD0;
		float3 worldNormal: TEXCOORD1;
		float3 worldPos: TEXCOORD2;
	};

	v2f vert(a2v v, float index)
	{
		v2f o;
		float _LayerOffset = 1.0f / _LayerCount * index;
		o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
		//fixed4 n = tex2Dlod(_FurTex, half4(o.uv.xy, 0, 0));
		float3 OffetVertex = v.vertex.xyz + v.normal * _LayerOffset *_FurLength;//顶点外扩
		OffetVertex += mul(unity_WorldToObject, _FurOffset * pow(_LayerOffset, _FurTenacity));//顶点受力偏移

		o.pos = UnityObjectToClipPos(float4(OffetVertex, 1.0));
		//o.uv.zw = TRANSFORM_TEX(v.texcoord2, _FurTex);
		o.worldNormal = UnityObjectToWorldNormal(v.normal);
		o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

		return o;
	}

	fixed4 frag(v2f i, float index) : SV_Target
	{
		float _LayerOffset = 1.0f / _LayerCount * index;
		fixed3 worldNormal = normalize(i.worldNormal);
		fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
		fixed3 worldView = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
		fixed3 worldHalf = normalize(worldView + worldLight);

		fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color;
		half vdotn = 1.0 - saturate(dot(worldView, worldNormal));
		fixed3 rim = _RimColor.rgb *  _RimColor.a * saturate(1 - pow(1 - vdotn, _RimPower));

		fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
		fixed3 diffuse = _LightColor0.rgb * albedo * (0.5f*saturate(dot(worldNormal, worldLight)) + 0.5f);
		fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, worldHalf)), _Shininess);

		fixed3 color = ambient + diffuse + specular + rim;
		color = lerp(_RootColor,color,saturate(pow(_LayerOffset,_FurShadow)));

		//fixed3 noise = tex2D(_FurTex, i.uv.zw).rgb;
		fixed3 noise = tex2D(_FurTex, i.uv.xy).rgb;
		fixed alpha = saturate(noise.x - (_LayerOffset * _LayerOffset));
		//fixed alpha = saturate((noise * 2 - (_LayerOffset *_LayerOffset + (_LayerOffset* FurMask * 5)))*_tming);


		return fixed4(color * noise, alpha);
	}
	ENDCG

    SubShader
    {
        Tags { "RenderType" = "Transparent" "IgnoreProjector" = "True" "Queue" = "Transparent" }
        
        //Cull Off
		//改成裁剪后边了，与关闭裁剪的效果相同
		Cull Back
        ZWrite On
        //ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
			v2f vertPass(a2v v)
			{				
				return vert(v, 0);
			}
			fixed4 fragPass(v2f i):SV_Target
			{
				return frag(i, 0);
			}
            ENDCG
        }
		Pass
		{
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
				v2f vertPass(a2v v)
			{
				return vert(v, 1);
			}
			fixed4 fragPass(v2f i) :SV_Target
			{
				return frag(i, 1);
			}
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
			v2f vertPass(a2v v)
			{
				return vert(v, 2);
			}
			fixed4 fragPass(v2f i) :SV_Target
			{
				return frag(i, 2);
			}
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
			v2f vertPass(a2v v)
			{
				return vert(v, 3);
			}
			fixed4 fragPass(v2f i) :SV_Target
			{
				return frag(i, 3);
			}
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
			v2f vertPass(a2v v)
			{
				return vert(v, 4);
			}
			fixed4 fragPass(v2f i) :SV_Target
			{
				return frag(i, 4);
			}
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
			v2f vertPass(a2v v)
			{
				return vert(v, 5);
			}
			fixed4 fragPass(v2f i) :SV_Target
			{
				return frag(i, 5);
			}
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
			v2f vertPass(a2v v)
			{
				return vert(v, 6);
			}
			fixed4 fragPass(v2f i) :SV_Target
			{
				return frag(i, 6);
			}
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
			v2f vertPass(a2v v)
			{
				return vert(v, 7);
			}
			fixed4 fragPass(v2f i) :SV_Target
			{
				return frag(i, 7);
			}
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
			v2f vertPass(a2v v)
			{
				return vert(v, 8);
			}
			fixed4 fragPass(v2f i) :SV_Target
			{
				return frag(i, 8);
			}
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
			v2f vertPass(a2v v)
			{
				return vert(v, 9);
			}
			fixed4 fragPass(v2f i) :SV_Target
			{
				return frag(i, 9);
			}
			ENDCG
		}
		/*Pass
		{
			CGPROGRAM
			#pragma vertex vertPass
			#pragma fragment fragPass
			v2f vertPass(a2v v)
			{
				return vert(v, 10);
			}
			fixed4 fragPass(v2f i) :SV_Target
			{
				return frag(i, 10);
			}
			ENDCG
		}*/
    }
}
