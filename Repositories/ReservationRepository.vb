
Imports MySql.Data.MySqlClient
Imports System.Collections.Generic
Imports System.Threading.Tasks

Public Class ReservationRepository
    ''' <summary>
    ''' Gets all reservations with pagination (Database-level LIMIT/OFFSET)
    ''' </summary>
    Public Function GetAllReservations(Optional limit As Integer = 100, Optional offset As Integer = 0, Optional statusFilter As String = "All Orders", Optional searchQuery As String = "") As List(Of Reservation)
        ' Use database-level pagination to avoid loading all 10,001+ records
        Dim whereLines As New List(Of String)
        Dim paramList As New List(Of MySqlParameter)

        ' Status Filtering
        If statusFilter = "Confirmed" Then
            whereLines.Add("r.ReservationStatus IN ('Confirmed', 'Accepted')")
        ElseIf statusFilter <> "All Orders" Then
            whereLines.Add("r.ReservationStatus = @status")
            paramList.Add(New MySqlParameter("@status", statusFilter))
        End If

        ' Search Query
        If Not String.IsNullOrEmpty(searchQuery) Then
            whereLines.Add("(r.FullName LIKE @search OR CONCAT(c.FirstName, ' ', c.LastName) LIKE @search)")
            paramList.Add(New MySqlParameter("@search", "%" & searchQuery & "%"))
        End If

        Dim whereClause As String = ""
        If whereLines.Count > 0 Then
            whereClause = " WHERE " & String.Join(" AND ", whereLines) & " "
        End If

        Dim parameters As MySqlParameter() = If(paramList.Count > 0, paramList.ToArray(), Nothing)

        Dim query As String = "SELECT r.ReservationID, r.CustomerID, r.FullName, CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName, c.Email, r.ContactNumber, r.AssignedStaffID, r.NumberOfGuests, r.EventDate, r.EventTime, r.EventType, r.ReservationStatus, r.ProductSelection, r.SpecialRequests, r.DeliveryAddress, r.DeliveryOption, COALESCE((SELECT SUM(TotalPrice) FROM reservation_items WHERE ReservationID = r.ReservationID), 0) AS TotalPrice " &
                              "FROM reservations r " &
                              "LEFT JOIN customers c ON r.CustomerID = c.CustomerID " &
                              whereClause &
                              " ORDER BY r.ReservationID DESC " &
                              $" LIMIT {limit} OFFSET {offset}"

        Return GetReservations(query, parameters)
    End Function

    Public Function GetReservationById(reservationID As Integer) As Reservation
        Dim query As String = "SELECT r.ReservationID, r.CustomerID, r.FullName, CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName, c.Email, r.ContactNumber, r.AssignedStaffID, r.NumberOfGuests, r.EventDate, r.EventTime, r.EventType, r.ReservationStatus, r.ProductSelection, r.SpecialRequests, r.DeliveryAddress, r.DeliveryOption, COALESCE((SELECT SUM(TotalPrice) FROM reservation_items WHERE ReservationID = r.ReservationID), 0) AS TotalPrice " &
                              "FROM reservations r " &
                              "LEFT JOIN customers c ON r.CustomerID = c.CustomerID " &
                              "WHERE r.ReservationID = @resID"
        
        Dim parameters As MySqlParameter() = {New MySqlParameter("@resID", reservationID)}
        Dim resList = GetReservations(query, parameters)
        Return If(resList.Count > 0, resList(0), Nothing)
    End Function

    ''' <summary>
    ''' Gets today's reservations (Buffered - Load All)
    ''' </summary>
    Public Function GetTodayReservations() As List(Of Reservation)

        Dim query As String = "SELECT r.ReservationID, r.CustomerID, CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName, " &
                               "c.Email, r.ContactNumber, r.NumberOfGuests, r.EventDate, r.EventTime, r.EventType, " &
                               "r.ReservationStatus " &
                               "FROM reservations r LEFT JOIN customers c ON r.CustomerID = c.CustomerID " &
                               "WHERE DATE(r.EventDate) = CURDATE() AND r.ReservationStatus IN ('Accepted', 'Confirmed') " &
                               "ORDER BY r.EventDate ASC, r.EventTime ASC"


        Return GetReservations(query)
    End Function

    ' Paginated calls - Now use proper database-level pagination
    Public Function GetTodayReservationsPaged(limit As Integer, offset As Integer) As List(Of Reservation)
        Return GetTodayReservations()
    End Function

    Public Function GetAllReservationsPaged(limit As Integer, offset As Integer, Optional statusFilter As String = "All Orders", Optional searchQuery As String = "") As List(Of Reservation)
        ' Use database-level pagination instead of loading all records
        Return GetAllReservations(limit, offset, statusFilter, searchQuery)
    End Function

    Public Async Function GetAllReservationsAsync(Optional statusFilter As String = "All Orders", Optional searchQuery As String = "") As Task(Of List(Of Reservation))
        Return Await Task.Run(Function() GetAllReservations(100, 0, statusFilter, searchQuery))
    End Function

    Public Async Function GetTodayReservationsPagedAsync(limit As Integer, offset As Integer) As Task(Of List(Of Reservation))
        Return Await Task.Run(Function() GetTodayReservations())
    End Function

    Public Function GetTotalTodayReservationsCount() As Integer
        Dim query As String = "SELECT COUNT(*) FROM reservations WHERE DATE(EventDate) = CURDATE() AND ReservationStatus IN ('Confirmed', 'Completed')"
        Dim result As Object = modDB.ExecuteScalar(query)
        If result IsNot Nothing AndAlso IsNumeric(result) Then
            Return CInt(result)
        End If
        Return 0
    End Function

    Public Async Function GetTotalTodayReservationsCountAsync() As Task(Of Integer)
        Return Await Task.Run(Function() GetTotalTodayReservationsCount())
    End Function

    Private Function GetReservations(query As String, Optional parameters As MySqlParameter() = Nothing) As List(Of Reservation)
        Dim reservations As New List(Of Reservation)
        Dim table As DataTable = modDB.ExecuteQuery(query, parameters)

        If table IsNot Nothing Then
            For Each row As DataRow In table.Rows
                Dim res As New Reservation()
                res.ReservationID = Convert.ToInt32(row("ReservationID"))
                res.CustomerName = If(IsDBNull(row("CustomerName")), "Unknown", row("CustomerName").ToString())
                res.EventTime = If(IsDBNull(row("EventTime")), TimeSpan.Zero, CType(row("EventTime"), TimeSpan))
                res.NumberOfGuests = If(IsDBNull(row("NumberOfGuests")), 0, Convert.ToInt32(row("NumberOfGuests")))
                res.ReservationStatus = If(IsDBNull(row("ReservationStatus")), "Pending", row("ReservationStatus").ToString())

                ' Optional fields depending on query
                If table.Columns.Contains("CustomerID") Then res.CustomerID = If(IsDBNull(row("CustomerID")), 0, Convert.ToInt32(row("CustomerID")))
                If table.Columns.Contains("FullName") Then res.FullName = If(IsDBNull(row("FullName")), "", row("FullName").ToString())
                If table.Columns.Contains("AssignedStaffID") AndAlso Not IsDBNull(row("AssignedStaffID")) Then res.AssignedStaffID = CInt(row("AssignedStaffID"))
                If table.Columns.Contains("EventDate") Then res.EventDate = If(IsDBNull(row("EventDate")), DateTime.MinValue, Convert.ToDateTime(row("EventDate")))
                If table.Columns.Contains("EventType") Then res.EventType = If(IsDBNull(row("EventType")), "", row("EventType").ToString())
                If table.Columns.Contains("ContactNumber") Then res.ContactNumber = If(IsDBNull(row("ContactNumber")), "", row("ContactNumber").ToString())
                If table.Columns.Contains("Email") Then res.CustomerEmail = If(IsDBNull(row("Email")), "", row("Email").ToString())
                If table.Columns.Contains("ProductSelection") Then res.ProductSelection = If(IsDBNull(row("ProductSelection")), "", row("ProductSelection").ToString())
                If table.Columns.Contains("SpecialRequests") Then res.SpecialRequests = If(IsDBNull(row("SpecialRequests")), "", row("SpecialRequests").ToString())
                If table.Columns.Contains("DeliveryAddress") Then res.DeliveryAddress = If(IsDBNull(row("DeliveryAddress")), "", row("DeliveryAddress").ToString())
                If table.Columns.Contains("DeliveryOption") Then res.DeliveryOption = If(IsDBNull(row("DeliveryOption")), "", row("DeliveryOption").ToString())
                If table.Columns.Contains("TotalPrice") Then res.TotalPrice = If(IsDBNull(row("TotalPrice")), 0D, Convert.ToDecimal(row("TotalPrice")))
                If table.Columns.Contains("PrepTime") Then res.PrepTime = If(IsDBNull(row("PrepTime")), 0, Convert.ToInt32(row("PrepTime")))

                reservations.Add(res)
            Next
        End If

        Return reservations
    End Function

    ''' <summary>
    ''' Creates a new reservation and deducts inventory if status is Confirmed/Accepted
    ''' </summary>
    Public Function CreateReservation(reservation As Reservation) As Integer
        If String.IsNullOrEmpty(reservation.ProductSelection) AndAlso reservation.Items IsNot Nothing AndAlso reservation.Items.Count > 0 Then
            Dim parts As New List(Of String)
            For Each item In reservation.Items
                parts.Add($"{item.ProductName} ({item.Quantity})")
            Next
            reservation.ProductSelection = String.Join(", ", parts)
        End If

        Dim query As String = "INSERT INTO reservations (CustomerID, FullName, AssignedStaffID, ReservationType, EventType, EventDate, EventTime, NumberOfGuests, ProductSelection, SpecialRequests, ReservationStatus, DeliveryAddress, DeliveryOption, ContactNumber, ReservationDate, UpdatedDate) VALUES (@customerID, @fullName, @assignedStaffID, @reservationType, @eventType, @eventDate, @eventTime, @numberOfGuests, @productSelection, @specialRequests, @reservationStatus, @deliveryAddress, @deliveryOption, @contactNumber, @reservationDate, @updatedDate)"

        Dim parameters As MySqlParameter() = {
            New MySqlParameter("@customerID", reservation.CustomerID),
            New MySqlParameter("@fullName", If(String.IsNullOrEmpty(reservation.FullName), DBNull.Value, reservation.FullName)),
            New MySqlParameter("@assignedStaffID", If(reservation.AssignedStaffID.HasValue, reservation.AssignedStaffID.Value, DBNull.Value)),
            New MySqlParameter("@reservationType", reservation.ReservationType),
            New MySqlParameter("@eventType", reservation.EventType),
            New MySqlParameter("@eventDate", reservation.EventDate),
            New MySqlParameter("@eventTime", reservation.EventTime),
            New MySqlParameter("@numberOfGuests", reservation.NumberOfGuests),
            New MySqlParameter("@productSelection", If(String.IsNullOrEmpty(reservation.ProductSelection), DBNull.Value, reservation.ProductSelection)),
            New MySqlParameter("@specialRequests", If(String.IsNullOrEmpty(reservation.SpecialRequests), DBNull.Value, reservation.SpecialRequests)),
            New MySqlParameter("@reservationStatus", reservation.ReservationStatus),
            New MySqlParameter("@deliveryAddress", If(String.IsNullOrEmpty(reservation.DeliveryAddress), DBNull.Value, reservation.DeliveryAddress)),
            New MySqlParameter("@deliveryOption", If(String.IsNullOrEmpty(reservation.DeliveryOption), DBNull.Value, reservation.DeliveryOption)),
            New MySqlParameter("@contactNumber", reservation.ContactNumber),
            New MySqlParameter("@reservationDate", DateTime.Now),
            New MySqlParameter("@updatedDate", DateTime.Now)
        }

        If modDB.ExecuteNonQuery(query, parameters) > 0 Then
            Dim newID As Object = modDB.ExecuteScalar("SELECT LAST_INSERT_ID()")
            If newID IsNot Nothing AndAlso IsNumeric(newID) Then
                Dim reservationID As Integer = CInt(newID)


                ' Add reservation items
                If reservation.Items IsNot Nothing Then
                    For Each item In reservation.Items
                        AddReservationItem(reservationID, item)
                    Next
                End If

                ' Note: Inventory deduction is now handled in UpdateReservationStatus when status changes to 'Completed'
                
                Return reservationID



                Return reservationID
            End If
        End If

        Return 0
    End Function

    Private Sub AddReservationItem(reservationID As Integer, item As ReservationItem)
        Dim query As String = "INSERT INTO reservation_items (ReservationID, ProductName, Quantity, UnitPrice, TotalPrice) VALUES (@reservationID, @productName, @quantity, @unitPrice, @totalPrice)"
        Dim parameters As MySqlParameter() = {
            New MySqlParameter("@reservationID", reservationID),
            New MySqlParameter("@productName", item.ProductName),
            New MySqlParameter("@quantity", item.Quantity),
            New MySqlParameter("@unitPrice", item.UnitPrice),
            New MySqlParameter("@totalPrice", item.TotalPrice)
        }
        modDB.ExecuteNonQuery(query, parameters)
    End Sub

    Public Function UpdateReservationStatus(reservationID As Integer, status As String, Optional silent As Boolean = False) As Boolean
        Dim query As String = "UPDATE reservations SET ReservationStatus = @status, UpdatedDate = @updatedDate WHERE ReservationID = @reservationID"
        Dim parameters As MySqlParameter() = {
            New MySqlParameter("@status", status),
            New MySqlParameter("@reservationID", reservationID),
            New MySqlParameter("@updatedDate", DateTime.Now)
        }

        Dim success As Boolean = modDB.ExecuteNonQuery(query, parameters, silent) > 0


        If success AndAlso status = "Completed" Then
            Try
                Dim inventoryService As New InventoryService()
                inventoryService.DeductInventoryForReservation(reservationID)
            Catch ex As Exception
                System.Diagnostics.Debug.WriteLine($"Inventory deduction failed for reservation #{reservationID}: {ex.Message}")
            End Try
        End If

        Return success
    End Function

    ''' <summary>
    ''' Gets the current status of a reservation
    ''' </summary>
    Private Function GetReservationStatus(reservationID As Integer) As String
        Dim query As String = "SELECT ReservationStatus FROM reservations WHERE ReservationID = @reservationID"
        Dim parameters As MySqlParameter() = {
            New MySqlParameter("@reservationID", reservationID)
        }

        Dim result As Object = modDB.ExecuteScalar(query, parameters)
        If result IsNot Nothing Then
            Return result.ToString()
        End If
        Return "Unknown"
    End Function

    ''' <summary>
    ''' Deducts inventory using the stored procedure
    ''' </summary>
    Private Sub DeductInventoryForReservation(reservationID As Integer)
        Dim conn As MySqlConnection = Nothing
        Dim cmd As MySqlCommand = Nothing

        Try
            conn = New MySqlConnection(modDB.ConnectionString)
            conn.Open()

            ' Call the stored procedure
            cmd = New MySqlCommand("DeductIngredientsForReservation", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@p_reservation_id", reservationID)
            cmd.CommandTimeout = 60 ' 60 seconds timeout

            cmd.ExecuteNonQuery()

        Catch ex As MySqlException
            Throw New Exception($"Database error deducting inventory: {ex.Message}", ex)
        Catch ex As Exception
            Throw New Exception($"Error deducting inventory: {ex.Message}", ex)
        Finally
            If cmd IsNot Nothing Then cmd.Dispose()
            If conn IsNot Nothing AndAlso conn.State = ConnectionState.Open Then
                conn.Close()
                conn.Dispose()
            End If
        End Try
    End Sub

    Public Function GetTodayReservationsCount() As Integer
        Dim query As String = "SELECT COUNT(*) FROM reservations WHERE DATE(EventDate) = CURDATE() AND ReservationStatus = 'Confirmed'"
        Dim result As Object = modDB.ExecuteScalar(query)
        If result IsNot Nothing AndAlso IsNumeric(result) Then
            Return CInt(result)
        End If
        Return 0
    End Function

    ''' <summary>
    ''' Gets total count of all reservations for pagination
    ''' </summary>
    Public Function GetTotalReservationsCount(Optional statusFilter As String = "All Orders", Optional searchQuery As String = "") As Integer
        Dim query As String = "SELECT COUNT(*) FROM reservations r LEFT JOIN customers c ON r.CustomerID = c.CustomerID"
        Dim whereLines As New List(Of String)
        Dim paramList As New List(Of MySqlParameter)

        ' Status Filtering
        If statusFilter = "Confirmed" Then
            whereLines.Add("r.ReservationStatus IN ('Confirmed', 'Accepted')")
        ElseIf statusFilter <> "All Orders" Then
            whereLines.Add("r.ReservationStatus = @status")
            paramList.Add(New MySqlParameter("@status", statusFilter))
        End If

        ' Search Query
        If Not String.IsNullOrEmpty(searchQuery) Then
            whereLines.Add("(r.FullName LIKE @search OR CONCAT(c.FirstName, ' ', c.LastName) LIKE @search)")
            paramList.Add(New MySqlParameter("@search", "%" & searchQuery & "%"))
        End If

        If whereLines.Count > 0 Then
            query &= " WHERE " & String.Join(" AND ", whereLines)
        End If

        Dim parameters As MySqlParameter() = If(paramList.Count > 0, paramList.ToArray(), Nothing)
        
        Dim result As Object = modDB.ExecuteScalar(query, parameters)
        If result IsNot Nothing AndAlso IsNumeric(result) Then
            Return Convert.ToInt32(result)
        End If
        Return 0
    End Function

    Public Async Function GetTotalReservationsCountAsync(Optional statusFilter As String = "All Orders", Optional searchQuery As String = "") As Task(Of Integer)
        Return Await Task.Run(Function() GetTotalReservationsCount(statusFilter, searchQuery))
    End Function

    Public Function GetReservationItems(reservationID As Integer) As List(Of ReservationItem)
        Dim items As New List(Of ReservationItem)
        Dim query As String = "SELECT ReservationItemID, ReservationID, ProductName, Quantity, UnitPrice, TotalPrice FROM reservation_items WHERE ReservationID = @reservationID"
        Dim parameters As MySqlParameter() = {
            New MySqlParameter("@reservationID", reservationID)
        }

        Dim table As DataTable = modDB.ExecuteQuery(query, parameters)
        If table IsNot Nothing Then
            For Each row As DataRow In table.Rows
                items.Add(New ReservationItem With {
                    .ReservationItemID = Convert.ToInt32(row("ReservationItemID")),
                    .ReservationID = Convert.ToInt32(row("ReservationID")),
                    .ProductName = row("ProductName").ToString(),
                    .Quantity = Convert.ToInt32(row("Quantity")),
                    .UnitPrice = Convert.ToDecimal(row("UnitPrice")),
                    .TotalPrice = Convert.ToDecimal(row("TotalPrice"))
                })
            Next
        End If

        Return items
    End Function
End Class
