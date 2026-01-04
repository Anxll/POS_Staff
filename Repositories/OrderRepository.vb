Imports MySql.Data.MySqlClient
Imports System.Collections.Generic

Public Class OrderRepository
    Public Function CreateOrder(order As Order, items As List(Of OrderItem)) As Integer
        ' Calculate Total Prep Time (Estimate) based on items
        Dim totalPrepTime As Integer = 0
        If items IsNot Nothing Then
            For Each item In items
                ' Assuming efficient parallel kitchen, but basic logic is usually sum or max.
                ' Restoring "erased logic": defaulting to sum of prep times for now.
                totalPrepTime += (item.PrepTime * item.Quantity)
            Next
        End If

        Dim query As String = "INSERT INTO orders (CustomerID, EmployeeID, OrderType, OrderSource, ReceiptNumber, NumberOfDiners, OrderDate, OrderTime, ItemsOrderedCount, TotalAmount, OrderStatus, Remarks, PreparationTimeEstimate) VALUES (@customerID, @employeeID, @orderType, @orderSource, @receiptNumber, @numberOfDiners, @orderDate, @orderTime, @itemsCount, @totalAmount, @orderStatus, @remarks, @prepTime)"
        
        Dim parameters As MySqlParameter() = {
            New MySqlParameter("@customerID", If(order.CustomerID.HasValue, order.CustomerID.Value, DBNull.Value)),
            New MySqlParameter("@employeeID", If(order.EmployeeID.HasValue, order.EmployeeID.Value, DBNull.Value)),
            New MySqlParameter("@orderType", order.OrderType),
            New MySqlParameter("@orderSource", order.OrderSource),
            New MySqlParameter("@receiptNumber", If(String.IsNullOrEmpty(order.ReceiptNumber), DBNull.Value, order.ReceiptNumber)),
            New MySqlParameter("@numberOfDiners", If(order.NumberOfDiners.HasValue, order.NumberOfDiners.Value, DBNull.Value)),
            New MySqlParameter("@orderDate", order.OrderDate),
            New MySqlParameter("@orderTime", order.OrderTime),
            New MySqlParameter("@itemsCount", order.ItemsOrderedCount),
            New MySqlParameter("@totalAmount", order.TotalAmount),
            New MySqlParameter("@orderStatus", order.OrderStatus),
            New MySqlParameter("@remarks", If(String.IsNullOrEmpty(order.Remarks), DBNull.Value, order.Remarks)),
            New MySqlParameter("@prepTime", totalPrepTime)
        }

        ' Use raw connection to handle potential errors gracefully
        Dim orderID As Integer = 0
        
        Try
            Using conn As New MySqlConnection(modDB.ConnectionString)
                conn.Open()
                
                ' 1. Insert Order
                Using cmd As New MySqlCommand(query, conn)
                    cmd.Parameters.AddRange(parameters)
                    cmd.ExecuteNonQuery()
                End Using
                
                ' 2. Get Last ID
                Using cmdID As New MySqlCommand("SELECT LAST_INSERT_ID()", conn)
                    Dim result = cmdID.ExecuteScalar()
                    If result IsNot Nothing AndAlso IsNumeric(result) Then
                        orderID = CInt(result)
                    End If
                End Using
                
                If orderID > 0 Then
                    ' 3. Insert Items
                    For Each item In items
                        Using cmdItem As New MySqlCommand("INSERT INTO order_items (OrderID, ProductName, Quantity, UnitPrice, SpecialInstructions) VALUES (@orderID, @productName, @quantity, @unitPrice, @specialInstructions)", conn)
                            cmdItem.Parameters.AddWithValue("@orderID", orderID)
                            cmdItem.Parameters.AddWithValue("@productName", item.ProductName)
                            cmdItem.Parameters.AddWithValue("@quantity", item.Quantity)
                            cmdItem.Parameters.AddWithValue("@unitPrice", item.UnitPrice)
                            cmdItem.Parameters.AddWithValue("@specialInstructions", If(String.IsNullOrEmpty(item.SpecialInstructions), DBNull.Value, item.SpecialInstructions))
                            cmdItem.ExecuteNonQuery()
                        End Using
                    Next
                End If
            End Using
            
            If orderID > 0 Then
                Return orderID
            End If
            
        Catch ex As Exception
            ' Debugging: Show the specific error to the user
            MessageBox.Show($"Order creation failed details: {ex.Message}", "Database Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            System.Diagnostics.Debug.WriteLine($"Order creation error: {ex.Message}")
        End Try
        
        Return 0
    End Function

    Private Sub AddOrderItem(orderID As Integer, item As OrderItem)
        Dim query As String = "INSERT INTO order_items (OrderID, ProductName, Quantity, UnitPrice, SpecialInstructions) VALUES (@orderID, @productName, @quantity, @unitPrice, @specialInstructions)"
        Dim parameters As MySqlParameter() = {
            New MySqlParameter("@orderID", orderID),
            New MySqlParameter("@productName", item.ProductName),
            New MySqlParameter("@quantity", item.Quantity),
            New MySqlParameter("@unitPrice", item.UnitPrice),
            New MySqlParameter("@specialInstructions", If(String.IsNullOrEmpty(item.SpecialInstructions), DBNull.Value, item.SpecialInstructions))
        }
        modDB.ExecuteNonQuery(query, parameters)
    End Sub

    Public Function GetActiveOrders() As List(Of Order)
        Dim orders As New List(Of Order)
        ' Buffered loading: Fetch ALL active orders directly
        Dim query As String = "SELECT OrderID, CustomerID, OrderType, OrderSource, OrderDate, OrderTime, TotalAmount, OrderStatus, PreparationTimeEstimate " &
                              "FROM orders WHERE OrderStatus IN ('Pending', 'Preparing', 'Serving', 'Served') " &
                              "ORDER BY OrderDate DESC, OrderTime DESC"
        
        Dim table As DataTable = modDB.ExecuteQuery(query)
        If table IsNot Nothing Then
            For Each row As DataRow In table.Rows
                Dim order As New Order()
                order.OrderID = Convert.ToInt32(row("OrderID"))
                order.CustomerID = If(IsDBNull(row("CustomerID")), Nothing, CInt(row("CustomerID")))
                order.OrderType = row("OrderType").ToString()
                order.OrderSource = row("OrderSource").ToString()
                order.TotalAmount = Convert.ToDecimal(row("TotalAmount"))
                order.OrderDate = Convert.ToDateTime(row("OrderDate"))
                order.OrderTime = CType(row("OrderTime"), TimeSpan)
                order.OrderStatus = row("OrderStatus").ToString()
                ' Safely read nullable integer
                If row.Table.Columns.Contains("PreparationTimeEstimate") AndAlso Not IsDBNull(row("PreparationTimeEstimate")) Then
                    order.PreparationTimeEstimate = Convert.ToInt32(row("PreparationTimeEstimate"))
                End If
                
                orders.Add(order)
            Next
        End If
        
        Return orders
    End Function

    ' Legacy signature support - returns ALL orders now (client-side handling)
    Public Function GetActiveOrdersPaged(limit As Integer, offset As Integer) As List(Of Order)
        Return GetActiveOrders() ' Ignore pagination args, return full buffer
    End Function

    Public Function GetOrderItems(orderID As Integer) As List(Of OrderItem)
        Dim items As New List(Of OrderItem)
        Dim query As String = "SELECT ProductName, Quantity, UnitPrice FROM order_items WHERE OrderID = @orderID"
        Dim parameters As MySqlParameter() = {
            New MySqlParameter("@orderID", orderID)
        }
        
        Dim table As DataTable = modDB.ExecuteQuery(query, parameters)
        If table IsNot Nothing Then
            For Each row As DataRow In table.Rows
                Dim item As New OrderItem()
                item.ProductName = row("ProductName").ToString()
                item.Quantity = Convert.ToInt32(row("Quantity"))
                item.UnitPrice = Convert.ToDecimal(row("UnitPrice"))
                items.Add(item)
            Next
        End If
        
        Return items
    End Function

    Public Function GetTodayOrdersCount() As Integer
        Dim whereClause As String = "DATE(OrderDate) = CURDATE() AND OrderStatus != 'Cancelled'"
        Dim query As String = $"SELECT COUNT(*) AS TotalCount FROM orders WHERE {whereClause}"
        
        Dim result As Object = modDB.ExecuteScalar(query)
        If result IsNot Nothing AndAlso IsNumeric(result) Then
            Return Convert.ToInt32(result)
        End If
        Return 0
    End Function

    Public Sub UpdateOrderStatus(orderID As Integer, newStatus As String, Optional silent As Boolean = False)
        Dim query As String = "UPDATE orders SET OrderStatus = @status WHERE OrderID = @orderID"
        Dim parameters As MySqlParameter() = {
            New MySqlParameter("@status", newStatus),
            New MySqlParameter("@orderID", orderID)
        }
        modDB.ExecuteNonQuery(query, parameters, silent)
    End Sub

    Public Sub UpdateOrderReceiptNumber(orderID As Integer, receiptNumber As String)
        Dim query As String = "UPDATE orders SET ReceiptNumber = @receiptNumber WHERE OrderID = @orderID"
        Dim parameters As MySqlParameter() = {
            New MySqlParameter("@receiptNumber", receiptNumber),
            New MySqlParameter("@orderID", orderID)
        }
        modDB.ExecuteNonQuery(query, parameters)
    End Sub

    ''' <summary>
    ''' Gets all online orders with customer information
    ''' </summary>
    Public Function GetOnlineOrders() As List(Of OnlineOrder)
        Dim onlineOrders As New List(Of OnlineOrder)
        
        Dim query As String = "SELECT o.OrderID, o.CustomerID, o.OrderType, o.OrderSource, o.OrderDate, o.OrderTime, " &
                             "o.ItemsOrderedCount, o.TotalAmount, o.OrderStatus, o.Remarks, o.DeliveryAddress, " &
                             "o.SpecialRequests, o.CreatedDate, o.UpdatedDate, " &
                             "c.FirstName, c.LastName, c.Email, c.ContactNumber " &
                             "FROM orders o " &
                             "LEFT JOIN customers c ON o.CustomerID = c.CustomerID " &
                             "WHERE o.OrderType = 'Online' " &
                             "ORDER BY o.OrderDate DESC, o.OrderTime DESC"
        
        Dim table As DataTable = modDB.ExecuteQuery(query)
        
        Return GetOnlineOrdersPaged(50, 0)
    End Function

    ''' <summary>
    ''' Gets online orders with pagination and filtering
    ''' </summary>
    ''' <summary>
    ''' Gets online orders with pagination using Stored Procedure
    ''' </summary>
    Public Function GetOnlineOrdersPaged(limit As Integer, offset As Integer, Optional statusFilter As String = "All Orders") As List(Of OnlineOrder)
        Dim onlineOrders As New List(Of OnlineOrder)
        
        ' Buffered Loading: Fetch ALL online orders directly
        Dim whereClause As String = "o.OrderType = 'Online'"
        If statusFilter <> "All Orders" Then
            whereClause &= " AND o.OrderStatus = '" & statusFilter.Replace("'", "''") & "'"
        End If
        
        Dim query As String = "SELECT o.OrderID, o.CustomerID, o.OrderType, o.OrderSource, o.WebsiteStatus, o.OrderDate, o.OrderTime, " &
                              "o.ItemsOrderedCount, o.TotalAmount, o.OrderStatus, o.Remarks, o.DeliveryAddress, " &
                              "o.SpecialRequests, o.CreatedDate, o.UpdatedDate, " &
                              "c.FirstName, c.LastName, c.Email, c.ContactNumber " &
                              "FROM orders o LEFT JOIN customers c ON o.CustomerID = c.CustomerID " &
                              "WHERE " & whereClause & " " &
                              "ORDER BY o.OrderDate DESC, o.OrderTime DESC"
        
        Dim table As DataTable = modDB.ExecuteQuery(query)
        
        If table IsNot Nothing Then
            For Each row As DataRow In table.Rows
                Dim onlineOrder As New OnlineOrder()
                onlineOrder.OrderID = Convert.ToInt32(row("OrderID"))
                onlineOrder.CustomerID = If(IsDBNull(row("CustomerID")), 0, Convert.ToInt32(row("CustomerID")))
                onlineOrder.CustomerName = If(IsDBNull(row("FirstName")), "Unknown", row("FirstName").ToString() & " " & row("LastName").ToString())
                onlineOrder.Email = If(IsDBNull(row("Email")), "", row("Email").ToString())
                onlineOrder.ContactNumber = If(IsDBNull(row("ContactNumber")), "", row("ContactNumber").ToString())
                onlineOrder.OrderType = row("OrderType").ToString()
                onlineOrder.OrderSource = row("OrderSource").ToString()
                onlineOrder.WebsiteStatus = If(IsDBNull(row("WebsiteStatus")), "", row("WebsiteStatus").ToString())
                onlineOrder.OrderDate = Convert.ToDateTime(row("OrderDate"))
                onlineOrder.OrderTime = CType(row("OrderTime"), TimeSpan)
                onlineOrder.ItemsOrderedCount = Convert.ToInt32(row("ItemsOrderedCount"))
                onlineOrder.TotalAmount = Convert.ToDecimal(row("TotalAmount"))
                onlineOrder.OrderStatus = row("OrderStatus").ToString()
                onlineOrder.Remarks = If(IsDBNull(row("Remarks")), "", row("Remarks").ToString())
                onlineOrder.DeliveryAddress = If(IsDBNull(row("DeliveryAddress")), "", row("DeliveryAddress").ToString())
                onlineOrder.SpecialRequests = If(IsDBNull(row("SpecialRequests")), "", row("SpecialRequests").ToString())
                onlineOrder.CreatedDate = Convert.ToDateTime(row("CreatedDate"))
                onlineOrder.UpdatedDate = Convert.ToDateTime(row("UpdatedDate"))
                
                onlineOrders.Add(onlineOrder)
            Next
        End If
        
        Return onlineOrders
    End Function

    ''' <summary>
    ''' Gets total count of online orders for pagination
    ''' </summary>
    ''' <summary>
    ''' Gets total count of online orders using Global Record Counter
    ''' </summary>
    Public Function GetTotalOnlineOrdersCount(Optional statusFilter As String = "All Orders") As Integer
        Dim whereClause As String = "OrderType = 'Online'"
        If statusFilter <> "All Orders" Then
            whereClause &= " AND OrderStatus = '" & statusFilter.Replace("'", "''") & "'"
        End If
        
        ' Direct COUNT query instead of stored procedure
        Dim query As String = $"SELECT COUNT(*) AS TotalCount FROM orders WHERE {whereClause}"
        
        Dim result As Object = modDB.ExecuteScalar(query)
        If result IsNot Nothing AndAlso IsNumeric(result) Then
            Return Convert.ToInt32(result)
        End If
        Return 0
    End Function

    Public Function GetTotalActiveOrdersCount() As Integer
        Dim whereClause As String = "OrderStatus IN ('Preparing', 'Serving', 'Served')"
        Dim query As String = $"SELECT COUNT(*) AS TotalCount FROM orders WHERE {whereClause}"
        
        Dim result As Object = modDB.ExecuteScalar(query)
        If result IsNot Nothing AndAlso IsNumeric(result) Then
            Return Convert.ToInt32(result)
        End If
        Return 0
    End Function

    ''' <summary>
    ''' Async version of GetActiveOrdersPaged
    ''' </summary>
    Public Async Function GetActiveOrdersPagedAsync(limit As Integer, offset As Integer) As Task(Of List(Of Order))
        Return Await Task.Run(Function() GetActiveOrdersPaged(limit, offset))
    End Function

    ''' <summary>
    ''' Async version of GetTotalActiveOrdersCount
    ''' </summary>
    Public Async Function GetTotalActiveOrdersCountAsync() As Task(Of Integer)
        Return Await Task.Run(Function() GetTotalActiveOrdersCount())
    End Function
End Class
