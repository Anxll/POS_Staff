Public Class LogIn
    Private userRepository As New UserRepository()

    Private Sub btnLogin_Click(sender As Object, e As EventArgs) Handles btnLogin.Click
        Dim email As String = txtEmail.Text.Trim()
        Dim password As String = txtPassword.Text.Trim()

        If String.IsNullOrEmpty(email) OrElse String.IsNullOrEmpty(password) Then
            MessageBox.Show("Please enter both email and password.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        Try
            Dim user As User = userRepository.Authenticate(email, password)
            If user IsNot Nothing Then
                ' Login successful
                MessageBox.Show($"Welcome back, {user.FullName}!", "Login Successful", MessageBoxButtons.OK, MessageBoxIcon.Information)
                
                ' Open Dashboard
                Dim dashboard As New DashboardForm()
                dashboard.Show()
                Me.Hide()
            Else
                MessageBox.Show("Invalid email or password.", "Login Failed", MessageBoxButtons.OK, MessageBoxIcon.Error)
            End If
        Catch ex As Exception
            MessageBox.Show($"An error occurred during login: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub LogIn_FormClosed(sender As Object, e As FormClosedEventArgs) Handles MyBase.FormClosed
        Application.Exit()
    End Sub

    Private Sub Label5_Click(sender As Object, e As EventArgs) Handles Label5.Click
        MessageBox.Show("Please contact your administrator to create an account.", "Create Account", MessageBoxButtons.OK, MessageBoxIcon.Information)
    End Sub
End Class