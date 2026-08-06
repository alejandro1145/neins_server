package Modelo;

public class Fiado {
    private int id_fiado;
    private String fecha_fiado;
    private String fecha_limite_pago;
    private String fecha_pago;
    private double valor;
    private double saldo_pendiente;
    private int id_cliente;
    private int id_medio_pago;

    public int getId_fiado() { return id_fiado; }
    public void setId_fiado(int id_fiado) { this.id_fiado = id_fiado; }

    public String getFecha_fiado() { return fecha_fiado; }
    public void setFecha_fiado(String fecha_fiado) { this.fecha_fiado = fecha_fiado; }

    public String getFecha_limite_pago() { return fecha_limite_pago; }
    public void setFecha_limite_pago(String fecha_limite_pago) { this.fecha_limite_pago = fecha_limite_pago; }

    public String getFecha_pago() { return fecha_pago; }
    public void setFecha_pago(String fecha_pago) { this.fecha_pago = fecha_pago; }

    public double getValor() { return valor; }
    public void setValor(double valor) { this.valor = valor; }

    public double getSaldo_pendiente() { return saldo_pendiente; }
    public void setSaldo_pendiente(double saldo_pendiente) { this.saldo_pendiente = saldo_pendiente; }

    public int getId_cliente() { return id_cliente; }
    public void setId_cliente(int id_cliente) { this.id_cliente = id_cliente; }

    public int getId_medio_pago() { return id_medio_pago; }
    public void setId_medio_pago(int id_medio_pago) { this.id_medio_pago = id_medio_pago; }
}
