package Pruebas.Insertar;

import Controlador.MedioPagoDAO;
import Modelo.Medio_pago;
import java.util.Scanner;

public class PruebaInsertarMedioPago {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        
        System.out.print("Descripcion del medio de pago: ");
        String descripcion = sc.nextLine();
        
        Medio_pago m = new Medio_pago();
        m.setDescripcion_medio_pago(descripcion);
        
        MedioPagoDAO dao = new MedioPagoDAO();
        boolean resultado = dao.insertar(m);
        System.out.println(resultado ? "Medio de pago insertado correctamente" : "Error al insertar medio de pago");
    }
}