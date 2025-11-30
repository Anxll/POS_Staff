Public Class Dashboard

    Private currentActiveButton As Button = Nothing
    Private currentForm As Form = Nothing

    Private Sub Dashboard_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        SetActiveButton(btnDashboard)
        LoadForm(New DashboardForm())
    End Sub

    Private Sub btnDashboard_Click(sender As Object, e As EventArgs) Handles btnDashboard.Click
        SetActiveButton(btnDashboard)
        lblHeaderTitle.Text = "Dashboard"
        LoadForm(New DashboardForm())
    End Sub

    Private Sub btnPlaceOrder_Click(sender As Object, e As EventArgs) Handles btnPlaceOrder.Click
        SetActiveButton(btnPlaceOrder)
        lblHeaderTitle.Text = "Place Order"
        LoadForm(New PlaceOrderForm())
    End Sub

    Private Sub btnReservations_Click(sender As Object, e As EventArgs) Handles btnReservations.Click
        SetActiveButton(btnReservations)
        lblHeaderTitle.Text = "Reservations"
        LoadForm(New ReservationsForm())
    End Sub

    Private Sub btnReports_Click(sender As Object, e As EventArgs) Handles btnReports.Click
        SetActiveButton(btnReports)
        lblHeaderTitle.Text = "Reports"
        LoadForm(New ReportsForm())
    End Sub

    Private Sub SetActiveButton(activeButton As Button)
        If currentActiveButton IsNot Nothing Then
            currentActiveButton.BackColor = Color.Transparent
        End If
        activeButton.BackColor = Color.FromArgb(124, 94, 69)
        currentActiveButton = activeButton
    End Sub

    Private Sub LoadForm(newForm As Form)
        ' Dispose previous form if exists
        If currentForm IsNot Nothing Then
            pnlContent.Controls.Remove(currentForm)
            currentForm.Close()
            currentForm.Dispose()
        End If
        
        ' Configure the form to be a child form
        currentForm = newForm
        newForm.TopLevel = False
        newForm.FormBorderStyle = FormBorderStyle.None
        newForm.Dock = DockStyle.Fill
        
        ' Add to content panel and show
        pnlContent.Controls.Add(newForm)
        newForm.Show()
    End Sub

    Private Sub logo_Click(sender As Object, e As EventArgs) Handles logo.Click

    End Sub

    Private Sub lblBrand_Click(sender As Object, e As EventArgs) Handles lblBrand.Click

    End Sub
End Class
