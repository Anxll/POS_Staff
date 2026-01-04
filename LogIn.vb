Imports MySql.Data.MySqlClient

Public Class LogIn
    Private attendanceRepository As New AttendanceRepository()

    Private Sub btnLogin_Click(sender As Object, e As EventArgs) Handles btnLoginTimein.Click
        Dim username As String = txtUsername.Text.Trim()
        Dim password As String = txtPassword.Text.Trim()

        ' Validation
        If String.IsNullOrEmpty(username) Then
            MessageBox.Show("Please enter your username.", "Missing Field", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            txtUsername.Focus()
            Return
        End If

        If String.IsNullOrEmpty(password) Then
            MessageBox.Show("Please enter your password.", "Missing Field", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            txtPassword.Focus()
            Return
        End If

        Try
            ' Encrypt typed password
            Dim encryptedPass As String = Encrypt(password)

            ' Query user_accounts table with JOIN to employee table
            Dim query As String = "
                SELECT ua.*, 
                       COALESCE(e.EmployeeID, 0) as EmployeeID,
                       COALESCE(e.FirstName, '') as FirstName,
                       COALESCE(e.LastName, '') as LastName,
                       COALESCE(e.Email, '') as Email,
                       COALESCE(e.Position, ua.position) as Position
                FROM user_accounts ua
                LEFT JOIN employee e ON ua.employee_id = e.EmployeeID
                WHERE ua.username = @user 
                AND ua.password = @pass 
                LIMIT 1"

            openConn()
            cmd = New MySqlCommand(query, conn)
            cmd.Parameters.AddWithValue("@user", username)
            cmd.Parameters.AddWithValue("@pass", encryptedPass)

            Dim reader = cmd.ExecuteReader()

            If reader.Read() Then
                ' Store logged user
                CurrentLoggedUser.id = reader("id")
                CurrentLoggedUser.name = reader("name").ToString()
                CurrentLoggedUser.username = reader("username").ToString()
                CurrentLoggedUser.password = reader("password").ToString()
                CurrentLoggedUser.type = reader("type")
                CurrentLoggedUser.employee_id = If(IsDBNull(reader("employee_id")), 0, CInt(reader("employee_id")))

                ' Check status
                Dim status As String = "Active"
                Try
                    If Not IsDBNull(reader("status")) Then
                        status = reader("status").ToString()
                    End If
                Catch
                End Try

                If status = "Resigned" OrElse status = "InActive" Then
                    MessageBox.Show("Your account is deactivated or resigned. Access denied.", "Login Failed", MessageBoxButtons.OK, MessageBoxIcon.Error)
                    reader.Close()
                    conn.Close()
                    Return
                End If

                ' Get employee information
                Dim employeeID As Integer = If(IsDBNull(reader("EmployeeID")), 0, CInt(reader("EmployeeID")))
                Dim fullName As String = reader("name").ToString()
                Dim email As String = If(IsDBNull(reader("Email")), "", reader("Email").ToString())
                Dim position As String = If(IsDBNull(reader("Position")), "Staff", reader("Position").ToString())

                reader.Close()
                conn.Close()

                ' Check if employee ID is valid
                If employeeID = 0 Then
                    MessageBox.Show("Your account is not linked to an employee record. Please contact administrator.", "Account Error", MessageBoxButtons.OK, MessageBoxIcon.Warning)
                    Return
                End If

                ' Check if already clocked in today
                Dim todaysAttendance = attendanceRepository.GetTodaysAttendance(employeeID)
                Dim attendanceID As Integer
                Dim timeIn As DateTime

                If todaysAttendance IsNot Nothing Then
                    ' Already clocked in
                    attendanceID = todaysAttendance.AttendanceID
                    timeIn = todaysAttendance.TimeIn

                    MessageBox.Show(
                    $"Welcome back, {fullName}!" & vbCrLf & vbCrLf &
                    $"You already clocked in today at {timeIn:hh:mm tt}",
                    "Login Successful",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                )
                Else
                    ' Record time-in
                    attendanceID = attendanceRepository.RecordTimeIn(employeeID)
                    timeIn = DateTime.Now

                    MessageBox.Show(
                    $"Welcome, {fullName}!" & vbCrLf & vbCrLf &
                    $"Time In: {timeIn:hh:mm tt}",
                    "Login Successful",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                )
                End If

                ' Store session information
                CurrentSession.Initialize(employeeID, fullName, email, position, attendanceID, timeIn)

                ' Log Login Activity
                ActivityLogger.LogUserActivity(
                    action:="User Login",
                    actionCategory:="Login",
                    description:=$"{fullName} logged into POS",
                    sourceSystem:="POS"
                )

                ' Open Dashboard
                Dim dashboard As New Dashboard()
                dashboard.Show()
                Me.Hide()
            Else
                MessageBox.Show("Invalid username or password.", "Login Failed", MessageBoxButtons.OK, MessageBoxIcon.Error)
            End If

        Catch ex As Exception
            ' Generic error - Log it for debugging
            System.Diagnostics.Debug.WriteLine($"Login Error: {ex.ToString()}")
            MessageBox.Show($"An unexpected error occurred: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    ' ... rest of your existing code (LogIn_Load, etc.) ...

    Private Sub LogIn_FormClosed(sender As Object, e As FormClosedEventArgs) Handles MyBase.FormClosed
        Application.Exit()
    End Sub

    Private Sub LogIn_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        CenterLoginPanel()

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

        Dim usedBackup As Boolean = False
        Dim errorMessage As String = ""
        Dim connectionSuccess As Boolean = modDB.TestConnectionWithFallback(config, usedBackup, errorMessage)

        If Not connectionSuccess Then
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

        If usedBackup Then
            MessageBox.Show(
                "Primary server unavailable." & vbCrLf & vbCrLf &
                "Connected to backup server successfully.",
                "Using Backup Server",
                MessageBoxButtons.OK,
                MessageBoxIcon.Information
            )
            config.ServerIP = config.BackupServerIP
            modDB.ReloadConnectionString()
        End If

        ' TEMPORARY FIX: Reset passwords to '1234' (Encrypted with current logic)
        ' Hash for '1234' with EncryptionHelper logic: ObPPhIPBCnd6Y610sT8+cg==
        Try
            Dim newHash As String = "ObPPhIPBCnd6Y610sT8+cg=="
            modDB.ExecuteNonQuery("UPDATE user_accounts SET password = '" & newHash & "' WHERE username IN ('angelo', 'admin')")
        Catch ex As Exception
            ' Ignore error if update fails
        End Try
    End Sub

    Private Sub OpenServerConfigForm()
        Dim configForm As New ServerConfig()
        Me.Hide()

        If configForm.ShowDialog() = DialogResult.OK Then
            Application.Restart()
        Else
            Application.Exit()
        End If
    End Sub

    Private Sub LogIn_Resize(sender As Object, e As EventArgs) Handles MyBase.Resize
        CenterLoginPanel()
    End Sub

    Private Sub CenterLoginPanel()
        If Panel2 IsNot Nothing AndAlso Panel3 IsNot Nothing Then
            Panel3.Left = (Panel2.Width - Panel3.Width) \ 2
            Panel3.Top = (Panel2.Height - Panel3.Height) \ 2
        End If
    End Sub

    Private Sub Panel3_Paint(sender As Object, e As PaintEventArgs) Handles Panel3.Paint
    End Sub

    Private Sub chkShowPassword_CheckedChanged(sender As Object, e As EventArgs) Handles chkShowPassword.CheckedChanged
        txtPassword.UseSystemPasswordChar = Not chkShowPassword.Checked
    End Sub

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