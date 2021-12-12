<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.Configuration" %>
<% @Import Namespace="System.Web" %>
<% @Import Namespace="System.Data.Sqlclient" %>
<% @Import Namespace="System.Security.Cryptography" %>

<!--#include file="PutLog.aspx"-->

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

<%
    '	Service: CheckLogin.aspx
	'	Invoked by: login component
    ' 
    '	Request headers: email, password 
    '	Response: installer details and checklist (json)
    '	Result codes: 
    '       00 - Success
    '       10 - Information: Reset password request cancelled
    '       20 - Warning
    '       30 - Error: Invalid login (wrong user)
    '       31 - Error: Invalid login (wrong user)
    '       32 - Error: Invalid login (access revoked)
    '       9x - System error: (as detected)
    ' 
    '	On success, the client presents the installer checklist page.
    '

    Dim strUserEmail As String
    strUserEmail = Request.Headers("UserEmail")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "CheckLogin", "Started")
    Dim strSessionId As String = ""

    Dim intResultCode As Integer = 0
    Dim strResultTitle As String = ""
    Dim strResultMsg As String = ""
    Dim strResultType As String = "OK"
	Dim strSessionKey As String = ""
	Dim jsnInstaller As String = "{}"
	'Dim jsnCheckList As String = "[]"

    Dim strPassword As String
    Dim strEncPassword As String
    strPassword = Request.Headers("Password")
	strEncPassword = GenerateSHA512String(strPassword)
	
	Dim strEnvironment As String						'	The application environment - i.e. test or prod 
	Dim oAppSettings = ConfigurationManager.AppSettings
	strEnvironment = oAppSettings("Environment")

    Try
		Dim sqlConn As New SqlConnection
		Dim strConnString As String
		strConnString = ConfigurationManager.ConnectionStrings("CEPapp").ConnectionString
		sqlConn.ConnectionString = strConnString
        sqlConn.Open()

        Dim sqlSelectCmd As New SqlCommand
        sqlSelectCmd.Connection = sqlConn
        sqlSelectCmd.CommandText = "SELECT ID, Contactname, EncryptedPassword, ResetKey, IsArchived FROM tbl_installer WHERE (Email = '" & strUserEmail & "')"

        Dim sqlReader As SqlDataReader
        sqlReader = sqlSelectCmd.ExecuteReader()
        If sqlReader.HasRows Then
            sqlReader.Read()
			PutLog("CEP app", "Installer", strUserEmail, "Debug", "CheckLogin", "User found")
			Dim boolIsArchived As Boolean
			boolIsArchived = Convert.ToBoolean(sqlReader("IsArchived"))
			If boolIsArchived Then
				intResultCode = 32
				strResultTitle = "Invalid log in"
				strResultMsg = "You log in is no longer active. Contact Carpet Cutters Commercial."
				strResultType = "Error"
				PutLog("CEP app", "Installer", strUserEmail, "Error", "CheckLogin", "Login archived")
			Else
				Dim strDbPassword As String
				strDbPassword = sqlReader("EncryptedPassword").ToString()
				If strEncPassword = strDbPassword Then
					Dim oUid As Guid
					oUid = Guid.NewGuid()
					strSessionKey = oUid.ToString()
					Session("SessionKey") = strSessionKey		'	This checked by each service to ensure it is being performed within the context of an authenticated session.

					Dim intInstallerId As Integer
					Dim strContactName As String
					Dim strResetKey As String
					intInstallerId = Convert.ToInt32(sqlReader("ID"))
					strContactName = sqlReader("ContactName").ToString()
					strResetKey = sqlReader("ResetKey").ToString()
					
					Dim intInstallerCompanyId As Integer
					Dim strInstallerCompanyId As String
					sqlReader.Close()
					sqlSelectCmd.CommandText = "SELECT ID FROM tbl_installer_company WHERE (Email = '" & strUserEmail & "')"
					sqlReader = sqlSelectCmd.ExecuteReader()
					If sqlReader.HasRows Then
						sqlReader.Read()
						intInstallerCompanyId = Convert.ToInt32(sqlReader("ID"))
						strInstallerCompanyId = intInstallerCompanyId.ToString()
						PutLog("CEP app", "Installer", strUserEmail, "Debug", "CheckLogin", "User has company checklist" & strInstallerCompanyId)
					Else
						strInstallerCompanyId = ""
					End If
					
					sqlReader.Close()
					If strResetKey <> ""
						Dim sqlUpdateCmd As New SqlCommand
						sqlUpdateCmd.Connection = sqlConn
						sqlUpdateCmd.CommandText = "UPDATE tbl_installer SET ResetKey = NULL WHERE (Email = '" & strUserEmail & "')"
						Dim intUpdateCount As Integer
						intUpdateCount = sqlUpdateCmd.ExecuteNonQuery()
						If intUpdateCount = 0 Then
							intResultCode = 90
							strResultTitle = "Log in problem"
							strResultMsg = "There was an error while logging you in. Please contact Carpet Cutters Commercial."
							strResultType = "System Error"
							PutLog("CEP app", "Installer", strUserEmail, strResultType, "CheckLogin", strResultMsg & " Unable to update tbl_installer reset key")
						Else
							intResultCode = 10
							strResultTitle = "Reset cancelled"
							strResultMsg = "You had previously requested that your password be reset. The link sent to you to do that will no longer work."
							strResultType = "Information"
							PutLog("CEP app", "Installer", strUserEmail, strResultType, "CheckLogin", strResultMsg)
						End If
					End If
					
					jsnInstaller = "{""installerId"": """ & intInstallerId.ToString() & """, ""contactName"": """ & strContactName & """, ""installerCompanyId"": """ & strInstallerCompanyId & """}"
					
				Else
					intResultCode = 30
					strResultTitle = "Invalid log in"
					strResultMsg = "The email or password you entered is wrong."
					strResultType = "Error"
					PutLog("CEP app", "Installer", strUserEmail, strResultType, "CheckLogin", strResultMsg & " (password)")
				End If
			End If

        Else
            intResultCode = 31
            strResultTitle = "Invalid log in"
            strResultMsg = "The email or password you entered is wrong."
            strResultType = "Error"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "CheckLogin", strResultMsg & " (email)")
        End If
        sqlConn.Close()

    Catch ex As Exception
        intResultCode = 92
		strResultTitle = "Log in problem"
        strResultMsg = "There was an error while logging you in. Please contact Carpet Cutters Commercial."
        strResultType = "System Error"
		PutLog("CEP app", "Installer", strUserEmail, strResultType, "CheckLogin", strResultMsg & ex.Message)

    End Try
	
    Response.ContentType="application/json; charset=utf-8" 
	'Response.Write("{""environment"": """ & strEnvironment & """, ""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultText"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """, ""sessionKey"": """ & strSessionKey & """, ""installer"": " & jsnInstaller & ", ""checkList"": " & jsnCheckList & "}")
	Response.Write("{""environment"": """ & strEnvironment & """, ""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """, ""sessionKey"": """ & strSessionKey & """, ""installer"": " & jsnInstaller & "}")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "CheckLogin", "Ended - result: " & strResultType)

%>
