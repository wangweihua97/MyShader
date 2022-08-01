using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Cube : MonoBehaviour
{
    [Header("重力加速度")]
    public float g = 9.8f;
    [Header("重量每立方米")]
    public float p = 500f;

    private float m;
    [HideInInspector] public WavePhisics WavePhisics;
    public Vector3 v = Vector3.zero;
    private Matrix4x4 Inertia;

    private Matrix4x4 ii;

    private Vector3 f = Vector3.zero;
    private Vector3 w = Vector3.zero;
    private Vector3 t = Vector3.zero;

    private void Awake()
    {
        InitInertia();
    }

    void InitInertia()
    {
        m = 0;
        Inertia = Matrix4x4.zero;
        Mesh mesh = GetComponent<MeshFilter>().sharedMesh;
        int trisNum = GetComponent<MeshFilter>().sharedMesh.triangles.Length / 3;
        float[] verticeM = new float[mesh.vertices.Length];
        int[] verticeC = new int[mesh.vertices.Length];
        for (int i = 0; i < mesh.vertices.Length; i++)
        {
            verticeM[i] = 0;
            verticeC[i] = 0;
        }
        for (int i = 0; i < trisNum; i++)
        {
            Vector3 v0 = mesh.vertices[mesh.triangles[i * 3 + 0]];
            Vector3 v1 = mesh.vertices[mesh.triangles[i * 3 + 1]];
            Vector3 v2 = mesh.vertices[mesh.triangles[i * 3 + 2]];
            
            Vector3 n = Vector3.Cross(v1 - v0 ,v2 - v0);
            float vm = Mathf.Abs(Vector3.Dot(n, -v0)/3) * p;
            m += vm;
            vm = vm / 3;
            for (int j = 0; j < 3; j++)
            {
                int index = mesh.triangles[i * 3 + j];
                verticeC[index]++;
                verticeM[index] = verticeM[index] * (verticeC[index] - 1) / verticeC[index] +
                                  vm / verticeC[index];
            }
        }

        for (int i = 0; i < mesh.vertices.Length; i++)
        {
            Vector3 v = mesh.vertices[i];
            float a = Vector3.Dot(v, v);
            Matrix4x4 m1 =  Matrix4x4.identity;
            m1.m00 = a;
            m1.m11 = a;
            m1.m22 = a;

            Vector3 mv1 = v.x * v;
            Vector3 mv2 = v.y * v;
            Vector3 mv3 = v.z * v;
            
            Matrix4x4 m2 =  set(mv1,mv2,mv3);
            Inertia = add(Inertia ,multip(reduce(m1 , m2) ,verticeM[i]));
        }

        Inertia.m33 = 1;
        ii = Inertia.inverse;
    }

    public void AddF(Vector3 ipositon, Vector3 n ,Vector3 fi)
    {
        Vector3 fn = Vector3.Dot(n, fi) * n;
        fi = fn;
        
        float fi_len = fi.magnitude;
        Vector3 dir = transform.position - ipositon;
        Vector3 fi_dir = fi_len * Vector3.Dot(dir, fi) * dir.normalized;
        Vector3 fi_r = fi - fi_dir;

        f += fi_dir;
        t += Vector3.Cross(fi_r, dir);
    }

    /*public Vector3[][] GetEachFace()
    {
        Vector3 v2 = transform.localToWorldMatrix * new Vector4(0.5f, 0.5f, 0.5f, 1);
        Vector3 v1 = transform.localToWorldMatrix * new Vector4(-0.5f, 0.5f, 0.5f, 1);
        Vector3 v5 = transform.localToWorldMatrix * new Vector4(-0.5f, -0.5f, 0.5f, 1);
        Vector3 v8= transform.localToWorldMatrix * new Vector4(-0.5f, -0.5f, -0.5f, 1);
        
        Vector3 v6 = transform.localToWorldMatrix * new Vector4(0.5f, -0.5f, 0.5f, 1);
        Vector3 v7 = transform.localToWorldMatrix * new Vector4(0.5f, -0.5f, -0.5f, 1);
        Vector3 v3 = transform.localToWorldMatrix * new Vector4(0.5f, 0.5f, -0.5f, 1);
        Vector3 v4 = transform.localToWorldMatrix * new Vector4(-0.5f, 0.5f, -0.5f, 1);
        
        Vector3[][] faces = new Vector3[6][];
        faces[0] = new[] {v1,v2,v3,v4};
        faces[1] = new[] {v5,v6,v7,v8};
        faces[2] = new[] {v1,v2,v5,v6};
        faces[3] = new[] {v3,v4,v7,v8 };
        faces[4] = new[] { v1,v4,v5,v8};
        faces[5] = new[] { v2,v3,v6,v7};
        return faces;
    }*/
    
    public Vector3[][] GetTriangleFace()
    {
        Mesh mesh = GetComponent<MeshFilter>().sharedMesh;
        int trisNum = GetComponent<MeshFilter>().sharedMesh.triangles.Length / 3;
        Vector3[][] vs = new Vector3[trisNum][];
        for (int i = 0; i < trisNum; i++)
        {
            vs[i] = new Vector3[3];
            vs[i][0] = transform.localToWorldMatrix * ToVec4(mesh.vertices[mesh.triangles[i * 3 + 0]]);
            vs[i][1] = transform.localToWorldMatrix * ToVec4(mesh.vertices[mesh.triangles[i * 3 + 1]]);
            vs[i][2] = transform.localToWorldMatrix * ToVec4(mesh.vertices[mesh.triangles[i * 3 + 2]]);
        }

        return vs;
    }

    Vector4 ToVec4(Vector3 v3)
    {
        return new Vector4(v3.x, v3.y, v3.z, 1);
    }
    
    Matrix4x4 multip(Matrix4x4 m , float f)
    {
        m.m00 *= f;
        m.m01 *= f;
        m.m02 *= f;
        m.m10 *= f;
        m.m11 *= f;
        m.m12 *= f;
        m.m20 *= f;
        m.m21 *= f;
        m.m22 *= f;
        return m;
    }
    
    Matrix4x4 reduce(Matrix4x4 m , Matrix4x4 m2)
    {
        m.m00 -= m2.m00;
        m.m01 -= m2.m01;
        m.m02 -= m2.m02;
        m.m10 -= m2.m10;
        m.m11 -= m2.m11;
        m.m12 -= m2.m12;
        m.m20 -= m2.m20;
        m.m21 -= m2.m21;
        m.m22 -= m2.m22;
        return m;
    }
    Matrix4x4 add(Matrix4x4 m , Matrix4x4 m2)
    {
        m.m00 += m2.m00;
        m.m01 += m2.m01;
        m.m02 += m2.m02;
        m.m10 += m2.m10;
        m.m11 += m2.m11;
        m.m12 += m2.m12;
        m.m20 += m2.m20;
        m.m21 += m2.m21;
        m.m22 += m2.m22;
        return m;
    }
    
    Matrix4x4 set(Vector3 v1,Vector3 v2,Vector3 v3)
    {
        Matrix4x4 m =  Matrix4x4.identity;
        m.m00 = v1.x;
        m.m01 = v1.y;
        m.m02 = v1.z;
        m.m10 = v2.x;
        m.m11 = v2.y;
        m.m12 = v2.z;
        m.m20 = v3.x;
        m.m21 = v3.y;
        m.m22 = v3.z;
        return m;
    }
    
    

    void Update()
    {
        //AddF(transform.position + new Vector3(-0.5f,0,0), new Vector3(1, 1, 1));
        f += new Vector3(0, -m * g, 0);
        
        f += -v * m - 1f*v.normalized*m;
        t += -0.2f*w * m;
        Simulation();
        
        f = Vector3.zero;
        t = Vector3.zero;
        
        if(transform.position.y < -200)
            WavePhisics.RemoveCube(this);
    }

    void Simulation()
    {
        v += Time.deltaTime * f / m;
        if(v.magnitude>0.02f)
             transform.position += Time.deltaTime * v;

        Matrix4x4 rMat = GetRotateMat();
        Matrix4x4 irMat = rMat.transpose;
        Matrix4x4 iMat = ii;
        iMat.m33 = 1;
        w += Time.deltaTime * Mat4_multip_V3((irMat * iMat * rMat), t);
        if (w.magnitude > 0.02f)
        {
            Vector3 rw = 0.5f * Time.deltaTime * w;
            Quaternion q = new Quaternion(rw.x, rw.y, rw.z, 0) * transform.rotation;
            transform.rotation = Add(transform.rotation, q);
        }
        
    }

    Matrix4x4 GetRotateMat()
    {
        Matrix4x4 rot = new Matrix4x4();
        rot.SetTRS(new Vector3(0,0,0),transform.rotation,new Vector3(1,1,1));
        return rot;
    }

    Vector3 Mat4_multip_V3(Matrix4x4 m4 ,Vector3 v3)
    {
        return m4 * new Vector4(v3.x ,v3.y,v3.z,1);
    }
    
    Quaternion Add(Quaternion a ,Quaternion b)
    {
        Quaternion r = Quaternion.identity;
        r.x = a.x + b.x;
        r.y = a.y + b.y;
        r.z = a.z + b.z;
        r.w = a.w + b.w;
        return r;
    }
}
