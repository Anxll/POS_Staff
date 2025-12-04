Imports MySql.Data.MySqlClient

''' <summary>
''' Repository for employee attendance tracking operations
''' </summary>
Public Class AttendanceRepository

    ''' <summary>
    ''' Records employee time-in (clock in)
    ''' </summary>
    Public Function RecordTimeIn(employeeID As Integer) As Integer
        Try
            Dim query As String = "
                INSERT INTO employee_attendance (
                    EmployeeID, AttendanceDate, TimeIn, Status
                ) VALUES (
                    @EmployeeID, @AttendanceDate, @TimeIn, @Status
                )"

            Dim parameters As MySqlParameter() = {
                New MySqlParameter("@EmployeeID", employeeID),
                New MySqlParameter("@AttendanceDate", DateTime.Now.Date),
                New MySqlParameter("@TimeIn", DateTime.Now),
                New MySqlParameter("@Status", "Present")
            }

            Database.ExecuteNonQuery(query, parameters)

            ' Get the last inserted ID
            Dim lastIdQuery As String = "SELECT LAST_INSERT_ID()"
            Dim result As DataTable = Database.ExecuteQuery(lastIdQuery)

            If result IsNot Nothing AndAlso result.Rows.Count > 0 Then
                Return Convert.ToInt32(result.Rows(0)(0))
            End If

            Return 0
        Catch ex As Exception
            Throw New Exception($"Error recording time-in: {ex.Message}", ex)
        End Try
    End Function

    ''' <summary>
    ''' Records employee time-out (clock out)
    ''' </summary>
    Public Sub RecordTimeOut(employeeID As Integer, attendanceID As Integer)
        Try
            Dim timeOut As DateTime = DateTime.Now
            
            ' Calculate work hours
            Dim timeInQuery As String = "SELECT TimeIn FROM employee_attendance WHERE AttendanceID = @AttendanceID"
            Dim timeInParams As MySqlParameter() = {New MySqlParameter("@AttendanceID", attendanceID)}
            Dim timeInResult As DataTable = Database.ExecuteQuery(timeInQuery, timeInParams)
            
            Dim workHours As Decimal = 0
            If timeInResult IsNot Nothing AndAlso timeInResult.Rows.Count > 0 Then
                Dim timeIn As DateTime = Convert.ToDateTime(timeInResult.Rows(0)("TimeIn"))
                workHours = CDec((timeOut - timeIn).TotalHours)
            End If

            ' Update attendance record
            Dim query As String = "
                UPDATE employee_attendance 
                SET TimeOut = @TimeOut, WorkHours = @WorkHours
                WHERE AttendanceID = @AttendanceID AND EmployeeID = @EmployeeID"

            Dim parameters As MySqlParameter() = {
                New MySqlParameter("@TimeOut", timeOut),
                New MySqlParameter("@WorkHours", workHours),
                New MySqlParameter("@AttendanceID", attendanceID),
                New MySqlParameter("@EmployeeID", employeeID)
            }

            Database.ExecuteNonQuery(query, parameters)
        Catch ex As Exception
            Throw New Exception($"Error recording time-out: {ex.Message}", ex)
        End Try
    End Sub

    ''' <summary>
    ''' Checks if employee has already clocked in today
    ''' </summary>
    Public Function GetTodaysAttendance(employeeID As Integer) As AttendanceRecord
        Try
            Dim query As String = "
                SELECT AttendanceID, TimeIn, TimeOut 
                FROM employee_attendance 
                WHERE EmployeeID = @EmployeeID 
                AND DATE(AttendanceDate) = CURDATE()
                LIMIT 1"

            Dim parameters As MySqlParameter() = {New MySqlParameter("@EmployeeID", employeeID)}
            Dim result As DataTable = Database.ExecuteQuery(query, parameters)

            If result IsNot Nothing AndAlso result.Rows.Count > 0 Then
                Dim row = result.Rows(0)
                Return New AttendanceRecord With {
                    .AttendanceID = Convert.ToInt32(row("AttendanceID")),
                    .TimeIn = If(IsDBNull(row("TimeIn")), DateTime.MinValue, Convert.ToDateTime(row("TimeIn"))),
                    .TimeOut = If(IsDBNull(row("TimeOut")), DateTime.MinValue, Convert.ToDateTime(row("TimeOut")))
                }
            End If

            Return Nothing
        Catch ex As Exception
            Throw New Exception($"Error checking today's attendance: {ex.Message}", ex)
        End Try
    End Function

    ''' <summary>
    ''' Gets attendance records for an employee within a date range
    ''' </summary>
    Public Function GetAttendanceHistory(employeeID As Integer, startDate As DateTime, endDate As DateTime) As List(Of AttendanceRecord)
        Try
            Dim query As String = "
                SELECT AttendanceID, AttendanceDate, TimeIn, TimeOut, Status, WorkHours, Notes
                FROM employee_attendance 
                WHERE EmployeeID = @EmployeeID 
                AND AttendanceDate BETWEEN @StartDate AND @EndDate
                ORDER BY AttendanceDate DESC"

            Dim parameters As MySqlParameter() = {
                New MySqlParameter("@EmployeeID", employeeID),
                New MySqlParameter("@StartDate", startDate.Date),
                New MySqlParameter("@EndDate", endDate.Date)
            }

            Dim result As DataTable = Database.ExecuteQuery(query, parameters)
            Dim records As New List(Of AttendanceRecord)

            If result IsNot Nothing Then
                For Each row As DataRow In result.Rows
                    records.Add(New AttendanceRecord With {
                        .AttendanceID = Convert.ToInt32(row("AttendanceID")),
                        .AttendanceDate = Convert.ToDateTime(row("AttendanceDate")),
                        .TimeIn = If(IsDBNull(row("TimeIn")), DateTime.MinValue, Convert.ToDateTime(row("TimeIn"))),
                        .TimeOut = If(IsDBNull(row("TimeOut")), DateTime.MinValue, Convert.ToDateTime(row("TimeOut"))),
                        .Status = row("Status").ToString(),
                        .WorkHours = If(IsDBNull(row("WorkHours")), 0D, Convert.ToDecimal(row("WorkHours"))),
                        .Notes = If(IsDBNull(row("Notes")), "", row("Notes").ToString())
                    })
                Next
            End If

            Return records
        Catch ex As Exception
            Throw New Exception($"Error retrieving attendance history: {ex.Message}", ex)
        End Try
    End Function
End Class

''' <summary>
''' Data class for attendance record
''' </summary>
Public Class AttendanceRecord
    Public Property AttendanceID As Integer
    Public Property AttendanceDate As DateTime
    Public Property TimeIn As DateTime
    Public Property TimeOut As DateTime
    Public Property Status As String
    Public Property WorkHours As Decimal
    Public Property Notes As String
End Class
