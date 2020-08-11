using UnityEngine;

[ExecuteInEditMode]
public class ScreenDistortEffect : MonoBehaviour
{

    [Range(0.0f, 1.0f)]
    public float DistortTimeFactor = 0.15f;
    [Range(0.0f, 0.2f)]
    public float DistortStrength = 0.01f;
    public Texture NoiseTexture = null;

    public Shader distortShader = null;

    private Material _Material = null;

    private void OnEnable()
    {
        if (_Material == null)
            _Material = new Material(distortShader);
    }

    public void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_Material)
        {
            _Material.SetTexture("_NoiseTex", NoiseTexture);
            _Material.SetFloat("_DistortTimeFactor", DistortTimeFactor);
            _Material.SetFloat("_DistortStrength", DistortStrength);
            Graphics.Blit(source, destination, _Material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
