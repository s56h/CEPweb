<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.Data.Sqlclient" %>
<% @Import Namespace="System.Security.Cryptography" %>

<script language="vbscript" type="text/vbsscript" runat="server">
	'
    '       For password encryption
    '
    Public Shared Function GenerateSHA512String(ByVal strPassword As String) As String

		Dim oSha512 As SHA512 = SHA512Managed.Create()
		Dim bBytes As Byte() = Encoding.UTF8.GetBytes(strPassword)
		Dim bHash As Byte() = oSha512.ComputeHash(bBytes)
		Dim stringBuilder As New StringBuilder()

		For i As Integer = 0 To bHash.Length - 1
			stringBuilder.Append(bHash(i).ToString("X2"))
		Next

		Return stringBuilder.ToString()
	  
    End Function

</script>

<!--#include file="PutLog.aspx"-->

<%
    '	Service: ChangePassword.aspx 
	'	Invoked by: ResetPW component
    ' 
    '	Request headers: email, reset key, password 
    '	Response: email, reset key, Reset password page 
    '	Result codes: 
    '       00 - Success
    '       10 - Information
    '       20 - Warning
    '       30 - Error: reset link used is invalid (Userid/Key mismatch)
    '       31 - Error: no password reset request registered??
    '       90 - System error: (as detected)
    ' 
    '   On success, the client presents the login page. After log in, the user session will be returned to the client
    '

    Dim intResultCode As Integer = 0
    Dim strResultTitle As String = ""
    Dim strResultMsg As String = ""
    Dim strResultType As String = "OK"

    Dim strUserEmail As String
    Dim strResetKey As String
    Dim strNewPassword As String
    Dim strEncPassword As String
	
    strUserEmail = Request.Headers("UserEmail")
    strResetKey = Request.Headers("ResetKey")
    strNewPassword = Request.Headers("Password")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "ChangePassword", "Started")
    
	Response.ContentType = "application/json; charset=utf-8" 

    Try
		Dim strConnString As String
		strConnString = ConfigurationManager.ConnectionStrings("CEPapp").ConnectionString
		Dim sqlConn As New SqlConnection
		sqlConn.ConnectionString = strConnString
        sqlConn.Open()

        Dim sqlSelectCmd As New SqlCommand
        sqlSelectCmd.Connection = sqlConn
        sqlSelectCmd.CommandText = "SELECT ResetKey FROM tbl_installer WHERE (Email = '" & strUserEmail & "')"

        Dim sqlReader As SqlDataReader
        sqlReader = sqlSelectCmd.ExecuteReader()
        If sqlReader.HasRows Then
            sqlReader.Read()
            'strEncPassword = MD5Encrypt64(strNewPassword)
            strEncPassword = GenerateSHA512String(strNewPassword)
            Dim strDbResetKey As String
            strDbResetKey = sqlReader("ResetKey").ToString()
            If strResetKey = strDbResetKey Then
				sqlReader.Close()
                Dim sqlUpdateCmd As New SqlCommand
                sqlUpdateCmd.Connection = sqlConn
                sqlUpdateCmd.CommandText = "UPDATE tbl_installer SET EncryptedPassword = '" & strEncPassword & "', ResetKey = NULL WHERE (Email = '" & strUserEmail & "')"
                Dim intUpdateCount As Integer
                intUpdateCount = sqlUpdateCmd.ExecuteNonQuery()
                If intUpdateCount = 0 Then		'	some unexpected error
                    intResultCode = 90
					strResultTitle = "Password problem"
                    strResultMsg = "There was an error while updating your password. Please contact Carpet Cutters Commercial."
                    strResultType = "System Error"
					PutLog("CEP app", "Installer", strUserEmail, strResultType, "ChangePassword", strResultMsg & "tbl_installer update failed.")
				Else
                    intResultCode = 10
					strResultTitle = "Password changed"
                    strResultMsg = "Your password has been changed. Please log in."
                    strResultType = "Information"
					PutLog("CEP app", "Installer", strUserEmail, strResultType, "ChangePassword", strResultMsg)
                End If
            Else		 '   Note: this should not occur - if it does, this could be a primitive hacking attempt
                intResultCode = 30
				strResultTitle = "Invalid link"
                strResultMsg = "Your email link is invalid - please do \""forgot password\"" again"
                strResultType = "Error"
				PutLog("CEP app", "Installer", strUserEmail, strResultType, "ChangePassword", strResultMsg)
            End If

        Else 		'   Note: this should not occur - the user has put in a different email
            intResultCode = 31
			strResultTitle = "Incorrect email"
            strResultMsg = "You have not used the email we have recorded - try again"
            strResultType = "Error"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "ChangePassword", strResultMsg)
        End If
        sqlConn.Close()

    Catch ex As Exception
        intResultCode = 91
		strResultTitle = "System Error"
        strResultMsg = "There was an unexpected error while changing your password (" & intResultCode & "). Please contact Carpet Cutters Commercial. "
        strResultType = "System Error"
		PutLog("CEP app", "Installer", strUserEmail, strResultType, "ChangePassword", strResultMsg & ex.Message)

    End Try
	
	Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """}")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "ChangePassword", "Ended")

%>
