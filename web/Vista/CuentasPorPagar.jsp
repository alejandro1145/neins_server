<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="Controlador.ProveedorDAO, Modelo.Proveedores, java.util.List"%>
<%@page import="Controlador.FiadoDAO, Modelo.Fiado"%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cuentas por Pagar</title>
    <link rel="stylesheet" type="text/css" href="../Estilos/global.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@500;700&family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet">
    <style>
        .tabla-container { margin-top: 40px; width: 100%; max-width: 800px; }
        table { width: 100%; border-collapse: collapse; color: #e0d4b4; }
        th { background: rgba(212,175,55,0.2); color: #d4af37; padding: 12px; text-align: left; border-bottom: 1px solid rgba(212,175,55,0.3); }
        td { padding: 10px 12px; border-bottom: 1px solid rgba(255,255,255,0.07); font-size: 0.95rem; }
        tr:hover { background: rgba(212,175,55,0.05); }
        .total-row td { color: #d4af37; font-weight: 600; border-top: 1px solid rgba(212,175,55,0.3); }
        .badge-pendiente { background: rgba(192,57,43,0.2); color: #e74c3c; padding: 4px 10px; border-radius: 20px; font-size: 0.82rem; }
        .badge-pagado { background: rgba(46,204,113,0.2); color: #2ecc71; padding: 4px 10px; border-radius: 20px; font-size: 0.82rem; }
    </style>
    <link rel="stylesheet" href="../Estilos/global.css">
</head>
<body>

<%
    String usuario = (String) session.getAttribute("usuario");
    if (usuario == null) { response.sendRedirect("Login.jsp"); return; }
%>

<%
    ProveedorDAO proveedorDAO = new ProveedorDAO();
    FiadoDAO fiadoDAO = new FiadoDAO();
    List<Proveedores> proveedores = proveedorDAO.listar();
    List<Fiado> fiados = fiadoDAO.listar();
    double totalGeneral = 0;
%>

<div style="display:flex; flex-direction:column; align-items:center; padding: 40px 20px;">

    <div class="form-container" style="max-width:800px;">
        <h1>Cuentas por Pagar</h1>
        <p class="subtitle">Deudas con Proveedores</p>
    </div>

    <div class="tabla-container">
        <table>
            <thead>
                <tr>
                    <th>Proveedor</th>
                    <th>NIT</th>
                    <th>Fecha Fiado</th>
                    <th>Fecha Límite</th>
                    <th>Valor</th>
                    <th>Estado</th>
                </tr>
            </thead>
            <tbody>
                <% for (Proveedores p : proveedores) {
                    double totalProveedor = 0;
                    boolean tieneDeudas = false;
                    for (Fiado f : fiados) {
                        if (f.getId_proveedor() == p.getId_proveedores()) {
                            tieneDeudas = true;
                            totalProveedor += f.getValor();
                %>
                <tr>
                    <td><%= p.getRazon_social() %></td>
                    <td><%= p.getNit() %></td>
                    <td><%= f.getFecha_fiado() %></td>
                    <td><%= f.getFecha_limite_pago() %></td>
                    <td>$ <%= f.getValor() %></td>
                    <td>
                        <% if (f.getFecha_pago() != null && !f.getFecha_pago().isEmpty()) { %>
                            <span class="badge-pagado">Pagado</span>
                        <% } else { %>
                            <span class="badge-pendiente">Pendiente</span>
                        <% } %>
                    </td>
                </tr>
                <%      }
                    }
                    if (tieneDeudas) {
                        totalGeneral += totalProveedor;
                %>
                <tr class="total-row">
                    <td colspan="4">Total <%= p.getRazon_social() %></td>
                    <td>$ <%= totalProveedor %></td>
                    <td></td>
                </tr>
                <%  }
                } %>
            </tbody>
            <tfoot>
                <tr class="total-row">
                    <td colspan="4"><strong>TOTAL GENERAL</strong></td>
                    <td><strong>$ <%= totalGeneral %></strong></td>
                    <td></td>
                </tr>
            </tfoot>
        </table>
    </div>

    <div style="margin-top:30px;">
        <a href="Menu.jsp" style="color:#d4af37; text-decoration:none; font-size:0.95rem;">← Volver al Menú</a>
    </div>

</div>
    <script src="../Scripts/premium-ui.js"></script>
</body>
</html>
