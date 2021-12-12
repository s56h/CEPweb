<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.IO" %>
<% @Import Namespace="System.Configuration" %>
<% @Import Namespace="System.Web" %>

<!--#include file="PutLog.aspx"-->

<%
    '	Service: GetFAQ.aspx 
	'	Invoked by: FAQ.vue component
    ' 
    '	Request headers: session id
    '	Response: result Json 
    '	Result codes: 
    '       00 - Success
    '       90 - System error: (as detected)
    '

    Dim strUserEmail As String
    strUserEmail = Request.Headers("UserEmail")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "GetFAQ", "Started")

    Dim intResultCode As Integer = 0
    Dim strResultTitle As String = ""
    Dim strResultMsg As String = ""
    Dim strResultType As String = "OK"

    Dim strClientSession As String = Request.Headers("SessionId")
	
	Dim strJsonFAQ As String
    Try
			
		Dim oAppSettings = ConfigurationManager.AppSettings
		Dim strFAQPath As String							'	The prefix of the file store accessed by CCC staff 
		strFAQPath = oAppSettings("FAQPath")
		'Dim strAppPath = HttpRuntime.AppDomainAppPath
		'Dim strWebFolder = oAppSettings("WebFolder")
		PutLog("CEP app", "Installer", strUserEmail, "Debug", "GetDocument", "Reading from: " & strFAQPath)
		'Dim oReader As StreamReader = My.Computer.FileSystem.OpenTextFileReader(strAppPath & strWebFolder & strFAQPath)
		Dim oReader As StreamReader = My.Computer.FileSystem.OpenTextFileReader(strFAQPath)
		Dim strFAQ As String
		Dim strQuestion As String
		Dim strAnswer As String
		Dim intBreakIndex As Integer
		strJsonFAQ = "["
		Do While oReader.Peek() <> -1
		   strFAQ = oReader.ReadLine
		   intBreakIndex = strFAQ.IndexOf("^")
		   strQuestion = Left(strFAQ,intBreakIndex)
		   strAnswer = Right(strFAQ, Len(strFAQ) - intBreakIndex - 1)
		   strJsonFAQ = strJsonFAQ & "{""q"": """ & HttpUtility.JavaScriptStringEncode(strQuestion) & """, ""a"": """ & HttpUtility.JavaScriptStringEncode(strAnswer) & """},"
		Loop
		strJsonFAQ = Left(strJsonFAQ, Len(strJsonFAQ) - 1) & "]"
		oReader.Close()

    Catch ex As Exception
        intResultCode = 90
		strResultTitle = "System Error"
        strResultMsg = "There was an unexpected error while accessing the FAQs (" & intResultCode & ") "
        strResultType = "System Error"
		PutLog("CEP app", "Installer", strUserEmail, strResultType, "GetFAQ", strResultMsg & " " & ex.Message)

    End Try

	Response.ContentType = "application/json; charset=utf-8"
	Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """, ""FAQs"":" & strJsonFAQ & "}")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "GetFAQ", "Ended - result: " & strResultType)

%>
