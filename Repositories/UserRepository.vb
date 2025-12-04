Imports MySql.Data.MySqlClient

Public Class UserRepository
    ''' <summary>
    ''' Authenticates an employee using Email and EmployeeID
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

            Dim table As DataTable = Database.ExecuteQuery(query, parameters)

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
