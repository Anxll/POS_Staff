Imports System.Globalization

Public Class NewReservationForm
    Private reservationRepository As New ReservationRepository()
    
    ' Store selected reservation items
    Public Property SelectedItems As New List(Of ReservationItem)

    Private Sub NewReservationForm_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        ' Set default date to today
        dtpDate.Value = DateTime.Now
        dtpTime.Value = DateTime.Now
        cmbEventType.SelectedIndex = 0 ' Default to first item
    End Sub

    Private Sub Button1_Click(sender As Object, e As EventArgs) Handles Button1.Click
        ' Open ReservationSelectOrder form to select items
        Dim selectOrderForm As New ReservationSelectOrder()
        
        ' Pass existing items to the order form
        If SelectedItems IsNot Nothing AndAlso SelectedItems.Count > 0 Then
            selectOrderForm.SetPreSelectedItems(SelectedItems)
        End If

        If selectOrderForm.ShowDialog() = DialogResult.OK Then
            ' Get selected items from the order form
            SelectedItems = selectOrderForm.GetSelectedItems()
            
            ' Update UI to show items were selected
            If SelectedItems.Count > 0 Then
                Button1.Text = $"Selected ({SelectedItems.Count} items)"
                Button1.BackColor = Color.FromArgb(0, 200, 83) ' Green to indicate selected
            Else
                Button1.Text = "Select Order Items"
                Button1.BackColor = Color.WhiteSmoke
            End If
        End If
    End Sub

    Private Sub btnClose_Click(sender As Object, e As EventArgs) Handles btnClose.Click
        Me.DialogResult = DialogResult.Cancel
        Me.Close()
    End Sub

    Private Sub btnBookTable_Click(sender As Object, e As EventArgs) Handles btnBookTable.Click
        ' Validate required inputs
        If String.IsNullOrWhiteSpace(txtName.Text) OrElse
           String.IsNullOrWhiteSpace(txtPhone.Text) Then
            MessageBox.Show("Please fill in all required fields (Name, Phone).", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        ' Validate guests
        Dim numberOfGuests As Integer = numGuests.Value
        If numberOfGuests < 1 Then
            MessageBox.Show("Please enter a valid number of guests.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        ' Get Date and Time
        Dim eventDate = dtpDate.Value.Date
        Dim eventTime = dtpTime.Value.TimeOfDay

        Try
            ' Create/Get Customer
            Dim nameParts = txtName.Text.Trim.Split(" "c)
            Dim firstName = nameParts(0)
            Dim lastName = If(nameParts.Length > 1, String.Join(" ", nameParts.Skip(1)), "")

            ' Pass empty string for email
            Dim customerID = modDB.GetOrCreateCustomer(firstName, lastName, "", txtPhone.Text.Trim)

            Dim reservation As New Reservation With {
                .CustomerID = customerID,
                .ReservationType = "Walk-in",
                .EventType = If(String.IsNullOrWhiteSpace(cmbEventType.Text), "General", cmbEventType.Text),
                .EventDate = eventDate,
                .EventTime = eventTime,
                .NumberOfGuests = numberOfGuests,
                .SpecialRequests = txtSpecialRequest.Text,
                .ReservationStatus = "Pending",
                .ContactNumber = txtPhone.Text,
                .Items = SelectedItems ' Attach selected items to reservation
            }

            If reservationRepository.CreateReservation(reservation) > 0 Then
                MessageBox.Show("Reservation created successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information)
                DialogResult = DialogResult.OK
                Close()
            Else
                MessageBox.Show("Failed to create reservation.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            End If
        Catch ex As Exception
            MessageBox.Show($"Error creating reservation: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub
End Class
