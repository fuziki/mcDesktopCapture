using UnityEngine;
using UnityEngine.UI;
using mcDesktopCapture;
using System.Linq;
using System.Threading.Tasks;

public class Cube : MonoBehaviour
{
    public Dropdown dropdown;

    private DisplayProperty[] list = { };

    private bool isRunning = false;

    // Start is called before the first frame update
    void Start()
    {
        Application.targetFrameRate = 60;

        list = DesktopCapture.DisplayList;
        dropdown.options = list.ToList()
            .ConvertAll(display => new Dropdown.OptionData($"{display.name}({display.id})"));

        DesktopCapture.StartCapture(list[0].id);
        isRunning = true;
    }

    // Update is called once per frame
    void Update()
    {
        transform.Rotate(-0.2f, -0.3f, 0.4f);

        if (!isRunning) return;

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

    public void DropdownValueChanged()
    {
        Debug.Log($"dropdown: {dropdown.value}");
        dropdown.enabled = false;
        isRunning = false;
        DesktopCapture.StopCapture();
        Debug.Log("restarting...");
        Restart();
    }

    async void Restart()
    {
        await Task.Delay(500);
        DesktopCapture.StartCapture(list[dropdown.value].id);
        await Task.Delay(500);
        Debug.Log("restart!");
        isRunning = true;
        dropdown.enabled = true;
    }
}

