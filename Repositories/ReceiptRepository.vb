Imports MySql.Data.MySqlClient

''' <summary>
''' Repository for managing receipt database operations
''' </summary>
Public Class ReceiptRepository

    ''' <summary>
    ''' Inserts receipt header into sales_receipts table
    ''' </summary>
    Public Function InsertReceiptHeader(orderID As Integer, orderNumber As String, totalAmount As Decimal,
                                       paymentMethod As String, amountGiven As Decimal, changeAmount As Decimal,
                                       orderDate As DateTime, orderTime As TimeSpan,
                                       Optional cashierName As String = "POS Cashier",
                                       Optional customerName As String = "Walk-in Customer",
                                       Optional customerType As String = "Walk-in",
                                       Optional orderSource As String = "POS") As Integer
        Try
            Dim query As String = "
                INSERT INTO sales_receipts (
                    OrderNumber, ReceiptDate, ReceiptTime, CashierName, CustomerName, CustomerType,
                    Subtotal, TaxAmount, TotalAmount, PaymentMethod, AmountGiven, ChangeAmount,
                    OrderSource, TransactionStatus, CreatedDate
                ) VALUES (
                    @OrderNumber, @ReceiptDate, @ReceiptTime, @CashierName, @CustomerName, @CustomerType,
                    @Subtotal, @TaxAmount, @TotalAmount, @PaymentMethod, @AmountGiven, @ChangeAmount,
                    @OrderSource, @TransactionStatus, @CreatedDate
                )"

            Dim parameters As MySqlParameter() = {
                New MySqlParameter("@OrderNumber", orderNumber),
                New MySqlParameter("@ReceiptDate", orderDate.Date),
                New MySqlParameter("@ReceiptTime", orderTime),
                New MySqlParameter("@CashierName", cashierName),
                New MySqlParameter("@CustomerName", customerName),
                New MySqlParameter("@CustomerType", customerType),
                New MySqlParameter("@Subtotal", totalAmount),
                New MySqlParameter("@TaxAmount", 0),
                New MySqlParameter("@TotalAmount", totalAmount),
                New MySqlParameter("@PaymentMethod", paymentMethod),
                New MySqlParameter("@AmountGiven", amountGiven),
                New MySqlParameter("@ChangeAmount", changeAmount),
                New MySqlParameter("@OrderSource", orderSource),
                New MySqlParameter("@TransactionStatus", "Completed"),
                New MySqlParameter("@CreatedDate", DateTime.Now)
            }

            modDB.ExecuteNonQuery(query, parameters)

            ' Get the last inserted ID
            Dim lastIdQuery As String = "SELECT LAST_INSERT_ID()"
            Dim result As DataTable = modDB.ExecuteQuery(lastIdQuery)

            If result IsNot Nothing AndAlso result.Rows.Count > 0 Then
                Return Convert.ToInt32(result.Rows(0)(0))
            End If

            Return 0
        Catch ex As Exception
            Throw New Exception($"Error inserting receipt header: {ex.Message}", ex)
        End Try
    End Function

    ''' <summary>
    ''' Inserts receipt line items with batch information
    ''' </summary>
    Public Sub InsertReceiptItems(receiptID As Integer, orderID As Integer, orderItems As List(Of OrderItem))
        Try
            For Each item In orderItems
                ' Get batch information for this product from recent inventory deductions
                Dim batchInfo = GetBatchInfoForProduct(item.ProductName, orderID)

                Dim query As String = "
                    INSERT INTO receipt_items (
                        ReceiptID, ItemName, ProductID, Quantity, UnitPrice, LineTotal,
                        BatchNumber, QtyDeducted, ItemCategory, ItemType, CreatedDate
                    ) VALUES (
                        @ReceiptID, @ItemName, @ProductID, @Quantity, @UnitPrice, @LineTotal,
                        @BatchNumber, @QtyDeducted, @ItemCategory, @ItemType, @CreatedDate
                    )"

                Dim parameters As MySqlParameter() = {
                    New MySqlParameter("@ReceiptID", receiptID),
                    New MySqlParameter("@ItemName", item.ProductName),
                    New MySqlParameter("@ProductID", If(item.ProductID > 0, item.ProductID, DBNull.Value)),
                    New MySqlParameter("@Quantity", item.Quantity),
                    New MySqlParameter("@UnitPrice", item.UnitPrice),
                    New MySqlParameter("@LineTotal", item.UnitPrice * item.Quantity),
                    New MySqlParameter("@BatchNumber", If(String.IsNullOrEmpty(batchInfo), DBNull.Value, batchInfo)),
                    New MySqlParameter("@QtyDeducted", item.Quantity),
                    New MySqlParameter("@ItemCategory", If(String.IsNullOrEmpty(item.Category), DBNull.Value, item.Category)),
                    New MySqlParameter("@ItemType", "Single"),
                    New MySqlParameter("@CreatedDate", DateTime.Now)
                }

                modDB.ExecuteNonQuery(query, parameters)
            Next
        Catch ex As Exception
            Throw New Exception($"Error inserting receipt items: {ex.Message}", ex)
        End Try
    End Sub

    ''' <summary>
    ''' Gets batch information for a product from inventory movement log
    ''' </summary>
    Private Function GetBatchInfoForProduct(productName As String, orderID As Integer) As String
        Try
            ' Query the inventory_movement_log to find batch numbers used for this order
            Dim query As String = "
                SELECT DISTINCT ReferenceNumber
                FROM inventory_movement_log
                WHERE OrderID = @OrderID
                AND ChangeType = 'DEDUCT'
                AND Notes LIKE CONCAT('%', @ProductName, '%')
                LIMIT 1"

            Dim parameters As MySqlParameter() = {
                New MySqlParameter("@OrderID", orderID),
                New MySqlParameter("@ProductName", productName)
            }

            Dim result As DataTable = modDB.ExecuteQuery(query, parameters)

            If result IsNot Nothing AndAlso result.Rows.Count > 0 Then
                Return result.Rows(0)("ReferenceNumber").ToString()
            End If

            Return "N/A"
        Catch ex As Exception
            Return "N/A"
        End Try
    End Function

    ''' <summary>
    ''' Records a payment entry into the payments table
    ''' </summary>
    Public Sub RecordPayment(orderID As Integer, reservationID As Integer?, amount As Decimal,
                             paymentMethod As String, paymentSource As String,
                             Optional transactionID As String = "",
                             Optional notes As String = "")
        Try
            ' Validate PaymentMethod enum against DB ('Cash','GCash','COD')
            ' Normalize common inputs
            Dim normalizedMethod As String = "Cash"
            If paymentMethod.ToUpper().Contains("GCASH") Then
                normalizedMethod = "GCash"
            ElseIf paymentMethod.ToUpper().Contains("COD") Then
                normalizedMethod = "COD"
            End If

            ' Validate PaymentSource enum ('POS','Website')
            Dim normalizedSource As String = If(paymentSource.ToUpper() = "WEBSITE", "Website", "POS")

            Dim query As String = "
                INSERT INTO payments (
                    OrderID, ReservationID, PaymentDate, PaymentMethod, PaymentStatus, 
                    AmountPaid, PaymentSource, TransactionID, Notes
                ) VALUES (
                    @OrderID, @ReservationID, @PaymentDate, @PaymentMethod, 'Completed', 
                    @AmountPaid, @PaymentSource, @TransactionID, @Notes
                )"

            Dim parameters As MySqlParameter() = {
                New MySqlParameter("@OrderID", orderID),
                New MySqlParameter("@ReservationID", If(reservationID.HasValue, reservationID.Value, DBNull.Value)),
                New MySqlParameter("@PaymentDate", DateTime.Now),
                New MySqlParameter("@PaymentMethod", normalizedMethod),
                New MySqlParameter("@AmountPaid", amount),
                New MySqlParameter("@PaymentSource", normalizedSource),
                New MySqlParameter("@TransactionID", If(String.IsNullOrEmpty(transactionID), DBNull.Value, transactionID)),
                New MySqlParameter("@Notes", If(String.IsNullOrEmpty(notes), DBNull.Value, notes))
            }

            modDB.ExecuteNonQuery(query, parameters)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine($"Error recording payment for Order #{orderID}: {ex.Message}")
            ' We don't throw here to avoid failing the receipt generation if payment log fails
        End Try
    End Sub

    ''' <summary>
    ''' Gets complete receipt details for PDF generation
    ''' </summary>
    Public Function GetReceiptDetails(receiptID As Integer) As ReceiptData
        Try
            ' Get receipt header
            Dim headerQuery As String = "
                SELECT 
                    ReceiptID, OrderNumber, ReceiptDate, ReceiptTime, CashierName,
                    CustomerName, Subtotal, TaxAmount, TotalAmount, PaymentMethod,
                    AmountGiven, ChangeAmount
                FROM sales_receipts
                WHERE ReceiptID = @ReceiptID"

            Dim headerParams As MySqlParameter() = {New MySqlParameter("@ReceiptID", receiptID)}
            Dim headerTable As DataTable = modDB.ExecuteQuery(headerQuery, headerParams)

            If headerTable Is Nothing OrElse headerTable.Rows.Count = 0 Then
                Return Nothing
            End If

            Dim row = headerTable.Rows(0)

            ' Get receipt items
            Dim itemsQuery As String = "
                SELECT 
                    ItemName, Quantity, UnitPrice, LineTotal, BatchNumber, QtyDeducted
                FROM receipt_items
                WHERE ReceiptID = @ReceiptID
                ORDER BY ReceiptItemID"

            Dim itemsTable As DataTable = modDB.ExecuteQuery(itemsQuery, headerParams)

            ' Build receipt data object
            Dim receipt As New ReceiptData With {
                .ReceiptID = receiptID,
                .OrderNumber = row("OrderNumber").ToString(),
                .ReceiptDate = Convert.ToDateTime(row("ReceiptDate")),
                .ReceiptTime = CType(row("ReceiptTime"), TimeSpan),
                .CashierName = row("CashierName").ToString(),
                .CustomerName = row("CustomerName").ToString(),
                .Subtotal = Convert.ToDecimal(row("Subtotal")),
                .TaxAmount = Convert.ToDecimal(row("TaxAmount")),
                .TotalAmount = Convert.ToDecimal(row("TotalAmount")),
                .PaymentMethod = row("PaymentMethod").ToString(),
                .AmountGiven = Convert.ToDecimal(row("AmountGiven")),
                .ChangeAmount = Convert.ToDecimal(row("ChangeAmount")),
                .Items = New List(Of ReceiptItemData)
            }

            ' Add items
            If itemsTable IsNot Nothing Then
                For Each itemRow As DataRow In itemsTable.Rows
                    receipt.Items.Add(New ReceiptItemData With {
                        .ItemName = itemRow("ItemName").ToString(),
                        .Quantity = Convert.ToInt32(itemRow("Quantity")),
                        .UnitPrice = Convert.ToDecimal(itemRow("UnitPrice")),
                        .LineTotal = Convert.ToDecimal(itemRow("LineTotal")),
                        .BatchNumber = If(IsDBNull(itemRow("BatchNumber")), "N/A", itemRow("BatchNumber").ToString()),
                        .QtyDeducted = Convert.ToInt32(itemRow("QtyDeducted"))
                    })
                Next
            End If

            Return receipt
        Catch ex As Exception
            Throw New Exception($"Error retrieving receipt details: {ex.Message}", ex)
        End Try
    End Function
End Class

''' <summary>
''' Data class for receipt header information
''' </summary>
Public Class ReceiptData
    Public Property ReceiptID As Integer
    Public Property OrderNumber As String
    Public Property ReceiptDate As DateTime
    Public Property ReceiptTime As TimeSpan
    Public Property CashierName As String
    Public Property CustomerName As String
    Public Property Subtotal As Decimal
    Public Property TaxAmount As Decimal
    Public Property TotalAmount As Decimal
    Public Property PaymentMethod As String
    Public Property AmountGiven As Decimal
    Public Property ChangeAmount As Decimal
    Public Property Items As List(Of ReceiptItemData)
End Class

''' <summary>
''' Data class for receipt line item information
''' </summary>
Public Class ReceiptItemData
    Public Property ItemName As String
    Public Property Quantity As Integer
    Public Property UnitPrice As Decimal
    Public Property LineTotal As Decimal
    Public Property BatchNumber As String
    Public Property QtyDeducted As Integer
End Class
