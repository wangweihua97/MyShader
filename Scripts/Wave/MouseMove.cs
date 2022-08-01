using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MouseMove : MonoBehaviour
{
    [Header("镜头移动速度")]
    public float MoveSpeed = 2.0f;
    // Start is called before the first frame update
    [SerializeField] WavePlane _shallowWater;
    [SerializeField] GameObject _hitGo;
    [SerializeField] bool _useFixedUpdate;
    [SerializeField] protected float _inputSize = 20;
    [SerializeField] protected float _minInputSize = 5;
    [SerializeField] protected bool _inputPush = false;
    
    Vector2 mousePos = new Vector2(-1,-1);
    Vector2 mousePos2 = new Vector2(-1,-1);
    private Camera cam;

    private void Awake()
    {
        cam = Camera.main;
    }

    void Update()
    {
        if (Input.GetMouseButton(0))
        {
            var ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit;
            if (_hitGo.GetComponent<MeshCollider>().Raycast(ray, out hit, Mathf.Infinity))
            {
                _shallowWater.SetInputPosition(hit.textureCoord, _inputSize, _minInputSize, _inputPush);
            }
            else
            {
                _shallowWater.ClearInput();
            }
        }
        else
        {
            _shallowWater.ClearInput();
        }

        if (Input.GetMouseButton(1))
        {
            if (mousePos.x < 0)
            {
                mousePos = new Vector2(Input.mousePosition.x ,Input.mousePosition.y);
            }
            else
            {
                Vector2 newMousePos = new Vector2(Input.mousePosition.x, Input.mousePosition.y);
                Vector2 mouseMove = (newMousePos - mousePos)*0.1f;
                mousePos = newMousePos;
                cam.transform.eulerAngles += new Vector3(-mouseMove.y,mouseMove.x ,0);
            }
        }
        else
        {
            mousePos = new Vector2(-1,-1);
        }
        
        if (Input.GetMouseButton(2))
        {
            if (mousePos2.x < 0)
            {
                mousePos2 = new Vector2(Input.mousePosition.x ,Input.mousePosition.y);
            }
            else
            {
                Vector2 newMousePos = new Vector2(Input.mousePosition.x, Input.mousePosition.y);
                Vector2 mouseMove = (newMousePos - mousePos2)*0.04f;
                mousePos2 = newMousePos;
                cam.transform.position += MoveSpeed * cam.transform.right * mouseMove.x;
                cam.transform.position += MoveSpeed * cam.transform.up * mouseMove.y;
            }
        }
        else
        {
            mousePos2 = new Vector2(-1,-1);
        }

        cam.transform.position += MoveSpeed * cam.transform.forward * Input.GetAxis("Mouse ScrollWheel");

    }
}
