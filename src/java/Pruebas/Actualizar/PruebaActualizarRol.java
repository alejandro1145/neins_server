package Pruebas.Actualizar;

import Controlador.RolesDAO;
import Modelo.Roles;
import java.util.Scanner;

public class PruebaActualizarRol {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        
        System.out.print("ID del rol a actualizar: ");
        int id = sc.nextInt();
        sc.nextLine();
        
        System.out.print("Nueva descripcion del rol: ");
        String descripcion = sc.nextLine();
        
        Roles r = new Roles();
        r.setId_roles(id);
        r.setDescrpcion_roles(descripcion);
        
        RolesDAO dao = new RolesDAO();
        boolean resultado = dao.actualizar(r);
        System.out.println(resultado ? "Rol actualizado correctamente" : "Error al actualizar rol");
    }
}