// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Parallax/Parallax_HeightMap"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _HeightMap("Height Texture", 2D) = "white" {}
        HeightScale("Scale", Vector) = (0.1, 0.1, 0, 0)
        HeightThreshold("HeightThreshold", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
		    #pragma exclude_renderers xbox360 ps3 flash d3d11_9x

            struct appdata
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 objViewDir : TEXCOORD1;
                float3 objPos : TEXCOORD3;
            };

            sampler2D _MainTex;
            sampler2D _HeightMap;

            float4 HeightScale;
            float HeightThreshold;
            float4x4 CustomWorld2Object;

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;
                float3 objPos = v.vertex;
                float3 objCamPos = mul(CustomWorld2Object, float4(_WorldSpaceCameraPos.xyz, 1));
                //float3 objCamPos = mul(_World2Object, float4(_WorldSpaceCameraPos.xyz, 1));
                o.objViewDir = normalize(objCamPos - objPos);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                /*if (_World2Object[1][2] == 0)
                    return float4(1,0,0,1);*/
                float heightValue = tex2D(_HeightMap, i.uv).r;
                heightValue = (heightValue - HeightThreshold) * 0.5;
                float2 viewScale = i.objViewDir.xy * HeightScale * heightValue;
                float2 offsetUV = viewScale + i.uv;
                float4 cardCol = tex2D(_MainTex, i.uv);
                clip(cardCol.a - 0.5);
                float4 newCardCol = tex2D(_MainTex, offsetUV);
                //clip(newCardCol.a - 1);
                //newCardCol.a = smoothstep(0, 1, newCardCol.a);
                //return newCardCol;
                return newCardCol;
            }
            ENDCG
        }
    }
}