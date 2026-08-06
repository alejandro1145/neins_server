package Pruebas.Listar;

import Controlador.MedioPagoDAO;
import Modelo.Medio_pago;
import java.util.List;

public class PruebaListarMedioPago {
    public static void main(String[] args) {
        MedioPagoDAO dao = new MedioPagoDAO();
        List<Medio_pago> lista = dao.listar();
        for (Medio_pago m : lista) {
            System.out.println("ID: " + m.getId_medio_pago() + " | Descripcion: " + m.getDescripcion_medio_pago());
        }
    }
}