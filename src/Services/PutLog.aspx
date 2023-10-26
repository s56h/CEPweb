<script language="vbscript" type="text/vbsscript" runat="server">
	'
    '       For tracing/error logging
    '
    Public Sub PutLog(strServiceName As String, strUserType As String, strUserId As String, strTraceType As String, strProcedure As String, strMessage As String)
	'
	'	Trace levels: All (except debug), Information, Warning, Error, System Error, Debug
	'

		Dim strTraceLevel As String
		Dim oAppSettings = ConfigurationManager.AppSettings
		strTraceLevel = oAppSettings("TraceLevel")
		
		If strTraceLevel <> "All" Then
			If strTraceLevel <> "Debug" And strTraceType = "Debug" Then
				Exit Sub
			End If
			If strTraceLevel = "Information" And strTraceType = "OK" Then
				Exit Sub
			End If
			If strTraceLevel = "Warning" And (strTraceType = "OK" Or strTraceType = "Information") Then
				Exit Sub
			End If
			If strTraceLevel = "Error" And (strTraceType <> "Error" And strTraceType <> "System Error") Then
				Exit Sub
			End If
			If strTraceLevel = "System Error" And strTraceType <> "System Error" Then
				Exit Sub
			End If
		End If
		
		Dim strAppPath = HttpRuntime.AppDomainAppPath
		Dim strTraceFilename As String
		Dim strSuffix As String
		strSuffix = DateTime.Now.Tostring("yyyyMM")
		strTraceFilename = strAppPath & oAppSettings("TraceFile") & strSuffix & ".log"
		Dim strPM As String
		strPM = oAppSettings("LogProjectMgr")
		
		Dim strDate As String
		strDate = DateTime.Now.Tostring("yyyy-MM-dd")
		Dim strTime As String
		strTime = DateTime.Now.Tostring("HH:mm:ss")
		Dim strTraceString As String
		strTraceString = strServiceName & "^" & strUserType & " " & strUserId & "^" & strPM & "^" & strTraceType & "^" & strProcedure & "^" & strMessage & "^" & strDate & "^" & strTime & Environment.NewLine
		My.Computer.FileSystem.WriteAllText(strTraceFilename, strTraceString, True)
	  
    End Sub

</script>