using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestCamera : MonoBehaviour
{
    // Start is called before the first frame update
    public Material material;
    public Material blendMaterial;
    Camera cam;
    private RenderTexture dRt;
    private RenderTexture[] rts;
    public float StepDistance;
    public float MaxStepTime;
    public float SubdivideTime;

    void Start()
    {
        cam = GetComponent<Camera>();
        cam.allowHDR = true;

        rts = new RenderTexture[3];
        RenderBuffer[] buffers = new RenderBuffer[3];
        rts[0] = new RenderTexture((int) cam.pixelWidth, (int) cam.pixelHeight, 0, RenderTextureFormat.ARGB64);
        rts[0].filterMode = FilterMode.Bilinear;
        rts[0].name = "MainColor";
        rts[0].useMipMap = true;
        rts[0].autoGenerateMips = true;
        rts[0].Create();
        buffers[0] = rts[0].colorBuffer;
        
        rts[1] = new RenderTexture((int) cam.pixelWidth, (int) cam.pixelHeight, 0, RenderTextureFormat.ARGBFloat);
        rts[1].filterMode = FilterMode.Bilinear;
        rts[1].name = "Pos_R";
        rts[1].Create();
        buffers[1] = rts[1].colorBuffer;
        
        rts[2] = new RenderTexture((int) cam.pixelWidth, (int) cam.pixelHeight, 0, RenderTextureFormat.ARGB64);
        rts[2].filterMode = FilterMode.Bilinear;
        rts[2].name = "Normal_S";
        rts[2].Create();
        buffers[2] = rts[2].colorBuffer;
        
        /*rts[3] = new RenderTexture((int) cam.pixelWidth, (int) cam.pixelHeight, 0, RenderTextureFormat.RG16);
        rts[3].filterMode = FilterMode.Bilinear;
        rts[3].name = "RS";
        rts[3].Create();
        buffers[3] = rts[3].colorBuffer;*/

        dRt = new RenderTexture((int) cam.pixelWidth, (int) cam.pixelHeight, 24, RenderTextureFormat.Depth);
        dRt.name = "dep";

        cam.SetTargetBuffers(buffers, dRt.depthBuffer);
        /*Shader.SetGlobalFloat("_X_Range", 10f);
        Shader.SetGlobalFloat("_Y_Range", 10f);
        Shader.SetGlobalFloat("_Z_Range", 10f);*/
    }

    // Update is called once per frame
    void Update()
    {

    }

    private void OnPostRender()
    {
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        material.SetFloat("_StepDistance",StepDistance);
        material.SetFloat("_MaxStepTime",MaxStepTime);
        material.SetFloat("_SubdivideTime",SubdivideTime);
        material.SetTexture("_Main_Tex", rts[0]);
        material.SetTexture("_Deep_Tex", dRt);
        material.SetTexture("_WorldPos_R_Tex", rts[1]);
        material.SetTexture("_WorldNor_S_Tex", rts[2]);
        
        Shader.SetGlobalMatrix("_ViewToScreenUv", (cam.projectionMatrix * cam.worldToCameraMatrix));
        
        
        RenderTexture src0 = new RenderTexture(cam.pixelWidth,cam.pixelHeight,0, RenderTextureFormat.ARGB32);
        src0.filterMode = FilterMode.Bilinear;
        src0.useMipMap = true;
        src0.autoGenerateMips = true;
        src0.Create();
        Graphics.Blit(src, src0, material);
        
        blendMaterial.SetTexture("_SSR_Tex", src0);
        blendMaterial.SetTexture("_WorldPos_R_Tex", rts[1]);
        blendMaterial.SetTexture("_WorldNor_S_Tex", rts[2]);
        Vector3[] corners = GetCorners(cam.nearClipPlane);
        blendMaterial.SetVector("_UpperLeft" ,new Vector4(corners[0].x,corners[0].y,corners[0].z,1));
        blendMaterial.SetVector("_UpperRight" ,new Vector4(corners[1].x,corners[1].y,corners[1].z,1));
        blendMaterial.SetVector("_LowerLeft" ,new Vector4(corners[2].x,corners[2].y,corners[2].z,1));
        Graphics.Blit(rts[0], dest, blendMaterial);
        src0.Release();
    }
    
    Vector3[] GetCorners(float distance)
    {
        Vector3[] corners = new Vector3[4];

        float halfFOV = (cam.fieldOfView * 0.5f) * Mathf.Deg2Rad;
        float aspect = cam.aspect;

        float height = distance * Mathf.Tan(halfFOV);
        float width = height * aspect;

        corners[0] = transform.position - (transform.right * width);
        corners[0] += transform.up * height;
        corners[0] += transform.forward * distance;

        corners[1] = transform.position + (transform.right * width);
        corners[1] += transform.up * height;
        corners[1] += transform.forward * distance;

        corners[2] = transform.position - (transform.right * width);
        corners[2] -= transform.up * height;
        corners[2] += transform.forward * distance;

        corners[3] = transform.position + (transform.right * width);
        corners[3] -= transform.up * height;
        corners[3] += transform.forward * distance;

        return corners;
    }
}
