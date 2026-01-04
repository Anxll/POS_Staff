Imports MySql.Data.MySqlClient
Imports System.Data

Public Class modDB
    ' Dynamic connection string - loaded from config.json
    Private Shared _connectionString As String = Nothing
    Private Shared _currentConfig As DatabaseConfig = Nothing

    ''' <summary>
    ''' Gets the current connection string from config.json
    ''' Falls back to default localhost settings if config doesn't exist
    ''' </summary>
    Public Shared ReadOnly Property ConnectionString As String
        Get
            If _connectionString Is Nothing Then
                LoadConnectionString()
            End If
            Return _connectionString
        End Get
    End Property

    ''' <summary>
    ''' Loads connection string from config.json
    ''' </summary>
    Private Shared Sub LoadConnectionString()
        _currentConfig = ConfigManager.LoadConfig()

        If _currentConfig IsNot Nothing AndAlso _currentConfig.IsValid() Then
            _connectionString = BuildConnectionString(_currentConfig)
        Else
            ' Fallback to default localhost settings for backward compatibility
            _connectionString = "Server=localhost;Port=3306;Database=tabeya_system;Uid=root;Pwd=;CharSet=utf8mb4;"
        End If
    End Sub

    ''' <summary>
    ''' Builds a MySQL connection string from DatabaseConfig
    ''' </summary>
    ''' <param name="config">Database configuration object</param>
    ''' <returns>MySQL connection string</returns>
    Public Shared Function BuildConnectionString(config As DatabaseConfig) As String
        Return BuildConnectionString(config.ServerIP, config)
    End Function

    ''' <summary>
    ''' Builds a MySQL connection string with a specific server IP (for fallback)
    ''' </summary>
    ''' <param name="serverIP">Server IP to use</param>
    ''' <param name="config">Database configuration object</param>
    ''' <returns>MySQL connection string</returns>
    Public Shared Function BuildConnectionString(serverIP As String, config As DatabaseConfig) As String
        Dim builder As New MySqlConnectionStringBuilder()
        builder.Server = serverIP
        builder.Port = Convert.ToUInt32(config.Port)
        builder.Database = config.DatabaseName
        builder.UserID = config.Username
        builder.Password = config.Password
        builder.CharacterSet = "utf8mb4"
        builder.ConnectionTimeout = 30
        builder.SslMode = MySqlSslMode.Preferred
        builder.AllowPublicKeyRetrieval = True
        builder.ConvertZeroDateTime = True
        
        Return builder.ToString()
    End Function

    ''' <summary>
    ''' Reloads the connection string from config.json
    ''' Call this after saving new configuration
    ''' </summary>
    Public Shared Sub ReloadConnectionString()
        _connectionString = Nothing
        _currentConfig = Nothing
        LoadConnectionString()
    End Sub

    ''' <summary>
    ''' Tests database connection with a specific configuration without saving it
    ''' </summary>
    ''' <param name="config">Configuration to test</param>
    ''' <param name="errorMessage">Output parameter containing error details if connection fails</param>
    ''' <returns>True if connection successful, False otherwise</returns>
    Public Shared Function TestConnectionWithConfig(config As DatabaseConfig, ByRef errorMessage As String) As Boolean
        If config Is Nothing Then
            errorMessage = "Configuration is null"
            Return False
        End If

        If Not config.IsValid() Then
            errorMessage = "Configuration is invalid. Please fill all required fields."
            Return False
        End If

        Dim testConnectionString As String = BuildConnectionString(config)

        Try
            Using connection As New MySqlConnection(testConnectionString)
                connection.Open()
                errorMessage = "Connection successful!"
                Return True
            End Using
        Catch ex As MySqlException
            ' Provide user-friendly error messages based on MySQL error codes
            Select Case ex.Number
                Case 0
                    errorMessage = "Cannot connect to server. Please check the server IP address."
                Case 1042
                    errorMessage = "Unable to connect to server. Server may be offline or IP address is incorrect."
                Case 1045
                    errorMessage = "Access denied. Please check your username and password." & vbCrLf & vbCrLf & 
                                  "Note: If connecting remotely, you must use the credentials for the remote user (e.g., 'root'@'%'), which may differ from the local user ('root'@'localhost')."
                Case 1049
                    errorMessage = $"Unknown database '{config.DatabaseName}'. Please verify the database name."
                Case 1130
                    errorMessage = $"Host access denied. The MariaDB server is rejecting connections from this computer." & vbCrLf & vbCrLf &
                                  "To fix this, run the following SQL command on the MariaDB server:" & vbCrLf &
                                  $"GRANT ALL PRIVILEGES ON {config.DatabaseName}.* TO '{config.Username}'@'%' IDENTIFIED BY 'your_password';" & vbCrLf &
                                  "FLUSH PRIVILEGES;" & vbCrLf & vbCrLf &
                                  "Replace 'your_password' with your actual password."
                Case Else
                    errorMessage = $"MySQL Error ({ex.Number}): {ex.Message}"
            End Select
            Return False
        Catch ex As Exception
            errorMessage = $"Connection error: {ex.Message}"
            Return False
        End Try
    End Function

    ''' <summary>
    ''' Tests connection with primary server, automatically falls back to backup if primary fails
    ''' </summary>
    ''' <param name="config">Configuration to test</param>
    ''' <param name="usedBackup">Output parameter indicating if backup server was used</param>
    ''' <param name="errorMessage">Output parameter containing error details</param>
    ''' <returns>True if connection successful (primary or backup), False if both failed</returns>
    Public Shared Function TestConnectionWithFallback(config As DatabaseConfig, ByRef usedBackup As Boolean, ByRef errorMessage As String) As Boolean
        usedBackup = False

        ' Try primary server first
        If TestConnectionWithConfig(config, errorMessage) Then
            Return True
        End If

        ' If primary fails and backup is configured, try backup
        If Not String.IsNullOrWhiteSpace(config.BackupServerIP) Then
            Dim primaryError As String = errorMessage
            Dim backupConfig As New DatabaseConfig() With {
                .ServerIP = config.BackupServerIP,
                .BackupServerIP = config.BackupServerIP,
                .DatabaseName = config.DatabaseName,
                .Username = config.Username,
                .Password = config.Password,
                .Port = config.Port
            }

            If TestConnectionWithConfig(backupConfig, errorMessage) Then
                usedBackup = True
                errorMessage = $"Primary server failed, connected to backup server successfully. Primary error: {primaryError}"
                Return True
            Else
                errorMessage = $"Both servers failed. Primary: {primaryError}. Backup: {errorMessage}"
                Return False
            End If
        End If

        Return False
    End Function


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
    Public Shared Function ExecuteNonQuery(query As String, Optional parameters As MySqlParameter() = Nothing, Optional silent As Boolean = False) As Integer
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
            If Not silent Then
                MessageBox.Show($"Database operation error: {ex.Message}", "Operation Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            End If
            System.Diagnostics.Debug.WriteLine($"Database operation error (Silent={silent}): {ex.Message}")
            Return -1
        Catch ex As Exception
            If Not silent Then
                MessageBox.Show($"Unexpected error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            End If
            System.Diagnostics.Debug.WriteLine($"Unexpected error (Silent={silent}): {ex.Message}")
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

