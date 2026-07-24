package Pruebas.Insertar;

import Controlador.ProductosDAO;
import Modelo.Productos;
import java.util.Scanner;

public class PruebaInsertarProducto {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        
        System.out.print("Nombre del producto: ");
        String nombre = sc.nextLine();
        
        System.out.print("Precio: ");
        float precio = sc.nextFloat();
        
        System.out.print("Stock: ");
        int stock = sc.nextInt();
        
        Productos p = new Productos();
        p.setNombre(nombre);
        p.setPrecio(precio);
        p.setStock(stock);
        
        ProductosDAO dao = new ProductosDAO();
        boolean resultado = dao.insertar(p);
        System.out.println(resultado ? "Producto insertado correctamente" : "Error al insertar producto");
    }
}