Shader "Custom/Indicator" {
    Properties { 
        _MainTex("Main Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0.17,0.36,0.81,0.0)
        _Angle ("Angle", Range(0, 360)) = 60
        _Gradient ("Gradient", Range(0, 1)) = 0
    }
 
    SubShader {
    Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" }
         Pass {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
  
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
 
            sampler2D _MainTex;
            float4 _Color;
            float _Angle;
            float _Gradient;
  
            struct fragmentInput {
                float4 pos : SV_POSITION;
                float2 uv : TEXTCOORD0;
            };
 
            fragmentInput vert (appdata_base v)
            {
                fragmentInput o;
 
                o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
                o.uv = v.texcoord.xy;
 
                return o;
            }
  
            fixed4 frag(fragmentInput i) : SV_Target {
                // �����ĵ�ľ���
                float distance = sqrt(pow(i.uv.x - 0.5, 2) + pow(i.uv.y - 0.5, 2));
                // ��Բ��
                if(distance > 0.5f){
                    discard;
                }
                // ���ݾ������͸���Ƚ���
                float grediant = (1 - distance - 0.5 * _Gradient) / 0.5;
                // ������ʾ�Ľ��
                fixed4 result = tex2D(_MainTex, i.uv) * _Color * fixed4(1,1,1, grediant);
                float x = i.uv.x;
                float y = i.uv.y;
                float deg2rad = 0.017453;   // �Ƕ�ת����
                // ���ݽǶ��޳�������Ҫ��ʾ�Ĳ���
                // ����180��
                if(_Angle > 30){
                    if(y > 0.5 && abs(0.5 - y) >= abs(0.5 - x) / tan((180 - _Angle / 2) * deg2rad))
                        discard;// �޳�
                }
                else    // 180������
                {
                    if(y > 0.5 || abs(0.5 -y) < abs(0.5 - x) / tan(_Angle / 2 * deg2rad))
                        discard;
                }
                return result;
            }
 
            ENDCG
        }
    } 
    FallBack "Diffuse"
}