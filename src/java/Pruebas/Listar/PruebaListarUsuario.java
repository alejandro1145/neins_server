package Pruebas.Listar;

import Controlador.UsuariosDAO;
import Modelo.Usuarios;
import java.util.List;

public class PruebaListarUsuario {
    public static void main(String[] args) {
        UsuariosDAO dao = new UsuariosDAO();
        List<Usuarios> lista = dao.listar();
        for (Usuarios u : lista) {
            System.out.println("ID: " + u.getId_usuarios() + " | Nombre: " + u.getNombre() + " | Correo: " + u.getCorreo());
        }
    }
}