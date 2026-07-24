package Pruebas.Listar;

import Controlador.ProductosDAO;
import Modelo.Productos;
import java.util.List;

public class PruebaListarProducto {
    public static void main(String[] args) {
        ProductosDAO dao = new ProductosDAO();
        List<Productos> lista = dao.listar();
        for (Productos p : lista) {
            System.out.println("ID: " + p.getId_productos() + " | Nombre: " + p.getNombre() + " | Precio: " + p.getPrecio());
        }
    }
}