package Pruebas.Eliminar;

import Controlador.UsuariosDAO;
import java.util.Scanner;

public class PruebaEliminarUsuario {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        System.out.print("ID del usuario a eliminar: ");
        int id = sc.nextInt();
        UsuariosDAO dao = new UsuariosDAO();
        boolean resultado = dao.eliminar(id);
        System.out.println(resultado ? "Usuario eliminado correctamente" : "Error al eliminar usuario");
    }
}