package Pruebas.Eliminar;

import Controlador.RolesDAO;
import java.util.Scanner;

public class PruebaEliminarRol {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        System.out.print("ID del rol a eliminar: ");
        int id = sc.nextInt();
        RolesDAO dao = new RolesDAO();
        boolean resultado = dao.eliminar(id);
        System.out.println(resultado ? "Rol eliminado correctamente" : "Error al eliminar rol");
    }
}