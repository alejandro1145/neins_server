package Controlador;

public class JsonUtil {
    // Escapa comillas y saltos de línea para que el JSON no se rompa
    public static String esc(String valor) {
        if (valor == null) return "";
        return valor.replace("\\", "\\\\")
                     .replace("\"", "\\\"")
                     .replace("\n", " ")
                     .replace("\r", "");
    }
}