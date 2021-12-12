<% @Page Language="VB" %>

<!--#include file="PutLog.aspx"-->
<%
    '   Service: ResetPassword.aspx
	'	Invoked by: a reset password email
	'
	'	This sets Session variables with values retrieved from the email link. These are checked up when the authentication page loads
	'	to determine which component to show (i.e. Login  or Change Password)
    ' 
    '   Header request parameters: email, reset key 
    '   Response: redirect to Authentication page (Quasar layout)
    ' 
    Dim strUserEmail As String
    Dim strResetKey As String
    strUserEmail = Request.QueryString("UserLogin")
    strResetKey	= Request.QueryString("ResetKey")
    Session("Email") = strUserEmail
    Session("ResetKey") = strResetKey
    Response.Redirect("../")  '		Authentication layout
%>