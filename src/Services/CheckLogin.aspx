<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.Configuration" %>
<% @Import Namespace="System.Web" %>
<% @Import Namespace="System.Data.Sqlclient" %>
<% @Import Namespace="System.Security.Cryptography" %>

<!--#include file="PutLog.aspx"-->

<script language="vbscript" type="text/vbsscript" runat="server">
    Public Function SetFailCount(strUserId As String, strUserEmail As String, intWrongPWCount As Integer, sqlConn As SqlConnection) As Integer
	'
	'		Update wrong password count
	'
    	Dim intResultCode As Integer = 0
		Dim sqlUpdateCmd As New SqlCommand
		sqlUpdateCmd.Connection = sqlConn
		sqlUpdateCmd.CommandText = "UPDATE tbl_installer SET FailedLoginAttemptCount = " & intWrongPWCount.ToString() & " WHERE ID = " & strUserId
		'	sqlUpdateCmd.CommandText = "UPDATE tbl_installer_login_attempt SET FailedLoginAttemptCount = FailedLoginAttemptCount + 1 OUTPUT FailedLoginAttemptCount WHERE ID = " & strUserId
		Dim intUpdateCount As Integer
		intUpdateCount = sqlUpdateCmd.ExecuteNonQuery()
		If intUpdateCount = 0 Then
			intResultCode = 901		'	System error: unable to update FailedLoginAttemptCount
			PutLog("CEP app", "Installer", strUserEmail, "System Error", "CheckLogin/SetFailCount", "Unable to update FailedLoginAttemptCount in tbl_installer")
		Else
			PutLog("CEP app", "Installer", strUserEmail, "Information", "CheckLogin/SetFailCount", "Wrong password count updated to " & intWrongPWCount.ToString())
		End If
		Return intResultCode

    End Function

    Public Function CheckFailedAttempts(strUserId As String, strUserEmail As String, intWrongPWCount As Integer, sqlConn As SqlConnection) As Object
	'
	'		Check if the count of failed login attempts exceeds the maximum allowed before password reset is required
	'
    	Dim intResultCode As Integer = 0

		'	Get maximum attempts allowed
		Dim intFailMax As Integer
		Dim intTriesLeft AS Integer
		Dim sqlSelectCmd As New SqlCommand
		Dim sqlReader As SqlDataReader

		intTriesLeft = 0
		sqlSelectCmd.CommandText = "SELECT ref_value FROM tbl_reference WHERE ref_description = 'FailedLoginAttemptCount'"
		sqlSelectCmd.Connection = sqlConn
		sqlReader = sqlSelectCmd.ExecuteReader()
		If sqlReader.HasRows Then
            sqlReader.Read()
			intFailMax = Convert.ToInt32(sqlReader(0))
			intTriesLeft = intFailMax - intWrongPWCount
			If intWrongPWCount >= intFailMax Then
				intTriesLeft = 0
			End If
			PutLog("CEP app", "Installer", strUserEmail, "Information", "CheckLogin/CheckFailedAttempts", "Failed password count checked - count: " & intWrongPWCount.ToString())
		Else
			intResultCode = 902		'	System error: missing parameter
			PutLog("CEP app", "Installer", strUserEmail, "System Error", "CheckLogin/CheckFailedAttempts", "Unable to get wrong password maximum from tbl_reference")
		End If
		sqlReader.Close()
		Return {intResultCode, intTriesLeft}

    End Function

    Public Function AuditLogin(strUserId As String, strUserEmail As String, strResult As String, strContext As String, sqlConn As SqlConnection) As Integer
    '
	'       Insert a login audit row
    '
    	Dim intResultCode As Integer = 0
		Dim sqlUpdateCmd As New SqlCommand
		sqlUpdateCmd.Connection = sqlConn
		sqlUpdateCmd.CommandText = "INSERT INTO tbl_installer_login_attempt (InstallerID, loginResult, LoginDateTime, Context) VALUES (" & strUserId & ", '" & strResult & "', GETDATE(), '" & strContext & "')"
		Dim intUpdateCount As Integer
		intUpdateCount = sqlUpdateCmd.ExecuteNonQuery()
		If intUpdateCount = 0 Then
			intResultCode = 902		'	System error: unable to log login
			PutLog("CEP app", "Installer", strUserEmail, "System Error", "CheckLogin/AuditLogin", "Unable to insert into tbl_installer_login_attempt")
		Else
			PutLog("CEP app", "Installer", strUserEmail, "Information", "CheckLogin/AuditLogin", "Login audit entry inserted: " & strResult)
		End If
		Return intResultCode
	  
    End Function

    Public Function GenerateSHA512String(ByVal strPassword As String) As String
    '
	'       For password encryption
    '

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
    '       31 - Error: Invalid login (wrong password)
    '       32 - Error: Invalid login (access revoked)
    '       33 - Error: Invalid login (too many failed attempts)
    '       9xx - System error: (as detected)
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
	Dim intInstallerCompanyId As Integer
	Dim strInstallerCompanyId As String
	Dim intTriesLeft AS Integer = 0

    Dim strPassword As String
    Dim strEncPassword As String
	Dim strUserDevice As String
	strPassword = Request.Headers("Password")
	strEncPassword = GenerateSHA512String(strPassword)
	strUserDevice = Request.Headers("Device")
	
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
        Dim sqlReader As SqlDataReader
        sqlSelectCmd.Connection = sqlConn
        sqlSelectCmd.CommandText = "SELECT ID, Contactname, EncryptedPassword, ResetKey, IsArchived, FailedLoginAttemptCount FROM tbl_installer WHERE (Email = '" & strUserEmail & "')"

        sqlReader = sqlSelectCmd.ExecuteReader()
        If sqlReader.HasRows Then		'	Userid (email) is valid
            sqlReader.Read()
			PutLog("CEP app", "Installer", strUserEmail, "Debug", "CheckLogin", "User found")

			Dim strDbPassword As String
			strDbPassword = sqlReader("EncryptedPassword").ToString()
			Dim strInstallerId As String
			Dim strContactName As String
			Dim strResetKey As String
			Dim intFailCount As Integer
			Dim strAuditResult As String
			Dim strAuditContext As String
			Dim boolIsArchived As Boolean
			strInstallerId = sqlReader("ID").ToString()
			strContactName = sqlReader("ContactName").ToString()
			strResetKey = sqlReader("ResetKey").ToString()
			intFailCount = Convert.ToInt32(sqlReader("FailedLoginAttemptCount"))
			boolIsArchived = Convert.ToBoolean(sqlReader("IsArchived"))
			'	Get IP address of request
			Dim objContext As System.Web.HttpContext = System.Web.HttpContext.Current
			Dim sIPAddress As String = objContext.Request.ServerVariables("HTTP_X_FORWARDED_FOR")
			If String.IsNullOrEmpty(sIPAddress) Then
				strAuditContext = objContext.Request.ServerVariables("REMOTE_ADDR")
			Else
				Dim ipArray As String() = sIPAddress.Split(New [Char]() {","c})
				strAuditContext = ipArray(0)
			End If
			strAuditContext = "IP: " + strAuditContext + "; " + strUserDevice
			' strAuditContext = "0.0.0"
			sqlReader.Close()
			Dim intAuditResult As Integer
			intAuditResult = 0
			If strEncPassword = strDbPassword Then		'	Valid password entered
				strAuditResult = "Logged in"
				If boolIsArchived Then				'	User is archived
					intAuditResult = AuditLogin(strInstallerId, strUserEmail, "Login attempt when user was archived", strAuditContext, sqlConn)
					If intAuditResult = 0 Then
						intResultCode = 32
						strResultTitle = "Inactive log in"
						strResultMsg = "Your log in is no longer active. Contact Carpet Cutters Commercial."
						strResultType = "Error"
						PutLog("CEP app", "Installer", strUserEmail, strResultType, "CheckLogin", "Login archived")
					Else
						intResultCode = intAuditResult
						strResultTitle = "System Error"
						strResultMsg = "System error detected while checking login. Contact Carpet Cutters Commercial."
						strResultType = "System Error"
					End If
				Else				'	Check wrong password count
					If intFailCount > 0 Then		'	Check for too many incorrect passwords entered previously
						Dim objCheckFailed
						objCheckFailed = CheckFailedAttempts(strInstallerId, strUserEmail, intFailCount, sqlConn)
						intResultCode = objCheckFailed(0)
						intTriesLeft = objCheckFailed(1)
						If intResultCode = 0 Then
							If intTriesLeft > 0 Then		'	Correct password entered - reset wrong password count
								intResultCode = SetFailCount(strInstallerId, strUserEmail, 0, sqlConn)
								If intResultCode <> 0 Then
									strResultTitle = "System Error"
									strResultMsg = "System error detected while checking login. Contact Carpet Cutters Commercial."
									strResultType = "System Error"
								End If
							Else	'	All the tries have been used up
								intAuditResult = AuditLogin(strInstallerId, strUserEmail, "Correct password after maximum wrong passwords", strAuditContext, sqlConn)
								If intAuditResult <> 0 Then
									intResultCode = intAuditResult
									strResultTitle = "System Error"
									strResultMsg = "System error detected while checking login. Contact Carpet Cutters Commercial."
									strResultType = "System Error"
								Else
									intResultCode = 33
									strResultTitle = "Reset Password"
									strResultMsg = "You have entered too many incorrect passwords. Please reset your password."
									strResultType = "Error"
								End If
							End If
						Else
							strResultTitle = "System Error"
							strResultMsg = "System error detected while checking login. Contact Carpet Cutters Commercial."
							strResultType = "System Error"
						End If
					End If
				End If
				If intResultCode = 0 Then	'	Password is good and no other issues
					'	Login is good
					intAuditResult = AuditLogin(strInstallerId, strUserEmail, "Logged in", strAuditContext, sqlConn)
					If intAuditResult <> 0 Then
						intResultCode = intAuditResult
						strResultTitle = "System Error"
						strResultMsg = "System error detected while checking login. Contact Carpet Cutters Commercial."
						strResultType = "System Error"
					Else		'	set up session
						Dim oUid As Guid
						oUid = Guid.NewGuid()
						strSessionKey = oUid.ToString()
						Session("SessionKey") = strSessionKey		'	This is checked by each service to ensure it is being performed within the context of an authenticated session.
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
						If strResetKey <> ""		'	Remove reset key
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
					End If
				End If
					
				jsnInstaller = "{""installerId"": """ & strInstallerId & """, ""contactName"": """ & strContactName & """, ""installerCompanyId"": """ & strInstallerCompanyId & """}"
			Else		'	Wrong password
				'	Audit failure, increment failed attempts count and check against maximum allowed
				If intAuditResult <> 0 Then
					intResultCode = intAuditResult
					strResultTitle = "System Error"
					strResultMsg = "System error detected while checking login. Contact Carpet Cutters Commercial."
					strResultType = "System Error"
				Else
					Dim objCheckFailed
					objCheckFailed = CheckFailedAttempts(strInstallerId, strUserEmail, intFailCount+1, sqlConn)
					intResultCode = objCheckFailed(0)
					intTriesLeft = objCheckFailed(1)
					If intResultCode = 0 Then			'	Increment wrong password count
						intResultCode = SetFailCount(strInstallerId, strUserEmail, intFailCount+1, sqlConn)
						If intResultCode = 0 Then
							If intTriesLeft > 0 Then
								intAuditResult = AuditLogin(strInstallerId, strUserEmail, "Wrong password", strAuditContext, sqlConn)
								If intAuditResult = 0 Then	'	Wrong password - more tries available
									strResultType = "System Error"
									intResultCode = 30
									strResultTitle = "Invalid log in"
									If intTriesLeft > 1 Then
										strResultMsg = "The password you entered is wrong. You have " & intTriesLeft & " more attempts before you will need to reset your password."
									Else
										strResultMsg = "The password you entered is wrong. You have one more attempt before you will need to reset your password."
									End If
									strResultType = "Error"
								Else
									strResultTitle = "System Error"
									strResultMsg = "System error detected while checking login. Contact Carpet Cutters Commercial."
									strResultType = "System Error"
								End If
							Else	'	Too many previous failed login attempts
								intAuditResult = AuditLogin(strInstallerId, strUserEmail, "Login attempt after maximum wrong passwords", strAuditContext, sqlConn)
								If intAuditResult = 0 Then
									intResultCode = 30
									strResultTitle = "Invalid log in"
									strResultTitle = "Reset Password"
									strResultMsg = "You have entered too many incorrect passwords. Please reset your password."
									strResultType = "Error"
								Else
									intResultCode = intAuditResult
									strResultTitle = "System Error"
									strResultMsg = "System error detected while checking login. Contact Carpet Cutters Commercial."
									strResultType = "System Error"
								End If
							End If
						Else
							strResultTitle = "System Error"
							strResultMsg = "System error detected while checking login. Contact Carpet Cutters Commercial."
							strResultType = "System Error"
						End If
					Else		'	Error returned from CheckFailedAttempts function
						strResultTitle = "System Error"
						strResultMsg = "System error detected while checking login. Contact Carpet Cutters Commercial."
						strResultType = "System Error"
					End If

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
	
    Response.ContentType = "application/json; charset=utf-8" 
	Response.Write("{""environment"": """ & strEnvironment & """, ""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """, ""sessionKey"": """ & strSessionKey & """, ""installer"": " & jsnInstaller & "}")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "CheckLogin", "Ended - result: " & strResultType)

%>
