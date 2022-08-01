using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class CharacterFacePupil : MonoBehaviour
{
    [Header("眼球1的位置")] public Transform m_pupilBoneTf1;
    [Header("眼球2的位置")] public Transform m_pupilBoneTf2;
    private int m_pupil1PositionPId;
    private int m_pupil2PositionPId;
    private List<Material> m_toonPupilMats;

    private void Awake()
    {
        m_pupil1PositionPId = Shader.PropertyToID("_Pupil1WorldPosition");
        m_pupil2PositionPId = Shader.PropertyToID("_Pupil2WorldPosition");
        m_toonPupilMats = new List<Material>();
        foreach (var sharedMaterial in GetComponent<SkinnedMeshRenderer>().sharedMaterials)
        {
            if (sharedMaterial.shader.name.Equals("Unlit/ToonEye"))
            {
                m_toonPupilMats.Add(sharedMaterial);
            }
        }
    }

    private void LateUpdate()
    {
        Vector3 pupil1WorldPosition =m_pupilBoneTf1.position;
        Vector3 pupil2WorldPosition =m_pupilBoneTf2.position;
        foreach (var m_toonPupilMat in m_toonPupilMats)
        {
            m_toonPupilMat.SetVector(m_pupil1PositionPId ,new Vector4(pupil1WorldPosition.x,pupil1WorldPosition.y,pupil1WorldPosition.z,1.0f));
            m_toonPupilMat.SetVector(m_pupil2PositionPId ,new Vector4(pupil2WorldPosition.x,pupil2WorldPosition.y,pupil2WorldPosition.z,1.0f));
            m_toonPupilMat.SetMatrix("_WorldToLocalMatrixMat1" ,m_pupilBoneTf1.transform.worldToLocalMatrix);
            m_toonPupilMat.SetMatrix("_WorldToLocalMatrixMat2" ,m_pupilBoneTf2.transform.worldToLocalMatrix);
        }
    }
}