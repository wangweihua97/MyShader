using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(CameraPostRenderer), UnityEngine.Rendering.PostProcessing.PostProcessEvent.AfterStack, "Custom/CameraPost", true)]
public class CameraPost : PostProcessEffectSettings
{
    [Range(0f, 1f), Tooltip("Grayscale effect intensity.")]
    public FloatParameter m_Blend = new FloatParameter { value = 0.5f };

    public override bool IsEnabledAndSupported(PostProcessRenderContext context)
    {
        return enabled.value
               && m_Blend.value > 0f;
    }
}
[UnityEngine.Scripting.Preserve]
internal sealed class CameraPostRenderer : PostProcessEffectRenderer<CameraPost>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Test/Grayscale"));
        sheet.properties.SetFloat("_Blend", settings.m_Blend);
        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
