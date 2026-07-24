package Pruebas.Insertar;

import Controlador.FiadoDAO;
import Modelo.Fiado;
import java.util.Scanner;

public class PruebaInsertarFiado {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        System.out.print("Fecha fiado (yyyy-mm-dd): ");
        String fecha_fiado = sc.nextLine();

        System.out.print("Fecha limite pago (yyyy-mm-dd): ");
        String fecha_limite = sc.nextLine();

        System.out.print("Fecha pago (yyyy-mm-dd, dejar vacio si no ha pagado): ");
        String fecha_pago = sc.nextLine();
        if (fecha_pago.trim().isEmpty()) fecha_pago = null;

        System.out.print("Valor: ");
        double valor = Double.parseDouble(sc.nextLine());

        System.out.print("ID del cliente: ");
        int id_cliente = Integer.parseInt(sc.nextLine());

        System.out.print("ID del medio de pago: ");
        int id_medio_pago = Integer.parseInt(sc.nextLine());

        Fiado f = new Fiado();
        f.setFecha_fiado(fecha_fiado);
        f.setFecha_limite_pago(fecha_limite);
        f.setFecha_pago(fecha_pago);
        f.setValor(valor);
        f.setId_cliente(id_cliente);
        f.setId_medio_pago(id_medio_pago);

        FiadoDAO dao = new FiadoDAO();
        boolean resultado = dao.insertar(f);
        System.out.println(resultado ? "Fiado insertado correctamente" : "Error al insertar fiado");
    }
}
