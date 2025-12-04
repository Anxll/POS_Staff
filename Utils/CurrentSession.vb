''' <summary>
''' Global session storage for currently logged-in employee
''' </summary>
Public Class CurrentSession
    ''' <summary>
    ''' Currently logged-in employee ID
    ''' </summary>
    Public Shared Property EmployeeID As Integer = 0

    ''' <summary>
    ''' Full name of logged-in employee
    ''' </summary>
    Public Shared Property FullName As String = ""

    ''' <summary>
    ''' Email of logged-in employee
    ''' </summary>
    Public Shared Property Email As String = ""

    ''' <summary>
    ''' Position/Role of logged-in employee
    ''' </summary>
    Public Shared Property Position As String = ""

    ''' <summary>
    ''' Current attendance record ID for today's session
    ''' </summary>
    Public Shared Property AttendanceID As Integer = 0

    ''' <summary>
    ''' Time when employee clocked in
    ''' </summary>
    Public Shared Property TimeIn As DateTime = DateTime.MinValue

    ''' <summary>
    ''' Check if there is an active session
    ''' </summary>
    Public Shared ReadOnly Property IsLoggedIn As Boolean
        Get
            Return EmployeeID > 0
        End Get
    End Property

    ''' <summary>
    ''' Clear all session data (used on logout)
    ''' </summary>
    Public Shared Sub Clear()
        EmployeeID = 0
        FullName = ""
        Email = ""
        Position = ""
        AttendanceID = 0
        TimeIn = DateTime.MinValue
    End Sub

    ''' <summary>
    ''' Initialize session with employee data
    ''' </summary>
    Public Shared Sub Initialize(empId As Integer, empFullName As String, empEmail As String, empPosition As String, attId As Integer, timeIn As DateTime)
        EmployeeID = empId
        FullName = empFullName
        Email = empEmail
        Position = empPosition
        AttendanceID = attId
        TimeIn = timeIn
    End Sub
End Class
