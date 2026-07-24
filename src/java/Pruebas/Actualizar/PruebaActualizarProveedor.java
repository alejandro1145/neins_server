package Pruebas.Actualizar;

import Controlador.ProveedorDAO;
import Modelo.Proveedores;
import java.util.Scanner;

public class PruebaActualizarProveedor {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        
        System.out.print("ID del proveedor a actualizar: ");
        int id = sc.nextInt();
        sc.nextLine();
        
        System.out.print("Nueva razon social: ");
        String razon = sc.nextLine();
        
        System.out.print("Nuevo NIT: ");
        String nit = sc.nextLine();
        
        Proveedores p = new Proveedores();
        p.setId_proveedores(id);
        p.setRazon_social(razon);
        p.setNit(nit);
        
        ProveedorDAO dao = new ProveedorDAO();
        boolean resultado = dao.actualizar(p);
        System.out.println(resultado ? "Proveedor actualizado correctamente" : "Error al actualizar proveedor");
    }
}