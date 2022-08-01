using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class CharacterHariCenter : MonoBehaviour
{
    [Header("头发中心位置")] public Transform m_hairCenter;
    private int m_hairCenterPId;
    private List<Material> m_hairCenterMats;

    private void Awake()
    {
        m_hairCenterPId = Shader.PropertyToID("_HairCenter");
        m_hairCenterMats = new List<Material>();
        foreach (var sharedMaterial in GetComponent<SkinnedMeshRenderer>().sharedMaterials)
        {
            if (sharedMaterial.shader.name.Equals("Unlit/ToonHair"))
            {
                m_hairCenterMats.Add(sharedMaterial);
            }
        }
    }

    private void LateUpdate()
    {
        Vector3 hairCenterPos =m_hairCenter.position;
        foreach (var mat  in m_hairCenterMats)
        {
            mat.SetVector(m_hairCenterPId ,new Vector4(hairCenterPos.x,hairCenterPos.y,hairCenterPos.z,1.0f));
        }
    }
}