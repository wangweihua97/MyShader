using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
[ExecuteInEditMode]
public class CharacterFaceNosePosition : MonoBehaviour
{
    [Header("鼻尖位置")] public Transform m_noseTf;
    private int m_nosePositionPId;
    private int m_noseWorldForwardDirPId;
    private int m_noseWorldRightdDirPId;
    private Vector3 m_boneOffeset;
    private Transform m_faceBoneTf;
    private List<Material> m_toonMats;

    private void Start()
    {
        m_nosePositionPId = Shader.PropertyToID("_NoseWorldPosition");
        m_noseWorldForwardDirPId = Shader.PropertyToID("_NoseWorldForwardDir");
        m_noseWorldRightdDirPId = Shader.PropertyToID("_NoseWorldRightDir");
        m_toonMats = new List<Material>();
        foreach (var sharedMaterial in GetComponent<SkinnedMeshRenderer>().sharedMaterials)
        {
            if (sharedMaterial.shader.name.Equals("Unlit/ToonFace"))
            {
                m_toonMats.Add(sharedMaterial);
            }
        }
    }

    private void LateUpdate()
    {
        Vector3 noseWorldPosition = m_noseTf.position;
        Vector3 noseWorldForwardDir = m_noseTf.forward;
        Vector3 noseWorldRightdDir = m_noseTf.right;
        foreach (var m_toonMat in m_toonMats)
        {
            m_toonMat.SetVector(m_nosePositionPId ,new Vector4(noseWorldPosition.x,noseWorldPosition.y,noseWorldPosition.z,1.0f));
            m_toonMat.SetVector(m_noseWorldForwardDirPId ,new Vector4(noseWorldForwardDir.x,noseWorldForwardDir.y,noseWorldForwardDir.z,1.0f));
            m_toonMat.SetVector(m_noseWorldRightdDirPId,new Vector4(noseWorldRightdDir.x,noseWorldRightdDir.y,noseWorldRightdDir.z,1.0f));
        }
    }
}