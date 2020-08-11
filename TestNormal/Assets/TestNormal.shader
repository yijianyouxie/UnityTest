/*Shader "Example/Diffuse Bump" {
    Properties {
      _MainTex ("Texture", 2D) = "white" {}
      _BumpMap ("Bumpmap", 2D) = "bump" {}
    }
    SubShader {
      Tags { "RenderType" = "Opaque" }
      CGPROGRAM
      #pragma surface surf Lambert
      struct Input {
        float2 uv_MainTex;
        float2 uv_BumpMap;
      };
      sampler2D _MainTex;
      sampler2D _BumpMap;
      void surf (Input IN, inout SurfaceOutput o) {
        o.Albedo = tex2D (_MainTex, IN.uv_MainTex).rgb;
        o.Normal = UnpackNormal (tex2D (_BumpMap, IN.uv_BumpMap));
      }
      ENDCG
    } 
    Fallback "Diffuse"
  }
  
Shader "TLStudio/Opaque/Diffuse" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Base (RGB)", 2D) = "white" {}
	_BumpMap("Bumpmap", 2D) = "bump" {}
	}
		SubShader{
		Tags{ "RenderType" = "Opaque" }
		LOD 200

		CGPROGRAM
#pragma surface surf Lambert noforwardadd

		sampler2D _MainTex;
	sampler2D _BumpMap;
	fixed4 _Color;

	struct Input {
		half2 uv_MainTex;
		float2 uv_BumpMap;
	};

	void surf(Input IN, inout SurfaceOutput o) {
		fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
		o.Albedo = c.rgb*_Color.rgb;
		//o.Alpha = c.a*_Color.a;

		o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
		//o.Emission = _Color.rgb*0.1 ;
	}
	ENDCG
	} 
    Fallback "Diffuse"
  }*/
  
  Shader "Custom/UsingNormalMaps" {
 Properties {
  _MainTex ("Base (RGB)", 2D) = "white" {}
  _Bump ("Bump", 2D) = "bump" {}
  _Specular ("Specular", Range(1.0, 500.0)) = 250.0
  _Gloss ("Gloss", Range(0.0, 1.0)) = 0.2
 }
 SubShader {
  Tags { "RenderType"="Opaque" }
  LOD 200
   
  Pass {
   Tags { "LightMode" = "ForwardBase" }
     
   CGPROGRAM
     
   #pragma vertex vert
   #pragma fragment frag
   #pragma multi_compile_fwdbase
      
   #include "UnityCG.cginc"
   #include "Lighting.cginc"
   #include "AutoLight.cginc"
     
   uniform float4x4 _LightMatrix0; // 引入光矩阵
   sampler2D _MainTex;
   sampler2D _Bump;
   float _Specular;
   float _Gloss;

   float4 _MainTex_ST;
   float4 _Bump_ST;
     
   struct a2v {
    float4 vertex : POSITION;  // 输入的模型顶点信息
    fixed3 normal : NORMAL;   // 输入的法线信息
    fixed4 texcoord : TEXCOORD0; // 输入的坐标纹理集
	fixed4 texcoord2 : TEXCOORD1; // 输入的坐标纹理集
    fixed4 tangent : TANGENT;  // 切线信息
   };
     
   struct v2f {
    float4 pos : POSITION; // 输出的顶点信息
    fixed2 uv : TEXCOORD0; // 输出的UV信息
	fixed2 uv2 : TEXCOORD5; // 输出的UV信息
    fixed3 lightDir: TEXCOORD1; // 输出的光照方向
    fixed3 viewDir : TEXCOORD2; // 输出的摄像机方向
    //LIGHTING_COORDS(3,4) // 封装了下面的写法
    float3 _LightCoord : TEXCOORD3;  // 光照坐标
    float4 _ShadowCoord : TEXCOORD4; // 阴影坐标
   };
     
   v2f vert(a2v v) {
    v2f o;
    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
	o.uv2 = TRANSFORM_TEX (v.texcoord2, _Bump);
       
    // 创建一个正切空间的旋转矩阵,TANGENT_SPACE_ROTATION由下面两行组成
    //TANGENT_SPACE_ROTATION;
    float3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
    float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal );
    
    // 将顶点的光方向，转到切线空间
    // 该顶点在对象坐标中的光方向向量,乘以切线空间旋转矩阵
    o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
    // 该顶点在摄像机坐标中的方向向量,乘以切线空间旋转矩阵
    o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
       
    // 将照明信息给像素着色器，应该是用于下面片段中光衰弱atten的计算
      // TRANSFER_VERTEX_TO_FRAGMENT(o); // 由下面两行组成
    // 顶点转到世界坐标,再转到光坐标
    o._LightCoord = mul(_LightMatrix0, mul(_Object2World, v.vertex)).xyz;
    // 顶点转到世界坐标，再从世界坐标转到阴影坐标
    o._ShadowCoord = mul(unity_World2Shadow[0], mul(_Object2World, v.vertex));
    // 注：把上面两行代码注释掉，也看不出上面效果，或许我使用的是平行光
    return o;
   }
     
   fixed4 frag(v2f i) : COLOR {
    // 对主纹理进行采样
    fixed4 texColor = tex2D(_MainTex, i.uv);
    // 对法线图进行采样
    fixed3 norm = UnpackNormal(tex2D(_Bump, i.uv));
    // 光衰弱，卧槽，里面封装了比较深，暂时看不进去，就不拆开了
    fixed atten = LIGHT_ATTENUATION(i);
    // 环境光，Unity内置
    fixed3 ambi = UNITY_LIGHTMODEL_AMBIENT.xyz;
    // 求漫反射
    // 公式：漫反射色 = 光颜色*N,L的余弦值(取大于0的)，所以夹角越小亮度越小
    fixed3 diff = _LightColor0.rgb * saturate (dot (normalize(norm),  normalize(i.lightDir))) * 2;

    // 计算反射光线向量
    // 公式：reflect(入射光方向,法线向量)
    fixed3 refl = reflect(-i.lightDir, norm);
    // 计算反射高光
    // 公式：反射高光 = 光颜色 * 【(反射光向量，摄像机方向向量)的余弦值】的【高光指数_Specular】次方 * 光泽度
    fixed3 spec = _LightColor0.rgb * pow(saturate(dot(normalize(refl), normalize(i.viewDir))), _Specular) * _Gloss;
    // 最终颜色
    // 公式：(环境光 + (漫反射 + 反射高光) * 光衰弱 ) * 材质主色
    fixed4 fragColor;
    fragColor.rgb = float3((ambi + (diff + spec) * atten) * texColor);
    fragColor.a = 1.0f;
    return fragColor;
    }
    ENDCG
  }
 }
 FallBack "Diffuse"
}