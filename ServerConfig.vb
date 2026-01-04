Imports System.Threading.Tasks

Public Class ServerConfig
    Private Sub ServerConfig_Load(sender As Object, e As EventArgs)
        ' Center the form panel
        CenterConfigPanel()

        ' Set password field to use password character
        TextBox5.PasswordChar = "*"c

        ' Load existing configuration if available
        LoadExistingConfig()
    End Sub

    ''' <summary>
    ''' Loads existing configuration from config.json and populates form fields
    ''' </summary>
    Private Sub LoadExistingConfig()
        Try
            Dim config As DatabaseConfig = ConfigManager.LoadConfig()

            If config IsNot Nothing Then
                TextBox2.Text = config.ServerIP
                TextBox1.Text = config.Port
                TextBox3.Text = config.DatabaseName
                TextBox4.Text = config.Username
                TextBox5.Text = config.Password
            Else
                ' Set default values for new configuration
                TextBox2.Text = "192.168.137.1"
                TextBox1.Text = "3306"
                TextBox3.Text = "tabeya_system"
                TextBox4.Text = "root"
                TextBox5.Text = ""
            End If
        Catch ex As Exception
            MessageBox.Show($"Error loading configuration: {ex.Message}", "Load Error", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        End Try
    End Sub

    ''' <summary>
    ''' Test Connection button click handler
    ''' </summary>
    ''' <summary>
    ''' Test Connection button click handler
    ''' </summary>
    Private Async Sub Button1_Click(sender As Object, e As EventArgs) Handles Button1.Click
        ' Validate input fields
        If Not ValidateFields() Then
            Return
        End If

        ' Disable UI to prevent multiple clicks and show working state
        SetUIState(False)
        Button1.Text = "Testing..."

        Try
            ' Create config from form inputs
            Dim config As DatabaseConfig = GetConfigFromForm()
            Dim errorMessage As String = ""
            Dim success As Boolean = False

            ' Run connection test in background
            success = Await Task.Run(Function() modDB.TestConnectionWithConfig(config, errorMessage))

            If success Then
                ' Show green success message
                MessageBox.Show(
                    "✓ Connection successful!" & vbCrLf & vbCrLf &
                    $"Server: {config.ServerIP}:{config.Port}" & vbCrLf &
                    $"Database: {config.DatabaseName}" & vbCrLf &
                    $"User: {config.Username}",
                    "Connection Test - Success",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                )
            Else
                ' Show red error message with details
                MessageBox.Show(
                    "✗ Connection failed!" & vbCrLf & vbCrLf &
                    "Error Details:" & vbCrLf &
                    errorMessage & vbCrLf & vbCrLf &
                    "Please verify your settings and try again.",
                    "Connection Test - Failed",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                )
            End If
        Finally
            ' Re-enable UI
            SetUIState(True)
            Button1.Text = "Test Connection"
        End Try
    End Sub

    ''' <summary>
    ''' Save and Continue button click handler
    ''' </summary>
    ''' <summary>
    ''' Save and Continue button click handler
    ''' </summary>
    Private Async Sub Button2_Click(sender As Object, e As EventArgs) Handles Button2.Click
        ' Validate input fields
        If Not ValidateFields() Then
            Return
        End If

        ' Disable UI
        SetUIState(False)
        Button2.Text = "Saving..."

        Try
            ' Create config from form inputs
            Dim config As DatabaseConfig = GetConfigFromForm()
            Dim errorMessage As String = ""
            Dim success As Boolean = False

            ' Test connection before saving (in background)
            success = Await Task.Run(Function() modDB.TestConnectionWithConfig(config, errorMessage))

            If Not success Then
                ' Block saving if connection fails
                MessageBox.Show(
                    "Cannot save configuration - connection test failed!" & vbCrLf & vbCrLf &
                    "Error Details:" & vbCrLf &
                    errorMessage & vbCrLf & vbCrLf &
                    "Please fix the connection issues before saving.",
                    "Save Failed",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                )
                Return
            End If

            ' Save configuration to config.json (password will be encrypted automatically)
            If ConfigManager.SaveConfig(config) Then
                ' Reload connection string in modDB
                modDB.ReloadConnectionString()

                MessageBox.Show(
                    "✓ Configuration saved successfully!" & vbCrLf & vbCrLf &
                    "You can now log in to the system.",
                    "Configuration Saved",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                )

                ' Return OK to signal successful configuration
                Me.DialogResult = DialogResult.OK
                Me.Close()
            Else
                MessageBox.Show(
                    "Failed to save configuration." & vbCrLf &
                    "Please check file permissions and try again.",
                    "Save Error",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                )
            End If
        Finally
            ' Re-enable UI
            SetUIState(True)
            Button2.Text = "Save and Continue"
        End Try
    End Sub

    Private Sub SetUIState(enabled As Boolean)
        TextBox1.Enabled = enabled
        TextBox2.Enabled = enabled
        TextBox3.Enabled = enabled
        TextBox4.Enabled = enabled
        TextBox5.Enabled = enabled
        Button1.Enabled = enabled
        Button2.Enabled = enabled
        Me.Cursor = If(enabled, Cursors.Default, Cursors.WaitCursor)
    End Sub

    ''' <summary>
    ''' Validates all required form fields
    ''' </summary>
    ''' <returns>True if all fields are valid, False otherwise</returns>
    Private Function ValidateFields() As Boolean
        ' Validate Server IP
        If String.IsNullOrWhiteSpace(TextBox2.Text) Then
            MessageBox.Show("Please enter the Server IP address.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            TextBox2.Focus()
            Return False
        End If

        ' Validate Database Name
        If String.IsNullOrWhiteSpace(TextBox3.Text) Then
            MessageBox.Show("Please enter the Database name.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            TextBox3.Focus()
            Return False
        End If

        ' Validate Username
        If String.IsNullOrWhiteSpace(TextBox4.Text) Then
            MessageBox.Show("Please enter the Username.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            TextBox4.Focus()
            Return False
        End If

        ' Password can be empty (for root user with no password)

        Return True
    End Function

    ''' <summary>
    ''' Creates a DatabaseConfig object from form field values
    ''' </summary>
    ''' <returns>DatabaseConfig object populated with form data</returns>
    Private Function GetConfigFromForm() As DatabaseConfig
        Return New DatabaseConfig() With {
            .ServerIP = TextBox2.Text.Trim(),
            .BackupServerIP = "",
            .DatabaseName = TextBox3.Text.Trim(),
            .Username = TextBox4.Text.Trim(),
            .Password = TextBox5.Text,
            .Port = TextBox1.Text.Trim()
        }
    End Function

    ''' <summary>
    ''' Centers the configuration panel on the form
    ''' </summary>
    Private Sub CenterConfigPanel()
        If Panel3 IsNot Nothing Then
            Panel3.Left = (Me.ClientSize.Width - Panel3.Width) \ 2
            Panel3.Top = (Me.ClientSize.Height - Panel3.Height) \ 2
        End If
    End Sub

    Private Sub ServerConfig_Resize(sender As Object, e As EventArgs)
        CenterConfigPanel()
    End Sub

    Private Sub Label1_Click(sender As Object, e As EventArgs)

    End Sub

    Private Sub Panel3_Paint(sender As Object, e As PaintEventArgs)

    End Sub

    Private Sub Panel1_Paint(sender As Object, e As PaintEventArgs)

    End Sub

    Private Sub TextBox2_TextChanged(sender As Object, e As EventArgs) Handles TextBox2.TextChanged

    End Sub

    Private Sub ServerConfig_Load_1(sender As Object, e As EventArgs) Handles MyBase.Load

    End Sub
End Class