<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.Web" %>
<% @Import Namespace="System.Data.Sqlclient" %>

<!--#include file="PutLog.aspx"-->

<%
    '	Service: GetInstallerlists.aspx
	'	Invoked by: client get/refrech checklist and invoices list
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
    '	On success, the client refreshes the installer checklist and invoices list.
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

	PutLog("CEP app", "Installer", strUserEmail, "Debug", "GetInstallerLists", "Started")

	Dim jsnCheckList As String = "[]"
	Dim jsnInvoiceList As String = "[]"
	Dim jsnProjectList As String = "[]"
	Dim jsnStatementData As String = "{}"

    Dim strClientSession As String = Request.Headers("SessionKey")
    If strClientSession <> Session("SessionKey") Then
		intResultCode = 30
		strResultTitle = "Login Needed"
		strResultMsg = "Your session has timed out. Please login again."	'	Or, this could be a hacking attempt. Not likely.
		strResultType = "Error"
	Else
		Try
			Dim sqlConn As New SqlConnection
			Dim strConnString As String
			strConnString = ConfigurationManager.ConnectionStrings("CEPapp").ConnectionString
			sqlConn.ConnectionString = strConnString
			sqlConn.Open()

			'	PutLog("CEP app", "Installer", strUserEmail, "DEBUG", "GetInstallerLists", "Getting cheklist")
			Dim sqlChecklistCmd As New SqlCommand
			sqlChecklistCmd.Connection = sqlConn
			'sqlSelectCmd.CommandText = "SELECT C.ChecklistID, C.FileFolderPath, C.ExpiryDate, L.Name, L.HasExpiryDate, S.Name, FROM tbl_installer_checklist C, tbl_checklist_status S, tbl_checklist L WHERE (C.InstallerID = " & strInstallerID & ") AND (C.CheckListID = L.ID) AND (C.ChecklistStatusID = S.ID) FOR JSON AUTO, INCLUDE_NULL_VALUES"
			sqlChecklistCmd.CommandText = "SELECT C.ChecklistID AS 'Item.Id', C.FileFolderPath AS 'Item.File', C.ExpiryDate AS 'Item.Exp', L.Name AS 'Item.Name', L.HasExpiryDate AS 'Item.ExpFlag', S.Name AS 'Item.Status', CAST(T.IsMandatory AS INT) AS 'Item.MandFlag', 'I' AS 'Item.Type' FROM tbl_installer_checklist C, tbl_checklist_status S, tbl_checklist L, tbl_checklist_checklist_type T WHERE (C.InstallerID = " & strInstallerID & ") AND (C.CheckListID = L.ID) AND (C.ChecklistStatusID = S.ID) AND (L.ID = T.ChecklistID)"
			If strInstallerCompanyID <> "" Then
				sqlChecklistCmd.CommandText = sqlChecklistCmd.CommandText & " UNION ALL SELECT C.ChecklistID AS 'Item.Id', C.FileFolderPath AS 'Item.File', C.ExpiryDate AS 'Item.Exp', L.Name AS 'Item.Name', L.HasExpiryDate AS 'Item.ExpFlag', S.Name AS 'Item.Status', CAST(T.IsMandatory AS INT) AS 'Item.MandFlag', 'C' AS 'Item.Type' FROM tbl_installer_company_checklist C, tbl_checklist_status S, tbl_checklist L, tbl_checklist_checklist_type T WHERE (C.InstallerCompanyID = " & strInstallerCompanyID & ") AND (C.CheckListID = L.ID) AND (C.ChecklistStatusID = S.ID) AND (L.ID = T.ChecklistID)"
			End If
			sqlChecklistCmd.CommandText = sqlChecklistCmd.CommandText & " ORDER BY 'Item.Name' FOR JSON PATH, INCLUDE_NULL_VALUES"
			Dim sqlReader As SqlDataReader
			sqlReader = sqlChecklistCmd.ExecuteReader()
			If sqlReader.HasRows Then
				jsnCheckList = ""
				While sqlReader.Read()
					jsnCheckList = jsnCheckList & sqlReader(0).ToString()
				End While
			Else
				jsnCheckList = "[]"
			End If
			sqlReader.Close()

			'	************ future enhancement
			'Dim sqlReader2 As SqlDataReader
			'Dim sqlInvoicesCmd As New SqlCommand
			'sqlInvoicesCmd.Connection = sqlConn
			'sqlInvoicesCmd.CommandText = "SELECT C.ID, C.Project_Ref_No AS projectRefNo, P.Project_Name AS projectName, C.InvoiceFrom AS invoiceFrom, C.InvoiceTo AS invoiceTo, S.Name AS invoiceStatus, C.InvoiceTotal, C.InvoiceFileFolderPath, C.SubStatementFileFolderPath, C.ActionedOnDateTime FROM tbl_sub_contractor_statement C, tbl_sub_contractor_statement_status S, tbl_projects P WHERE (C.InstallerID = " & strInstallerID & ") AND (C.SubContractorStatementStatusId = S.ID) AND (C.Project_Ref_No = P.Project_Ref_No) ORDER BY C.ActionedOnDateTime FOR JSON AUTO, INCLUDE_NULL_VALUES"
			'sqlReader2 = sqlInvoicesCmd.ExecuteReader()
			'If sqlReader2.HasRows Then
			'	jsnInvoiceList = ""
			'	While sqlReader2.Read()
			'		jsnInvoiceList = jsnInvoiceList & sqlReader2(0).ToString()
			'	End While
			'Else
			'	jsnInvoiceList = "[]"
			'End If
			'sqlReader2.Close()

			'Dim sqlReader3 As SqlDataReader
			'Dim sqlInstallerProjectsCmd As New SqlCommand
			'sqlInstallerProjectsCmd.Connection = sqlConn
			'sqlInstallerProjectsCmd.CommandText = "SELECT P.Project_Ref_No AS projectRefNo, P.Project_Name AS projectName FROM tbl_installer_project IP, tbl_projects P WHERE (IP.InstallerID = " & strInstallerID & ") AND (IP.Project_Ref_No = P.Project_Ref_No) ORDER BY P.Project_Name FOR JSON AUTO, INCLUDE_NULL_VALUES"
			' ********************** exclude completed projects (can no longer invoice)
			'sqlReader3 = sqlInstallerProjectsCmd.ExecuteReader()
			'If sqlReader3.HasRows Then
			'	jsnProjectList = ""
			'	While sqlReader3.Read()
			'		jsnProjectList = jsnProjectList & sqlReader3(0).ToString()
			'	End While
			'Else
			'	jsnProjectList = "[]"
			'End If
			'sqlReader3.Close()

			'	PutLog("CEP app", "Installer", strUserEmail, "DEBUG", "GetInstallerLists", "Getting statement data")
			'Dim sqlReader4 As SqlDataReader
			'Dim sqlInstallerCmd As New SqlCommand
			'sqlInstallerCmd.Connection = sqlConn
			'sqlInstallerCmd.CommandText = "SELECT BusinessName, Address, BusinessTitle, ABN, WorkerCompDate FROM tbl_installer WHERE (ID = " & strInstallerID & ")"
			'sqlReader4 = sqlInstallerCmd.ExecuteReader()
			'Dim businessName As String
			'Dim address As String
			'Dim businessTitle As String
			'Dim ABN As String
			'Dim workCompDate As String
			'If sqlReader4.HasRows Then
			'	sqlReader4.Read()
			'	businessName = sqlReader4("BusinessName").ToString()
			'	address = sqlReader4("Address").ToString()
			'	businessTitle = sqlReader4("BusinessTitle").ToString()
			'	ABN = sqlReader4("ABN").ToString()
			'	workCompDate = sqlReader4("WorkerCompDate").ToString()
			'Else
			'	intResultCode = 94
			'	strResultTitle = "Installer data problem"
			'	strResultMsg = "There was an error while retrieving your data. Please contact Carpet Cutters Commercial."
			'	strResultType = "System Error"
			'	PutLog("CEP app", "Installer", strUserEmail, strResultType, "GetInstallerLists", strResultMsg + " (Statement data)")
			'End If
			'sqlReader4.Close()

			'jsnInvoiceList = "[{""invoiceListId"":1,""invoiceFrom"":""2022-01-15T00:00:00"",""invoiceTo"":""2022-01-21T00:00:00"",""status"":""Rejected""},{""invoiceListId"":2,""invoiceFrom"":""2022-01-08T00:00:00"",""invoiceTo"":""2022-01-14T00:00:00"",""status"":""Approved""},{""invoiceListId"":3,""invoiceFrom"":""2022-01-01T00:00:00"",""invoiceTo"":""2022-01-07T00:00:00"",""status"":""Paid""},{""invoiceListId"":4,""invoiceFrom"":""2021-12-05T00:00:00"",""invoiceTo"":""2021-12-18T00:00:00"",""status"":""Paid""}]"
			'jsnProjectList = "[{""projectId"":""1X"",""jobDesc"":""Carpet"", ""jobCustomer"":""ANZ Bank""},{""projectId"":""2xcv235"",""jobDesc"":""Better carpet"", ""jobCustomer"":""CBA Bank""},{""projectId"":""3678y"",""jobDesc"":""El cheapo"", ""jobCustomer"":""Supercheap Auto""}]"
			'jsnStatementData = "{""businessName"":""" + businessName + """,""address"":""" + address + """, ""insuranceDate"":""" + workCompDate + """, ""signerTitle"":""" + businessTitle + """, ""ABN"":""" + ABN + """}"
			sqlConn.Close()

		Catch ex As Exception
			intResultCode = 92
			strResultTitle = "Checklist Problem"
			strResultMsg = "There was an error while retrieving your data. Please contact Carpet Cutters Commercial."
			strResultType = "System Error"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "GetInstallerLists", strResultMsg & " Code: " & intResultCode & " " & ex.Message & " for: " & sqlChecklistCmd.CommandText)

		End Try
	End If
	
    Response.ContentType="application/json; charset=utf-8" 
	'Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """, ""checkList"": " & jsnCheckList & ", ""projectList"": " & jsnProjectList & ", ""invoiceList"": " & jsnInvoiceList & ", ""statementData"": " & jsnStatementData & "}")
	Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """, ""checkList"": " & jsnCheckList & "}")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "GetInstallerLists", "Result: " & strResultType)

%>
