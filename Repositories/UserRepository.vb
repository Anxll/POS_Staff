Imports MySql.Data.MySqlClient

Public Class UserRepository
    ''' <summary>
    ''' Authenticates a user using username and password from user_accounts table
    ''' </summary>
    Public Function AuthenticateUser(username As String, password As String) As Employee
        Try
            ' Query user_accounts table with JOIN to employee table
            Dim query As String = "
                SELECT 
                    ua.id AS UserAccountID,
                    ua.name AS FullName,
                    ua.username,
                    ua.password,
                    ua.position,
                    ua.status,
                    ua.employee_id,
                    e.EmployeeID,
                    e.FirstName,
                    e.LastName,
                    e.Email,
                    e.Position AS EmployeePosition,
                    e.EmploymentStatus
                FROM user_accounts ua
                LEFT JOIN employee e ON ua.employee_id = e.EmployeeID
                WHERE ua.username = @Username"

            Dim parameters As MySqlParameter() = {
                New MySqlParameter("@Username", username)
            }

            Dim table As DataTable = modDB.ExecuteQuery(query, parameters)

            If table IsNot Nothing AndAlso table.Rows.Count > 0 Then
                Dim row As DataRow = table.Rows(0)
                Dim storedPassword As String = row("password").ToString()
                Dim accountStatus As String = row("status").ToString()
                
                ' DEBUGGING: Compute hash to see what's happening
                Dim computedHash As String = ""
                Try
                    computedHash = EncryptionHelper.Encrypt(password)
                Catch ex As Exception
                    computedHash = "Error computing hash: " & ex.Message
                End Try

                ' DEBUG: Show exact details why it is failing
                ' MessageBox.Show($"Debug Info:" & vbCrLf &
                '                 $"User Found: {username}" & vbCrLf &
                '                 $"Stored Hash: '{storedPassword}'" & vbCrLf &
                '                 $"Input Pwd: '{password}'" & vbCrLf &
                '                 $"Computed Hash: '{computedHash}'" & vbCrLf &
                '                 $"Match: {storedPassword = computedHash}" & vbCrLf &
                '                 $"Status: {accountStatus}", 
                '                 "Login Debug", MessageBoxButtons.OK, MessageBoxIcon.Information)

                ' Verify password (using the helper)
                Dim encryptedInput As String = EncryptionHelper.Encrypt(password)
                
                If encryptedInput <> storedPassword Then
                    ' For now, show why it failed
                     MessageBox.Show($"Password Mismatch!" & vbCrLf &
                                     $"Stored: {storedPassword}" & vbCrLf & 
                                     $"Computed: {encryptedInput}", "Debug", MessageBoxButtons.OK, MessageBoxIcon.Error)
                    Return Nothing ' Invalid password
                End If

                ' Check account status
                If accountStatus = "Resigned" Then
                    Throw New UnauthorizedAccessException("Account is inactive. Access denied for resigned employees.")
                End If

                If accountStatus <> "Active" AndAlso accountStatus <> "On Leave" Then
                    Throw New UnauthorizedAccessException($"Account status '{accountStatus}' is not authorized for login.")
                End If

                ' Build Employee object
                Dim employee As New Employee()
                
                ' Use employee data if linked, otherwise use user_accounts data
                If Not IsDBNull(row("EmployeeID")) Then
                    employee.EmployeeID = Convert.ToInt32(row("EmployeeID"))
                    employee.FirstName = row("FirstName").ToString()
                    employee.LastName = row("LastName").ToString()
                    employee.Email = If(IsDBNull(row("Email")), "", row("Email").ToString())
                    employee.Position = If(IsDBNull(row("EmployeePosition")), row("position").ToString(), row("EmployeePosition").ToString())
                    employee.EmploymentStatus = If(IsDBNull(row("EmploymentStatus")), accountStatus, row("EmploymentStatus").ToString())
                Else
                    ' No linked employee record - use user_accounts data
                    employee.EmployeeID = Convert.ToInt32(row("UserAccountID"))
                    employee.FirstName = row("FullName").ToString().Split(" "c)(0)
                    employee.LastName = If(row("FullName").ToString().Contains(" "), row("FullName").ToString().Substring(row("FullName").ToString().IndexOf(" ") + 1), "")
                    employee.Email = username ' Use username as email fallback
                    employee.Position = If(IsDBNull(row("position")), "Staff", row("position").ToString())
                    employee.EmploymentStatus = accountStatus
                End If

                Return employee
            Else
                 MessageBox.Show($"User '{username}' not found in database.", "Debug", MessageBoxButtons.OK, MessageBoxIcon.Error)
            End If

            Return Nothing ' User not found
        Catch ex As UnauthorizedAccessException
            ' Re-throw authorization exceptions
            Throw
        Catch ex As Exception
            Throw New Exception($"Error authenticating user: {ex.Message}", ex)
        End Try
    End Function

    ''' <summary>
    ''' Verifies password against stored encrypted password
    ''' </summary>
    Private Function VerifyPassword(inputPassword As String, storedPassword As String) As Boolean
        Try
            ' Encrypt input password using the shared helper and compare
            Dim encryptedInput As String = EncryptionHelper.Encrypt(inputPassword)
            Return encryptedInput = storedPassword
        Catch ex As Exception
            ' If encryption fails, return false
            Return False
        End Try
    End Function

    ''' <summary>
    ''' Legacy method - Authenticates an employee using Email and EmployeeID
    ''' Kept for backward compatibility
    ''' </summary>
    Public Function AuthenticateEmployee(email As String, employeeID As String) As Employee
        Try
            Dim query As String = "
                SELECT EmployeeID, FirstName, LastName, Email, Position, EmploymentStatus 
                FROM employee 
                WHERE Email = @Email 
                AND EmployeeID = @EmployeeID 
                AND EmploymentStatus = 'Active'"

            Dim parameters As MySqlParameter() = {
                New MySqlParameter("@Email", email),
                New MySqlParameter("@EmployeeID", employeeID)
            }

            Dim table As DataTable = modDB.ExecuteQuery(query, parameters)

            If table IsNot Nothing AndAlso table.Rows.Count > 0 Then
                Dim row As DataRow = table.Rows(0)
                Return New Employee With {
                    .EmployeeID = Convert.ToInt32(row("EmployeeID")),
                    .FirstName = row("FirstName").ToString(),
                    .LastName = row("LastName").ToString(),
                    .Email = row("Email").ToString(),
                    .Position = If(IsDBNull(row("Position")), "Staff", row("Position").ToString()),
                    .EmploymentStatus = row("EmploymentStatus").ToString()
                }
            End If

            Return Nothing
        Catch ex As Exception
            Throw New Exception($"Error authenticating employee: {ex.Message}", ex)
        End Try
    End Function

    ''' <summary>
    ''' Legacy method for backward compatibility - delegates to AuthenticateEmployee
    ''' </summary>
    Public Function Authenticate(email As String, password As String) As User
        ' For backward compatibility, treat password as EmployeeID
        Dim employee = AuthenticateEmployee(email, password)
        If employee IsNot Nothing Then
            Return New User With {
                .UserID = employee.EmployeeID,
                .Username = employee.Email,
                .FullName = $"{employee.FirstName} {employee.LastName}",
                .Role = employee.Position
            }
        End If
        Return Nothing
    End Function
End Class

