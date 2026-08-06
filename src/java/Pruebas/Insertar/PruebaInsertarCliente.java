package Pruebas.Insertar;

import Controlador.ClienteDAO;
import Modelo.Clientes;
import java.util.Scanner;

public class PruebaInsertarCliente {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        System.out.print("Nombre: ");
        String nombre = sc.nextLine();

        System.out.print("Telefono: ");
        String telefono = sc.nextLine();

        System.out.print("Identificacion: ");
        String identificacion = sc.nextLine();

        System.out.print("Cupo de credito: ");
        String cupo = sc.nextLine();

        Clientes c = new Clientes();
        c.setNombre(nombre);
        c.setTelefono(telefono);
        c.setIdentificacion(identificacion);
        c.setCupo_credito(cupo);

        ClienteDAO dao = new ClienteDAO();
        boolean resultado = dao.insertar(c);
        System.out.println(resultado ? "Cliente insertado correctamente" : "Error al insertar cliente");
    }
}
