Public Class ViewOnlineOrderItemsForm
    Private orderId As Integer
    Private orderCode As String

    Public Sub New(ordId As Integer, ordCode As String, customerName As String, items As List(Of OrderItem), totalAmount As Decimal)
        InitializeComponent()
        orderId = ordId
        orderCode = ordCode
        DisplayItems(items, customerName, totalAmount)
    End Sub

    Private Sub DisplayItems(items As List(Of OrderItem), customerName As String, totalAmount As Decimal)
        Me.Text = $"Order Details - {orderCode}"
        lblCustomer.Text = $"Customer: {customerName}"
        
        ' Clear existing rows except header
        If dgvItems.Rows.Count > 0 Then
            dgvItems.Rows.Clear()
        End If

        ' Add items to DataGridView
        For Each item In items
            dgvItems.Rows.Add(
                item.ProductName,
                item.Quantity,
                item.UnitPrice.ToString("C"),
                (item.Quantity * item.UnitPrice).ToString("C")
            )
        Next

        ' Display total
        lblTotal.Text = $"Total: {totalAmount:C}"
    End Sub

    Private Sub btnClose_Click(sender As Object, e As EventArgs) Handles btnClose.Click
        Me.Close()
    End Sub
End Class
