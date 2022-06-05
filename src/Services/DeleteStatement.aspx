<% @Page Language="VB" Debug="true" aspcompat="true" %>
<% @Import Namespace="System.Configuration" %>
<% @Import Namespace="System.IO" %>
<% @Import Namespace="System.Web" %>
<% @Import Namespace="System.Data.Sqlclient" %>

<!--#include file="PutLog.aspx"-->

<%
    '	Service: CancelStatement.aspx
	'				- delete subcontractor statement and invoice
	'	Invoked by: Statement.vue component
    ' 
    '	Request headers: session id, user email, statement id, request type
    '	Response: result (in Session cookies due to perceived constraints of Quasar upload component) 
    '	Result codes: 
    '       00 - Success
    '       1x - Information
    '       2x - Warning
    '       30 - Error: session timeout
    '       9x - System error: (as detected)
    '

    Dim strUserEmail As String = Request.Headers("UserEmail")
	PutLog("CEP app", "Installer", strUserEmail, "Debug", "CancelStatement", "Started")

    Dim strStatementId As String = Request.Headers("StatementId")
	Dim strSubStatementFileFolderPath As String = Request.Headers("StatementFile")
	Dim strDeleteType As String = Request.Headers("DeleteType")
	Dim strDeleteText As String
	If strDeleteType = "Statement" Then
		strDeleteText = "cancelling your subcontractor statement"
	Else
		strDeleteText = "deleting your invoice/statement"
	End If

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
			sqlSelectCmd.CommandText = "SELECT InvoiceFileFolderPath, SubStatementFileFolderPath FROM tbl_sub_contractor_statement WHERE ID = " & strStatementId
			Dim sqlReader As SqlDataReader

			sqlReader = sqlSelectCmd.ExecuteReader()
			If sqlReader.HasRows Then
            	sqlReader.Read()
				Dim strInvoiceFileFolderPath As String
            	strInvoiceFileFolderPath = sqlReader("InvoiceFileFolderPath").ToString()
            	'strSubStatementFileFolderPath = sqlReader("SubStatementFileFolderPath").ToString()
				sqlReader.Close()

				'	delete files
				File.Delete(strInvoiceFileFolderPath)
				File.Delete(strSubStatementFileFolderPath)
				'	delete statement row
				Dim sqlUpdateCmd As New SqlCommand
				sqlUpdateCmd.Connection = sqlConn
				sqlUpdateCmd.CommandText = "DELETE tbl_sub_contractor_statement WHERE ID = " & strStatementId

				Dim intUpdateCount As Integer
				intUpdateCount = sqlUpdateCmd.ExecuteNonQuery()
				
				If intUpdateCount = 0 Then
					intResultCode = 90
					strResultTitle = "Statement Problem"
					strResultMsg = "There was an unexpected error while " & strDeleteText & " (90). Please contact Carpet Cutters Commercial."
					strResultType = "System Error"
					PutLog("CEP app", "Installer", strUserEmail, "System Error", "CancelStatement", "Unable to delete from tbl_sub_contractor_statement for id: " & strStatementId)
					Throw New Exception("Custom")
				End If

			Else
				intResultCode = 91
				strResultTitle = "Statement Problem"
				strResultMsg = "There was an unexpected error while " & strDeleteText & " (91). Please contact Carpet Cutters Commercial."
				strResultType = "System Error"
				PutLog("CEP app", "Installer", strUserEmail, "System Error", "CancelStatement", " Unable to obtain the tbl_sub_contractor_statement statement row for id: " & strStatementId)
			End If

			sqlConn.Close()

			intResultCode = 10
			strResultTitle = "Statement cancelled"
			strResultMsg = "Your invoice and subcontractor statement have been deleted."
			strResultType = "Information"

		Catch ex As Exception
			intResultCode = 90
			strResultTitle = "System Error"
			strResultMsg = "There was an unexpected error while " & strDeleteText & " (90). Please contact CCC."
			strResultType = "System Error"
			PutLog("CEP app", "Installer", strUserEmail, strResultType, "CancelStatement", strResultMsg & " " & ex.Message)

		End Try

	End If

	PutLog("CEP app", "Installer", strUserEmail, "Debug", "CancelStatement", "Ended - result: " & strResultType)
	Response.Write("{""resultCode"": """ & intResultCode & """, ""resultMsg"": """ & strResultMsg & """, ""resultType"": """ & strResultType & """, ""resultTitle"": """ & strResultTitle & """}")

%>
