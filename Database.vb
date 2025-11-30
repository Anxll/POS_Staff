Imports MySql.Data.MySqlClient
Imports System.Data

''' <summary>
''' Database connection and operation class for MySQL database
''' Provides reusable methods for executing queries, non-queries, and scalar operations
''' </summary>
Public Class Database
    ' Connection string constants - modify these if your database settings differ
    Private Const SERVER As String = "localhost"
    Private Const USERNAME As String = "root"
    Private Const PASSWORD As String = ""
    Private Const DATABASE As String = "tabeya_system"
    Private Const PORT As String = "3306"

    ' Global connection string - used for all database operations
    Public Shared ReadOnly ConnectionString As String = String.Format(
        "Server={0};Port={1};Database={2};Uid={3};Pwd={4};CharSet=utf8mb4;",
        SERVER, PORT, DATABASE, USERNAME, PASSWORD
    )

    ''' <summary>
    ''' Tests the database connection
    ''' </summary>
    ''' <returns>True if connection is successful, False otherwise</returns>
    Public Shared Function TestConnection() As Boolean
        Try
            Using connection As New MySqlConnection(ConnectionString)
                connection.Open()
                Return True
            End Using
        Catch ex As Exception
            MessageBox.Show($"Database connection failed: {ex.Message}", "Connection Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            Return False
        End Try
    End Function

    ''' <summary>
    ''' Executes a SELECT query and returns the results as a DataTable
    ''' Use this for queries that return multiple rows (SELECT statements)
    ''' </summary>
    ''' <param name="query">SQL SELECT query string</param>
    ''' <param name="parameters">Optional parameter array for parameterized queries</param>
    ''' <returns>DataTable containing query results, or Nothing if error occurs</returns>
    Public Shared Function ExecuteQuery(query As String, Optional parameters As MySqlParameter() = Nothing) As DataTable
        Dim dataTable As New DataTable()

        Try
            Using connection As New MySqlConnection(ConnectionString)
                connection.Open()

                Using command As New MySqlCommand(query, connection)
                    ' Add parameters if provided (prevents SQL injection)
                    If parameters IsNot Nothing Then
                        command.Parameters.AddRange(parameters)
                    End If

                    ' Execute query and fill DataTable
                    Using adapter As New MySqlDataAdapter(command)
                        adapter.Fill(dataTable)
                    End Using
                End Using
            End Using

            Return dataTable
        Catch ex As MySqlException
            MessageBox.Show($"Database query error: {ex.Message}", "Query Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            Return Nothing
        Catch ex As Exception
            MessageBox.Show($"Unexpected error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            Return Nothing
        End Try
    End Function

    ''' <summary>
    ''' Executes INSERT, UPDATE, or DELETE queries
    ''' Use this for queries that modify data but don't return results
    ''' </summary>
    ''' <param name="query">SQL INSERT/UPDATE/DELETE query string</param>
    ''' <param name="parameters">Optional parameter array for parameterized queries</param>
    ''' <returns>Number of rows affected, or -1 if error occurs</returns>
    Public Shared Function ExecuteNonQuery(query As String, Optional parameters As MySqlParameter() = Nothing) As Integer
        Try
            Using connection As New MySqlConnection(ConnectionString)
                connection.Open()

                Using command As New MySqlCommand(query, connection)
                    ' Add parameters if provided (prevents SQL injection)
                    If parameters IsNot Nothing Then
                        command.Parameters.AddRange(parameters)
                    End If

                    ' Execute command and return rows affected
                    Return command.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As MySqlException
            MessageBox.Show($"Database operation error: {ex.Message}", "Operation Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            Return -1
        Catch ex As Exception
            MessageBox.Show($"Unexpected error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            Return -1
        End Try
    End Function

    ''' <summary>
    ''' Executes a query that returns a single value (first column of first row)
    ''' Use this for COUNT, MAX, MIN, or any query that returns one value
    ''' </summary>
    ''' <param name="query">SQL query string that returns a single value</param>
    ''' <param name="parameters">Optional parameter array for parameterized queries</param>
    ''' <returns>The scalar value, or Nothing if error occurs or no result</returns>
    Public Shared Function ExecuteScalar(query As String, Optional parameters As MySqlParameter() = Nothing) As Object
        Try
            Using connection As New MySqlConnection(ConnectionString)
                connection.Open()

                Using command As New MySqlCommand(query, connection)
                    ' Add parameters if provided (prevents SQL injection)
                    If parameters IsNot Nothing Then
                        command.Parameters.AddRange(parameters)
                    End If

                    ' Execute scalar query and return result
                    Return command.ExecuteScalar()
                End Using
            End Using
        Catch ex As MySqlException
            MessageBox.Show($"Database scalar error: {ex.Message}", "Scalar Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            Return Nothing
        Catch ex As Exception
            MessageBox.Show($"Unexpected error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            Return Nothing
        End Try
    End Function

    ''' <summary>
    ''' Gets the next OrderID (INT AUTO_INCREMENT) from database
    ''' The database will auto-generate the ID, but this helps get the next value
    ''' </summary>
    ''' <returns>Next OrderID integer</returns>
    Public Shared Function GetNextOrderID() As Integer
        Try
            ' Get the maximum order ID number from the database
            Dim query As String = "SELECT COALESCE(MAX(OrderID), 0) + 1 FROM orders"
            Dim nextID As Object = ExecuteScalar(query)

            If nextID IsNot Nothing AndAlso IsNumeric(nextID) Then
                Return CInt(nextID)
            Else
                Return 1006 ' Default starting point based on your schema
            End If
        Catch ex As Exception
            ' Fallback: return default
            Return 1006
        End Try
    End Function

    ''' <summary>
    ''' Gets the next ReservationID (INT AUTO_INCREMENT) from database
    ''' The database will auto-generate the ID, but this helps get the next value
    ''' </summary>
    ''' <returns>Next ReservationID integer</returns>
    Public Shared Function GetNextReservationID() As Integer
        Try
            ' Get the maximum reservation ID number from the database
            Dim query As String = "SELECT COALESCE(MAX(ReservationID), 0) + 1 FROM reservations"
            Dim nextID As Object = ExecuteScalar(query)

            If nextID IsNot Nothing AndAlso IsNumeric(nextID) Then
                Return CInt(nextID)
            Else
                Return 1 ' Default starting point
            End If
        Catch ex As Exception
            ' Fallback: return default
            Return 1
        End Try
    End Function

    ''' <summary>
    ''' Gets or creates a customer ID for walk-in customers
    ''' If customer exists (by email or phone), returns existing CustomerID
    ''' Otherwise, creates a new walk-in customer record
    ''' </summary>
    ''' <param name="firstName">Customer first name</param>
    ''' <param name="lastName">Customer last name</param>
    ''' <param name="email">Customer email (optional)</param>
    ''' <param name="phone">Customer phone number</param>
    ''' <returns>CustomerID integer</returns>
    Public Shared Function GetOrCreateCustomer(firstName As String, lastName As String, email As String, phone As String) As Integer
        Try
            ' First, try to find existing customer by email or phone
            Dim findQuery As String = "SELECT CustomerID FROM customers WHERE (Email = @email AND Email IS NOT NULL AND Email != '') OR ContactNumber = @phone LIMIT 1"
            Dim findParams As MySqlParameter() = {
                New MySqlParameter("@email", If(String.IsNullOrWhiteSpace(email), DBNull.Value, email)),
                New MySqlParameter("@phone", phone)
            }

            Dim existingID As Object = ExecuteScalar(findQuery, findParams)

            If existingID IsNot Nothing AndAlso IsNumeric(existingID) Then
                Return CInt(existingID)
            End If

            ' Customer doesn't exist, create new walk-in customer
            Dim insertQuery As String = "INSERT INTO customers (FirstName, LastName, Email, ContactNumber, CustomerType, AccountStatus) VALUES (@firstName, @lastName, @email, @phone, 'Walk-in', 'Active')"
            Dim insertParams As MySqlParameter() = {
                New MySqlParameter("@firstName", firstName),
                New MySqlParameter("@lastName", lastName),
                New MySqlParameter("@email", If(String.IsNullOrWhiteSpace(email), DBNull.Value, email)),
                New MySqlParameter("@phone", phone)
            }

            ExecuteNonQuery(insertQuery, insertParams)

            ' Get the newly created CustomerID
            Dim newID As Object = ExecuteScalar("SELECT LAST_INSERT_ID()")
            If newID IsNot Nothing AndAlso IsNumeric(newID) Then
                Return CInt(newID)
            End If

            Return 0 ' Error case
        Catch ex As Exception
            MessageBox.Show($"Error getting/creating customer: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            Return 0
        End Try
    End Function
End Class

