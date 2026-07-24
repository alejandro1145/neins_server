package Pruebas.Actualizar;

import Controlador.ProductosDAO;
import Modelo.Productos;
import java.util.Scanner;

public class PruebaActualizarProducto {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        
        System.out.print("ID del producto a actualizar: ");
        int id = sc.nextInt();
        sc.nextLine();
        
        System.out.print("Nuevo nombre: ");
        String nombre = sc.nextLine();
        
        System.out.print("Nuevo precio: ");
        float precio = sc.nextFloat();
        
        System.out.print("Nuevo stock: ");
        int stock = sc.nextInt();
        
        Productos p = new Productos();
        p.setId_productos(id);
        p.setNombre(nombre);
        p.setPrecio(precio);
        p.setStock(stock);
        
        ProductosDAO dao = new ProductosDAO();
        boolean resultado = dao.actualizar(p);
        System.out.println(resultado ? "Producto actualizado correctamente" : "Error al actualizar producto");
    }
}