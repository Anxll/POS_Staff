Imports System.IO
Imports System.Security.Cryptography
Imports System.Text
Imports MySql.Data.MySqlClient
Imports System.Data

Module modDB
    ' ============================================
    ' CONFIGURATION & CONNECTION
    ' ============================================

    ' Dynamic connection string - loaded from config.json
    Private _connectionString As String = Nothing
    Private _currentConfig As DatabaseConfig = Nothing
    Private iniFilePath As String = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "db_config.ini")

    ' Legacy variables for backward compatibility
    Public db_server As String = "127.0.0.1"
    Public db_uid As String = "root"
    Public db_pwd As String = ""
    Public db_name As String = "tabeya_system"

    ' Legacy connection objects
    Public conn As MySqlConnection
    Public cmd As MySqlCommand
    Public cmdRead As MySqlDataReader

    ' ============================================
    ' USER STRUCTURE
    ' ============================================

    Public Structure LoggedUser
        Dim id As Integer
        Dim name As String
        Dim position As String
        Dim username As String
        Dim password As String
        Dim type As Integer
        Dim employee_id As Integer
    End Structure

    Public CurrentLoggedUser As LoggedUser

    ' ============================================
    ' CONNECTION STRING MANAGEMENT
    ' ============================================

    ''' <summary>
    ''' Gets the current connection string (tries config.json first, then falls back to INI)
    ''' </summary>
    Public ReadOnly Property ConnectionString As String
        Get
            If _connectionString Is Nothing Then
                LoadConnectionString()
            End If
            Return _connectionString
        End Get
    End Property

    ''' <summary>
    ''' Loads connection string from config.json or falls back to INI file
    ''' </summary>
    Private Sub LoadConnectionString()
        ' Try loading from config.json first (Staff system)
        _currentConfig = ConfigManager.LoadConfig()

        If _currentConfig IsNot Nothing AndAlso _currentConfig.IsValid() Then
            _connectionString = BuildConnectionString(_currentConfig)
        Else
            ' Fallback to INI file (Admin system)
            LoadDatabaseConfig()
            _connectionString = $"Server={db_server};Port=3306;Database={db_name};Uid={db_uid};Pwd={db_pwd};AllowUserVariables=True;CharSet=utf8mb4;"
        End If
    End Sub

    ''' <summary>
    ''' Builds a MySQL connection string from DatabaseConfig
    ''' </summary>
    Public Function BuildConnectionString(config As DatabaseConfig) As String
        Return BuildConnectionString(config.ServerIP, config)
    End Function

    ''' <summary>
    ''' Builds a MySQL connection string with a specific server IP
    ''' </summary>
    Public Function BuildConnectionString(serverIP As String, config As DatabaseConfig) As String
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
    ''' Reloads the connection string from config
    ''' </summary>
    Public Sub ReloadConnectionString()
        _connectionString = Nothing
        _currentConfig = Nothing
        LoadConnectionString()
    End Sub

    ' ============================================
    ' LEGACY ADMIN CONNECTION METHODS
    ' ============================================

    ''' <summary>
    ''' Opens connection (Admin legacy method)
    ''' </summary>
    Public Sub openConn()
        LoadDatabaseConfig()

        Try
            If conn IsNot Nothing AndAlso conn.State <> ConnectionState.Closed Then
                conn.Close()
            End If

            conn = New MySqlConnection(ConnectionString)
            conn.Open()
        Catch ex As Exception
            MsgBox("Connection Error: " & ex.Message, MsgBoxStyle.Critical)
        End Try
    End Sub

    ''' <summary>
    ''' Closes connection (Admin legacy method)
    ''' </summary>
    Public Sub closeConn()
        Try
            If conn IsNot Nothing AndAlso conn.State = ConnectionState.Open Then
                conn.Close()
            End If
        Catch ex As Exception
            MsgBox(ex.Message, MsgBoxStyle.Critical)
        End Try
    End Sub

    ''' <summary>
    ''' Read Query (Admin legacy method)
    ''' </summary>
    Public Sub readQuery(ByVal sql As String)
        Try
            openConn()
            cmd = New MySqlCommand(sql, conn)
            cmdRead = cmd.ExecuteReader()
        Catch ex As Exception
            MsgBox(ex.Message, MsgBoxStyle.Critical)
        End Try
    End Sub

    ''' <summary>
    ''' Load to DataGridView (Admin legacy method)
    ''' </summary>
    Function LoadToDGV(query As String, dgv As DataGridView, filter As String) As Integer
        Try
            readQuery(query)
            Dim dt As New DataTable
            dt.Load(cmdRead)
            dgv.DataSource = dt
            dgv.Refresh()
            closeConn()
            Return dgv.Rows.Count
        Catch ex As Exception
            MsgBox(ex.Message, MsgBoxStyle.Critical)
        End Try
        Return 0
    End Function

    ' ============================================
    ' MODERN STAFF METHODS
    ' ============================================

    ''' <summary>
    ''' Tests the database connection
    ''' </summary>
    Public Function TestConnection() As Boolean
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
    ''' Tests connection with primary server, automatically falls back to backup
    ''' </summary>
    Public Function TestConnectionWithFallback(config As DatabaseConfig, ByRef usedBackup As Boolean, ByRef errorMessage As String) As Boolean
        usedBackup = False

        If TestConnectionWithConfig(config, errorMessage) Then
            Return True
        End If

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
    ''' Tests database connection with a specific configuration
    ''' </summary>
    Public Function TestConnectionWithConfig(config As DatabaseConfig, ByRef errorMessage As String) As Boolean
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
            Select Case ex.Number
                Case 0
                    errorMessage = "Cannot connect to server. Please check the server IP address."
                Case 1042
                    errorMessage = "Unable to connect to server. Server may be offline or IP address is incorrect."
                Case 1045
                    errorMessage = "Access denied. Please check your username and password."
                Case 1049
                    errorMessage = $"Unknown database '{config.DatabaseName}'. Please verify the database name."
                Case 1130
                    errorMessage = $"Host access denied. The MariaDB server is rejecting connections from this computer."
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
    ''' Executes a SELECT query and returns results as DataTable
    ''' </summary>
    Public Function ExecuteQuery(query As String, Optional parameters As MySqlParameter() = Nothing) As DataTable
        Dim dataTable As New DataTable()

        Try
            Using connection As New MySqlConnection(ConnectionString)
                connection.Open()

                Using command As New MySqlCommand(query, connection)
                    If parameters IsNot Nothing Then
                        command.Parameters.AddRange(parameters)
                    End If

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
    ''' </summary>
    Public Function ExecuteNonQuery(query As String, Optional parameters As MySqlParameter() = Nothing, Optional silent As Boolean = False) As Integer
        Try
            Using connection As New MySqlConnection(ConnectionString)
                connection.Open()

                Using command As New MySqlCommand(query, connection)
                    If parameters IsNot Nothing Then
                        command.Parameters.AddRange(parameters)
                    End If

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
    ''' Executes a query that returns a single value
    ''' </summary>
    Public Function ExecuteScalar(query As String, Optional parameters As MySqlParameter() = Nothing) As Object
        Try
            Using connection As New MySqlConnection(ConnectionString)
                connection.Open()

                Using command As New MySqlCommand(query, connection)
                    If parameters IsNot Nothing Then
                        command.Parameters.AddRange(parameters)
                    End If

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

    ' ============================================
    ' INI CONFIGURATION (ADMIN SYSTEM)
    ' ============================================

    ''' <summary>
    ''' Loads database config from INI file
    ''' </summary>
    Public Sub LoadDatabaseConfig()
        Try
            If File.Exists(iniFilePath) Then
                Dim lines = File.ReadAllLines(iniFilePath)
                For Each line In lines
                    If line.StartsWith("Server=") Then
                        db_server = line.Substring(7).Trim()
                    ElseIf line.StartsWith("Database=") Then
                        db_name = line.Substring(9).Trim()
                    ElseIf line.StartsWith("Uid=") Then
                        db_uid = line.Substring(4).Trim()
                    ElseIf line.StartsWith("Pwd=") Then
                        db_pwd = line.Substring(4).Trim()
                    End If
                Next
            End If
        Catch ex As Exception
            ' Fallback to defaults
        End Try
    End Sub

    ''' <summary>
    ''' Saves database config to INI file
    ''' </summary>
    Public Sub SaveDatabaseConfig(server As String, db As String, uid As String, pwd As String)
        Try
            Dim sb As New StringBuilder()
            sb.AppendLine("[Database]")
            sb.AppendLine($"Server={server}")
            sb.AppendLine($"Database={db}")
            sb.AppendLine($"Uid={uid}")
            sb.AppendLine($"Pwd={pwd}")

            File.WriteAllText(iniFilePath, sb.ToString())

            db_server = server
            db_name = db
            db_uid = uid
            db_pwd = pwd

            ReloadConnectionString()
        Catch ex As Exception
            Throw New Exception("Failed to save configuration: " & ex.Message)
        End Try
    End Sub

    ' ============================================
    ' ENCRYPTION & SECURITY
    ' ============================================

    ''' <summary>
    ''' Encrypts text using AES encryption
    ''' </summary>
    Public Function Encrypt(clearText As String) As String
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

    ''' <summary>
    ''' Decrypts AES encrypted text
    ''' </summary>
    Public Function Decrypt(cipherText As String) As String
        Dim EncryptionKey As String = "MAKV2SPBNI99212"
        Dim cipherBytes As Byte() = Convert.FromBase64String(cipherText)
        Using encryptor As Aes = Aes.Create()
            Dim pdb As New Rfc2898DeriveBytes(EncryptionKey,
                New Byte() {&H49, &H76, &H61, &H6E, &H20, &H4D, &H65, &H64, &H76, &H65, &H64, &H65, &H76})
            encryptor.Key = pdb.GetBytes(32)
            encryptor.IV = pdb.GetBytes(16)
            Using ms As New MemoryStream()
                Using cs As New CryptoStream(ms, encryptor.CreateDecryptor(), CryptoStreamMode.Write)
                    cs.Write(cipherBytes, 0, cipherBytes.Length)
                End Using
                cipherText = Encoding.Unicode.GetString(ms.ToArray())
            End Using
        End Using
        Return cipherText
    End Function

    ' ============================================
    ' LOGGING
    ' ============================================

    ''' <summary>
    ''' Logs events (Admin legacy method)
    ''' </summary>
    Sub Logs(transaction As String, Optional events As String = "*_Click")
        Try
            readQuery($"INSERT INTO logs(dt, user_accounts_id, event, transactions)
                       VALUES (NOW(), {CurrentLoggedUser.id}, '{events}', '{transaction}')")
            closeConn()
        Catch ex As Exception
            MsgBox(ex.Message)
        End Try
    End Sub

    ' ============================================
    ' TABLE INITIALIZATION
    ' ============================================

    ''' <summary>
    ''' Checks and creates necessary database tables
    ''' </summary>
    Public Sub CheckAndCreateTables()
        Try
            Using connection As New MySqlConnection(ConnectionString)
                connection.Open()

                ' 1. Create user_accounts table
                Dim sqlUser As String = "
                    CREATE TABLE IF NOT EXISTS user_accounts (
                        id INT PRIMARY KEY AUTO_INCREMENT,
                        employee_id INT NULL,
                        name VARCHAR(100) NOT NULL,
                        username VARCHAR(50) UNIQUE NOT NULL,
                        password VARCHAR(255) NOT NULL,
                        type INT NOT NULL DEFAULT 1,
                        position VARCHAR(100) NULL,
                        status VARCHAR(50) DEFAULT 'Active',
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                    )"
                Using cmdUser As New MySqlCommand(sqlUser, connection)
                    cmdUser.ExecuteNonQuery()
                End Using

                ' Ensure employee_id column exists
                Try
                    Dim colCheckSql As String = "SELECT COUNT(*) FROM information_schema.COLUMNS " &
                                                "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user_accounts' AND COLUMN_NAME = 'employee_id'"
                    Using colCheckCmd As New MySqlCommand(colCheckSql, connection)
                        Dim colCount As Integer = Convert.ToInt32(colCheckCmd.ExecuteScalar())
                        If colCount = 0 Then
                            Using alterCmd As New MySqlCommand("ALTER TABLE user_accounts ADD COLUMN employee_id INT NULL", connection)
                                alterCmd.ExecuteNonQuery()
                            End Using
                        End If
                    End Using
                Catch
                End Try

                ' Ensure status column exists
                Try
                    Dim colCheckSqlStatus As String = "SELECT COUNT(*) FROM information_schema.COLUMNS " &
                                                "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user_accounts' AND COLUMN_NAME = 'status'"
                    Using colCheckCmd As New MySqlCommand(colCheckSqlStatus, connection)
                        Dim colCount As Integer = Convert.ToInt32(colCheckCmd.ExecuteScalar())
                        If colCount = 0 Then
                            Using alterCmd As New MySqlCommand("ALTER TABLE user_accounts ADD COLUMN status VARCHAR(50) DEFAULT 'Active'", connection)
                                alterCmd.ExecuteNonQuery()
                            End Using
                        End If
                    End Using
                Catch
                End Try

                ' 2. Create payroll table
                Dim sqlPayroll As String = "
                    CREATE TABLE IF NOT EXISTS payroll (
                        PayrollID INT PRIMARY KEY AUTO_INCREMENT,
                        EmployeeID INT NOT NULL,
                        PayPeriodStart DATE NOT NULL,
                        PayPeriodEnd DATE NOT NULL,
                        BasicSalary DECIMAL(10,2) NOT NULL,
                        Overtime DECIMAL(10,2) DEFAULT 0,
                        Deductions DECIMAL(10,2) DEFAULT 0,
                        Bonuses DECIMAL(10,2) DEFAULT 0,
                        NetPay DECIMAL(10,2) GENERATED ALWAYS AS (BasicSalary + Overtime + Bonuses - Deductions) STORED,
                        Status ENUM('Pending', 'Approved', 'Paid') DEFAULT 'Pending',
                        ProcessedBy INT NULL,
                        ProcessedDate DATETIME NULL,
                        Notes TEXT NULL,
                        CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (EmployeeID) REFERENCES employee(EmployeeID) ON DELETE CASCADE
                    )"
                Using cmdPayroll As New MySqlCommand(sqlPayroll, connection)
                    cmdPayroll.ExecuteNonQuery()
                End Using

                ' 3. Create activity_logs table
                Dim sqlActivityLogs As String = "
                    CREATE TABLE IF NOT EXISTS activity_logs (
                        LogID INT PRIMARY KEY AUTO_INCREMENT,
                        UserType ENUM('Admin','Staff','Customer') NOT NULL,
                        UserID INT NULL,
                        Username VARCHAR(100) NULL,
                        Action VARCHAR(255) NOT NULL,
                        ActionCategory ENUM('Login','Logout','Order','Reservation','Payment','Inventory','Product','User Management','Report','System') NOT NULL,
                        Description TEXT NULL,
                        SourceSystem ENUM('POS','Website','Admin Panel') NOT NULL,
                        ReferenceID VARCHAR(50) NULL,
                        ReferenceTable VARCHAR(100) NULL,
                        OldValue TEXT NULL,
                        NewValue TEXT NULL,
                        Status ENUM('Success','Failed','Warning') DEFAULT 'Success',
                        SessionID VARCHAR(100) NULL,
                        Timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        INDEX idx_user_type (UserType),
                        INDEX idx_action_category (ActionCategory),
                        INDEX idx_timestamp (Timestamp),
                        INDEX idx_user_id (UserID),
                        INDEX idx_source_system (SourceSystem)
                    )"
                Using cmdActivityLogs As New MySqlCommand(sqlActivityLogs, connection)
                    cmdActivityLogs.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            MsgBox("Error initializing database tables: " & ex.Message, MsgBoxStyle.Critical)
        End Try
    End Sub

    ' ============================================
    ' HELPER METHODS
    ' ============================================

    ''' <summary>
    ''' Gets the next OrderID
    ''' </summary>
    Public Function GetNextOrderID() As Integer
        Try
            Dim query As String = "SELECT COALESCE(MAX(OrderID), 0) + 1 FROM orders"
            Dim nextID As Object = ExecuteScalar(query)

            If nextID IsNot Nothing AndAlso IsNumeric(nextID) Then
                Return CInt(nextID)
            Else
                Return 1006
            End If
        Catch ex As Exception
            Return 1006
        End Try
    End Function

    ''' <summary>
    ''' Gets the next ReservationID
    ''' </summary>
    Public Function GetNextReservationID() As Integer
        Try
            Dim query As String = "SELECT COALESCE(MAX(ReservationID), 0) + 1 FROM reservations"
            Dim nextID As Object = ExecuteScalar(query)

            If nextID IsNot Nothing AndAlso IsNumeric(nextID) Then
                Return CInt(nextID)
            Else
                Return 1
            End If
        Catch ex As Exception
            Return 1
        End Try
    End Function

    ''' <summary>
    ''' Gets or creates a customer ID for walk-in customers
    ''' </summary>
    Public Function GetOrCreateCustomer(firstName As String, lastName As String, email As String, phone As String) As Integer
        Try
            Dim findQuery As String = "SELECT CustomerID FROM customers WHERE (Email = @email AND Email IS NOT NULL AND Email != '') OR ContactNumber = @phone LIMIT 1"
            Dim findParams As MySqlParameter() = {
                New MySqlParameter("@email", If(String.IsNullOrWhiteSpace(email), DBNull.Value, email)),
                New MySqlParameter("@phone", phone)
            }

            Dim existingID As Object = ExecuteScalar(findQuery, findParams)

            If existingID IsNot Nothing AndAlso IsNumeric(existingID) Then
                Return CInt(existingID)
            End If

            Dim insertQuery As String = "INSERT INTO customers (FirstName, LastName, Email, ContactNumber, CustomerType, AccountStatus) VALUES (@firstName, @lastName, @email, @phone, 'Walk-in', 'Active')"
            Dim insertParams As MySqlParameter() = {
                New MySqlParameter("@firstName", firstName),
                New MySqlParameter("@lastName", lastName),
                New MySqlParameter("@email", If(String.IsNullOrWhiteSpace(email), DBNull.Value, email)),
                New MySqlParameter("@phone", phone)
            }

            ExecuteNonQuery(insertQuery, insertParams)

            Dim newID As Object = ExecuteScalar("SELECT LAST_INSERT_ID()")
            If newID IsNot Nothing AndAlso IsNumeric(newID) Then
                Return CInt(newID)
            End If

            Return 0
        Catch ex As Exception
            MessageBox.Show($"Error getting/creating customer: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            Return 0
        End Try
    End Function

End Module