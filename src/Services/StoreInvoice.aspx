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
    Public Sub SetHeaders(intResultCode As Integer, strResultTitle As String, strResultMsg As String, strResultType As String, intInsertId As Integer)
		
	Response.Cookies("ResultCode").Value = intResultCode.ToString()
	Response.Cookies("ResultTitle").Value = strResultTitle
	Response.Cookies("ResultMsg").Value = strResultMsg
	Response.Cookies("ResultType").Value = strResultType
	Response.Cookies("StatementId").Value = intInsertId.ToString()
	  
    End Sub

</script>

<%
    '	Service: StoreInvoice.aspx 
	'	Invoked by: Home.vue component
    ' 
    '	Request headers: session id, installer id 
    '	Response: result (in Session cookies due to perceived constraints of Quasar upload component) 
    '	Result codes: 
    '       00 - Success
    '       1x - Information
    '       2x - Warning
    '       30 - Error: session timeout
    '       9x - System error: (as detected)
    '

    Dim strUserEmail As String
	strUserEmail = Request.Headers("UserEmail")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "StoreDocument", "Started")

    Dim intResultCode As Integer = 0
    Dim strResultTitle As String = ""
    Dim strResultMsg As String = ""
    Dim strResultType As String = "OK"
	Dim intInsertID As Integer = 0

    Dim strClientSession As String = Request.Headers("SessionKey")
    If strClientSession <> Session("SessionKey") Then
		intResultCode = 30
		strResultTitle = "Login Needed"
		strResultMsg = "Your session has timed out. Please login again."		'	Or, this could be a hacking attempt. Not likely.
		strResultType = "Error"
		SetHeaders(intResultCode, strResultTitle, strResultMsg, strResultType, 0)
		Response.End()
	End If

	Try
		
		Dim oFilePost = Request.Files(0)
		Dim intContentLength As Integer
		Dim strContentType As String
		Dim strFileName As String
		intContentLength = Convert.toInt32(oFilePost.ContentLength)
		strContentType = oFilePost.ContentType
		strFileName = oFilePost.FileName
		
    	Dim strInstallerId As String = Request.Headers("InstallerId")
    	Dim strInstallerCompanyId As String = Request.Headers("InstallerCompanyId")
    	Dim strInstallerName As String = Request.Headers("InstallerName")
    	Dim strProjectRef As String = Request.Headers("ProjectRef")
    	Dim strInvoiceFrom As String = Request.Headers("DateFrom")
    	Dim strInvoiceTo As String = Request.Headers("DateTo")
		
		Dim sqlConn As New SqlConnection
		Dim strConnString As String
		strConnString = ConfigurationManager.ConnectionStrings("CEPapp").ConnectionString
		sqlConn.ConnectionString = strConnString
		sqlConn.Open()

		Dim sqlSelectCmd As New SqlCommand
		sqlSelectCmd.Connection = sqlConn
		sqlSelectCmd.CommandText = "SELECT FolderPath FROM tbl_installer WHERE (ID = " & strInstallerId & ")"
		Dim sqlReader As SqlDataReader

		sqlReader = sqlSelectCmd.ExecuteReader()
		If Not sqlReader.HasRows Then
			intResultCode = 90
			strResultTitle = "Upload Problem"
			strResultMsg = "There was an unexpected error while storing your invoice. Please contact Carpet Cutters Commercial."
			strResultType = "System Error"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "StoreInvoice", strResultMsg & " Unable to obtain the folder path for the installer: " & sqlSelectCmd.CommandText)
			SetHeaders(intResultCode, strResultTitle, strResultMsg, strResultType, 0)
			Throw New Exception("Custom")
		End If

		sqlReader.Read()
		Dim strInstallerFolder As String
		strInstallerFolder = sqlReader("FolderPath").ToString()
		Dim oAppSettings = ConfigurationManager.AppSettings
		Dim strFolderDropPrefix As String						'	The prefix of the file store accessed by CCC staff 
		strFolderDropPrefix = oAppSettings("FolderDropPrefix")
		'Dim strAppPath = HttpRuntime.AppDomainAppPath
		Dim strWebPath As String								'	The location (mirrored) of the documents/images accessible by the Web app
		Dim strInstallerFolderPart As String					'	The installer folder stripped of the CCC staff access prefix
		strInstallerFolderPart = Right(strInstallerFolder, strInstallerFolder.Length() - strFolderDropPrefix.Length())
		strWebPath = Server.MapPath(oAppSettings("VirtualData")) & strInstallerFolderPart & "\"
		Dim strFolderPath As String
		strFolderPath = strInstallerFolder & "\" 
		Dim strFileFolderPath As String							'	Where the file will end up after mirroring

		Dim strDate As String
		strDate = DateTime.Now.Tostring("yyyy-MM-dd")
		Dim strTime As String
		strTime = DateTime.Now.Tostring("hh_mm_ss")

		Dim strNewFilename As String = "Invoice-" & strInstallerId & " " & strDate & " " & strTime & ".pdf"
		strFileFolderPath = strFolderPath & strNewFilename
		Dim strWebFileFolderPath As String						'	Where the file will be mirrored from
		strWebFileFolderPath = strWebPath & strNewFilename
		oFilePost.SaveAs(strWebFileFolderPath)
		sqlReader.Close()

		Dim sqlUpdateCmd As New SqlCommand
		sqlUpdateCmd.Connection = sqlConn
		sqlUpdateCmd.CommandText = "INSERT INTO tbl_sub_contractor_statement (InstallerId, project_ref_no, InvoiceTotal, InvoiceFrom, InvoiceTo, SubContractorStatementStatusId, InvoiceFileFolderPath) VALUES (" & strInstallerId & ",'" & strProjectRef & "', 0, '" & strInvoiceFrom & "', '" & strInvoiceTo & "', 2, '" & strFileFolderPath & "'); SELECT SCOPE_IDENTITY() AS ID;"

		Try

			intInsertID = sqlUpdateCmd.ExecuteScalar()
			
			If intInsertID = 0 Then
				intResultCode = 93
				strResultTitle = "Upload Problem"
				strResultMsg = "There was an unexpected error while saving your invoice (93). Please contact Carpet Cutters Commercial."
				strResultType = "System Error"
				PutLog("CEP app", "Installer", strUserEmail, strResultType, "StoreInvoice", strResultMsg & " Unable to update tbl_installer_checklist or tbl_installer_company_checklist. " & sqlUpdateCmd.CommandText)
				Throw New Exception("Custom")
			End If

			sqlConn.Close()

			intResultCode = 10
			strResultTitle = "Invoice Uploaded"
			strResultMsg = "Your invoice has been uploaded"
			strResultType = "Information"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "StoreInvoice", strResultMsg & " to " & strWebFileFolderPath)

		Catch ex As Exception
			If ex.Message <> "Custom" Then
				intResultCode = 95
				strResultTitle = "System Error"
				strResultMsg = "There was an unexpected error while saving your invoice (95). Please contact Carpet Cutters Commercial."
				strResultType = "System Error"
				PutLog("CEP app", "Installer", strUserEmail, strResultType, "StoreInvoice", strResultMsg & " " & ex.Message)
			End If

		End Try

	Catch ex As Exception
		If ex.Message <> "Custom" Then
			intResultCode = 96
			strResultTitle = "System Error"
			strResultMsg = "There was an unexpected error while saving yor invoice (96). Please contact Carpet Cutters Commercial."
			strResultType = "System Error"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "StoreInvoice", strResultMsg & " " & ex.Message)
		End If

	End Try
		
	SetHeaders(intResultCode, strResultTitle, strResultMsg, strResultType, intInsertID)

	PutLog("CEP app", "Installer", strUserEmail, "Debug", "StoreInvoice", "Ended - result: " & strResultType)
	Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """, ""statementID"": " & intInsertID & "}")

%>
