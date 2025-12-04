Public Class LogIn
    Private userRepository As New UserRepository()
    Private attendanceRepository As New AttendanceRepository()

    Private Sub btnLogin_Click(sender As Object, e As EventArgs) Handles btnLoginTimein.Click
        Dim email As String = txtEmail.Text.Trim()
        Dim empID As String = EmployeeID.Text.Trim()

        If String.IsNullOrEmpty(email) OrElse String.IsNullOrEmpty(empID) Then
            MessageBox.Show("Please enter both email and employee ID.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        Try
            ' Authenticate employee
            Dim employee As Employee = userRepository.AuthenticateEmployee(email, empID)
            
            If employee IsNot Nothing Then
                ' Check if employee already clocked in today
                Dim todaysAttendance = attendanceRepository.GetTodaysAttendance(employee.EmployeeID)
                
                Dim attendanceID As Integer
                Dim timeIn As DateTime
                
                If todaysAttendance IsNot Nothing Then
                    ' Already clocked in today
                    attendanceID = todaysAttendance.AttendanceID
                    timeIn = todaysAttendance.TimeIn

                    MessageBox.Show(
                        $"Welcome back, {employee.FullName}!" & vbCrLf & vbCrLf &
                        $"You already clocked in today at {timeIn:hh:mm tt}",
                        "Login Successful",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Information
                    )
                Else
                    ' Record time-in
                    attendanceID = attendanceRepository.RecordTimeIn(employee.EmployeeID)
                    timeIn = DateTime.Now
                    
                    MessageBox.Show(
                        $"Welcome, {employee.FullName}!" & vbCrLf & vbCrLf &
                        $"Time In: {timeIn:hh:mm tt}",
                        "Login Successful",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Information
                    )
                End If
                
                ' Store session information
                CurrentSession.Initialize(
                    employee.EmployeeID,
                    employee.FullName,
                    employee.Email,
                    employee.Position,
                    attendanceID,
                    timeIn
                )
                
                ' Open Dashboard
                Dim dashboard As New Dashboard()
                dashboard.Show()
                Me.Hide()
            Else
                MessageBox.Show("Invalid email or employee ID.", "Login Failed", MessageBoxButtons.OK, MessageBoxIcon.Error)
            End If
        Catch ex As Exception
            MessageBox.Show($"An error occurred during login: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub LogIn_FormClosed(sender As Object, e As FormClosedEventArgs) Handles MyBase.FormClosed
        Application.Exit()
    End Sub

    Private Sub Label5_Click(sender As Object, e As EventArgs)
        MessageBox.Show("Please contact your administrator to create an account.", "Create Account", MessageBoxButtons.OK, MessageBoxIcon.Information)
    End Sub

    Private Sub LogIn_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        CenterLoginPanel()
    End Sub

    Private Sub LogIn_Resize(sender As Object, e As EventArgs) Handles MyBase.Resize
        CenterLoginPanel()
    End Sub

    Private Sub CenterLoginPanel()
        If Panel2 IsNot Nothing AndAlso Panel3 IsNot Nothing Then
            ' Center Panel3 within Panel2
            Panel3.Left = (Panel2.Width - Panel3.Width) \ 2
            Panel3.Top = (Panel2.Height - Panel3.Height) \ 2
        End If
    End Sub
End Class