<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.Configuration" %>
<% @Import Namespace="System.IO" %>
<% @Import Namespace="System.Web" %>
<% @Import Namespace="System.Data.Sqlclient" %>

<!--#include file="PutLog.aspx"-->

<script language="vbscript" type="text/vbsscript" runat="server">
	'
    '       To set response cookies
    '
    Public Sub SetHeaders(intResultCode As Integer, strResultTitle As String, strResultMsg As String, strResultType As String)
		
	Response.Cookies("ResultCode").Value = intResultCode.ToString()
	Response.Cookies("ResultTitle").Value = strResultTitle
	Response.Cookies("ResultMsg").Value = strResultMsg
	Response.Cookies("ResultType").Value = strResultType
	  
    End Sub

</script>


<%
    '	Service: StoreDocument.aspx 
	'	Invoked by: Upload.vue component
    ' 
    '	Request headers: session id, installer id, checklist id 
    '	Response: result (in Session cookies due to perceived constraints of Quasar upload component) 
    '	Result codes: 
    '       00 - Success
    '       1x - Information
    '       2x - Warning
    '       30 - Error: session timeout
    '       9x - System error: (as detected)
    '

    Dim strUserEmail As String
	strUserEmail = Request.Cookies.Item("UserEmail").Value.ToString()
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "StoreDocument", "Started")

    Dim intResultCode As Integer = 0
    Dim strResultTitle As String = ""
    Dim strResultMsg As String = ""
    Dim strResultType As String = "OK"

    Dim strClientSession As String = Request.Cookies.Item("SessionKey").Value.ToString()
    If strClientSession <> Session("SessionKey") Then
		intResultCode = 30
		strResultTitle = "Login Needed"
		strResultMsg = "Your session has timed out. Please login again."		'	Or, this could be a hacking attempt. Not likely.
		strResultType = "Error"
		SetHeaders(intResultCode, strResultTitle, strResultMsg, strResultType)
		Response.End()
	End If

	Try
	
		Dim uploadedFiles
		uploadedFiles = Request.Files
		
		Dim oFilePost = Request.Files(0)
		Dim intContentLength As Integer
		Dim strContentType As String
		Dim strFileName As String
		intContentLength = Convert.toInt32(oFilePost.ContentLength)
		strContentType = oFilePost.ContentType
		strFileName = oFilePost.FileName
		
		Dim strInstallerId As String
		strInstallerId = Request.Cookies.Item("InstallerId").Value.ToString()
		Dim strChecklistId As String
		strChecklistId = Request.Cookies.Item("ChecklistId").Value.ToString()
		Dim strChecklistType As String
		strChecklistType = Request.Cookies.Item("ChecklistType").Value.ToString()
		Dim strInstallerCompanyId As String
		strInstallerCompanyId = Request.Cookies.Item("InstallerCompanyId").Value.ToString()
		Dim strInstallerName As String
		strInstallerName = Request.Cookies.Item("InstallerName").Value.ToString().Replace("'","''")
		Dim strCheckName As String
		strCheckName = Request.Cookies.Item("CheckName").Value.ToString()
		Dim strExpiryDate As String
		strExpiryDate = Request.Cookies.Item("ExpiryDate").Value.ToString()
		If strExpiryDate <> "NULL" Then
			strExpiryDate = "'" & strExpiryDate & "'"
		End If
		
		Dim strStoredFileName As String
		Dim strDateTime As String
		
		Dim sqlConn As New SqlConnection
		Dim strConnString As String
		strConnString = ConfigurationManager.ConnectionStrings("CEPapp").ConnectionString
		sqlConn.ConnectionString = strConnString
		sqlConn.Open()

		Dim sqlSelectCmd As New SqlCommand
		sqlSelectCmd.Connection = sqlConn
		'		Get the folder to store the file in
		If strChecklistType = "I"				'		Installer document
			sqlSelectCmd.CommandText = "SELECT FolderPath FROM tbl_installer WHERE (ID = " & strInstallerId & ")"
		Else
			sqlSelectCmd.CommandText = "SELECT FolderPath FROM tbl_installer_company WHERE (ID = " & strInstallerCompanyId & ")"
		End If
		Dim sqlReader As SqlDataReader

		sqlReader = sqlSelectCmd.ExecuteReader()
		If Not sqlReader.HasRows Then
			intResultCode = 90
			strResultTitle = "Upload Problem"
			strResultMsg = "There was an unexpected error while storing the document. Please contact Carpet Cutters Commercial."
			strResultType = "System Error"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "StoreDocument", strResultMsg & " Unable to obtain the folder path for the installer from tbl_installer.")
			SetHeaders(intResultCode, strResultTitle, strResultMsg, strResultType)
			Throw New Exception("Custom")
		End If

		sqlReader.Read()
		Dim strInstallerFolder As String
		strInstallerFolder = sqlReader("FolderPath").ToString()
		Dim oAppSettings = ConfigurationManager.AppSettings
		Dim strFolderDropPrefix As String						'	The prefix of the file store accessed by CCC staff 
		strFolderDropPrefix = oAppSettings("FolderDropPrefix")
		Dim strFolderPending As String							'	The folder used for documents/images that are "pending"
		strFolderPending = oAppSettings("PendingFolder")
		'Dim strAppPath = HttpRuntime.AppDomainAppPath
		Dim strWebPath As String								'	The location (mirrored) of the documents/images accessible by the Web app
		Dim strInstallerFolderPart As String					'	The installer folder stripped of the CCC staff access prefix
		strInstallerFolderPart = Right(strInstallerFolder, strInstallerFolder.Length() - strFolderDropPrefix.Length())
		strWebPath = Server.MapPath(oAppSettings("VirtualData")) & strInstallerFolderPart & "\" & strFolderPending & "\"
		Dim strFolderPath As String
		strFolderPath = strInstallerFolder & "\" & strFolderPending & "\"
		Dim strFileFolderPath As String							'	Where the file will end up after mirroring
		strFileFolderPath = strFolderPath & strFileName.Replace("'","''")
		Dim strWebFileFolderPath As String						'	Where the file will be mirrored from
		strWebFileFolderPath = strWebPath & strFileName
		oFilePost.SaveAs(strWebFileFolderPath)

		'		Get the ID of the "Pending" status
		sqlReader.Close()
		sqlSelectCmd.CommandText = "SELECT ID FROM tbl_checklist_status WHERE (Name = 'Pending')"
		sqlReader = sqlSelectCmd.ExecuteReader()
		If Not sqlReader.HasRows Then
			intResultCode = 91
			strResultTitle = "Upload Problem"
			strResultMsg = "There was an unexpected error while storing the document. Please contact Carpet Cutters Commercial."
			strResultType = "System Error"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "StoreDocument", strResultMsg & " Unable to obtain the Pending Id from tbl_checklist_status.")
			SetHeaders(intResultCode, strResultTitle, strResultMsg, strResultType)
			Throw New Exception("Custom")
		End If

		sqlReader.Read()
		Dim strPendingStatus As String
		strPendingStatus = sqlReader("ID").ToString()
		sqlReader.Close()

		'		Get the ID of the "Installer Web Application Update" alert
		sqlSelectCmd.CommandText = "SELECT ID FROM tbl_alert_type WHERE (Name = 'Installer Web Application Update')"
		sqlReader = sqlSelectCmd.ExecuteReader()
		If Not sqlReader.HasRows Then
			intResultCode = 92
			strResultTitle = "Upload Problem"
			strResultMsg = "There was an unexpected error while storing the document. Please contact Carpet Cutters Commercial."
			strResultType = "System Error"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "StoreDocument", strResultMsg & " Unable to obtain the Alert Id from tbl_alert_type.")
			SetHeaders(intResultCode, strResultTitle, strResultMsg, strResultType)
			Throw New Exception("Custom")
		End If

		sqlReader.Read()
		Dim strAlertId As String
		strAlertId = sqlReader("ID").ToString()
		sqlReader.Close()

		'		Determine if an alert has been recorded for today
		Dim strAlertText As String
		strAlertText = "Check update processed for Installer " & strInstallerName & " for Check " & strCheckName & " status set to Pending ready for review by Admin"
		Dim strTodayDate As String
		strTodayDate = DateTime.Now.Tostring("yyyyMMdd")
		Dim strTomorrowDate As String
		strTomorrowDate = DateTime.Now.AddDays(1).Tostring("yyyyMMdd")

		sqlSelectCmd.CommandText = "SELECT ID FROM tbl_alert WHERE (RaisedBy = '" & strUserEmail & "' AND MessageBody = '" & strAlertText & "' AND CreatedDateTime > '" & strTodayDate & "' AND CreatedDateTime < '" & strTomorrowDate & "')"
		sqlReader = sqlSelectCmd.ExecuteReader()
		Dim blnNewAlert As Boolean
		blnNewAlert = True
		If sqlReader.HasRows Then
			blnNewAlert = False
		End If
		sqlReader.Close()

		Dim sqlUpdateCmd As New SqlCommand
		sqlUpdateCmd.Connection = sqlConn
		If strChecklistType = "I"					'		Installer document
			sqlUpdateCmd.CommandText = "UPDATE tbl_installer_checklist SET ChecklistStatusID = " & strPendingStatus & ", ExpiryDate = " & strExpiryDate & ", FileFolderPath = '" & strFileFolderPath & "' WHERE (InstallerID = " & strInstallerId & " AND ChecklistID = " & strChecklistId & ")"
		Else										'		Company document
			sqlUpdateCmd.CommandText = "UPDATE tbl_installer_company_checklist SET ChecklistStatusID = " & strPendingStatus & ", ExpiryDate = " & strExpiryDate & ", FileFolderPath = '" & strFileFolderPath & "' WHERE (InstallerCompanyID = " & strInstallerCompanyId & " AND ChecklistID = " & strChecklistId & ")"
		End If

		Dim sqlTransaction As sqlTransaction
		sqlTransaction = sqlConn.BeginTransaction("StoreDoc")
		sqlUpdateCmd.Transaction = sqlTransaction

		Try

			Dim intUpdateCount As Integer
			intUpdateCount = sqlUpdateCmd.ExecuteNonQuery()
			
			If intUpdateCount = 0 Then
				intResultCode = 93
				strResultTitle = "Upload Problem"
				strResultMsg = "There was an unexpected error while storing the document. Please contact Carpet Cutters Commercial."
				strResultType = "System Error"
				PutLog("CEP app", "Installer", strUserEmail, strResultType, "StoreDocument", strResultMsg & " Unable to update tbl_installer_checklist or tbl_installer_company_checklist. " & strChecklistType & " " & sqlUpdateCmd.CommandText)
				SetHeaders(intResultCode, strResultTitle, strResultMsg, strResultType)
				Throw New Exception("Custom")
			End If

			If blnNewAlert Then				'		This is the first upload for this user/document today
				Dim sqlUpdateCmd2 As New SqlCommand
				sqlUpdateCmd2.Connection = sqlConn
				sqlUpdateCmd2.CommandText = "INSERT INTO tbl_alert (AlertTypeId, MessageBody, CreatedDateTime, RaisedBy) VALUES (" & strAlertId & ", '" & strAlertText & "', GETDATE(), '" & strUserEmail & "')"
				sqlUpdateCmd2.Transaction = sqlTransaction
				intUpdateCount = sqlUpdateCmd2.ExecuteNonQuery()

				If intUpdateCount = 0 Then
					intResultCode = 94
					strResultTitle = "Upload Problem"
					strResultMsg = "There was an unexpected error while storing the document. Please contact Carpet Cutters Commercial."
					strResultType = "System Error"
					PutLog("CEP app", "Installer", strUserEmail, strResultType, "StoreDocument", strResultMsg & " Unable to insert into tbl_alert.")
					SetHeaders(intResultCode, strResultTitle, strResultMsg, strResultType)
					Throw New Exception("Custom")
				End If
			End If
			sqlTransaction.Commit()
			sqlConn.Close()

			intResultCode = 10
			strResultTitle = "Document Uploaded"
			strResultMsg = "Your document has been uploaded"
			strResultType = "Information"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "StoreDocument", strResultMsg & " to " & strWebFileFolderPath)

		Catch ex As Exception
			sqlTransaction.Rollback()
			If ex.Message <> "Custom" Then
				intResultCode = 95
				strResultTitle = "System Error"
				strResultMsg = "There was an unexpected error while storing the document (" & intResultCode & ") "
				strResultType = "System Error"
				PutLog("CEP app", "Installer", strUserEmail, strResultType, "StoreDocument", strResultMsg & " " & ex.Message)
			End If

		End Try

	Catch ex As Exception
		If ex.Message <> "Custom" Then
			intResultCode = 96
			strResultTitle = "System Error"
			strResultMsg = "There was an unexpected error while storing the document (" & intResultCode & ") "
			strResultType = "System Error"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "StoreDocument", strResultMsg & " " & ex.Message)
		End If

	End Try
		
	SetHeaders(intResultCode, strResultTitle, strResultMsg, strResultType)
	'Response.Cookies("ResultCode").Value = intResultCode.ToString()
	'Response.Cookies("ResultTitle").Value = strResultTitle
	'Response.Cookies("ResultMsg").Value = strResultMsg
	'Response.Cookies("ResultType").Value = strResultType

	PutLog("CEP app", "Installer", strUserEmail, "Debug", "StoreDocument", "Ended - result: " & strResultType)

%>
