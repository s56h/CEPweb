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
		
		Dim strInstallerId As String
		strInstallerId = Request.Cookies.Item("InstallerId").Value.ToString()

		Dim intContentLength As Integer
		Dim strContentType As String
		
		Dim oAppSettings = ConfigurationManager.AppSettings

		Dim strJsonFileName As String
		Dim strSignatureFilename As String
		Dim strFileName As String
		'intContentLength = Convert.toInt32(oSignatureDataPost.ContentLength)

		Dim oFilePost As HttpPostedFile
		Dim streamReader As System.IO.StreamReader
		Dim strBase64Encoded as String
		Dim strBase64Decoded as String
		Dim bytData() As Byte

		For intFileIx As Integer = 0 To 1
			oFilePost = Request.Files(intFileIx)
			intContentLength = Convert.toInt32(oFilePost.ContentLength)
			strContentType = oFilePost.ContentType
			PutLog("CEP app", "Installer", strUserEmail, "content type ", "SaveSignature", strContentType)
			strSignatureFilename = Server.MapPath("/CEPWeb/CEPdata") & "\Signatures\Signature-" & strInstallerId
			If (strContentType = "image/png") Then			'		Encoded image
				strSignatureFilename = strSignatureFilename & ".png"
				Dim buffer(intContentLength) As Byte
				oFilePost.InputStream.Read(buffer,0,intContentLength)
				strBase64Encoded = System.Text.Encoding.Default.GetString(buffer)
				strBase64Encoded = strBase64Encoded.Substring(0,intContentLength)		'	An extra space seems to get added for some reason

				'PutLog("CEP app", "Installer", strUserEmail, "content length", "SaveSignature", intContentLength)
				'PutLog("CEP app", "Installer", strUserEmail, "content length", "SaveSignature", strBase64Encoded.Length())
				'PutLog("CEP app", "Installer", strUserEmail, "content bytes", "SaveSignature", strBase64Encoded)
				bytData = System.Convert.FromBase64String(strBase64Encoded)
				'strBase64Decoded = System.Text.ASCIIEncoding.ASCII.GetString(bytData)
				File.WriteAllBytes(strSignatureFilename, bytData)

			Else		'		JSON signature data
				strJsonFileName = strSignatureFilename & ".json"
				oFilePost.SaveAs(strJsonFileName)
			End if
			PutLog("CEP app", "Installer", strUserEmail, "save data", "SaveSignature", strSignatureFilename)
		Next
		'strSignaturePath = Server.MapPath(oAppSettings("SignatureFolder")) & "\Signature" & strInstallerId & ".dat"

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
