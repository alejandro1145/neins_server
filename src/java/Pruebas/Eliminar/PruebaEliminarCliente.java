package Pruebas.Eliminar;

import Controlador.ClienteDAO;
import java.util.Scanner;

public class PruebaEliminarCliente {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        System.out.print("ID del cliente a eliminar: ");
        int id = sc.nextInt();
        ClienteDAO dao = new ClienteDAO();
        boolean resultado = dao.eliminar(id);
        System.out.println(resultado ? "Cliente eliminado correctamente" : "Error al eliminar cliente");
    }
}