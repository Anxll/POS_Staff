Public Class OrderItem
    Public Property OrderItemID As Integer
    Public Property OrderID As Integer
    Public Property ProductName As String
    Public Property Quantity As Integer
    Public Property UnitPrice As Decimal
    Public Property ItemStatus As String
    Public Property Category As String ' Helper property for UI
    Public Property ProductID As Integer
    Public Property PrepTime As Integer ' Helper property for calculation
End Class
