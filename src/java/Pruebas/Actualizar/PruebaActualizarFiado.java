package Pruebas.Actualizar;

import Controlador.FiadoDAO;
import Modelo.Fiado;
import java.util.Scanner;

public class PruebaActualizarFiado {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        System.out.print("ID del fiado a actualizar: ");
        int id = Integer.parseInt(sc.nextLine());

        System.out.print("Nueva fecha fiado (yyyy-mm-dd): ");
        String fecha_fiado = sc.nextLine();

        System.out.print("Nueva fecha limite pago (yyyy-mm-dd): ");
        String fecha_limite = sc.nextLine();

        System.out.print("Nueva fecha pago (yyyy-mm-dd, dejar vacio si no ha pagado): ");
        String fecha_pago = sc.nextLine();
        if (fecha_pago.trim().isEmpty()) fecha_pago = null;

        System.out.print("Nuevo valor: ");
        double valor = Double.parseDouble(sc.nextLine());

        System.out.print("ID del cliente: ");
        int id_cliente = Integer.parseInt(sc.nextLine());

        System.out.print("ID del medio de pago: ");
        int id_medio_pago = Integer.parseInt(sc.nextLine());

        Fiado f = new Fiado();
        f.setId_fiado(id);
        f.setFecha_fiado(fecha_fiado);
        f.setFecha_limite_pago(fecha_limite);
        f.setFecha_pago(fecha_pago);
        f.setValor(valor);
        f.setId_cliente(id_cliente);
        f.setId_medio_pago(id_medio_pago);

        FiadoDAO dao = new FiadoDAO();
        boolean resultado = dao.actualizar(f);
        System.out.println(resultado ? "Fiado actualizado correctamente" : "Error al actualizar fiado");
    }
}
