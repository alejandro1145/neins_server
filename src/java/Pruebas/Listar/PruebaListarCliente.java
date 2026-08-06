package Pruebas.Listar;

import Controlador.ClienteDAO;
import Modelo.Clientes;
import java.util.List;

public class PruebaListarCliente {
    public static void main(String[] args) {
        ClienteDAO dao = new ClienteDAO();
        List<Clientes> lista = dao.listar();
        for (Clientes c : lista) {
            System.out.println("ID: " + c.getId_clientes() + " | Cupo: " + c.getCupo_credito());
        }
    }
}