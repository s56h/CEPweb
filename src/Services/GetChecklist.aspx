<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.Web" %>
<% @Import Namespace="System.Data.Sqlclient" %>

<!--#include file="PutLog.aspx"-->

<%
    '	Service: GetChecklist.aspx
	'	Invoked by: client get/refrech checklist
    ' 
    '	Request headers: installer id 
    '	Response: checklist (json)
    '	Result codes: 
    '       00 - Success
    '       10 - Information
    '       20 - Warning
    '       30 - Error
    '       9x - System error: (as detected)
    ' 
    '	On success, the client refreshes the installer checklist.
    '

    Dim strUserEmail As String
    strUserEmail = Request.Headers("UserEmail")
    Dim strInstallerId As String
    strInstallerId = Request.Headers("InstallerId")
    Dim strInstallerCompanyId As String
    strInstallerCompanyId = Request.Headers("InstallerCompanyId")

    Dim intResultCode As Integer = 0
    Dim strResultTitle As String = ""
    Dim strResultMsg As String = ""
    Dim strResultType As String = "OK"

	PutLog("CEP app", "Installer", strUserEmail, "Debug", "GetChecklist", "Started")

	Dim jsnCheckList As String = "[]"

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
			'sqlSelectCmd.CommandText = "SELECT C.ChecklistID, C.FileFolderPath, C.ExpiryDate, L.Name, L.HasExpiryDate, S.Name, FROM tbl_installer_checklist C, tbl_checklist_status S, tbl_checklist L WHERE (C.InstallerID = " & strInstallerID & ") AND (C.CheckListID = L.ID) AND (C.ChecklistStatusID = S.ID) FOR JSON AUTO, INCLUDE_NULL_VALUES"
			sqlSelectCmd.CommandText = "SELECT C.ChecklistID, C.FileFolderPath, C.ExpiryDate, L.Name AS CheckName, L.HasExpiryDate, S.Name AS Status, 'I' AS Type FROM tbl_installer_checklist C, tbl_checklist_status S, tbl_checklist L WHERE (C.InstallerID = " & strInstallerID & ") AND (C.CheckListID = L.ID) AND (C.ChecklistStatusID = S.ID) "
			If strInstallerCompanyID <> "" Then
				sqlSelectCmd.CommandText = sqlSelectCmd.CommandText & " UNION ALL SELECT C.ChecklistID, C.FileFolderPath, C.ExpiryDate, L.Name, L.HasExpiryDate, S.Name, 'C' AS Type FROM tbl_installer_company_checklist C, tbl_checklist_status S, tbl_checklist L WHERE (C.InstallerCompanyID = " & strInstallerCompanyID & ") AND (C.CheckListID = L.ID) AND (C.ChecklistStatusID = S.ID)"
			End If
			sqlSelectCmd.CommandText = sqlSelectCmd.CommandText & " ORDER BY L.Name FOR JSON AUTO, INCLUDE_NULL_VALUES"
			Dim sqlReader As SqlDataReader
			sqlReader = sqlSelectCmd.ExecuteReader()
			If sqlReader.HasRows Then
				jsnCheckList = ""
				While sqlReader.Read()
					jsnCheckList = jsnCheckList & sqlReader(0).ToString()
				End While
			Else
				intResultCode = 91
				strResultTitle = "Checklist problem"
				strResultMsg = "There was an error while retrieving your checklist. Please contact Carpet Cutters Commercial."
				strResultType = "System Error"
				PutLog("CEP app", "Installer", strUserEmail, strResultType, "GetChecklist", strResultMsg)
			End If
			sqlConn.Close()

		Catch ex As Exception
			intResultCode = 92
			strResultTitle = "Checklist Problem"
			strResultMsg = "There was an error while refreshing your checklist. Please contact Carpet Cutters Commercial."
			strResultType = "System Error"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "GetChecklist", strResultMsg & ex.Message)

		End Try
	End If
	
    Response.ContentType="application/json; charset=utf-8" 
	Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultText"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """, ""checkList"": " & jsnCheckList & "}")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "GetChecklist", "Result: " & strResultType)

%>
