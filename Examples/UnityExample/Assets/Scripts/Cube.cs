using UnityEngine;
using mcDesktopCapture;

public class Cube : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        var list = DesktopCapture.DisplayList;
        DesktopCapture.StartCapture(list[0].id);
    }

    // Update is called once per frame
    void Update()
    {
        transform.Rotate(-0.2f, -0.3f, 0.4f);

        var texture = DesktopCapture.GetCurrentFrame();
        if (texture == null) return;

        Renderer m_Renderer = GetComponent<Renderer>();
        m_Renderer.material.SetTexture("_MainTex", texture);
    }

    void OnDisable()
    {
        Debug.Log("OnDisable");
        DesktopCapture.StopCapture();
    }
}
