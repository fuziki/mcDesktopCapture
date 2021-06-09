using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Sphere : MonoBehaviour
{

    private float vy = 0.0f;

    private int state = 0;


    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        switch(state)
        {
            case 0:
                this.transform.position = new Vector3(1, 0, 0);
                break;
            case 1:
                vy -= 0.01f;
                if (vy < 0)
                {
                    vy = 0;
                    state = 0;
                }
                this.transform.position = new Vector3(1, vy, 0);
                break;
            case 2:
                vy += 0.01f;
                if (vy > 0.5)
                {
                    vy = 0.5f;
                    state = 1;
                }
                this.transform.position = new Vector3(1, vy, 0);
                break;
        }
    }

    public void OnClick()
    {
        Debug.Log("OnClick");

        state = 2;
    }
}
