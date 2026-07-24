package Pruebas.Eliminar;

import Controlador.TipoDocumentoDAO;
import java.util.Scanner;

public class PruebaEliminarTipoDocumento {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        System.out.print("ID del tipo documento a eliminar: ");
        int id = sc.nextInt();
        TipoDocumentoDAO dao = new TipoDocumentoDAO();
        boolean resultado = dao.eliminar(id);
        System.out.println(resultado ? "Tipo documento eliminado correctamente" : "Error al eliminar tipo documento");
    }
}