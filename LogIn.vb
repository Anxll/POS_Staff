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
        ' Center the login panel
        CenterLoginPanel()

        ' Check if config.json exists
        If Not ConfigManager.ConfigExists() Then
            MessageBox.Show(
                "Database configuration not found." & vbCrLf & vbCrLf &
                "Please configure your server settings before logging in.",
                "Configuration Required",
                MessageBoxButtons.OK,
                MessageBoxIcon.Information
            )
            OpenServerConfigForm()
            Return
        End If

        ' Test database connection with fallback
        Dim config As DatabaseConfig = ConfigManager.LoadConfig()
        If config Is Nothing OrElse Not config.IsValid() Then
            MessageBox.Show(
                "Invalid database configuration." & vbCrLf & vbCrLf &
                "Please reconfigure your server settings.",
                "Configuration Error",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning
            )
            OpenServerConfigForm()
            Return
        End If

        ' Test connection with automatic fallback to backup server
        Dim usedBackup As Boolean = False
        Dim errorMessage As String = ""
        Dim connectionSuccess As Boolean = modDB.TestConnectionWithFallback(config, usedBackup, errorMessage)

        If Not connectionSuccess Then
            ' Database not reachable
            MessageBox.Show(
                "Database not reachable." & vbCrLf & vbCrLf &
                "Error Details:" & vbCrLf &
                errorMessage & vbCrLf & vbCrLf &
                "Please reconfigure your server settings.",
                "Connection Failed",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error
            )
            OpenServerConfigForm()
            Return
        End If

        ' If backup server was used, update the connection string
        If usedBackup Then
            MessageBox.Show(
                "Primary server unavailable." & vbCrLf & vbCrLf &
                "Connected to backup server successfully.",
                "Using Backup Server",
                MessageBoxButtons.OK,
                MessageBoxIcon.Information
            )

            ' Update config to use backup as primary for this session
            config.ServerIP = config.BackupServerIP
            modDB.ReloadConnectionString()
        End If
    End Sub

    ''' <summary>
    ''' Opens the server configuration form and closes the login form
    ''' </summary>
    ''' <summary>
    ''' Opens the server configuration form and restarts if configuration changed
    ''' </summary>
    Private Sub OpenServerConfigForm()
        Dim configForm As New ServerConfig()
        Me.Hide()

        If configForm.ShowDialog() = DialogResult.OK Then
            ' Restart application to reload all settings and connections
            Application.Restart()
        Else
            ' User cancelled or closed the form without saving
            Application.Exit()
        End If
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

    Private Sub Panel3_Paint(sender As Object, e As PaintEventArgs) Handles Panel3.Paint

    End Sub

    ''' <summary>
    ''' Server Settings button click handler
    ''' Opens the server configuration form
    ''' </summary>
    Private Sub btnServerSettings_Click(sender As Object, e As EventArgs) Handles btnServerSettings.Click
        Dim result As DialogResult = MessageBox.Show(
            "Do you want to reconfigure the database server settings?" & vbCrLf & vbCrLf &
            "This will close the login form and open the server configuration.",
            "Reconfigure Server",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Question
        )

        If result = DialogResult.Yes Then
            OpenServerConfigForm()
        End If
    End Sub

    Private Sub Panel2_Paint(sender As Object, e As PaintEventArgs) Handles Panel2.Paint

    End Sub
End Class
