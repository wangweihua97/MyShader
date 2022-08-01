using System;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

public class WavePhisics : MonoBehaviour
{
    public float width = 20;
    public float height = 20;
    public ComputeShader csBuffer;
    public GameObject Cube;
    public GameObject Capsule;
    public GameObject Rock;
    List<Cube> cubes;
    Vector2 _resolution = new Vector2(512, 512);
    //public GameObject Test;
    
    Texture2D tex;
    Texture2D waveTex;
    private float[] maps;
    private float[] preMaps;
    private bool[] usedMap;
    private WavePlane _wavePlane;
    private Vector2[] _data;

    private void Awake()
    {
        maps = new float[512 * 512];
        for (int i = 0; i < 512 * 512; i++)
            maps[i] = 0;
        preMaps = new float[512 * 512];
        for (int i = 0; i < 512 * 512; i++)
            preMaps[i] = 0;
        usedMap = new bool[512 * 512];
        for (int i = 0; i < 512 * 512; i++)
            usedMap[i] = false;
        tex = new Texture2D(512, 512, TextureFormat.RFloat, false);
        waveTex = new Texture2D(512, 512, TextureFormat.RGFloat, false ,true);
        waveTex.Apply(false);
        _data = new Vector2[512 * 512];
        cubes = new List<Cube>();
    }

    private void Start()
    {
        _wavePlane = GetComponent<WavePlane>();
    }

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.R))
        {
            float rx = Random.Range(-2f, 2f);
            float rz = Random.Range(-2f, 2f);
            GameObject cube = GameObject.Instantiate(Cube);
            cube.transform.position = new Vector3(rx ,3,rz);
            Cube c = cube.GetComponent<Cube>();
            c.WavePhisics = this;
            cubes.Add(c);
        }

        if (Input.GetKeyDown(KeyCode.E))
        {
            float rx = Random.Range(-2f, 2f);
            float rz = Random.Range(-2f, 2f);
            GameObject cube = GameObject.Instantiate(Capsule);
            cube.transform.position = new Vector3(rx ,3,rz);
            Cube c = cube.GetComponent<Cube>();
            c.WavePhisics = this;
            cubes.Add(c);
        }
        
        if (Input.GetKeyDown(KeyCode.W))
        {
            float rx = Random.Range(-2f, 2f);
            float rz = Random.Range(-2f, 2f);
            GameObject cube = GameObject.Instantiate(Rock);
            cube.transform.position = new Vector3(rx ,3,rz);
            Cube c = cube.GetComponent<Cube>();
            c.WavePhisics = this;
            cubes.Add(c);
        }
        if (_wavePlane != null)
        {
            tex.SetPixelData(maps ,0,0);
            tex.Apply();
            
            _wavePlane.Test(tex);

            var customRenderTexture = _wavePlane.GetCustomRenderTexture();
            CustomRenderTexture.active  = customRenderTexture;
            //waveTex.ReadPixels(new Rect(0, 0, 512, 512), 0, 0);
            var buffer = new ComputeBuffer(512*512,16);
            int kernel = csBuffer.FindKernel("CSMain");
            csBuffer.SetBuffer(kernel,"buffer",buffer);
            csBuffer.SetTexture(kernel,"tex",waveTex);
            csBuffer.Dispatch(kernel,512/8,512/8,1);
            buffer.GetData(_data);
            buffer.Release();
            //waveTex.Apply();
            Graphics.ConvertTexture(customRenderTexture, waveTex);
            
            //_data = waveTex.GetPixelData<Vector2>(0);
            //Test.GetComponent<MeshRenderer>().sharedMaterial.SetTexture("_MainTex" ,waveTex);
        }
        for (int i = 0; i < 512 * 512; i++)
        {
            preMaps[i] = maps[i];
            maps[i] = 0;
            usedMap[i] = false;
        }
            
        foreach (var cube in cubes)
        {
            foreach (var vs in cube.GetTriangleFace())
            {
                UpdateMap(vs[0], vs[1], vs[2] ,cube);
            }
        }

        
    }

    public void RemoveCube(Cube cube)
    {
        int removeIndex = -1;
        for (int i = 0; i < cubes.Count; i++)
        {
            if (cube == cubes[i])
            {
                removeIndex = i;
                break;
            }
        }

        cubes.RemoveAt(removeIndex);
        GameObject.Destroy(cube);
    }

    void UpdateMap(Vector3 v0 ,Vector3 v1 ,Vector3 v2 ,Cube cube)
    {
        Vector3 uv0 = new Vector3((v0.x - (-10)) / 20 * 512, (v0.z - (-10)) / 20 * 512 ,v0.y);
        Vector3 uv1 = new Vector3((v1.x - (-10)) / 20 * 512, (v1.z - (-10)) / 20 * 512 ,v1.y);
        Vector3 uv2 = new Vector3((v2.x - (-10)) / 20 * 512, (v2.z - (-10)) / 20 * 512 ,v2.y);
        
        Vector3 n = Vector3.Cross(v1 - v0, v2 - v0).normalized;
        
        Vector3[] vs = new Vector3[3]{uv0,uv1,uv2};
        for(int i = 0 ;i<3 ;i++)
        {
            for (int j = 0; j < 3 - i - 1; j++)
            {
                if (vs[j].y > vs[j + 1].y)
                {
                    Vector3 temp = vs[j];
                    vs[j] = vs[j + 1];
                    vs[j + 1] = temp;
                }
            }
        }

        float dy01 = Mathf.Max((vs[1].y - vs[0].y), 0.000001f);
        float dy02 = Mathf.Max((vs[2].y - vs[0].y), 0.000001f);
        float dy12 = Mathf.Max((vs[2].y - vs[1].y), 0.000001f);
        float d01 = (vs[1].x - vs[0].x) / dy01 ;
        float d02 = (vs[2].x - vs[0].x) / dy02 ;
        float d12 = (vs[2].x - vs[1].x) / dy12 ;
        
        float z01 = (vs[1].z - vs[0].z) / dy01 ;
        float z02 = (vs[2].z - vs[0].z) / dy02 ;
        float z12 = (vs[2].z - vs[1].z) / dy12 ;

        int x0, x1;
        float z0, z1;
        for (int i = 0; i < (int) vs[1].y - (int) vs[0].y; i++)
        {
            x0 = (int)(vs[0].x+i * d01);
            x1 = (int)(vs[0].x+i * d02);
            
            z0 = (vs[0].z+i * z01);
            z1 = (vs[0].z+i * z02);

            if (x0 <= x1)
                SetMap(x0, x1, z0, z1, (int) vs[0].y + i ,n ,cube);
            else
            {
                SetMap(x1, x0, z1, z0, (int) vs[0].y + i ,n ,cube);
            }
        }

        int l01 = (int) vs[1].y - (int) vs[0].y;
        for (int i = 0; i < (int) vs[2].y - (int) vs[1].y; i++)
        {
            x0 = (int)(vs[1].x+i * d12);
            x1 = (int)(vs[0].x+(i + l01) * d02);
            
            z0 = (vs[1].z+i * z12);
            z1 = (vs[0].z+(i + l01) * z02);

            if (x0 <= x1)
                SetMap(x0, x1, z0, z1, (int) vs[1].y + i ,n ,cube);
            else
            {
                SetMap(x1, x0, z1, z0, (int) vs[1].y + i ,n ,cube);
            }
        }
    }

    void SetMap(int x0, int x1, float z0, float z1 ,int y ,Vector3 n ,Cube cube)
    {
        float d = (z1 - z0) / Mathf.Max((x1 - x0),0.000001f);
        for (int i = 0; i <= x1 - x0; i++)
        {
            if(y < 0 || y >= 512)
                continue;
            if(x0 + i < 0 || x0 + i >= 512)
                continue;
            if(usedMap[y * 512 + x0 + i])
                continue;
            float z = z0 + d * i +  0.1f*cube.v.y*Time.deltaTime;
            Vector2 a = _data[(511 - y) * 512 + 511-x0 - i];
            
            float w = 2*(a.x - 0.5f) + 0.01f * preMaps[y * 512 + x0 + i];
            if (w > z)
            {
                usedMap[y * 512 + x0 + i] = true;
                if (w > 0.5f)
                    w = 0.5f;
                Vector3 position = new Vector3(-10 + (float)(x0 + i)/512*20,z ,-10 + (float)y/512*20);
                Vector3 f = new Vector3(0,(w-z)*10000/512,0);
                cube.AddF(position ,n ,f);
                maps[y * 512 + x0 + i] = w-z;
                //maps[y * 512 + x0 + i] = -z;
                /*if (waveTex != null)
                {
                    Vector2 a = _data[(511 - y) * 512 + 511-x0 - i];
                    float w = a.x - 0.5f + 0.02f * preMaps[y * 512 + x0 + i];
                    if (w > 1)
                        w = 1;
                    if (w < -1)
                        w = -1;
                    Vector3 position = new Vector3(-10 + (float)(x0 + i)/512*20,z ,-10 + (float)y/512*20);
                    Vector3 f = new Vector3(0,(w-z)*5000/512,0);
                    cubes[0].AddF(position ,f);
                }*/
            }
                
        }
    }
}