Imports MySql.Data.MySqlClient

Public Class UserRepository
    Public Function Authenticate(email As String, password As String) As User
        ' Note: In production, passwords should be hashed. 
        ' Assuming plain text for this legacy/local project as per current state.
        
        Dim query As String = "SELECT UserID, Username, FullName, Role FROM users WHERE Email = @email AND Password = @password"
        Dim parameters As MySqlParameter() = {
            New MySqlParameter("@email", email),
            New MySqlParameter("@password", password)
        }
        
        Dim table As DataTable = Database.ExecuteQuery(query, parameters)
        
        If table IsNot Nothing AndAlso table.Rows.Count > 0 Then
            Dim row As DataRow = table.Rows(0)
            Return New User With {
                .UserID = Convert.ToInt32(row("UserID")),
                .Username = row("Username").ToString(),
                .FullName = row("FullName").ToString(),
                .Role = row("Role").ToString()
            }
        End If
        
        Return Nothing
    End Function
End Class
