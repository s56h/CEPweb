<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.Configuration" %>
<% @Import Namespace="System.Web" %>
<% @Import Namespace="System.Data.Sqlclient" %>

<!--#include file="PutLog.aspx"-->

<%
    '	Service: GetDocument.aspx 
	'	Invoked by: Image.vue component
    ' 
    '	Request headers: session id, installer id, checklist id 
    '	Response: result Json 
	'			  document filename
    '	Result codes: 
    '       00 - Success
    '       10 - Information
    '       20 - Warning
    '       30 - Error: session timeout
    '       90 - System error: (as detected)
    '

    Dim strUserEmail As String
    strUserEmail = Request.Headers("UserEmail")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "GetDocument", "Started")

    Dim intResultCode As Integer = 0
    Dim strResultTitle As String = ""
    Dim strResultMsg As String = ""
    Dim strResultType As String = "OK"
    
	Dim strWebFilePath As String = ""										'	Where the file should be found on the web server
	Dim strStoredFileName As String = ""

	Dim strInstallerId As String
	Dim strInstallerCompanyId As String
	Dim strChecklistId As String
	Dim strCheckType As String
    Dim strClientSession As String = Request.Headers("SessionKey")
    If strClientSession <> Session("SessionKey") Then
		intResultCode = 30
		strResultTitle = "Login Needed"
		strResultMsg = "Your session has timed out. Please login again."		'	Or, this could be a hacking attempt. Not likely.
		strResultType = "Error"
	Else
		Try
			strInstallerId = Request.Headers("InstallerId")
			strInstallerCompanyId = Request.Headers("InstallerCompanyId")
			strChecklistId = Request.Headers("ChecklistId")
			strCheckType = Request.Headers("CheckType")

			Dim sqlConn As New SqlConnection
			Dim strConnString As String
			strConnString = ConfigurationManager.ConnectionStrings("CEPapp").ConnectionString
			sqlConn.ConnectionString = strConnString
			sqlConn.Open()

			Dim sqlSelectCmd As New SqlCommand
			sqlSelectCmd.Connection = sqlConn
			If strCheckType = "I" Then
				sqlSelectCmd.CommandText = "SELECT FileFolderPath FROM tbl_installer_checklist WHERE (InstallerId = " & strInstallerId & " AND ChecklistId = " & strChecklistId & ")"
			Else
				sqlSelectCmd.CommandText = "SELECT FileFolderPath FROM tbl_installer_company_checklist WHERE (InstallerCompanyId = " & strInstallerCompanyId & " AND ChecklistId = " & strChecklistId & ")"
			End If
			Dim sqlReader As SqlDataReader
			sqlReader = sqlSelectCmd.ExecuteReader()
			If sqlReader.HasRows Then
				sqlReader.Read()
				strStoredFileName = sqlReader("FileFolderPath").ToString()	'	Where the file should be mapped to?/mirrored from
				
				Dim oAppSettings = ConfigurationManager.AppSettings
				Dim strFolderDropPrefix As String							'	The prefix of the file store accessed by CCC staff 
				strFolderDropPrefix = oAppSettings("FolderDropPrefix")
				Dim strFilePart As String									'	The path and filename stripped of the CCC staff access prefix
				strFilePart = Right(strStoredFileName, strStoredFileName.Length() - strFolderDropPrefix.Length())
				Dim strWebDataMap As String
				strWebDataMap = oAppSettings("VirtualData")
				strWebFilePath = strWebDataMap & strFilePart
				strWebFilePath = strWebFilePath.Replace("\","\\")				'	\ is JSON escape character
				PutLog("CEP app", "Installer", strUserEmail, "Information", "GetDocument", "File: " & strWebFilePath)
				'PutLog("CEP app", "Installer", strUserEmail, "Information", "GetDocument", "File: " & strStoredFileName)
			Else
				intResultCode = 90
				strResultTitle = "Download Problem"
				strResultMsg = "There was an unexpected error while accessing the document. Please contact Carpet Cutters Commercial."
				strResultType = "System Error"
				PutLog("CEP app", "Installer", strUserEmail, strResultType, "GetDocument", strResultMsg & " Unable to find checklist row in tbl_installer_checklist.")
			End If

		Catch ex As Exception
			intResultCode = 91
			strResultTitle = "System Error"
			strResultMsg = "There was an unexpected error while accessing the document (" & intResultCode & ") "
			strResultType = "System Error"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "GetDocument", strResultMsg & " " & ex.Message & " (" & strInstallerCompanyId & "," & strInstallerId & "," & strChecklistId & ")")

		End Try
	End If
	

	Response.ContentType = "application/json; charset=utf-8"
	Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """, ""imageSource"": """ & strWebFilePath & """}")
	'Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """, ""imageSource"": """ & strStoredFileName & """}")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "GetDocument", "Ended - result: " & strResultType)

%>
