Public Class Order
    Public Property OrderID As Integer
    Public Property CustomerID As Integer? ' Nullable for walk-ins
    Public Property EmployeeID As Integer? ' NEW: Staff who processed the order
    Public Property OrderType As String
    Public Property OrderSource As String
    Public Property ReceiptNumber As String ' NEW: Receipt identifier
    Public Property NumberOfDiners As Integer? ' NEW: Number of people
    Public Property OrderDate As Date
    Public Property OrderTime As TimeSpan
    Public Property ItemsOrderedCount As Integer
    Public Property TotalAmount As Decimal
    Public Property OrderStatus As String
    Public Property Remarks As String ' NEW: General notes
    Public Property PreparationTimeEstimate As Integer? ' Nullable in DB
    Public Property CustomerName As String ' NEW: For display purposes
    
    ' Related data
    Public Property Items As List(Of OrderItem) ' Order line items
End Class
