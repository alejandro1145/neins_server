package Pruebas.Eliminar;

import Controlador.MedioPagoDAO;
import java.util.Scanner;

public class PruebaEliminarMedioPago {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        System.out.print("ID del medio de pago a eliminar: ");
        int id = sc.nextInt();
        MedioPagoDAO dao = new MedioPagoDAO();
        boolean resultado = dao.eliminar(id);
        System.out.println(resultado ? "Medio de pago eliminado correctamente" : "Error al eliminar medio de pago");
    }
}