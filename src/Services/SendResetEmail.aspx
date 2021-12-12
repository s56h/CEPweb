<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.IO" %>
<% @Import Namespace="System.Data.Sqlclient" %>
<% @Import Namespace="System.Net" %>
<% @Import Namespace="System.Net.Mail" %>
<% @Import Namespace="System.Configuration" %>

<!--#include file="PutLog.aspx"-->

<%
    '	Service: SendResetEmail.aspx 
	'	Invoked by: Login.vue component
    ' 
    '	Request headers: user email
    '	Response: result Json 
    '	Result codes: 
    '       00 - Success
    '       10 - Information
    '       20 - Warning
    '       30 - Error: the user email is not registered
    '       90 - System error: (as detected)
    '

    Dim strUserEmail As String
    strUserEmail = Request.Headers("UserEmail")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "SendResetEmail", "Started")

    Dim intResultCode As Integer = 0
    Dim strResultTitle As String = ""
    Dim strResultMsg As String = ""
    Dim strResultType As String = "OK"

    Try
		Dim sqlConn As New SqlConnection
		Dim strConnString As String
		strConnString = ConfigurationManager.ConnectionStrings("CEPapp").ConnectionString
		sqlConn.ConnectionString = strConnString
        sqlConn.Open()
		
		'	Check the login
        Dim sqlSelectCmd As New SqlCommand
        sqlSelectCmd.Connection = sqlConn
        sqlSelectCmd.CommandText = "SELECT ID, ContactName FROM tbl_installer WHERE (Email = '" & strUserEmail & "')"

        Dim sqlReader As SqlDataReader
        sqlReader = sqlSelectCmd.ExecuteReader()
        If sqlReader.HasRows Then		'	the user email is correct
            sqlReader.Read()
			Dim strInstallerName As String
            strInstallerName = sqlReader("ContactName").ToString()
			'	Generate ande save reset key
			Static Generator As System.Random = New System.Random()
			Dim strResetKey As String
			strResetKey = Generator.Next(100000, 1000000).ToString()

			Dim sqlUpdateCmd As New SqlCommand
			sqlUpdateCmd.Connection = sqlConn
			sqlUpdateCmd.CommandText = "UPDATE tbl_installer SET ResetKey = '" & strResetKey & "' WHERE (Email = '" & strUserEmail & "')"

			sqlReader.Close()
			Dim intUpdateCount As Integer
			intUpdateCount = sqlUpdateCmd.ExecuteNonQuery()

			If intUpdateCount = 1 Then		'	the reset key has been updated, send email
				PutLog("CEP app", "Installer", strUserEmail, "Debug", "SendResetEmail", "Reset key updated in database")
				Dim smtpClient As New SmtpClient
				
				'	****	The following applies for gmail. For another smtp provider, these settings will need to change		****
				
				smtpClient.DeliveryMethod = SmtpDeliveryMethod.Network
				smtpClient.UseDefaultCredentials = False
				smtpClient.EnableSsl = True
				'smtpClient.Host = "smtp.gmail.com"
				smtpClient.Host = "smtp.office365.com"
				smtpClient.Port = 587 ' 587 for TLS?
				Dim strMailPW As String
				Dim oAppSettings = ConfigurationManager.AppSettings
				strMailPW = oAppSettings("MailPW")
				Dim strMailUser As String
				strMailUser = oAppSettings("MailUser")
				smtpClient.Credentials = New NetworkCredential(strMailUser, strMailPW)

				Dim eMail As New MailMessage
				Dim strMailSubject As String
				strMailSubject = oAppSettings("ResetMailSubject")
				eMail.Subject = strMailSubject
				eMail.From = New MailAddress(strMailUser)
				eMail.To.Add(strUserEmail)
				Dim strEmailBody As String
				Dim strHostName As String
				strHostName = oAppSettings("HostName")
				strEmailBody = "<p>Hello " & strInstallerName & "</p><p>Please click this reset your password:</p><p><a href='" & strHostName & "Services/ResetPassword.aspx?UserLogin=" & strUserEmail & "&ResetKey=" & strResetKey & "'>Reset Password</a></p><p>Regards, Carpet Cutters Commercial</p>"
				eMail.Body = strEmailBody
				eMail.IsBodyHtml = True
				PutLog("CEP app", "Installer", strUserEmail, "Debug", "SendResetEmail", "About to send email (" & strMailSubject & ") : " &strEmailBody)
				smtpClient.Send(eMail)
				PutLog("CEP app", "Installer", strUserEmail, "Debug", "SendResetEmail", "Email sent")

				intResultCode = 10
				strResultTitle = "Email send"
				strResultMsg = "An email had been sent to allow you to enter a new password"
				strResultType = "Information"
				PutLog("CEP app", "Installer", strUserEmail, strResultType, "SendResetEmail", strResultMsg)
			Else		'	The email is valid, but could not update. Should never see this
				intResultCode = 90
				strResultTitle = "System Error"
				strResultMsg = "There was an error while resetting your password. Please contact Carpet Cutters Commercial."
				strResultType = "System Error"
				PutLog("CEP app", "Installer", strUserEmail, strResultType, "SendResetEmail", strResultMsg & " Could not update tbl_installer")
			End If
		Else
			intResultCode = 30
			strResultTitle = "Incorrect email"
			strResultMsg = "You have not used the email we have recorded - try again"
			strResultType = "Error"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "SendResetEmail", strResultMsg)
		End If

        sqlConn.Close()

    Catch ex As Exception
        intResultCode = 90
		strResultTitle = "System Error"
        strResultMsg = "There was an unexpected error while sending your password reset email (" & intResultCode & ") "
        strResultType = "System Error"
		PutLog("CEP app", "Installer", strUserEmail, strResultType, "SendResetEmail", strResultMsg & ex.Message)

    End Try
	
	Response.ContentType = "application/json; charset=utf-8" 
	Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """}")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "SendResetEmail", "Ended")

%>
