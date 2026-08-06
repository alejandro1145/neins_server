<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    /*
     * Login.jsp — ya no es el punto de entrada.
     * El único login es index.html → LoginServlet.
     * Este archivo solo redirige para no romper enlaces viejos.
     */
    String base = request.getContextPath() + "/index.html";
    String registrado = request.getParameter("registrado");
    String logout     = request.getParameter("logout");

    if ("1".equals(registrado)) {
        base += "?registrado=1";
    } else if ("1".equals(logout)) {
        base += "?logout=1";
    }

    response.sendRedirect(base);
%>


