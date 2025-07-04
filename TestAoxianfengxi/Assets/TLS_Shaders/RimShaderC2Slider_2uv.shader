// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Shader created with Shader Forge v1.38 
// Shader Forge (c) Neat Corporation / Joachim Holmer - http://www.acegikmo.com/shaderforge/
// Note: Manually altering this data may prevent you from opening it in Shader Forge

Shader "FXEffect/TT_Change2Slider_2uv" {
    Properties {
        _Texture ("Texture", 2D) = "bump" {}
        _Inlinecolor ("Inlinecolor", Color) = (0.55,0.7,1,1)
        _SliderColorPower ("SliderColorPower", Range(0, 2) ) = 1//[MaterialToggle] 
        _Inlineslider ("Inlineslider", Range(0, 3)) = 0.5
        _Alpha ("Alpha", Range(0, 1)) = 0.2
        _Normal ("Normal", 2D) = "bump" {}
        _Normalslider ("Normalslider", Range(0, 1)) = 0.2535667
		_Flow_Texture("Flow_Texture", 2D) = "white" {}
		_Color("Flow Color", Color) = (1,1,1,1)
		_SpeedX("SpeedX", Float) = 1
		_SpeedY("SpeedY", Float) = 1
		_Vis("Visiable" , Range(0,1)) = 1
		_MSpeedX("MSpeedX", Float) = 1
		_MSpeedY("MSpeedY", Float) = 1
		//_MVis("MVisiable" , Range(0,1)) = 1
		//_SpecPower ("Spec Power", Range(0.02, 2)) = 2
		//_Gloss ("Gloss",Range(1,1024)) = 900
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
		Pass {
			ZWrite On
			ColorMask 0
		}
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //#define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            //#pragma multi_compile_fwdbase
            //#pragma only_renderers d3d9 d3d11 glcore gles 
            /#pragma target 3.0
            uniform float4 _LightColor0;
            uniform sampler2D _Texture; uniform float4 _Texture_ST;
            uniform float4 _Inlinecolor;
            uniform fixed _SliderColorPower;
            uniform float _Inlineslider;
            uniform half _Alpha;
            uniform sampler2D _Normal; uniform float4 _Normal_ST;
            uniform float _Normalslider;
			//uniform float _SpecPower;
			//uniform float _Gloss;
			sampler2D _Flow_Texture;
			fixed4	_Flow_Texture_ST;
			fixed4	_Color;
			fixed	_SpeedX;
			fixed	_SpeedY;
			fixed	_Vis;
			fixed	_MSpeedX;
			fixed	_MSpeedY;
			fixed	_MVis;


            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
				
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
               //float3 tangentDir : TEXCOORD3;
			   //float3 bitangentDir : TEXCOORD4;
                float4 projPos : TEXCOORD5;
				fixed2 uv2 : TEXCOORD6;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
				//o.normalDir = normalize(mul(float4(v.normal, 0.0), _World2Object).xyz);
				o.normalDir = normalize(mul(float4(v.normal, 0.0), unity_ObjectToWorld).xyz);
               // o.normalDir = UnityObjectToWorldNormal(v.normal);
			   //  o.tangentDir = normalize( mul(_Object2World, float4( v.tangent.xyz, 0.0 ) ).xyz );
			   //  o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos(v.vertex );
                o.projPos = ComputeScreenPos (o.pos);
                COMPUTE_EYEDEPTH(o.projPos.z);

				//, TRANSFORM_TEX(i.uv0, _Texture)
				fixed2 uv0 = TRANSFORM_TEX(v.texcoord0, _Texture);
				fixed2 uv2 = TRANSFORM_TEX(v.texcoord0, _Flow_Texture);
				if (_Vis >= 0.1)
				{
					fixed modtime = fmod(_Time.x, 60);
					o.uv0.x = uv0.x + modtime * _MSpeedX;
					o.uv0.y = uv0.y + modtime * _MSpeedY;
					o.uv2.x = uv2.x + modtime * _SpeedX;
					o.uv2.y = uv2.y + modtime * _SpeedY;
				}
				else
				{
					o.uv0.x = uv0.x;
					o.uv0.y = uv0.y;
					o.uv2.x = uv2.x;
					o.uv2.y = uv2.y;
				}
			
                return o;
            }
			
			float4 frag(VertexOutput i) : COLOR {
				// i.normalDir = normalize(i.normalDir);
			// float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
				// float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				// float3 _Normal_var = UnpackNormal(tex2D(_Normal,TRANSFORM_TEX(i.uv0, _Normal)));//UnpackNormalDXT5nm
				// float3 normalLocal = lerp(float3(0,0,1),_Normal_var.rgb,_Normalslider);
				// float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
		 // float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				// float3 lightColor = _LightColor0.rgb;
				//  float4 _Texture_var = tex2D(_Texture,i.uv0);
				
				//half3 h = normalize (lightDirection + viewDirection);
				//fixed diff = max (0, dot (normalDirection, lightDirection));
				//float nh = max (0, dot (normalDirection, h));
				//float spec = pow (nh, _Gloss) * _SpecPower;


				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				float3 normalDirection = normalize(i.normalDir);
				
				fixed4 Tex2D1 = tex2D(_Flow_Texture, i.uv2);
				fixed4 _Texture_var = tex2D(_Texture, TRANSFORM_TEX(i.uv0, _Texture));
				fixed alpha = pow((1.0-max(0,dot(normalDirection, viewDirection))),_Inlineslider) * _SliderColorPower;
				
				fixed3 finalColor = _Inlinecolor;// * spec;	
				fixed3 finalTexCol =_Inlinecolor *_Texture_var;  
				
				finalColor = finalColor * _Texture_var + alpha *_Inlinecolor.rgb ;
				finalColor = lerp(finalColor,finalTexCol,_Alpha)+ Tex2D1*_Vis*_Color;
				return fixed4(finalColor,(max(alpha,_Alpha*(alpha*5))));
            }
			
			
            ENDCG
        }
    }
    FallBack "Diffuse"
}
