package Pruebas.Actualizar;

import Controlador.UsuariosDAO;
import Modelo.Usuarios;
import java.util.Scanner;

public class PruebaActualizarUsuario {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        
        System.out.print("ID del usuario a actualizar: ");
        int id = sc.nextInt();
        sc.nextLine();
        
        System.out.print("Nuevo nombre: ");
        String nombre = sc.nextLine();
        
        System.out.print("Nuevo apellido: ");
        String apellido = sc.nextLine();
        
        System.out.print("Nueva identificacion: ");
        String identificacion = sc.nextLine();
        
        System.out.print("Nuevo correo: ");
        String correo = sc.nextLine();
        
        System.out.print("Nuevo telefono: ");
        String telefono = sc.nextLine();
        
        System.out.print("Nueva clave: ");
        String clave = sc.nextLine();
        
        Usuarios u = new Usuarios();
        u.setId_usuarios(id);
        u.setNombre(nombre);
        u.setApellido(apellido);
        u.setIdentificacion(identificacion);
        u.setCorreo(correo);
        u.setTelefono(telefono);
        u.setClave(clave);
        
        UsuariosDAO dao = new UsuariosDAO();
        boolean resultado = dao.actualizar(u);
        System.out.println(resultado ? "Usuario actualizado correctamente" : "Error al actualizar usuario");
    }
}