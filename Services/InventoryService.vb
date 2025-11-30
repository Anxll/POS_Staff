Imports MySql.Data.MySqlClient
Imports System.Collections.Generic

Public Class InventoryService
    
    ''' <summary>
    ''' Validates inventory for an order and returns items that should be removed due to insufficient stock.
    ''' This logic remains manual because the stored procedure doesn't support a "dry run" / validation-only mode.
    ''' </summary>
    Public Function ValidateInventoryForOrder(items As List(Of OrderItem)) As InventoryValidationResult
        Dim result As New InventoryValidationResult()
        
        For Each item In items
            ' Get product ingredients
            Dim ingredients = GetProductIngredients(item.ProductName)
            
            ' If no ingredients mapped, skip validation (e.g., bottled drinks)
            If ingredients.Count = 0 Then
                Continue For
            End If
            
            ' Check if sufficient inventory exists for all ingredients
            Dim insufficientIngredients As New List(Of String)
            
            For Each ingredient In ingredients
                Dim requiredQuantity = ingredient.QuantityUsed * item.Quantity
                Dim availableQuantity = GetAvailableQuantity(ingredient.IngredientID)
                
                If availableQuantity < requiredQuantity Then
                    insufficientIngredients.Add($"{ingredient.IngredientName} (need {requiredQuantity:F2} {ingredient.UnitType}, have {availableQuantity:F2})")
                End If
            Next
            
            ' If any ingredient is insufficient, mark this item for removal
            If insufficientIngredients.Count > 0 Then
                result.ItemsToRemove.Add(item.ProductName)
                Dim detail = $"{item.ProductName} × {item.Quantity}: Insufficient " & String.Join(", ", insufficientIngredients)
                result.RemovedItemDetails.Add(detail)
            End If
        Next
        
        ' Build warning message if items need to be removed
        If result.ItemsToRemove.Count > 0 Then
            result.IsValid = False
            result.WarningMessage = "The following items have insufficient inventory and will be removed from your order:" & vbCrLf & vbCrLf
            result.WarningMessage &= String.Join(vbCrLf, result.RemovedItemDetails)
        End If
        
        Return result
    End Function
    
    ''' <summary>
    ''' Deducts inventory for a completed POS order using the stored procedure.
    ''' </summary>
    Public Function DeductInventoryForOrder(orderID As Integer, items As List(Of OrderItem)) As Boolean
        Try
            ' Use raw connection to avoid Database class MessageBox on error
            ' This allows us to handle specific SP errors gracefully
            Using conn As New MySqlConnection(Database.ConnectionString)
                conn.Open()
                Using cmd As New MySqlCommand("CALL DeductIngredientsForPOSOrder(@orderID)", conn)
                    cmd.Parameters.AddWithValue("@orderID", orderID)
                    cmd.ExecuteNonQuery()
                End Using
            End Using
            Return True
        Catch ex As Exception
            ' Log error but don't show UI message (unless critical)
            ' Error 1172: Result consisted of more than one row - usually means data inconsistency but we don't want to crash the POS
            System.Diagnostics.Debug.WriteLine($"Inventory deduction error for Order #{orderID}: {ex.Message}")
            Return False
        End Try
    End Function

    ''' <summary>
    ''' Deducts inventory for a confirmed reservation using the stored procedure.
    ''' </summary>
    Public Function DeductInventoryForReservation(reservationID As Integer) As Boolean
        Try
            Dim query As String = "CALL DeductIngredientsForReservation(@reservationID)"
            Dim parameters As MySqlParameter() = {
                New MySqlParameter("@reservationID", reservationID)
            }
            
            Database.ExecuteNonQuery(query, parameters)
            Return True
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine($"Inventory deduction error for Reservation #{reservationID}: {ex.Message}")
            Return False
        End Try
    End Function

    ''' <summary>
    ''' Adds a new inventory batch using the stored procedure.
    ''' </summary>
    Public Function AddInventoryBatch(ingredientID As Integer, quantity As Decimal, unitType As String, costPerUnit As Decimal, expirationDate As Date, storageLocation As String, notes As String) As Boolean
        Try
            Dim query As String = "CALL AddInventoryBatch(@ingredientID, @quantity, @unitType, @costPerUnit, @expirationDate, @storageLocation, @notes, @batchID, @batchNumber)"
            
            Dim pBatchID As New MySqlParameter("@batchID", MySqlDbType.Int32)
            pBatchID.Direction = ParameterDirection.Output
            
            Dim pBatchNumber As New MySqlParameter("@batchNumber", MySqlDbType.VarChar, 50)
            pBatchNumber.Direction = ParameterDirection.Output

            Dim parameters As MySqlParameter() = {
                New MySqlParameter("@ingredientID", ingredientID),
                New MySqlParameter("@quantity", quantity),
                New MySqlParameter("@unitType", unitType),
                New MySqlParameter("@costPerUnit", costPerUnit),
                New MySqlParameter("@expirationDate", expirationDate),
                New MySqlParameter("@storageLocation", storageLocation),
                New MySqlParameter("@notes", notes),
                pBatchID,
                pBatchNumber
            }
            
            Database.ExecuteNonQuery(query, parameters)
            Return True
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine($"Error adding batch: {ex.Message}")
            Return False
        End Try
    End Function

    ''' <summary>
    ''' Discards a batch using the stored procedure.
    ''' </summary>
    Public Function DiscardBatch(batchID As Integer, reason As String, notes As String) As Boolean
        Try
            Dim query As String = "CALL DiscardBatch(@batchID, @reason, @notes)"
            Dim parameters As MySqlParameter() = {
                New MySqlParameter("@batchID", batchID),
                New MySqlParameter("@reason", reason),
                New MySqlParameter("@notes", notes)
            }
            
            Database.ExecuteNonQuery(query, parameters)
            Return True
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine($"Error discarding batch #{batchID}: {ex.Message}")
            Return False
        End Try
    End Function

    ''' <summary>
    ''' Logs a manual edit to a batch using the stored procedure.
    ''' </summary>
    Public Function LogBatchEdit(batchID As Integer, ingredientID As Integer, oldQty As Decimal, newQty As Decimal, unitType As String, batchNumber As String, ingredientName As String, reason As String, notes As String) As Boolean
        Try
            Dim query As String = "CALL LogBatchEdit(@batchID, @ingredientID, @oldQty, @newQty, @unitType, @batchNumber, @ingredientName, @reason, @notes)"
            Dim parameters As MySqlParameter() = {
                New MySqlParameter("@batchID", batchID),
                New MySqlParameter("@ingredientID", ingredientID),
                New MySqlParameter("@oldQty", oldQty),
                New MySqlParameter("@newQty", newQty),
                New MySqlParameter("@unitType", unitType),
                New MySqlParameter("@batchNumber", batchNumber),
                New MySqlParameter("@ingredientName", ingredientName),
                New MySqlParameter("@reason", reason),
                New MySqlParameter("@notes", notes)
            }
            
            Database.ExecuteNonQuery(query, parameters)
            Return True
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine($"Error logging batch edit #{batchID}: {ex.Message}")
            Return False
        End Try
    End Function
    
    ''' <summary>
    ''' Gets all ingredients required for a product.
    ''' </summary>
    Private Function GetProductIngredients(productName As String) As List(Of ProductIngredient)
        Dim ingredients As New List(Of ProductIngredient)
        
        Dim query As String = "SELECT pi.ProductIngredientID, pi.ProductID, pi.IngredientID, pi.QuantityUsed, pi.UnitType, i.IngredientName " &
                              "FROM product_ingredients pi " &
                              "JOIN products p ON pi.ProductID = p.ProductID " &
                              "JOIN ingredients i ON pi.IngredientID = i.IngredientID " &
                              "WHERE p.ProductName = @productName"
        
        Dim parameters As MySqlParameter() = {
            New MySqlParameter("@productName", productName)
        }
        
        Dim table As DataTable = Database.ExecuteQuery(query, parameters)
        If table IsNot Nothing Then
            For Each row As DataRow In table.Rows
                ingredients.Add(New ProductIngredient With {
                    .ProductIngredientID = Convert.ToInt32(row("ProductIngredientID")),
                    .ProductID = Convert.ToInt32(row("ProductID")),
                    .IngredientID = Convert.ToInt32(row("IngredientID")),
                    .QuantityUsed = Convert.ToDecimal(row("QuantityUsed")),
                    .UnitType = row("UnitType").ToString(),
                    .IngredientName = row("IngredientName").ToString()
                })
            Next
        End If
        
        Return ingredients
    End Function
    
    ''' <summary>
    ''' Gets total available quantity for an ingredient across all active batches.
    ''' </summary>
    Private Function GetAvailableQuantity(ingredientID As Integer) As Decimal
        Dim query As String = "SELECT COALESCE(SUM(StockQuantity), 0) AS TotalStock " &
                              "FROM inventory_batches " &
                              "WHERE IngredientID = @ingredientID AND BatchStatus = 'Active' AND StockQuantity > 0"
        
        Dim parameters As MySqlParameter() = {
            New MySqlParameter("@ingredientID", ingredientID)
        }
        
        Dim result As Object = Database.ExecuteScalar(query, parameters)
        If result IsNot Nothing AndAlso IsNumeric(result) Then
            Return Convert.ToDecimal(result)
        End If
        
        Return 0
    End Function

End Class
