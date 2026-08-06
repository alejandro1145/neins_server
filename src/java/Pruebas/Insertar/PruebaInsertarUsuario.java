package Pruebas.Insertar;

import Controlador.UsuariosDAO;
import Modelo.Usuarios;
import java.util.Scanner;

public class PruebaInsertarUsuario {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        
        System.out.print("Nombre: ");
        String nombre = sc.nextLine();
        
        System.out.print("Apellido: ");
        String apellido = sc.nextLine();
        
        System.out.print("Identificacion: ");
        String identificacion = sc.nextLine();
        
        System.out.print("Correo: ");
        String correo = sc.nextLine();
        
        System.out.print("Telefono: ");
        String telefono = sc.nextLine();
        
        System.out.print("Clave: ");
        String clave = sc.nextLine();
        
        Usuarios u = new Usuarios();
        u.setNombre(nombre);
        u.setApellido(apellido);
        u.setIdentificacion(identificacion);
        u.setCorreo(correo);
        u.setTelefono(telefono);
        u.setClave(clave);
        
        UsuariosDAO dao = new UsuariosDAO();
        boolean resultado = dao.insertar(u);
        System.out.println(resultado ? "Usuario insertado correctamente" : "Error al insertar usuario");
    }
}