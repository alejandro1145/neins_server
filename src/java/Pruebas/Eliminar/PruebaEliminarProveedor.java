package Pruebas.Eliminar;

import Controlador.ProveedorDAO;
import java.util.Scanner;

public class PruebaEliminarProveedor {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        System.out.print("ID del proveedor a eliminar: ");
        int id = sc.nextInt();
        ProveedorDAO dao = new ProveedorDAO();
        boolean resultado = dao.eliminar(id);
        System.out.println(resultado ? "Proveedor eliminado correctamente" : "Error al eliminar proveedor");
    }
}