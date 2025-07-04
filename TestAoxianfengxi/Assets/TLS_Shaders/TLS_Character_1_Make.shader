Shader "TLStudio/Character/Character_Make" 
{
    Properties 
	{
		_Color("AddColor", Color) = (0,0,0,1)
        _MainTex ("MainTex", 2D) = "black" {}
        _Reflection ("Reflection", 2D) = "white" {}
        _RimColor ("RimColor", Color) = (1,1,1,1)
		_ReflectionIntension("Reflection Intensity",Range(0,1)) = 0.5
		FogSwitch("FogSwitch", float) = 0
		
		_PosX("PosX", Range (-1, 1)) = 0
		_PosY("PosY", Range (-1, 1)) = 0
		_Angle("Angle", Range (0, 360)) = 0
		_Scale("Scale", Range (0.1, 2)) = 1
		_Mirror("Mirror", Range (0, 1)) = 0
    }
    SubShader 
	{
        Tags 
		{
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
		LOD 150

        Pass 
		{
            Name "ForwardBase"
            Tags 
			{
                "LightMode"="ForwardBase"
            }
            ColorMask RGBA
			Blend SrcAlpha OneMinusSrcAlpha  
            CGPROGRAM
            #pragma skip_variants FOG_EXP INSTANCING_ON DIRECTIONAL DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SHADOWS_SCREEN SHADOWS_SHADOWMASK VERTEXLIGHT_ON SHADOWS_CUBE SHADOWS_DEPTH POINT SPOT UNITY_HDR_ON
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            //#define SHOULD_SAMPLE_SH_PROBE ( defined (LIGHTMAP_OFF) )
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #pragma exclude_renderers xbox360 ps3 flash d3d11_9x
            /*#pragma multi_compile __ PROJECTOR_DEPTH_MAP_ON
            #include "DepthMapShadow.cginc"*/
            uniform float4 _LightColor0;
            uniform sampler2D _Reflection; uniform float4 _Reflection_ST;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform fixed4 _Color;
            uniform fixed4 _RimColor;
            uniform fixed _ReflectionIntension;
			uniform fixed _PosX;
			uniform fixed _PosY;
			uniform fixed _Angle;
			uniform fixed _Scale;
			uniform int _Mirror;
            struct VertexInput 
			{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput 
			{
                float4 pos : SV_POSITION;
                half2 uv0 : TEXCOORD0;
                fixed3 viewDirection : TEXCOORD1;
                fixed3 normalDir : TEXCOORD2;
                LIGHTING_COORDS(3,4)
                float3 shLight : TEXCOORD5;
                float4 posWorld:TEXCOORD6;
            };
            VertexOutput vert (VertexInput v) 
			{
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);//  mul(_Object2World, float4(v.normal,0)).xyz;
                //#if SHOULD_SAMPLE_SH_PROBE
                o.shLight = ShadeSH9(float4(o.normalDir * 1.0,1));
                //#endif
                o.posWorld = mul(unity_ObjectToWorld , v.vertex);
                o.viewDirection = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR 
			{
                i.normalDir = normalize(i.normalDir);
/////// Vectors:
                fixed3 normalDirection = i.normalDir;

				float2 center = float2(0.5, 0.5);
		
				i.uv0 = i.uv0 - center;
				// 平移
				i.uv0 = i.uv0 + float2(_PosX, _PosY);
				// 缩放
				i.uv0 = i.uv0 / _Scale;
				// 旋转
				float rot = _Angle * UNITY_PI / 180.0f;
				// float3x3 roate = float3x3(cos(rot), -sin(rot), 0, sin(rot), cos(rot), 0, 0, 0, 1);
				float2x2 roate = float2x2(cos(rot), -sin(rot), sin(rot), cos(rot));
				i.uv0 = mul(i.uv0, roate);
			
				i.uv0 = i.uv0 + center;
				// 镜像
				i.uv0.x = (1 - i.uv0.x) * _Mirror + i.uv0.x * (1 -_Mirror);

				fixed4 _MainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
                fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
////// Lighting:
                fixed attenuation = LIGHT_ATTENUATION(i)*0.9;
                fixed3 attenColor = attenuation*_LightColor0.xyz;
/////// Diffuse:
                fixed NdotL = max(0.2,dot( normalDirection, lightDirection ));
                //fixed3 indirectDiffuse = UNITY_LIGHTMODEL_AMBIENT.rgb;
                fixed3 directDiffuse = NdotL* attenColor;
                //#if SHOULD_SAMPLE_SH_PROBE
                fixed3 indirectDiffuse = i.shLight;
                //#endif
                fixed3 diffuse = (directDiffuse + indirectDiffuse) * _MainTexColor.rgb;
////// Emissive:
				fixed rimRange = 1-abs(dot(i.viewDirection,normalDirection));
                half2 ReflUV = mul( UNITY_MATRIX_V, float4(normalDirection,0)).rg*0.5+0.5;
                fixed4 _Reflection_var = tex2D(_Reflection,TRANSFORM_TEX(ReflUV, _Reflection));
				//fixed ReflectionRange = tex2D(_Reflection, TRANSFORM_TEX(i.uv0, _MainTex));
                fixed3 emissive = _Color.rgb+_Reflection_var.rgb*_ReflectionIntension+rimRange*rimRange*_RimColor;
				//float3 emissive = _Color.rgb + _Reflection_var.rgb*ReflectionRange;
/// Final Color:
                fixed3 finalColor = diffuse + emissive;
                /*finalColor *= ShadowColorAtten(i.posWorld);
				#ifdef PROJECTOR_DEPTH_MAP_ON
				finalColor *= ProjectorShadowColorAtten(i.posWorld);
				#endif*/
                return fixed4(finalColor,_MainTexColor.a);
            }
            ENDCG
        }
    }
	FallBack "Mobile/Diffuse"
}
