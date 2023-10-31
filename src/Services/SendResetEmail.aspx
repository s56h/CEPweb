<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.IO" %>
<% @Import Namespace="System.Management" %>
<% @Import Namespace="System.Net" %>
<% @Import Namespace="System.Data" %>
<% @Import Namespace="System.Data.Sqlclient" %>
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

				Dim strMailSubject As String
				Dim oAppSettings = ConfigurationManager.AppSettings
				strMailSubject = oAppSettings("ResetMailSubject")
				Dim strHostName As String
				strHostName = oAppSettings("HostName")
				Dim strMailPW As String
				strMailPW = oAppSettings("MailPW")
				'Dim strMailSender As String
				'strMailSender = oAppSettings("MailSender")
				Dim strEmailProfile As String
				strEmailProfile = oAppSettings("EmailProfile")

				Dim strEmailPath As String							'	The prefix of the file store accessed by CCC staff
				Dim strHtmlLine As String
				Dim strEmailBody As String
				strEmailBody = ""
				strEmailPath = oAppSettings("ResetPath")
				Dim oReader As StreamReader = My.Computer.FileSystem.OpenTextFileReader(strEmailPath)
				Do While oReader.Peek() <> -1
					strHtmlLine = oReader.ReadLine
					strHtmlLine = strHtmlLine.Replace("~name~", strInstallerName).Replace("~host~", strHostName).Replace("~email~", strUserEmail).Replace("~key~",strResetKey)
					strEmailBody = strEmailBody & strHtmlLine
				Loop
				oReader.Close()
				PutLog("CEP app", "Installer", strUserEmail, "Debug", "SendResetEmail", "About to send mail to (" & strUserEmail & ")")
				Dim spCommand As New SqlCommand()
				spCommand.Connection = sqlConn
				spCommand.CommandText = "msdb.dbo.sp_send_dbmail"
				spCommand.CommandType = CommandType.StoredProcedure
				spCommand.Parameters.AddWithValue("profile_name", strEmailProfile)
				spCommand.Parameters.AddWithValue("recipients", strUserEmail)
				' spCommand.Parameters.AddWithValue("from_address", strMailSender)
				spCommand.Parameters.AddWithValue("subject", strMailSubject)
				spCommand.Parameters.AddWithValue("body", strEmailBody)
				spCommand.Parameters.AddWithValue("body_format", "HTML")
				spCommand.ExecuteNonQuery()

				PutLog("CEP app", "Installer", strUserEmail, "Debug", "SendResetEmail", "Email sent")

				intResultCode = 10
				strResultTitle = "Email sent"
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
        intResultCode = 91
		strResultTitle = "System Error"
        strResultMsg = "There was an unexpected error while sending your password reset email (" & intResultCode & ") "
        strResultType = "System Error"
		PutLog("CEP app", "Installer", strUserEmail, strResultType, "SendResetEmail", strResultMsg & ex.Message)
		PutLog("CEP app", "Installer", strUserEmail, strResultType, "SendResetEmail - Trace", strResultMsg & ex.StackTrace)

    End Try
	
	Response.ContentType = "application/json; charset=utf-8"
	Response.Clear()	'	Previous code somewhare (stored procedure call?) puts spurious data in Response
	Response.Write("{""resultCode"": """ & intResultCode.ToString() & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """}")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "SendResetEmail", "Ended")

%>
