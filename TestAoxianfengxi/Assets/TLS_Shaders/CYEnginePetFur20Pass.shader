Shader "Pet Fur/CYEnginePetFur20Pass" 
{
	Properties 
	{
		[Header(Basic Setting)][Space(10)]
        _FurColor ("外层毛发颜色", Color) = (1,1,1,1)
		_BaseColor ("内层毛发颜色", Color) = (0.9,0.9,0.9,1)
		
        [NoScaleOffset]_MainTex ("主纹理", 2D) = "white" { }
        [NoScaleOffset]_FurControlTex ("控制图(R:毛长，G:毛粗细，B:流向图强度)", 2D) = "white" { }     
        _FurNoiseTex ("毛发噪声图(Tilling控制毛发的粗细)", 2D) = "white" { }	
		[NoScaleOffset]_FlowMap("毛发走向图", 2D) = "bump"{}
		_FlowMapStrength("毛发走向强度", Range(-1,1)) = 0
		_UVOffset("毛发走向UV强度", Range(-1,1)) = 0
		
        _MaxHairLength ("毛发长度", Range(0,0.5)) = 0.02
		_Thickness ("毛发密度控制1", Range(0, 0.5)) = 0
		_FurDensity("毛发密度控制2", Range(0, 1)) = 1
		
		[Space(20)][Header(Light Setting)][Space(10)]
		
      	_RimPower ("边缘光范围", Range(0.5,8.0)) = 2.0
		_RimStrength ("边缘光强度", Range(0, 5)) = 2.0
		_EnvironmentLightControl("环境光亮度调制", Range(0.0, 3.0)) = 1
		_TotalLightControl("整体亮度调制", Range(0.0, 3.0)) = 1
        
		[Space(20)][Header(Dirty Effect)][Space(10)]
		_DissolveAmount ("干净程度(程序调用接口)", Range (0, 1)) = 1
		_DissolveInfo ("x:最脏程度, y:污点偏移, z:污点密度, w:上下身变脏差异", Vector) = (0.6, 0.85, 0.4, 0.66)
		[NoScaleOffset]_DissolveSrc ("变脏噪声图", 2D) = "white" {}
		
		[Space(20)][Header(FatThin Effect)][Space(10)]
		_ExtraControl ("其他控制功能，x:胖瘦程度", Vector) = (0, 0, 0, 0)
		
		[Space(20)][Header(Decal Effect)][Space(10)]
		[NoScaleOffset]_DecalTex("贴花图", 2D) = "black" {}
		_DecalColor("贴花颜色", Color) = (1,1,1,1)

		[Space(20)][Header(Cloth Mask)][Space(10)]
		[NoScaleOffset]_ControlAddTex ("衣服Mask图", 2D) = "white" { }     
 	}
	
	SubShader 
	{
		ZWrite On
		Tags { "QUEUE"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True"}	
		//Blend SrcAlpha OneMinusSrcAlpha
		LOD 150

		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG
		}

		ZWrite Off ColorMask RGB
		
		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.10

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG
		}
		
		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.15

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG
		}
		
		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.20

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG
		}
		
		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.25

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG
		}
			
	    Pass
	    {
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.30

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG
		}

		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
	
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.35

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG
		}

		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.40

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG
		}

		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
	
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.45

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG

		}
		
		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
	
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.50

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG

		}

		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
		
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.55

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG
		}

		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
		
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.60

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG
		}

		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.65

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG

		}
		
		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.70

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG

		}
		
		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.75

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG

		}
		
		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.80

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG

		}
		
		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.85

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG

		}
		
		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.90

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG

		}

		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 0.95

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG

		}

		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert_surf_simplified
			#pragma fragment frag_surf_simplified
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
			/*#pragma target 3.0

			#pragma multi_compile FOG_EXP2 FOG_LINEAR
			#pragma multi_compile_fwdbasealpha noshadow
			#pragma shader_feature __ DEBUG_FUR*/
		
			#define FURSTEP 1.0

			#include "Pet_Fur_New_Lib.cginc"
			ENDCG
		}
	} 

	FallBack "VertexLit"
    CustomEditor "PetFurShaderGUI"
}
