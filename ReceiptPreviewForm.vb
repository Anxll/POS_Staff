Imports System.Text
Imports System.Drawing.Printing
Imports System.IO
Imports System.Diagnostics

Public Class ReceiptPreviewForm
    Public Property OrderID As Integer
    Public Property OrderType As String ' "OnlineOrder" or "Reservation"
    Public Property ReceiptText As String

    Public Sub New(id As Integer, type As String, content As String)
        InitializeComponent()
        OrderID = id
        OrderType = type
        ReceiptText = content
        rtbPreview.Text = content
    End Sub

    Private Sub btnClose_Click(sender As Object, e As EventArgs) Handles btnClose.Click
        Me.Close()
    End Sub

    Private Sub btnGenerate_Click(sender As Object, e As EventArgs) Handles btnGenerate.Click
        Try
            Dim receiptRepo As New ReceiptRepository()
            Dim receiptID As Integer = 0
            Dim cashierName As String = If(CurrentSession.FullName <> "", CurrentSession.FullName, "Staff Member")
            Dim orderNum As String = ""
            
            ' 1. Logic for Online Order
            If OrderType = "OnlineOrder" Then
                Dim orderRepo As New OrderRepository()
                Dim order = orderRepo.GetOnlineOrderById(OrderID)
                If order Is Nothing Then Throw New Exception("Online Order not found in database.")
                
                ' Use existing receipt number if available, otherwise generate
                orderNum = If(Not String.IsNullOrEmpty(order.ReceiptNumber), order.ReceiptNumber, $"WEB-{order.OrderDate:yyyy}-{order.OrderID:D6}")
                
                ' 1. Update status to Completed FIRST to trigger inventory deduction
                ' This ensures batch info exists in logs for InsertReceiptItems to find
                orderRepo.UpdateOrderStatus(OrderID, "Completed")
                orderRepo.UpdateOrderReceiptNumber(OrderID, orderNum)

                ' 2. Insert Receipt Header
                receiptID = receiptRepo.InsertReceiptHeader(
                    OrderID, orderNum, order.TotalAmount, 
                    "CASH", order.TotalAmount, 0, 
                    order.OrderDate, order.OrderTime, 
                    cashierName, order.CustomerName, "Online", "WEBSITE"
                )
                
                ' 3. Insert Items (now with batch info available in logs)
                Dim items = orderRepo.GetOrderItems(OrderID)
                If items.Count > 0 Then
                    receiptRepo.InsertReceiptItems(receiptID, OrderID, items)
                End If

                ' 4. Record Payment in payments table
                receiptRepo.RecordPayment(OrderID, Nothing, order.TotalAmount, "Cash", "Website", orderNum)

                ' Log Activity
                ActivityLogger.LogUserActivity(
                    action:="Receipt Generated",
                    actionCategory:="Order",
                    description:=$"Generated receipt {orderNum} for Online Order #{OrderID}",
                    sourceSystem:="Staff App",
                    referenceID:=orderNum,
                    referenceTable:="sales_receipts"
                )
                
            ' 2. Logic for Reservation
            ElseIf OrderType = "Reservation" Then
                Dim resRepo As New ReservationRepository()
                Dim res = resRepo.GetReservationById(OrderID)
                If res Is Nothing Then Throw New Exception("Reservation not found in database.")
                
                ' Generate Order Number
                orderNum = $"RES-{res.EventDate:yyyy}-{res.ReservationID:D6}"
                
                ' 1. Update status to Completed FIRST to trigger inventory deduction
                resRepo.UpdateReservationStatus(OrderID, "Completed")

                ' 2. Insert Receipt Header
                receiptID = receiptRepo.InsertReceiptHeader(
                    OrderID, orderNum, res.TotalPrice, 
                    "CASH", res.TotalPrice, 0, 
                    res.EventDate, res.EventTime, 
                    cashierName, res.CustomerName, "Reservation", "RESERVATION"
                )
                
                ' 3. Insert Items (now with batch info available in logs)
                Dim resItems = resRepo.GetReservationItems(OrderID)
                Dim orderItems As New List(Of OrderItem)
                For Each ri In resItems
                    orderItems.Add(New OrderItem With {
                        .ProductName = ri.ProductName, 
                        .Quantity = ri.Quantity, 
                        .UnitPrice = ri.UnitPrice,
                        .OrderID = OrderID
                    })
                Next
                
                If orderItems.Count > 0 Then
                    receiptRepo.InsertReceiptItems(receiptID, OrderID, orderItems)
                End If

                ' 4. Record Payment in payments table
                receiptRepo.RecordPayment(OrderID, OrderID, res.TotalPrice, "Cash", "POS", orderNum)

                ' Log Activity
                ActivityLogger.LogUserActivity(
                    action:="Receipt Generated",
                    actionCategory:="Reservation",
                    description:=$"Generated receipt {orderNum} for Reservation #{OrderID}",
                    sourceSystem:="Staff App",
                    referenceID:=orderNum,
                    referenceTable:="sales_receipts"
                )
            End If

            ' 3. Generate PDF
            If receiptID > 0 Then
                Dim pdfGen As New ReceiptPDFGenerator()
                Dim filePath As String = pdfGen.GenerateReceipt(receiptID)
                
                MessageBox.Show($"Receipt generated successfully!" & vbCrLf & vbCrLf & $"Recorded in database and saved as PDF." & vbCrLf & $"Path: {filePath}", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information)
                
                ' Open Folder & Select File
                Try
                    Process.Start("explorer.exe", $"/select,""{filePath}""")
                Catch ex As Exception
                    ' Ignore explorer errors
                End Try
                
                Me.DialogResult = DialogResult.OK
                Me.Close()
            Else
                Throw New Exception("Failed to save receipt record to database.")
            End If
            
        Catch ex As Exception
            MessageBox.Show($"Error generating receipt: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub PrintPageHandler(sender As Object, e As PrintPageEventArgs)
        Dim font As New Font("Consolas", 10)
        Dim leftMargin As Single = e.MarginBounds.Left
        Dim topMargin As Single = e.MarginBounds.Top
        Dim printAreaHeight As Single = e.MarginBounds.Height
        
        e.Graphics.DrawString(ReceiptText, font, Brushes.Black, leftMargin, topMargin)
    End Sub
End Class
