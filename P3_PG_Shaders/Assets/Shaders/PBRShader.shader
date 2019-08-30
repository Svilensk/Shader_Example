
//Shader especializado para poder utilizarse con el "LIGHTWEIGHT RENDER PIPELINE" de Unity 3D

Shader "Lightweight Render Pipeline/4.0.0-preview/Physically Based Example"
{
	Properties
	{
		_Color("Main Color", Color)         = (0.5,0.5,0.5,1)
		_DetailColor("Detail Color", Color) = (0.5,0.5,0.5,1)

		_MainTex("Albedo", 2D) = "white" {}
		_MaskTex("Mask"  , 2D) = "white" {}

		_Glossiness ("Smoothness", Range(0.0, 1.0)) = 0.5
		_Metallic   ("Metallic"  , Range(0.0, 1.0)) = 0.0

		_ReceiveShadows("Receive Shadows", Float) = 1.0
	}

	SubShader
	{

			//Necesario añadir el tag "RenderPipeline" para el shader si se busca usar en un LWRP
			Tags{"RenderType" = "Opaque" "RenderPipeline" = "LightweightPipeline" "IgnoreProjector" = "True"}
			LOD 300

			// Pase principal, encargado de iluminación global y fuentes de luz
			Pass
			{
				Name "StandardLit"
				Tags{"LightMode" = "LightweightForward"}

				HLSLPROGRAM

				//Todos los shader usados en LWRP deben compilarse con HLSLcc, gles no usa HLSLcc por defecto
				#pragma prefer_hlslcc gles
				#pragma exclude_renderers d3d11_9x
				#pragma target 2.0

				//Palabras clave LWRP
				#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
				#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
				#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
				#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
				#pragma multi_compile _ _SHADOWS_SOFT
				#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

				//Palabras clave para UNITY
				#pragma multi_compile _ DIRLIGHTMAP_COMBINED
				#pragma multi_compile _ LIGHTMAP_ON
				#pragma multi_compile_fog

				//Instanciado de GPU
				#pragma multi_compile_instancing
				#pragma vertex LitPassVertex
				#pragma fragment LitPassFragment

				//Paquetes necesarios para el renderizado en pipeline (Siguiendo la documentación de unity)
				#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Core.hlsl"
				#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
				#include "Packages/com.unity.render-pipelines.lightweight/Shaders/LitInput.hlsl"

				//Definimos los atributos para el vertexshader
				struct Att
				{
					float4 position   : POSITION;
					float3 normal     : NORMAL;
					float4 tangent    : TANGENT;
					float2 uv         : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				//Valores para el fragmentshader
				struct Var
				{
					float2 uv                       : TEXCOORD0;
					float4 positionWSAndFogFactor   : TEXCOORD1;
					half3  normalWS                 : TEXCOORD2;
					float4 positionCS               : SV_POSITION;
				};

				sampler2D _MaskTex;
				float4 _DetailColor;

				Var LitPassVertex(Att input)
				{
					Var output;

					//Posiciones de vértices en diferentes espacios
					VertexPositionInputs vertexInput = GetVertexPositionInputs(input.position.xyz);

					//Posiciones de normales, tangentes and bitangentes
					VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normal, input.tangent);

					//fog por píxel
					float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

					//TRANSFORM_TEX
					output.uv = TRANSFORM_TEX(input.uv, _MainTex);
					output.positionWSAndFogFactor = float4(vertexInput.positionWS, fogFactor);
					output.normalWS = vertexNormalInput.normalWS;

					//Posicion de input sobre vertices
					output.positionCS = vertexInput.positionCS;
					return output;
				}

				half4 LitPassFragment(Var input) : SV_Target
				{
					// SurfaceData posee información sobre: "albedo", "metallic", "specular", "smoothness", "occlusion", "emission" y "alpha"
					SurfaceData surfaceData;
					InitializeStandardLitSurfaceData(input.uv, surfaceData);

					//Normales en el espacio del mundo
					half3 normalWS = input.normalWS;
					normalWS = normalize(normalWS);

					//Iluminación global bakeada a partir de normales
					half3 bakedGI = SampleSH(normalWS);

					//Posiciones en el WorldSpace a partir de los valores del input sobre vértices y normales
					float3 positionWS = input.positionWSAndFogFactor.xyz;
					half3 viewDirectionWS = SafeNormalize(GetCameraPositionWS() - positionWS);

					// BRDFData posee información difusa, especular, reflección y dureza del material
					BRDFData brdfData;
					InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

					//Obtenemos la fuente de luz original
					Light mainLight = GetMainLight();

					//Aplicación de ilumiación global 
					half3 color = GlobalIllumination(brdfData, bakedGI, surfaceData.occlusion, normalWS, viewDirectionWS);

					//Aplicación de la iluminación de la fuente principal
					color += LightingPhysicallyBased(brdfData, mainLight, normalWS, viewDirectionWS);

//Cálculo de iluminación de fuentes de luz adicionales
#ifdef _ADDITIONAL_LIGHTS

					//Obtenemos las luces adicionales e iteramos por cada una de ellas
					int additionalLightsCount = GetAdditionalLightsCount();
					for (int i = 0; i < additionalLightsCount; ++i)
					{
						//Guardamos la luz según el índice
						Light light = GetAdditionalLight(i, positionWS);

						//Modificamos el color final con cada fuente de luz
						color += LightingPhysicallyBased(brdfData, light, normalWS, viewDirectionWS);
					}
#endif
					//Creamos un color de enmascaramiento a partir de la textura de mascara
					half4 maskColor = tex2D(_MaskTex , input.uv);
					//De manera auxiliar obtenemos el color principal como copia
					half3 auxiliaryColor = color;
					//Pintamos el color auxiliar
					auxiliaryColor *= _DetailColor;
					//Interpolamos las dos texturas con el alpha de la máscara de recorte
					color = lerp(color, auxiliaryColor, maskColor.r);

					//Devolvemos el color resultante y el alpha de la superficie
					return half4(color, surfaceData.alpha);
				}
			ENDHLSL
			}

			// LIGHTWEIGHT RP: Usado para shadow maps
			UsePass "Lightweight Render Pipeline/Lit/ShadowCaster"

			// LIGHTWEIGHT RP: Usado para depth prepass
			UsePass "Lightweight Render Pipeline/Lit/DepthOnly"

			// LIGHTWEIGHT RP: Usado para bakeado de GI.
			UsePass "Lightweight Render Pipeline/Lit/Meta"
	}

	FallBack "Hidden/InternalErrorShader"
}