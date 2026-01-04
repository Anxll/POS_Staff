Public Class Dashboard

    Private currentActiveButton As Button = Nothing
    Private currentForm As Form = Nothing
    
    ' Cached form instances
    Private cachedDashboardForm As DashboardForm = Nothing
    Private cachedPlaceOrderForm As PlaceOrderForm = Nothing
    Private cachedOnlineOrdersForm As OnlineOrdersForm = Nothing
    Private cachedReservationsForm As ReservationsForm = Nothing
    Private cachedReportsForm As ReportsForm = Nothing

    Private Sub Dashboard_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        ' Set active button but DON'T load form yet - prevents initial freeze
        SetActiveButton(btnDashboard)
        lblHeaderTitle.Text = "Dashboard"
        
        ' Load dashboard form asynchronously to prevent UI freeze
        Task.Run(Sub()
                     Me.Invoke(Sub()
                                   LoadForm(GetOrCreateDashboardForm())
                               End Sub)
                 End Sub)
    End Sub

    Private Sub btnDashboard_Click(sender As Object, e As EventArgs) Handles btnDashboard.Click
        SetActiveButton(btnDashboard)
        lblHeaderTitle.Text = "Dashboard"
        LoadForm(GetOrCreateDashboardForm())
    End Sub

    Private Sub btnPlaceOrder_Click(sender As Object, e As EventArgs) Handles btnPlaceOrder.Click
        SetActiveButton(btnPlaceOrder)
        lblHeaderTitle.Text = "Place Order"
        LoadForm(GetOrCreatePlaceOrderForm())
    End Sub

    Private Sub btnReservations_Click(sender As Object, e As EventArgs) Handles btnReservations.Click
        SetActiveButton(btnReservations)
        lblHeaderTitle.Text = "Reservations"
        LoadForm(GetOrCreateReservationsForm())
    End Sub

    Private Sub btnReports_Click(sender As Object, e As EventArgs) Handles btnReports.Click
        SetActiveButton(btnReports)
        lblHeaderTitle.Text = "Reports"
        LoadForm(GetOrCreateReportsForm())
    End Sub

    Private Sub Button1_Click(sender As Object, e As EventArgs) Handles Button1.Click
        SetActiveButton(Button1)
        lblHeaderTitle.Text = "Online Orders"
        LoadForm(GetOrCreateOnlineOrdersForm())
    End Sub

    ' Form caching methods
    Private Function GetOrCreateDashboardForm() As DashboardForm
        If cachedDashboardForm Is Nothing OrElse cachedDashboardForm.IsDisposed Then
            cachedDashboardForm = New DashboardForm()
        End If
        Return cachedDashboardForm
    End Function

    Private Function GetOrCreatePlaceOrderForm() As PlaceOrderForm
        If cachedPlaceOrderForm Is Nothing OrElse cachedPlaceOrderForm.IsDisposed Then
            cachedPlaceOrderForm = New PlaceOrderForm()
        End If
        Return cachedPlaceOrderForm
    End Function

    Private Function GetOrCreateOnlineOrdersForm() As OnlineOrdersForm
        If cachedOnlineOrdersForm Is Nothing OrElse cachedOnlineOrdersForm.IsDisposed Then
            cachedOnlineOrdersForm = New OnlineOrdersForm()
        End If
        Return cachedOnlineOrdersForm
    End Function

    Private Function GetOrCreateReservationsForm() As ReservationsForm
        If cachedReservationsForm Is Nothing OrElse cachedReservationsForm.IsDisposed Then
            cachedReservationsForm = New ReservationsForm()
        End If
        Return cachedReservationsForm
    End Function

    Private Function GetOrCreateReportsForm() As ReportsForm
        If cachedReportsForm Is Nothing OrElse cachedReportsForm.IsDisposed Then
            cachedReportsForm = New ReportsForm()
        End If
        Return cachedReportsForm
    End Function

    Private Sub SetActiveButton(activeButton As Button)
        If currentActiveButton IsNot Nothing Then
            currentActiveButton.BackColor = Color.Transparent
        End If
        activeButton.BackColor = Color.FromArgb(124, 94, 69)
        currentActiveButton = activeButton
    End Sub

    Private Sub LoadForm(formToShow As Form)
        ' Hide current form instead of disposing it
        If currentForm IsNot Nothing AndAlso currentForm IsNot formToShow Then
            currentForm.Hide()
            ' Don't remove from controls, just hide it to preserve state
            ' pnlContent.Controls.Remove(currentForm) 
        End If
        
        ' If this is a new form (not already in panel), configure and add it
        If Not pnlContent.Controls.Contains(formToShow) Then
            formToShow.TopLevel = False
            formToShow.FormBorderStyle = FormBorderStyle.None
            formToShow.Dock = DockStyle.Fill
            pnlContent.Controls.Add(formToShow)
        End If
        
        ' Ensure properties are correct every time we show it
        formToShow.Dock = DockStyle.Fill
        formToShow.Visible = True
        currentForm = formToShow
        formToShow.Show()
        formToShow.BringToFront()
    End Sub

    Private Sub logo_Click(sender As Object, e As EventArgs) Handles logo.Click

    End Sub

    Private Sub lblBrand_Click(sender As Object, e As EventArgs) Handles lblBrand.Click

    End Sub

    Private Sub btnLogout_Click(sender As Object, e As EventArgs) Handles btnLogout.Click
        ' Confirm logout
        Dim result = MessageBox.Show(
            "Are you sure you want to logout?" & vbCrLf & vbCrLf &
            "Your time-out will be recorded.",
            "Confirm Logout",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Question
        )

        If result = DialogResult.Yes Then
            Try
                ' Record time-out if there's an active session
                If CurrentSession.IsLoggedIn AndAlso CurrentSession.AttendanceID > 0 Then
                    Dim attendanceRepo As New AttendanceRepository()
                    attendanceRepo.RecordTimeOut(CurrentSession.EmployeeID, CurrentSession.AttendanceID)
                End If

                ' Clear session
                CurrentSession.Clear()

                ' Show login form
                Dim loginForm As New LogIn()
                loginForm.Show()
                Me.Close()
            Catch ex As Exception
                MessageBox.Show(
                    $"Error during logout: {ex.Message}",
                    "Logout Error",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                )
            End Try
        End If
    End Sub
End Class
