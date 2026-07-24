package Pruebas.Insertar;

import Controlador.RolesDAO;
import Modelo.Roles;
import java.util.Scanner;

public class PruebaInsertarRol {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        
        System.out.print("Descripcion del rol: ");
        String descripcion = sc.nextLine();
        
        Roles r = new Roles();
        r.setDescrpcion_roles(descripcion);
        
        RolesDAO dao = new RolesDAO();
        boolean resultado = dao.insertar(r);
        System.out.println(resultado ? "Rol insertado correctamente" : "Error al insertar rol");
    }
}