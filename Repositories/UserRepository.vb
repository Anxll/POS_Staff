Imports MySql.Data.MySqlClient
Imports System.IO
Imports System.Security.Cryptography
Imports System.Text

Public Class UserRepository
    ' Add the Encrypt function (same as in modDB)
    Private Function Encrypt(clearText As String) As String
        Dim EncryptionKey As String = "MAKV2SPBNI99212"
        Dim clearBytes As Byte() = Encoding.Unicode.GetBytes(clearText)
        Using encryptor As Aes = Aes.Create()
            Dim pdb As New Rfc2898DeriveBytes(EncryptionKey,
                New Byte() {&H49, &H76, &H61, &H6E, &H20, &H4D, &H65, &H64, &H76, &H65, &H64, &H65, &H76})
            encryptor.Key = pdb.GetBytes(32)
            encryptor.IV = pdb.GetBytes(16)
            Using ms As New MemoryStream()
                Using cs As New CryptoStream(ms, encryptor.CreateEncryptor(), CryptoStreamMode.Write)
                    cs.Write(clearBytes, 0, clearBytes.Length)
                End Using
                clearText = Convert.ToBase64String(ms.ToArray())
            End Using
        End Using
        Return clearText
    End Function
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

    Public Function AuthenticateUser(username As String, password As String) As Employee
        Try
            ' Encrypt the password using the SAME method as Admin login
            Dim encryptedPass As String = Encrypt(password)

            Dim query As String = "
            SELECT u.id, u.name, u.position, u.employee_id, u.status, u.password
            FROM user_accounts u
            WHERE u.username = @username 
            AND u.password = @password
            AND u.status IN ('Active', 'On Leave')"

            Dim parameters As MySqlParameter() = {
            New MySqlParameter("@username", username),
            New MySqlParameter("@password", encryptedPass)
        }

            Dim table As DataTable = modDB.ExecuteQuery(query, parameters)

            If table Is Nothing OrElse table.Rows.Count = 0 Then
                Return Nothing
            End If

            Dim row As DataRow = table.Rows(0)

            Dim empId As Integer = If(IsDBNull(row("employee_id")), 0, Convert.ToInt32(row("employee_id")))

            ' Create Employee object from user_accounts data
            Dim fullName As String = row("name").ToString()
            Dim parts As String() = fullName.Split(New Char() {" "c}, 2)

            Return New Employee With {
            .EmployeeID = empId,
            .FirstName = If(parts.Length > 0, parts(0), fullName),
            .LastName = If(parts.Length > 1, parts(1), ""),
            .Email = username,
            .Position = If(IsDBNull(row("position")), "Staff", row("position").ToString()),
            .EmploymentStatus = row("status").ToString()
        }
        Catch ex As Exception
            Throw New Exception($"Error authenticating user: {ex.Message}", ex)
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
