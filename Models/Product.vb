Public Class Product
    Public Property ProductID As Integer
    Public Property ProductName As String
    Public Property Category As String
    Public Property Description As String ' NEW: Product description
    Public Property Price As Decimal
    Public Property Availability As String ' Available/Not Available
    Public Property ServingSize As String ' NEW: REGULAR, SMALL, MEDIUM, LARGE
    Public Property ProductCode As String ' NEW: Unique code
    Public Property PopularityTag As String ' NEW: Best Seller/Regular
    Public Property MealTime As String ' NEW: Breakfast/Lunch/Dinner/All Day
    Public Property OrderCount As Integer ' NEW: Times ordered counter
    Public Property Image As String ' NEW: Image file path (changed from Byte())
    Public Property PrepTime As Integer ' NEW: Preparation time in minutes
End Class
