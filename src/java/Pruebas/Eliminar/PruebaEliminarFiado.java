package Pruebas.Eliminar;

import Controlador.FiadoDAO;
import java.util.Scanner;

public class PruebaEliminarFiado {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        System.out.print("ID del fiado a eliminar: ");
        int id = sc.nextInt();
        FiadoDAO dao = new FiadoDAO();
        boolean resultado = dao.eliminar(id);
        System.out.println(resultado ? "Fiado eliminado correctamente" : "Error al eliminar fiado");
    }
}