Shader "KPinURP/Base"
{
    Properties
    {
        _BaseColor("Main Color",color) = (1,1,1,1)
        _AmbientColor("AmbientColor",color) = (1,1,1,1)
        _Specular("高光强度", float) = 0
        _SpecularColor("高光颜色", Color) = (1,1,1,1)
        _BaseMap("Main Tex",2D) = "white"
        _UvSpeed("speed", float) = 0.0
    }
 
    SubShader
    {
        Tags { 
            
            "Queue"="Geometry"
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "RenderPipeline" = "UniversalPipeline"
            
        }
        LOD 100
        
        
 
        Pass
        {
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half3 _SpecularColor;
            half4 _AmbientColor;
            TEXTURE2D (_BaseMap);
            SAMPLER(sampler_BaseMap);
            float4 _BaseMap_ST;
            half _Specular;
            CBUFFER_END
            
            half valve_lambert(float nl)
            {
                // Valve公司改善兰伯特
                nl = 0.5 * nl + 0.5;
                return nl;
            }
            
 
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : NORMAL;
                float3 positionWS : TEXCOORD1;
            };
             
            Varyings vert(Attributes input)
            {
                Varyings output;
 
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX( input.uv , _BaseMap);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                return output;
            }
 
            half4 frag(Varyings input) : SV_Target
            {
                half4 col;
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);

                half3 normal = normalize(input.normalWS);
                Light light = GetMainLight();
                half3 lightDir = normalize(light.direction);
                half NdotL =  normal * lightDir;
                
                

                // 环境光颜色
                float3  ambient;
                ambient = _AmbientColor;

                // 漫反射
                half3 diffuse = baseMap.rgb * _BaseColor * valve_lambert(NdotL) * light.color;

                // 镜面反射
                half3 viewDir =  normalize(input.positionWS - _WorldSpaceCameraPos);// 在空间中，用点A减去点B时，得到的向量是从B指向A的；在这里我需要获得的是相机指向物体的向量(观察者向量)
                half3 ref = reflect(lightDir, normal);// reflect()函数计算反射向量，公式为L - 2(L · N)N
                float3 specular =pow(max(dot(viewDir,ref),0.0), _Specular) * _SpecularColor;// 计算反射向量与视线向量的夹角，得到高光强度值


                col.rgb = diffuse + specular; 
                col.a = baseMap.a;
      

                return col;
            }
            ENDHLSL
        }
    }
}