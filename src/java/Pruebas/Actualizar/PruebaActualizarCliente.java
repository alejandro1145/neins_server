package Pruebas.Actualizar;

import Controlador.ClienteDAO;
import Modelo.Clientes;
import java.util.Scanner;

public class PruebaActualizarCliente {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        System.out.print("ID del cliente a actualizar: ");
        int id = Integer.parseInt(sc.nextLine());

        System.out.print("Nuevo nombre: ");
        String nombre = sc.nextLine();

        System.out.print("Nuevo telefono: ");
        String telefono = sc.nextLine();

        System.out.print("Nueva identificacion: ");
        String identificacion = sc.nextLine();

        System.out.print("Nuevo cupo de credito: ");
        String cupo = sc.nextLine();

        Clientes c = new Clientes();
        c.setId_clientes(id);
        c.setNombre(nombre);
        c.setTelefono(telefono);
        c.setIdentificacion(identificacion);
        c.setCupo_credito(cupo);

        ClienteDAO dao = new ClienteDAO();
        boolean resultado = dao.actualizar(c);
        System.out.println(resultado ? "Cliente actualizado correctamente" : "Error al actualizar cliente");
    }
}
