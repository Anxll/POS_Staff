Public Class InventoryBatch
    Public Property BatchID As Integer
    Public Property IngredientID As Integer
    Public Property BatchNumber As String
    Public Property StockQuantity As Decimal
    Public Property OriginalQuantity As Decimal
    Public Property UnitType As String
    Public Property ExpirationDate As Date?
    Public Property PurchaseDate As DateTime
    Public Property BatchStatus As String
End Class
