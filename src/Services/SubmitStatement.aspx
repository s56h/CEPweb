<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.Configuration" %>
<% @Import Namespace="System.IO" %>
<% @Import Namespace="System.Web" %>
<% @Import Namespace="System.Data.Sqlclient" %>

<!--#include file="PutLog.aspx"-->

<%
    '	Service: SubmitStatement.aspx
	'				- change subcontractor statement status to submitted
	'	Invoked by: Statement.vue component
    ' 
    '	Request headers: session id, user email, installer name, statement id and path
    '	Response: result (in Session cookies due to perceived constraints of Quasar upload component) 
    '	Result codes: 
    '       00 - Success
    '       1x - Information
    '       2x - Warning
    '       30 - Error: session timeout
    '       9x - System error: (as detected)
    '

    Dim strUserEmail As String = Request.Headers("UserEmail")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "SubmitStatement", "Started")

    Dim strStatementId As String = Request.Headers("StatementId")
    Dim strStatementPath As String = Request.Headers("StatementPath")	' **************** invoice path???
	Dim strInstallerName As String = Request.Headers("InstallerName")
    Dim strInstallerId As String = Request.Headers("InstallerId")

    Dim intResultCode As Integer = 0
    Dim strResultTitle As String = ""
    Dim strResultMsg As String = ""
    Dim strResultType As String = "OK"
	Dim jsnInvoiceList As String = "[]"

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

			'		Get the ID of the "Installer Web Application Update" alert
			Dim sqlSelectCmd As New SqlCommand
			sqlSelectCmd.Connection = sqlConn
			sqlSelectCmd.CommandText = "SELECT ID FROM tbl_alert_type WHERE (Name = 'Installer Web Application Update')"
			Dim sqlReader As SqlDataReader
			sqlReader = sqlSelectCmd.ExecuteReader()
				PutLog("CEP app", "Installer", strUserEmail, "Debug", "SubmitStatement", "Starting alert insert")
			If Not sqlReader.HasRows Then
				'intResultCode = 90
				'strResultTitle = "Submit Problem"
				'strResultMsg = "There was an unexpected error while submitting your statement (90). Please contact CCC."
				'strResultType = "System Error"
				PutLog("CEP app", "Installer", strUserEmail, "System Error", "SubmitStatement", "Unable to obtain the Alert Id from tbl_alert_type.")
				Throw New Exception("Custom")
			End If

			sqlReader.Read()
			Dim strAlertId As String
			strAlertId = sqlReader("ID").ToString()
			sqlReader.Close()

			'		Determine if an alert has been recorded for today
			Dim strAlertText As String
			strAlertText = "Check invoice/statement submitted by Installer " & strInstallerName
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
			sqlUpdateCmd.CommandText = "UPDATE tbl_sub_contractor_statement SET SubContractorStatementStatusID = 2, SubStatementFileFolderPath = '" & strStatementPath & "' WHERE ID = " & strStatementId
			Dim sqlSubmitTxn As sqlTransaction
			sqlSubmitTxn = sqlConn.BeginTransaction("SubmitStatement")
			sqlUpdateCmd.Transaction = sqlSubmitTxn
			Try

				Dim intUpdateCount As Integer
				intUpdateCount = sqlUpdateCmd.ExecuteNonQuery()
				
				If intUpdateCount = 0 Then
					intResultCode = 91
					'strResultTitle = "Submit Problem"
					'strResultMsg = "There was an unexpected error while submitting your statement (91). Please contact CCC."
					'strResultType = "System Error"
					PutLog("CEP app", "Installer", strUserEmail, "System Error", "SubmitStatement", "Unable to update tbl_sub_contractor_statement. " & sqlUpdateCmd.CommandText)
					Throw New Exception("Custom")
				End If

				If blnNewAlert Then				'		This is the first invoice/statement submission for this user today
						PutLog("CEP app", "Installer", strUserEmail, "Debug", "SubmitStatement", "Inserting alert")
					Dim sqlUpdateCmd2 As New SqlCommand
					sqlUpdateCmd2.Connection = sqlConn
					sqlUpdateCmd2.CommandText = "INSERT INTO tbl_alert (AlertTypeId, MessageBody, CreatedDateTime, RaisedBy) VALUES (" & strAlertId & ", '" & strAlertText & "', GETDATE(), '" & strUserEmail & "')"
					sqlUpdateCmd2.Transaction = sqlSubmitTxn
					intUpdateCount = sqlUpdateCmd2.ExecuteNonQuery()

					If intUpdateCount = 0 Then
						intResultCode = 92
						'strResultTitle = "Submit Problem"
						'strResultMsg = "There was an unexpected error while submitting your statement (92). Please contact CCC."
						'strResultType = "System Error"
						PutLog("CEP app", "Installer", strUserEmail, "System Error", "SubmitStatement", strResultMsg & " Unable to insert into tbl_alert.")
						Throw New Exception("Custom")
					End If
				End If

				'	Get updated invoice list	******************** make include??????????
				Dim sqlReader2 As SqlDataReader
				Dim sqlInvoicesCmd As New SqlCommand
				sqlInvoicesCmd.Connection = sqlConn
				sqlInvoicesCmd.CommandText = "SELECT C.ID, C.Project_Ref_No AS projectRefNo, P.Project_Name AS projectName, C.InvoiceFrom AS invoiceFrom, C.InvoiceTo AS invoiceTo, S.Name AS invoiceStatus, C.InvoiceTotal, C.InvoiceFileFolderPath, C.SubStatementFileFolderPath, C.ActionedOnDateTime FROM tbl_sub_contractor_statement C, tbl_sub_contractor_statement_status S, tbl_projects P WHERE (C.InstallerID = " & strInstallerID & ") AND (C.SubContractorStatementStatusId = S.ID) AND (C.Project_Ref_No = P.Project_Ref_No) ORDER BY C.ActionedOnDateTime FOR JSON AUTO, INCLUDE_NULL_VALUES"
				sqlInvoicesCmd.Transaction = sqlSubmitTxn
				sqlReader2 = sqlInvoicesCmd.ExecuteReader()
				If sqlReader2.HasRows Then
					jsnInvoiceList = ""
					While sqlReader2.Read()
						jsnInvoiceList = jsnInvoiceList & sqlReader2(0).ToString()
					End While
				Else
					jsnInvoiceList = "[]"
				End If
				sqlReader2.Close()

				sqlSubmitTxn.Commit()
				sqlConn.Close()

				intResultCode = 10
				strResultTitle = "Statement submitted"
				strResultMsg = "Your subcontractor statement has been submitted"
				strResultType = "Information"

			Catch ex As Exception
				sqlSubmitTxn.Rollback()
				If intResultCode = 0 Then
					intResultCode = 93	'	Other
				End If
				strResultTitle = "System Error"
				strResultMsg = "There was an unexpected error while storing the document (" & intResultCode & ")"
				strResultType = "System Error"
				PutLog("CEP app", "Installer", strUserEmail, strResultType, "SubmitStatement", strResultMsg & " " & ex.Message)

			End Try

		Catch ex As Exception
			If ex.Message <> "Custom" Then
				intResultCode = 90
				strResultTitle = "System Error"
				strResultMsg = "There was an unexpected error while submitting your statement (90). Please contact CCC."
				strResultType = "System Error"
				PutLog("CEP app", "Installer", strUserEmail, strResultType, "SubmitStatement", strResultMsg & " " & ex.Message)
			End If

		End Try

	End If

	PutLog("CEP app", "Installer", strUserEmail, "Debug", "SubmitStatement", "Ended - result: " & strResultType)
	Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """, ""invoiceList"": " & jsnInvoiceList & "}")

%>
