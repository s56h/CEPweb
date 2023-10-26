<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.Configuration" %>
<% @Import Namespace="System.IO" %>
<% @Import Namespace="System.Web" %>
<% @Import Namespace="System.Data.Sqlclient" %>

<!--#include file="PutLog.aspx"-->

<%
    '	Service: SaveStatementPdf.aspx
	'				- save a subcontractor statement pdf to the file system
	'	Invoked by: Statement.vue component
    ' 
    '	Request headers: session id, user email, installer id 
    '	Response: result message, path of saved file 
    '	Result codes: 
    '       00 - Success
    '       1x - Information
    '       2x - Warning
    '       30 - Error: session timeout
    '       9x - System error: (as detected)
    '

    Dim strUserEmail As String = Request.Headers("UserEmail")
    Dim strClientSession As String = Request.Headers("SessionKey")
	Dim strInstallerId As String = Request.Headers("InstallerId")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "SaveStatementPdf", "Started")

    Dim intResultCode As Integer = 0
    Dim strResultTitle As String = ""
    Dim strResultMsg As String = ""
    Dim strResultType As String = "OK"

	Dim strPdfFormFilename As String = ""
	Dim strWebFileFolderPath As String = ""						'	Where the file will be mirrored from
	Dim strFileFolderPath As String	= ""						'	JSON encoded path
	Dim strStatementURL As String	= ""

    If strClientSession <> Session("SessionKey") Then
		intResultCode = 30
		strResultTitle = "Login Needed"
		strResultMsg = "Your session has timed out. Please login again."		'	Or, this could be a hacking attempt. Not likely.
		strResultType = "Error"
		Response.ContentType = "application/json; charset=utf-8" 
		Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """}")
		Response.End()
	End If

	Try

		Dim intContentLength As Integer
		Dim strContentType As String

		Dim oFilePost As HttpPostedFile
		Dim streamReader As System.IO.StreamReader
		Dim strBase64Encoded as String
		Dim strBase64Decoded as String

		'
		'		Get the folder to store the pdf in
		'
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
			'intResultCode = 90
			'strResultTitle = "Statement Problem"
			'strResultMsg = "There was an unexpected error while producing your subcontractor statement (90). Please contact Carpet Cutters Commercial."
			'strResultType = "System Error"
			PutLog("CEP app", "Installer", strUserEmail, "System Error", "SaveStatementPdf", " Unable to obtain the folder path for the installer from tbl_installer.")
			Throw New Exception("Custom")
		End If

		'		Create the statement pdf path
		sqlReader.Read()
		Dim strInstallerFolder As String
		strInstallerFolder = sqlReader("FolderPath").ToString()
		Dim oAppSettings = ConfigurationManager.AppSettings
		Dim strFolderDropPrefix As String						'	The prefix of the file store accessed by CCC staff 
		strFolderDropPrefix = oAppSettings("FolderDropPrefix")
		Dim strWebPath As String								'	The location (mirrored) of the statements accessible by the Web app
		Dim strInstallerFolderPart As String					'	The installer folder stripped of the CCC staff access prefix
		strInstallerFolderPart = Right(strInstallerFolder, strInstallerFolder.Length() - strFolderDropPrefix.Length())
		strWebPath = Server.MapPath(oAppSettings("VirtualData")) & strInstallerFolderPart & "/"
		Dim strFolderPath As String
		strFolderPath = strInstallerFolder & "\"
		Dim strDate As String
		strDate = DateTime.Now.Tostring("yyyy-MM-dd")
		Dim strTime As String
		strTime = DateTime.Now.Tostring("hh_mm_ss")

		strPdfFormFilename = "Statement-" & strInstallerId & " " & strDate & " " & strTime & ".pdf"
		strFileFolderPath = strFolderPath & strPdfFormFilename
		strFileFolderPath = strFileFolderPath.Replace("\","\\")
		strStatementURL = (oAppSettings("VirtualData") & strInstallerFolderPart  & "/" & strPdfFormFilename).Replace("\","/")
		
		strWebFileFolderPath = strWebPath & strPdfFormFilename
		
		'		Save the statement pdf
		oFilePost = Request.Files(0)
		intContentLength = Convert.toInt32(oFilePost.ContentLength)
		strContentType = oFilePost.ContentType
		PutLog("CEP app", "Installer", strUserEmail, "content type ", "SaveStatementPdf", strContentType)
		Dim buffer(intContentLength) As Byte
		oFilePost.InputStream.Read(buffer,0,intContentLength)
		strBase64Encoded = System.Text.Encoding.Default.GetString(buffer)
		strBase64Encoded = strBase64Encoded.Substring(0,intContentLength)		'	An extra space seems to get added for some reason

		Dim bytData() As Byte
		bytData = System.Convert.FromBase64String(strBase64Encoded)
		File.WriteAllBytes(strWebFileFolderPath, bytData)

	Catch ex As Exception
		intResultCode = 90
		strResultTitle = "Statement Problem"
		strResultMsg = "There was an unexpected error while while producing your subcontractor statement (90). Please contact Carpet Cutters Commercial."
		strResultType = "System Error"
		PutLog("CEP app", "Installer", strUserEmail, strResultType, "SaveStatementPdf", strResultMsg & " " & ex.Message)

	End Try

    Response.ContentType = "application/json; charset=utf-8" 
	Response.Write("{""resultCode"":" & intResultCode & ", ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """, ""pdfURL"":""" & strStatementURL & """, ""filePath"":""" & strFileFolderPath & """}")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "SaveStatementpdf", "Ended - result: " & strResultType)

%>
