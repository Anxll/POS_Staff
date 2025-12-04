Public Class Employee
    Public Property EmployeeID As Integer
    Public Property FirstName As String
    Public Property LastName As String
    Public Property Gender As String ' Male, Female, Other
    Public Property DateOfBirth As Date?
    Public Property ContactNumber As String
    Public Property Email As String
    Public Property Address As String
    Public Property HireDate As Date
    Public Property Position As String
    Public Property MaritalStatus As String ' Single, Married, Separated, Divorced, Widowed
    Public Property EmploymentStatus As String ' Active, On Leave, Resigned
    Public Property EmploymentType As String ' Full-time, Part-time, Contract
    Public Property EmergencyContact As String
    Public Property WorkShift As String ' Morning, Evening, Split
    Public Property Salary As Decimal?

    ''' <summary>
    ''' Computed property for full name
    ''' </summary>
    Public ReadOnly Property FullName As String
        Get
            Return $"{FirstName} {LastName}".Trim()
        End Get
    End Property
End Class
