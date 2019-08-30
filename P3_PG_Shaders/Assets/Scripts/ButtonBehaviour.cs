using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using UnityEngine.UI;
using UnityEngine.EventSystems;

public class ButtonBehaviour : MonoBehaviour
{
    public Material buttonMaterial;

    //Constantes que indican los valores extremos del efecto de carga (Tanto radial como lineal (0 = 0% / 1 = 100%)
    const float MIN_CHARGE_VALUE = 0f;
    const float MAX_CHARGE_VALUE = 1f;

    //Constantes para indicar si se ha terminado la "carga" y se puede ejecutar el efecto de "Magia en el hacha" 
    const float NON_CHARGED = 0;
    const float CHARGED     = 1;

    //Constantes para indicar si se desea ejecutar la "carga" radial o lineal
    const int RADIAL_CHARGE = 0;
    const int LINEAL_CHARGE = 1;

    //Valor de carga del efecto de carga (radial o lineal)(rango 0 - 1)
    private float chargeAmount;

    //Booleano que permite que cada vez que se pulse se cambie el efecto de carga de radial a lineal
    //Simplemente es un añadido para poder ver ambos a la vez en uso
    private bool prevChargeType;

    //Booleano que indica si se ha pulsado el boton en la UI
    private bool elementPressed;

    void Start()
    {
        //Inicializamos los parámetros del shader
        buttonMaterial.SetFloat("Boolean_97B4432" , NON_CHARGED);
        buttonMaterial.SetFloat("Vector1_9CDD414" , MAX_CHARGE_VALUE);
        buttonMaterial.SetFloat("Boolean_5AA2E615", LINEAL_CHARGE);

        //inicializamos el shader como "cargado" por defecto
        chargeAmount = MAX_CHARGE_VALUE;
    }

    void Update()
    {
        //Si la carga había alcanzado el maximo y se pulsa sobre el boton de UI...
        if (elementPressed && chargeAmount >= MAX_CHARGE_VALUE)
        {
            chargeAmount = MIN_CHARGE_VALUE;
            buttonMaterial.SetFloat("Boolean_97B4432", NON_CHARGED);
            prevChargeType = prevChargeType ? false : true;
        }

        //Si está cargando y el anterior efecto de carga era RADIAL...
        if (chargeAmount < MAX_CHARGE_VALUE && prevChargeType)
        {
            chargeAmount += Time.deltaTime / 2;
            buttonMaterial.SetFloat("Boolean_5AA2E615", LINEAL_CHARGE);
            buttonMaterial.SetFloat("Vector1_9CDD414" , chargeAmount);

            elementPressed = false;
        }

        //Si está cargando y el anterior efecto de carga era LINEAL...
        else if (chargeAmount < MAX_CHARGE_VALUE && !prevChargeType)
        {
            chargeAmount += Time.deltaTime / 2;
            buttonMaterial.SetFloat("Boolean_5AA2E615", RADIAL_CHARGE);
            buttonMaterial.SetFloat("Vector1_9CDD414" , chargeAmount);

            elementPressed = false;
        }

        //Si la carga ha terminado...
        else if(chargeAmount >= MAX_CHARGE_VALUE)
        {
            buttonMaterial.SetFloat("Boolean_97B4432", CHARGED);
        }
    }

    //Listener de interacción con la UI
    public void OnButtonPressed()
    {
        elementPressed = true;
    }
}