<% @Page Language="VB" %>
<% @Import Namespace="System.Configuration" %>
<% @Import Namespace="System.Web" %>

<!--#include file="PutLog.aspx"-->

<%
    ' ******************************** DEPRECATED ***********************************************
    '   Service: CheckReset.aspx
	'	Invoked by: Login component
	'
	'	The Login component uses this to determine if Session variables have been set from a reset password email.
    ' 
    '   Request parameter: none
    '   Response: session email and reset key, if set
    ' 
    Dim strUserEmail As String
    strUserEmail = Session("Email")
 	PutLog("CEP app", "Installer", strUserEmail, "Debug", "CheckReset", "Started")
    Dim strResetKey As String
    strResetKey = Session("ResetKey")
	Session("ResetKey") = ""
	
    Response.ContentType="application/json; charset=utf-8" 
	Response.Write("{""email"": """ & strUserEmail & """, ""resetKey"": """ & strResetKey & """}")
%>