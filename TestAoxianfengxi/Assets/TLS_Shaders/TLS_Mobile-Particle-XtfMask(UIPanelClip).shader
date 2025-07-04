// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TLStudio/Effect/Xtf_Maskblend(UIPanelClip)" {
Properties {
 _TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
 _MainTex ("Main Texture", 2D) = "white" {}
 _MaskTex ("Mask Texture (RG)", 2D) = "white" {}
 _ScrollTimeX  ("Scroll X Factor", Float) = 0
 _ScrollTimeY  ("Scroll Y Factor", Float) = 0
 _ClipRange0("_ClipRange0", Vector) = (0.0, 0.0, 1.0, 1.0)
 _ClipArgs0("_ClipArgs0", Vector) = (1000.0, 1000.0, 1.0, 1.0)
}

Category {
 Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
 Blend SrcAlpha One
 Cull Off Lighting Off ZWrite Off
 BindChannels {
     Bind "Color", color
     Bind "Vertex", vertex
     Bind "TexCoord", texcoord
 }
 
 // ---- Fragment program cards
 SubShader {
     Pass {
     
         CGPROGRAM
         #pragma vertex vert
         #pragma fragment frag
         //#pragma fragmentoption ARB_precision_hint_fastest
         //#pragma multi_compile_particles
         
         #include "UnityCG.cginc"

         sampler2D _MainTex;
         sampler2D _MaskTex;
		 float _ScrollTimeX;
		 float _ScrollTimeY;
         fixed4 _TintColor;
         float4 _ClipRange0;
         float2 _ClipArgs0;
         
         struct appdata_t {
             float4 vertex : POSITION;
             fixed4 color : COLOR;
             float2 texcoord : TEXCOORD0;
         };

         struct v2f {
             float4 vertex : POSITION;
             fixed4 color : COLOR;
             float2 texcoord : TEXCOORD0;
             float2 worldPos : TEXCOORD1;
         };
         
         v2f vert (appdata_t v)
         {
             v2f o;
             o.vertex = UnityObjectToClipPos(v.vertex);
             o.color = v.color;
             o.texcoord = v.texcoord;
             float2 clipSpace = o.vertex.xy / o.vertex.w;
             clipSpace = (clipSpace.xy + 1) * 0.5;
             o.worldPos = clipSpace * _ClipRange0.zw + _ClipRange0.xy;
             return o;
         }
         fixed4 frag (v2f i) : COLOR
         {
             float2 uvoft = i.texcoord;
             uvoft.x += _Time.y*_ScrollTimeX;
             uvoft.y += _Time.y*_ScrollTimeY;
             fixed4 offsetColor = tex2D(_MaskTex, uvoft);
             fixed grayscale = Luminance(offsetColor.rgb);
             fixed4 mainColor = tex2D(_MainTex, i.texcoord);
             float4 col = 2.0f * i.color * _TintColor * mainColor * grayscale;
             float2 factor = (float2(1.0, 1.0) - abs(i.worldPos)) * _ClipArgs0;
             col.a *= clamp(min(factor.x, factor.y), 0.0, 1.0);
             return col;
         }
         ENDCG
     }
 }   
}
}