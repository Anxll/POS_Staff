Imports System.Collections.Generic
Imports System.Windows.Forms

Public Class ViewReservationInfoForm
    Private reservationRepository As New ReservationRepository()

    Public Sub New(res As Reservation)
        InitializeComponent()
        DisplayReservationDetails(res)
    End Sub

    Private Sub DisplayReservationDetails(res As Reservation)
        Try
            lblName.Text = $"Name: {res.CustomerName}"
            lblPhone.Text = $"Phone: {If(String.IsNullOrEmpty(res.ContactNumber), "n/a", res.ContactNumber)}"
            lblEmail.Text = $"Email: {If(String.IsNullOrEmpty(res.CustomerEmail), "n/a", res.CustomerEmail)}"
            lblGuests.Text = $"No. of Guests: {res.NumberOfGuests}"
            lblDateTime.Text = $"Date/Time: {res.EventDate:MM/dd/yyyy} {DateTime.Today.Add(res.EventTime):h:mm tt}"
            lblEventType.Text = $"Event Type: {res.EventType}"

            ' Load items if not already loaded
            Dim items As List(Of ReservationItem) = res.Items
            If items Is Nothing OrElse items.Count = 0 Then
                items = reservationRepository.GetReservationItems(res.ReservationID)
            End If

            ' Populate Grid
            dgvItems.Rows.Clear()
            Dim total As Decimal = 0
            For Each item In items
                dgvItems.Rows.Add(
                    item.ProductName,
                    item.Quantity,
                    item.UnitPrice.ToString("C"),
                    (item.Quantity * item.UnitPrice).ToString("C")
                )
                total += (item.Quantity * item.UnitPrice)
            Next

            lblTotalAmount.Text = $"Total: {total:C}"

        Catch ex As Exception
            MessageBox.Show($"Error loading details: {ex.Message}", "Error")
        End Try
    End Sub

    Private Sub btnClose_Click(sender As Object, e As EventArgs) Handles btnClose.Click
        Me.Close()
    End Sub
End Class
