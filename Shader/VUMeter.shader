Shader "ryuu/VUmeter"
{
    Properties
    {
        _EmissionMask("Texture", 2D) = "black" {}
        _TextureBandCount("Light Count", Int) = 15

        [Space(2)]
        [Header(AudioLink)]
        [Space]
        [Toggle(USE_FILTERED)] _AudioLinkSmoothToggle("AudioLink Filtered", Float) = 0
        [KeywordEnum(Band,VU)] _Lookup("Lookup Table", Float) = 0
        [Space]

        [Header(Bands)]
        [Space]
        [Enum(One,0,Two,1,Three,2,Four,3)] _BandNumber("Band Number", Float) = 0
                

        [Enum(Left,0,Right,2)] _ChannelNumber("Channel", Float) = 0

        [Space(2)]


        [Header(Colors)]
        [Space(10)]
        [HDR] _RedColor("Red Color", Color) = (1,1,1)
        _RedLimit("Red Limit", Range(0,1)) = 0

        [Space]
        [HDR] _YellowColor("Yellow Color", Color) = (1,1,1)
        _YellowLimit("Yellow Limit", Range(0,1)) = 0

        [Space]
        [HDR] _GreenColor("Green Color", Color) = (1,1,1)

        [Space(10)]
        [Header(Extras)]
        [Toggle(RANDOM_MOVEMENT)] _RandomMovement("Random Movement", Float) = 0
        

    }
    SubShader
    {
            Cull Back
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Tags { "Queue" = "Transparent" }

        Pass
        {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma shader_feature _LOOKUP_VU _LOOKUP_BAND
                #pragma shader_feature USE_FILTERED
                #pragma shader_feature RANDOM_MOVEMENT
                #include "UnityCG.cginc"
                #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _EmissionMask;
            float4 _EmissionMask_ST;
            
            float _BandNumber;
            
            int _TextureBandCount;

            float _ChannelNumber;

            float4 _RedColor;
            float _RedLimit;
            
            float _YellowLimit;
            float4 _YellowColor;

            float4 _GreenColor;

            #define IF(a, b, c) lerp(b, c, step((fixed) (a), 0))

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _EmissionMask);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 texUV = float2(i.uv.x, i.uv.y * _TextureBandCount);
                fixed4 c = tex2D(_EmissionMask, texUV);

                uint2 audioLinkTable;
                uint2 audioLinkUV;
                
                #ifdef USE_FILTERED 
                    #ifdef _LOOKUP_VU
                        audioLinkTable = ALPASS_FILTEREDVU;
                        audioLinkUV = uint2(0, 0);
                    #else
                        audioLinkTable = ALPASS_FILTEREDAUDIOLINK;
                        audioLinkUV = float2(0, _BandNumber);
                        #endif
                #else 
                    #ifdef _LOOKUP_VU
                        audioLinkTable = ALPASS_GENERALVU;
                        audioLinkUV = uint2(8, 0);
                        #else
                        audioLinkTable = ALPASS_AUDIOLINK;
                        audioLinkUV = float2(0, _BandNumber);
                        #endif
                #endif
                i.uv.y = floor(i.uv.y * _TextureBandCount) / _TextureBandCount;
                
                _RedLimit = floor(_RedLimit * _TextureBandCount) / _TextureBandCount;
                _YellowLimit = floor(_YellowLimit * _TextureBandCount) / _TextureBandCount;

                c *= IF(i.uv.y > _RedLimit, _RedColor, IF(i.uv.y > _YellowLimit, _YellowColor, _GreenColor));
                float band;

                #ifdef USE_VU
                    band = AudioLinkLerp(audioLinkTable + audioLinkUV)[_ChannelNumber];
                #else
                    band = AudioLinkLerp(audioLinkTable + audioLinkUV).r;
                #endif
                
                #ifdef RANDOM_MOVEMENT
                band += + (0.3* (sin(_Time.yyy)+2)/2 );
                #endif
                c *= step(i.uv.y, band);
                return c;
            }
            ENDCG
        }
    }
}
