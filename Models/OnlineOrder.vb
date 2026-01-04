''' <summary>
''' Represents an online order with customer information
''' </summary>
Public Class OnlineOrder
    Public Property OrderID As Integer
    Public Property CustomerID As Integer
    Public Property CustomerName As String
    Public Property Email As String
    Public Property ContactNumber As String
    Public Property OrderType As String
    Public Property OrderSource As String
    Public Property OrderDate As Date
    Public Property OrderTime As TimeSpan
    Public Property ItemsOrderedCount As Integer
    Public Property TotalAmount As Decimal
    Public Property OrderStatus As String ' Pending, Confirmed, Prepared, Completed, Cancelled
    Public Property Remarks As String
    Public Property DeliveryAddress As String
    Public Property SpecialRequests As String
    Public Property CreatedDate As DateTime
    Public Property UpdatedDate As DateTime
End Class
