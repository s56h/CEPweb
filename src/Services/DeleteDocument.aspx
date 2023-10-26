<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.IO" %>
<% @Import Namespace="System.Web" %>
<% @Import Namespace="System.Data.Sqlclient" %>

<!--#include file="PutLog.aspx"-->

<%
    '	Service: DeleteDocument.aspx 
	'	Invoked by: Home.vue component
    ' 
    '	Request headers: session id, installer id, checklist id 
    '	Response: result
    '	Result codes: 
    '       00 - Success
    '       10 - Information: document deleted
    '       20 - Warning
	'		30 - Error: session expired
    '       9x - System error: (as detected)
    '

    Dim strUserEmail As String
    strUserEmail = Request.Headers("UserEmail")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "DeleteDocument", "Started")

	Dim strInstallerId As String
	strInstallerId = Request.Headers("InstallerId")
	Dim strInstallerCompanyId As String
	strInstallerCompanyId = Request.Headers("InstallerCompanyId")
	Dim strChecklistId As String
	strChecklistId = Request.Headers("ChecklistId")
	Dim strChecklistType As String
	strChecklistType = Request.Headers("CheckType")
    Dim intResultCode As Integer = 0
    Dim strResultTitle As String = ""
    Dim strResultMsg As String = ""
    Dim strResultType As String = "OK"

    Dim strClientSession As String = Request.Headers("SessionKey")
    If strClientSession <> Session("SessionKey") Then
		intResultCode = 30
		strResultTitle = "Login Needed"
		strResultMsg = "Your session has timed out. Please login again."		'	Or, this could be a hacking attempt. Not likely.
		strResultType = "Error"
	Else
		Try
			Dim sqlConn As New SqlConnection
			Dim strConnString As String
			strConnString = ConfigurationManager.ConnectionStrings("CEPapp").ConnectionString
			sqlConn.ConnectionString = strConnString
			sqlConn.Open()

			Dim sqlSelectCmd As New SqlCommand
			sqlSelectCmd.Connection = sqlConn
			If strChecklistType = "I" Then				'		Installer checklist item
				sqlSelectCmd.CommandText = "SELECT FileFolderPath FROM tbl_installer_checklist WHERE (InstallerID = " & strInstallerId & " AND CheckListId = " & strChecklistId & ")"
			Else										'		Company checklist item
				sqlSelectCmd.CommandText = "SELECT FileFolderPath FROM tbl_installer_company_checklist WHERE (InstallerCompanyID = " & strInstallerCompanyId & " AND CheckListId = " & strChecklistId & ")"
			End If

			Dim sqlReader As SqlDataReader
			sqlReader = sqlSelectCmd.ExecuteReader()
			If sqlReader.HasRows Then
				sqlReader.Read()
				Dim strInstallerFilePath As String
				strInstallerFilePath = sqlReader("FileFolderPath").ToString()
				Dim oAppSettings = ConfigurationManager.AppSettings
				Dim strFolderDropPrefix As String						'	The prefix of the file store accessed by CCC staff 
				strFolderDropPrefix = oAppSettings("FolderDropPrefix")
				'Dim strAppPath = HttpRuntime.AppDomainAppPath
				Dim strInstallerFilePart As String						'	The installer filename stripped of the CCC staff access prefix
				strInstallerFilePart = Right(strInstallerFilePath, strInstallerFilePath.Length() - strFolderDropPrefix.Length())
				Dim strWebPath As String
				strWebPath = Server.MapPath(oAppSettings("VirtualData")) & "\"
				Dim strWebFilePath As String	
				strWebFilePath = strWebPath & strInstallerFilePart
				'	The location (mirrored) of the documents/images accessible by the Web app
				'strWebFilePath = strAppPath & oAppSettings("WebFolder") & strInstallerFilePart

				If IO.File.Exists(strWebFilePath) Then
					IO.File.Delete(strWebFilePath)
				'If IO.File.Exists(strInstallerFilePath) Then
				'	IO.File.Delete(strInstallerFilePath)
					sqlReader.Close()
					sqlSelectCmd.CommandText = "SELECT ID FROM tbl_checklist_status WHERE (Name = 'None')"
					sqlReader = sqlSelectCmd.ExecuteReader()
					If sqlReader.HasRows Then
						sqlReader.Read()
						Dim strNoneStatus As String
						strNoneStatus = sqlReader("ID").ToString()
				
						sqlReader.Close()
						Dim sqlUpdateCmd As New SqlCommand
						sqlUpdateCmd.Connection = sqlConn
						If strChecklistType = "I" Then				'		Installer checklist item
							sqlUpdateCmd.CommandText = "UPDATE tbl_installer_checklist SET ExpiryDate = NULL, ChecklistStatusId = " & strNoneStatus & ", FileFolderPath = NULL WHERE (InstallerID = " & strInstallerId & " AND CheckListId = " & strChecklistId & ")"
						Else										'		Company checklist item
							sqlUpdateCmd.CommandText = "UPDATE tbl_installer_company_checklist SET ExpiryDate = NULL, ChecklistStatusId = " & strNoneStatus & ", FileFolderPath = NULL WHERE (InstallerCompanyID = " & strInstallerCompanyId & " AND CheckListId = " & strChecklistId & ")"
						End If
						Dim intUpdateCount As Integer
						intUpdateCount = sqlUpdateCmd.ExecuteNonQuery()
						If intUpdateCount = 0 Then
							intResultCode = 90
							strResultTitle = "Delete problem"
							strResultMsg = "There was an error while deleting the document (90). Please contact Carpet Cutters Commercial."
							strResultType = "System Error"
							PutLog("CEP app", "Installer", strUserEmail, strResultType, "DeleteDocument", strResultMsg & " Unable to update tbl_installer_checklist or tbl_installer_company_checklist")
						Else
							intResultCode = 10
							strResultTitle = "Document deleted"
							strResultMsg = "The document has been deleted"
							strResultType = "Information"
							PutLog("CEP app", "Installer", strUserEmail, strResultType, "DeleteDocument", strResultMsg)
						End If
					Else
						intResultCode = 91
						strResultTitle = "Delete problem"
						strResultMsg = "There was an error while deleting the document (91). Please contact Carpet Cutters Commercial."
						strResultType = "System Error"
						PutLog("CEP app", "Installer", strUserEmail, strResultType, "DeleteDocument", strResultMsg & " Unable to obtain the None Id from tbl_checklist_status.")
					End If
				Else
					intResultCode = 92
					strResultTitle = "Delete problem"
					strResultMsg = "Could not delete the document file (92). Please contact Carpet Cutters Commercial."
					strResultType = "System Error"
					PutLog("CEP app", "Installer", strUserEmail, strResultType, "DeleteDocument", strResultMsg & " Filename " & strWebFilePath & " does not exist")
				End If
					

			Else
				intResultCode = 93
				strResultTitle = "Delete Problem"
				strResultMsg = "There was an unexpected error while deleting the document (93). Please contact Carpet Cutters Commercial."
				strResultType = "System Error"
				PutLog("CEP app", "Installer", strUserEmail, strResultType, "DeleteDocument", strResultMsg & " Unable to get folder path from tbl_installer_checklist or tbl_installer_company_checklist")
			End If
			sqlConn.Close()

		Catch ex As Exception
			intResultCode = 94
			strResultTitle = "System Error"
			strResultMsg = "There was an unexpected error while deleting the document (94). Please contact Carpet Cutters Commercial."
			strResultType = "System Error"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "DeleteDocument", strResultMsg & " " & ex.Message)

		End Try
	End If

	PutLog("CEP app", "Installer", strUserEmail, "Debug", "DeleteDocument", "Ended - result: " & strResultType)
	Response.ContentType = "application/json; charset=utf-8"
	Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """}")

%>
