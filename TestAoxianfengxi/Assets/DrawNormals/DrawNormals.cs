using UnityEngine;
using UnityEngine.Serialization;
#if UNITY_EDITOR
using UnityEditor;
#endif

public class DrawNormals : MonoBehaviour
{
#if UNITY_EDITOR
    Mesh m_Mesh;

    //[SerializeField]
    //private bool _displayWireframe = false;
    [SerializeField]
    private NormalsDrawData m_VertexNormals = new NormalsDrawData(new Color32(0, 0, 255, 127), true);
    [SerializeField]
    private NormalsDrawData m_VertexTangents = new NormalsDrawData(new Color32(0, 255, 0, 127), true);
    [SerializeField]
    private NormalsDrawData m_VertexBinormals = new NormalsDrawData(new Color32(255, 0, 0, 127), true);

    [System.Serializable]
    private class NormalsDrawData
    {
        [SerializeField]
        protected DrawType m_Draw = DrawType.Selected;

        protected enum DrawType
        {
            Never,
            Selected,
            Always
        }

        [SerializeField]
        protected float m_Length = 0.3f;
        [SerializeField]
        protected Color m_NormalColor;
        Color m_BaseColor = new Color32(255, 133, 0, 255);
        [SerializeField]
        protected float m_BaseSize = 0.0125f;


        public NormalsDrawData(Color mNormalColor, bool draw)
        {
            m_NormalColor = mNormalColor;
            m_Draw = draw ? DrawType.Selected : DrawType.Never;
        }

        public bool CanDraw(bool isSelected)
        {
            return (m_Draw == DrawType.Always) || (m_Draw == DrawType.Selected && isSelected);
        }

        public void Draw(Vector3 from, Vector3 direction)
        {
            /*
            Gizmos.color = m_BaseColor;
            Gizmos.DrawWireSphere(from, m_BaseSize);
            */

            Gizmos.color = m_NormalColor;
            Gizmos.DrawRay(from, direction * m_Length);
        }
    }

    void OnDrawGizmosSelected()
    {
        //EditorUtility.SetSelectedWireframeHidden(GetComponent<Renderer>(), !_displayWireframe);
        OnDrawNormals(true);
    }

    void OnDrawGizmos()
    {
        if (!Selection.Contains(this))
            OnDrawNormals(false);
    }

    private void OnDrawNormals(bool isSelected)
    {
        if (m_Mesh == null)
        {
            MeshFilter meshFilter = GetComponent<MeshFilter>();
            if (meshFilter != null)
                m_Mesh = meshFilter.sharedMesh;
        }

        if (m_Mesh == null)
        {
            SkinnedMeshRenderer smr = GetComponent<SkinnedMeshRenderer>();
            if (smr != null)
                m_Mesh = smr.sharedMesh;
        }

        if (m_Mesh == null)
        {
            return;
        }

        //Draw Vertex Normals

        Vector3[] vertices = m_Mesh.vertices;
        Vector3[] normals = m_Mesh.normals;
        Vector4[] tangents = m_Mesh.tangents;


        for (int i = 0; i < vertices.Length; i++)
        {
            Vector3 view_world = Vector3.Normalize(Camera.current.transform.forward - vertices[i]);
            Vector3 normal_world = Vector3.Normalize(transform.TransformVector(normals[i]));
            float NdotV = Vector3.Dot(normal_world, view_world);
            if (NdotV < 0.0)
            {
                Vector3 tangent_world =
                    transform.TransformVector(new Vector3(tangents[i].x, tangents[i].y, tangents[i].z));
                if (m_VertexNormals.CanDraw(isSelected))
                    m_VertexNormals.Draw(transform.TransformPoint(vertices[i]), normal_world);
                if (m_VertexTangents.CanDraw(isSelected))
                    m_VertexTangents.Draw(transform.TransformPoint(vertices[i]), tangent_world);
                Vector3 binormal_world = Vector3.Normalize(Vector3.Cross(normal_world, tangent_world) * tangents[i].w);
                if (m_VertexBinormals.CanDraw(isSelected))
                    m_VertexBinormals.Draw(transform.TransformPoint(vertices[i]), binormal_world);
            }
        }
    }
#endif
}