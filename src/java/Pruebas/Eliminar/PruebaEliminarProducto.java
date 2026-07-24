package Pruebas.Eliminar;

import Controlador.ProductosDAO;
import java.util.Scanner;

public class PruebaEliminarProducto {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        System.out.print("ID del producto a eliminar: ");
        int id = sc.nextInt();
        ProductosDAO dao = new ProductosDAO();
        boolean resultado = dao.eliminar(id);
        System.out.println(resultado ? "Producto eliminado correctamente" : "Error al eliminar producto");
    }
}