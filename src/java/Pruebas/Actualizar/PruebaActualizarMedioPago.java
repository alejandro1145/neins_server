package Pruebas.Actualizar;

import Controlador.MedioPagoDAO;
import Modelo.Medio_pago;
import java.util.Scanner;

public class PruebaActualizarMedioPago {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        
        System.out.print("ID del medio de pago a actualizar: ");
        int id = sc.nextInt();
        sc.nextLine();
        
        System.out.print("Nueva descripcion: ");
        String descripcion = sc.nextLine();
        
        Medio_pago m = new Medio_pago();
        m.setId_medio_pago(id);
        m.setDescripcion_medio_pago(descripcion);
        
        MedioPagoDAO dao = new MedioPagoDAO();
        boolean resultado = dao.actualizar(m);
        System.out.println(resultado ? "Medio de pago actualizado correctamente" : "Error al actualizar medio de pago");
    }
}