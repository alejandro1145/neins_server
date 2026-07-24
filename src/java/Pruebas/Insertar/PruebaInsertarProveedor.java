package Pruebas.Insertar;

import Controlador.ProveedorDAO;
import Modelo.Proveedores;
import java.util.Scanner;

public class PruebaInsertarProveedor {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        
        System.out.print("Razon social: ");
        String razon = sc.nextLine();
        
        System.out.print("NIT: ");
        String nit = sc.nextLine();
        
        Proveedores p = new Proveedores();
        p.setRazon_social(razon);
        p.setNit(nit);
        
        ProveedorDAO dao = new ProveedorDAO();
        boolean resultado = dao.insertar(p);
        System.out.println(resultado ? "Proveedor insertado correctamente" : "Error al insertar proveedor");
    }
}