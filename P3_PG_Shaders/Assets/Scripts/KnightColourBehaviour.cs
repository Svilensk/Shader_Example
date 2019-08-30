using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class KnightColourBehaviour : MonoBehaviour
{
    public Material knightMaterial;

    //Colores customizados (Mejora visual)
    private Color customRed;
    private Color customGreen;
    private Color customTeal;
    private Color customPurple;

    // Start is called before the first frame update
    void Start()
    {
        customRed    = new Color( .8f, .2f, .2f, 1f);
        customGreen  = new Color( .2f, .8f, .2f, 1f);
        customTeal   = new Color( .2f, .8f, .8f, 1f);
        customPurple = new Color( .7f, .2f, .7f, 1f);
    }

    //Pulsado BOTON "RED" (Aplicado color rojo)
    public void RedButtonPressed()
    {
        knightMaterial.SetColor("_DetailColor", customRed);
    }

    //Pulsado BOTON "GREEN" (Aplicado color verde)
    public void GreenButtonPressed()
    {
        knightMaterial.SetColor("_DetailColor", customGreen);
    }

    //Pulsado BOTON "TEAL" (Aplicado color cyan)
    public void TealButtonPressed()
    {
        knightMaterial.SetColor("_DetailColor", customTeal);
    }

    //Pulsado BOTON "PURPLE" (Aplicado color morado)
    public void PurpleButtonPressed()
    {
        knightMaterial.SetColor("_DetailColor", customPurple);
    }
}
