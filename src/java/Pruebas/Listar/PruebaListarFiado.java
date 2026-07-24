package Pruebas.Listar;

import Controlador.FiadoDAO;
import Modelo.Fiado;
import java.util.List;

public class PruebaListarFiado {
    public static void main(String[] args) {
        FiadoDAO dao = new FiadoDAO();
        List<Fiado> lista = dao.listar();
        for (Fiado f : lista) {
            System.out.println("ID: " + f.getId_fiado() + " | Valor: " + f.getValor() + " | Fecha: " + f.getFecha_fiado());
        }
    }
}