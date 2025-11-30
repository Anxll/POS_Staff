Public Class InventoryValidationResult
    Public Property IsValid As Boolean
    Public Property WarningMessage As String
    Public Property ItemsToRemove As New List(Of String) ' Product names that should be removed due to insufficient inventory
    Public Property RemovedItemDetails As New List(Of String) ' Detailed reasons for each removal
    
    Public Sub New()
        IsValid = True
        WarningMessage = ""
    End Sub
End Class
