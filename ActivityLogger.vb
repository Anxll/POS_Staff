Imports MySql.Data.MySqlClient

Public Class ActivityLogger
    Public Shared Sub LogActivity(userType As String, userID As Integer?, username As String,
                                   action As String, actionCategory As String, description As String,
                                   sourceSystem As String, Optional referenceID As String = Nothing,
                                   Optional referenceTable As String = Nothing,
                                   Optional oldValue As String = Nothing, Optional newValue As String = Nothing,
                                   Optional status As String = "Success")
        Try
            Using conn As New MySqlConnection(modDB.ConnectionString)
                conn.Open()

                Dim query As String = "INSERT INTO activity_logs (UserType, UserID, Username, Action, ActionCategory, Description, SourceSystem, ReferenceID, ReferenceTable, OldValue, NewValue, Status, Timestamp) " &
                                      "VALUES (@UserType, @UserID, @Username, @Action, @ActionCategory, @Description, @SourceSystem, @ReferenceID, @ReferenceTable, @OldValue, @NewValue, @Status, NOW())"

                Using cmd As New MySqlCommand(query, conn)
                    cmd.Parameters.AddWithValue("@UserType", userType)
                    cmd.Parameters.AddWithValue("@UserID", If(userID.HasValue, CObj(userID.Value), DBNull.Value))
                    cmd.Parameters.AddWithValue("@Username", username)
                    cmd.Parameters.AddWithValue("@Action", action)
                    cmd.Parameters.AddWithValue("@ActionCategory", actionCategory)
                    cmd.Parameters.AddWithValue("@Description", description)
                    cmd.Parameters.AddWithValue("@SourceSystem", sourceSystem)
                    cmd.Parameters.AddWithValue("@ReferenceID", If(String.IsNullOrEmpty(referenceID), DBNull.Value, CObj(referenceID)))
                    cmd.Parameters.AddWithValue("@ReferenceTable", If(String.IsNullOrEmpty(referenceTable), DBNull.Value, CObj(referenceTable)))
                    cmd.Parameters.AddWithValue("@OldValue", If(String.IsNullOrEmpty(oldValue), DBNull.Value, CObj(oldValue)))
                    cmd.Parameters.AddWithValue("@NewValue", If(String.IsNullOrEmpty(newValue), DBNull.Value, CObj(newValue)))
                    cmd.Parameters.AddWithValue("@Status", status)

                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            ' Silent fail - don't interrupt operations
            Try
                System.IO.File.AppendAllText("activity_log_errors.txt",
                    $"{DateTime.Now}: {ex.Message}{Environment.NewLine}")
            Catch
                ' Ignore file write errors
            End Try
        End Try
    End Sub

    ' Simplified method using current logged user from modDB
    Public Shared Sub LogUserActivity(action As String, actionCategory As String, description As String,
                                      sourceSystem As String, Optional referenceID As String = Nothing,
                                      Optional referenceTable As String = Nothing,
                                      Optional oldValue As String = Nothing, Optional newValue As String = Nothing,
                                      Optional status As String = "Success")
        Try
            Dim userType As String = "Staff" ' Default
            Dim userID As Integer? = modDB.CurrentLoggedUser.id
            Dim username As String = modDB.CurrentLoggedUser.name

            ' ✅ FIX: Determine user type based on the type field from user_accounts table
            ' type = 0 means Admin
            ' type = 1 means Staff
            Select Case modDB.CurrentLoggedUser.type
                Case 0
                    userType = "Admin"   ' ✅ Admin user
                Case 1
                    userType = "Staff"   ' ✅ Staff user
                Case Else
                    userType = "Staff"   ' Default to Staff for unknown types
            End Select

            LogActivity(userType, userID, username, action, actionCategory, description,
                       sourceSystem, referenceID, referenceTable, oldValue, newValue, status)
        Catch ex As Exception
            ' Silent fail
            Try
                System.IO.File.AppendAllText("activity_log_errors.txt",
                    $"{DateTime.Now}: LogUserActivity Error - {ex.Message}{Environment.NewLine}")
            Catch
                ' Ignore
            End Try
        End Try
    End Sub
End Class