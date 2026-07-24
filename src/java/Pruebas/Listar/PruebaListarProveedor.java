package Pruebas.Listar;

import Controlador.ProveedorDAO;
import Modelo.Proveedores;
import java.util.List;

public class PruebaListarProveedor {
    public static void main(String[] args) {
        ProveedorDAO dao = new ProveedorDAO();
        List<Proveedores> lista = dao.listar();

        for (Proveedores p : lista) {
            System.out.println("ID: " + p.getId_proveedores() 
                + " | Razón Social: " + p.getRazon_social() 
                + " | NIT: " + p.getNit());
        }
    }
}