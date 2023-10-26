<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.Configuration" %>
<% @Import Namespace="System.IO" %>
<% @Import Namespace="System.Web" %>

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
    '	Service: SaveSignature.aspx 
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
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "SaveSignature", "Started")

    Dim intResultCode As Integer = 0
    Dim strResultTitle As String = ""
    Dim strResultMsg As String = ""
    Dim strResultType As String = "OK"

    Dim strClientSession As String = Request.Cookies.Item("SessionKey").Value.ToString()
    'If strClientSession <> Session("SessionKey") Then
	'	intResultCode = 30
	'	strResultTitle = "Login Needed"
	'	strResultMsg = "Your session has timed out. Please login again."		'	Or, this could be a hacking attempt. Not likely.
	'	strResultType = "Error"
	'	Response.ContentType = "application/json; charset=utf-8" 
	'	Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """}")
	'	Response.End()
	'End If

	Try
		Dim uploadedFiles
		'	PutLog("CEP app", "Installer", strUserEmail, "save data", "SaveSignature", strSignatureData)
		uploadedFiles = Request.Files
		
		Dim strSignatureData = Request.Form("SignatureData")
		Dim strSignatureJpgUrl = Request.Form("SignatureImage")
		Dim intContentLength As Integer
		Dim strContentType As String
		Dim strFileName As String
		'intContentLength = Convert.toInt32(oSignatureDataPost.ContentLength)
		'strContentType = oSignatureDataPost.ContentType
		
		Dim strInstallerId As String
		strInstallerId = Request.Cookies.Item("InstallerId").Value.ToString()

		Dim oAppSettings = ConfigurationManager.AppSettings
		Dim strSignatureDataFilename As String
		Dim strSignatureJpgFilename As String
		'strSignaturePath = Server.MapPath(oAppSettings("SignatureFolder")) & "\Signature" & strInstallerId & ".dat"
		strSignatureDataFilename = Server.MapPath("/CEPWeb/CEPdata") & "\Signatures\Signature" & strInstallerId & ".dat"
		strSignatureJpgFilename = Server.MapPath("/CEPWeb/CEPdata") & "\Signatures\Signature" & strInstallerId & ".png"
		PutLog("CEP app", "Installer", strUserEmail, "save data", "SaveSignature", strSignatureDataFilename)
		'Request.SaveAs(strSignaturePath,False)
		'oSignatureDataPost.SaveAs(strSignaturePath)
		Dim dataFile As System.IO.StreamWriter
		dataFile = My.Computer.FileSystem.OpenTextFileWriter(strSignatureDataFilename, False)
		dataFile.WriteLine(strSignatureData)
		dataFile.Close()
		'Dim imageFile As System.IO.StreamWriter
		'imageFile = My.Computer.FileSystem.OpenTextFileWriter(strSignatureJpgFilename, False)
		Dim bytSignatureJpg As Byte()
		If (strSignatureJpgUrl.IndexOf("data:image/jpeg;base64,") = 0) Then
		'If (strSignatureJpgUrl.IndexOf("data:image/png;base64,") = 0) Then
		PutLog("CEP app", "Installer", strUserEmail, "save data", "SaveSignature", strSignatureJpgUrl.Length())
			bytSignatureJpg = System.Convert.FromBase64String(strSignatureJpgUrl.Substring(23))
		End if
		Dim imageFile As StreamWriter = New StreamWriter(File.Create(strSignatureJpgFilename))
        imageFile.Write(System.Text.ASCIIEncoding.ASCII.GetString(bytSignatureJpg))
		imageFile.Close()

	Catch ex As Exception
		intResultCode = 90
		strResultTitle = "System Error"
		strResultMsg = "There was an unexpected error while storing the signature (" & intResultCode & ") "
		strResultType = "System Error"
		PutLog("CEP app", "Installer", strUserEmail, strResultType, "SaveSignature", strResultMsg & " " & ex.Message)

	End Try
		
	'SetHeaders(intResultCode, strResultTitle, strResultMsg, strResultType)
	'Response.Cookies("ResultCode").Value = intResultCode.ToString()
	'Response.Cookies("ResultTitle").Value = strResultTitle
	'Response.Cookies("ResultMsg").Value = strResultMsg
	'Response.Cookies("ResultType").Value = strResultType

    Response.ContentType = "application/json; charset=utf-8" 
	Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """}")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "SaveSignature", "Ended - result: " & strResultType)

%>
