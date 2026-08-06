package Pruebas.Listar;

import Controlador.RolesDAO;
import Modelo.Roles;
import java.util.List;

public class PruebaListarRol {
    public static void main(String[] args) {
        RolesDAO dao = new RolesDAO();
        List<Roles> lista = dao.listar();
        for (Roles r : lista) {
            System.out.println("ID: " + r.getId_roles() + " | Rol: " + r.getDescrpcion_roles());
        }
    }
}