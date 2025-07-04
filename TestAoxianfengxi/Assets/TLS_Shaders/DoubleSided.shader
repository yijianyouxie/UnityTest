    Shader "Custom/DoubleSided"
    {
        Properties 
        {
            _Color ("Main Color", Color) = (1,1,1,1)
            _MainTex ("Base (RGB)", 2D) = "white" {}
            _Cutoff ("Alpha cutoff", Range (0,1)) = 0.5
        }
        SubShader 
        {
            Pass
            {
            	Cull Off
            	AlphaTest Greater [_Cutoff]
     
        		Material 
        		{
            		//Diffuse [_MainTex]
       		 	}
        		SetTexture [_MainTex] 
        		{
            		constantColor [_Color]
            	}
        	}
        }
        FallBack "Diffuse", 1
    }