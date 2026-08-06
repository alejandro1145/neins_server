<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="Controlador.Conexion,java.sql.*,java.text.NumberFormat,java.util.Locale"%>
<%
    boolean embed = "1".equals(request.getParameter("embed"));
    String usuario = (String) session.getAttribute("usuario");
    String rol = (String) session.getAttribute("rol");
    if (usuario == null || !"administrador".equalsIgnoreCase(rol)) { response.sendRedirect("Login.jsp"); return; }
    int idCliente = 0;
    try { idCliente = Integer.parseInt(request.getParameter("id")); } catch (Exception ignored) {}
    String avisoCupo = "";
    if ("POST".equalsIgnoreCase(request.getMethod()) && "actualizar_cupo".equals(request.getParameter("accion")) && idCliente > 0) {
        try (Connection con = new Conexion().getConnection()) {
            double nuevoCupo = Double.parseDouble(request.getParameter("cupo_credito"));
            PreparedStatement upd = con.prepareStatement("UPDATE clientes SET cupo_credito=? WHERE id_cliente=? AND cupo_credito>=0");
            upd.setDouble(1, nuevoCupo); upd.setInt(2, idCliente); upd.executeUpdate();
            avisoCupo = "Cupo actualizado correctamente.";
        } catch (Exception e) { avisoCupo = "No se pudo actualizar el cupo. Escribe un valor numérico válido."; }
    }
    String nombre = "Cliente no encontrado", documento = "", correo = "", telefono = "";
    double cupo = 0, deuda = 0, abonado = 0;
    java.util.List<String[]> fiados = new java.util.ArrayList<>();
    java.util.List<String[]> pagos = new java.util.ArrayList<>();
    NumberFormat moneda = NumberFormat.getCurrencyInstance(new Locale("es", "CO"));
    if (idCliente > 0) {
        try (Connection con = new Conexion().getConnection()) {
            PreparedStatement ps = con.prepareStatement("SELECT CONCAT(u.nombre, ' ', u.apellidos), u.identificacion, u.correo, u.telefono, c.cupo_credito, c.saldo_pendiente_total FROM clientes c JOIN Usuarios u ON u.id_usuarios=c.id_usuario WHERE c.id_cliente=?");
            ps.setInt(1, idCliente); ResultSet rs = ps.executeQuery();
            if (rs.next()) { nombre=rs.getString(1); documento=rs.getString(2); correo=rs.getString(3); telefono=rs.getString(4); cupo=rs.getDouble(5); deuda=rs.getDouble(6); }
            rs.close(); ps.close();
            ps = con.prepareStatement("SELECT f.id_fiado, f.fecha_fiado, f.fecha_limite_pago, f.valor, f.saldo_pendiente, f.estado FROM Fiado f WHERE f.id_cliente=? ORDER BY f.fecha_fiado DESC, f.id_fiado DESC");
            ps.setInt(1,idCliente); rs=ps.executeQuery();
            while(rs.next()) fiados.add(new String[]{rs.getString(1),String.valueOf(rs.getDate(2)),String.valueOf(rs.getDate(3)),moneda.format(rs.getDouble(4)),moneda.format(rs.getDouble(5)),rs.getString(6)});
            rs.close(); ps.close();
            ps=con.prepareStatement("SELECT p.fecha_pago, p.monto, p.id_fiado, COALESCE(m.descripcion_medio_pago,'Sin medio') FROM Pagos p LEFT JOIN medio_pago m ON m.id_medio_pago=p.id_medio_pago WHERE p.id_cliente=? ORDER BY p.fecha_pago DESC, p.id_pago DESC");
            ps.setInt(1,idCliente); rs=ps.executeQuery();
            while(rs.next()) { pagos.add(new String[]{String.valueOf(rs.getDate(1)),moneda.format(rs.getDouble(2)),rs.getString(3),rs.getString(4)}); abonado+=rs.getDouble(2); }
        } catch(Exception e) { request.setAttribute("historialError", "No se pudo cargar el historial. Revisa que la base tenga la tabla Pagos."); }
    }
    double disponible=Math.max(cupo-deuda,0), porcentaje=cupo>0?(deuda/cupo)*100:0;
%>
<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Historial de cliente</title>
<style>:root{--bg:#0b0b09;--card:#15140f;--line:#443a19;--gold:#f6c745;--muted:#b5ae9e;--red:#ff8f82;--green:#7fd6a5}*{box-sizing:border-box}body{margin:0;background:var(--bg);color:#fff;font-family:Arial,sans-serif;padding:28px}.top{display:flex;justify-content:space-between;gap:16px;align-items:center;margin-bottom:22px}h1{margin:0;color:var(--gold);font-size:25px}.back{color:var(--gold);text-decoration:none}.identity,.metrics,.grids{display:grid;gap:16px}.identity{grid-template-columns:1.2fr .8fr;background:linear-gradient(135deg,#1b180d,#12110d);border:1px solid var(--line);border-radius:12px;padding:22px;margin-bottom:16px}.identity p{color:var(--muted);margin:6px 0}.metrics{grid-template-columns:repeat(4,1fr);margin-bottom:16px}.metric,.panel{background:linear-gradient(135deg,#17150e,#11100c);border:1px solid var(--line);border-radius:12px;padding:18px}.metric small{display:block;color:var(--muted);text-transform:uppercase}.metric b{display:block;color:var(--gold);font-size:22px;margin-top:9px}.metric .red{color:var(--red)}.metric .green{color:var(--green)}.bar{height:10px;background:#302b1b;border-radius:10px;overflow:hidden;margin-top:11px}.bar i{display:block;height:100%;background:linear-gradient(90deg,#d9a925,var(--gold))}.grids{grid-template-columns:1fr 1fr}.panel h2{color:var(--gold);font-size:17px;margin:0 0 14px}.scroll{overflow:auto;max-height:430px}table{border-collapse:collapse;width:100%;font-size:13px}th,td{padding:11px 8px;border-bottom:1px solid var(--line);text-align:left}th{color:var(--muted);font-size:11px;text-transform:uppercase}.empty{color:var(--muted);padding:22px 0}.cup-form{display:flex;gap:8px;align-items:end;margin-top:12px}.cup-form input{background:#0b0b09;color:#fff;border:1px solid var(--line);border-radius:7px;padding:9px;width:150px}.cup-form button{background:var(--gold);border:0;border-radius:7px;padding:10px 13px;font-weight:bold;cursor:pointer}@media(max-width:850px){.metrics,.grids,.identity{grid-template-columns:1fr}body{padding:16px}}</style></head>
<body><div class="top"><div><h1>Historial y cupo de crédito</h1><p style="color:var(--muted)">Ficha financiera completa del cliente</p></div><a class="back" href="Clientes.jsp<%=embed?"?embed=1":""%>">← Volver a clientes</a></div>
<% if(request.getAttribute("historialError")!=null){ %><p style="color:var(--red)"><%=request.getAttribute("historialError")%></p><% } %>
<section class="identity"><div><h2 style="color:var(--gold);margin:0"><%=nombre%></h2><p>Documento: <%=documento%></p><p><%=correo%> · <%=telefono%></p><%if(!avisoCupo.isEmpty()){%><p style="color:var(--green)"><%=avisoCupo%></p><%}%><form class="cup-form" method="post"><input type="hidden" name="accion" value="actualizar_cupo"><input type="hidden" name="id" value="<%=idCliente%>"><%if(embed){%><input type="hidden" name="embed" value="1"><%}%><label style="color:var(--muted);font-size:12px">Cupo aprobado (COP)<input type="number" name="cupo_credito" min="0" step="1000" value="<%=String.format(java.util.Locale.US,"%.0f",cupo)%>"></label><button type="submit">Guardar cupo</button></form></div><div><small style="color:var(--muted)">Uso del cupo</small><b style="font-size:23px"><%=Math.round(porcentaje)%>%</b><div class="bar"><i style="width:<%=Math.min(porcentaje,100)%>%"></i></div></div></section>
<section class="metrics"><article class="metric"><small>Cupo total</small><b><%=moneda.format(cupo)%></b></article><article class="metric"><small>Crédito usado</small><b class="red"><%=moneda.format(deuda)%></b></article><article class="metric"><small>Disponible</small><b class="green"><%=moneda.format(disponible)%></b></article><article class="metric"><small>Total abonado</small><b><%=moneda.format(abonado)%></b></article></section>
<section class="grids"><article class="panel"><h2>Historial de fiados (<%=fiados.size()%>)</h2><div class="scroll"><table><thead><tr><th>#</th><th>Fecha</th><th>Vence</th><th>Valor</th><th>Saldo</th><th>Estado</th></tr></thead><tbody><%if(fiados.isEmpty()){%><tr><td colspan="6" class="empty">No tiene fiados registrados.</td></tr><%}else{for(String[]f:fiados){%><tr><td>#<%=f[0]%></td><td><%=f[1]%></td><td><%=f[2]%></td><td><%=f[3]%></td><td><%=f[4]%></td><td><%=f[5]%></td></tr><%}}%></tbody></table></div></article>
<article class="panel"><h2>Historial de pagos (<%=pagos.size()%>)</h2><div class="scroll"><table><thead><tr><th>Fecha</th><th>Abono</th><th>Fiado</th><th>Medio</th></tr></thead><tbody><%if(pagos.isEmpty()){%><tr><td colspan="4" class="empty">No tiene pagos registrados.</td></tr><%}else{for(String[]p:pagos){%><tr><td><%=p[0]%></td><td><%=p[1]%></td><td>#<%=p[2]%></td><td><%=p[3]%></td></tr><%}}%></tbody></table></div></article></section></body></html>
