Public Class ViewReservationItemsForm
    Private reservationId As Integer
    Private reservationCode As String

    Public Sub New(resId As Integer, resCode As String, items As List(Of ReservationItem))
        InitializeComponent()
        reservationId = resId
        reservationCode = resCode
        DisplayItems(items)
    End Sub

    Private Sub DisplayItems(items As List(Of ReservationItem))
        Me.Text = $"Order Details - {reservationCode}"
        
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
                item.TotalPrice.ToString("C")
            )
        Next

        ' Calculate total from TotalPrice
        Dim total As Decimal = items.Sum(Function(i) i.TotalPrice)
        lblTotal.Text = $"Total: {total:C}"
    End Sub

    Private Sub btnClose_Click(sender As Object, e As EventArgs) Handles btnClose.Click
        Me.Close()
    End Sub
End Class
