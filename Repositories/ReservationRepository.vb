Imports MySql.Data.MySqlClient
Imports System.Collections.Generic
Imports System.Threading.Tasks

Public Class ReservationRepository
    ''' <summary>
    ''' Gets all reservations (Buffered - Load All)
    ''' </summary>
    Public Function GetAllReservations() As List(Of Reservation)
        Dim query As String = "SELECT r.ReservationID, r.CustomerID, r.FullName, CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName, c.Email, r.ContactNumber, r.AssignedStaffID, r.NumberOfGuests, r.EventDate, r.EventTime, r.EventType, r.ReservationStatus, r.ProductSelection, r.SpecialRequests, r.DeliveryAddress, r.DeliveryOption, COALESCE((SELECT SUM(TotalPrice) FROM reservation_items WHERE ReservationID = r.ReservationID), 0) AS TotalPrice " &
                              "FROM reservations r " &
                              "LEFT JOIN customers c ON r.CustomerID = c.CustomerID " &
                              "ORDER BY r.ReservationID DESC"

        Return GetReservations(query)
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

    ' Legacy support for paginated calls - Redirects to buffered list
    Public Function GetTodayReservationsPaged(limit As Integer, offset As Integer) As List(Of Reservation)
        Return GetTodayReservations()
    End Function

    Public Function GetAllReservationsPaged(limit As Integer, offset As Integer) As List(Of Reservation)
        Return GetAllReservations()
    End Function

    Public Async Function GetAllReservationsAsync() As Task(Of List(Of Reservation))
        Return Await Task.Run(Function() GetAllReservations())
    End Function

    Public Async Function GetTodayReservationsPagedAsync(limit As Integer, offset As Integer) As Task(Of List(Of Reservation))
        Return Await Task.Run(Function() GetTodayReservations())
    End Function

    Public Function GetTotalTodayReservationsCount() As Integer
        Dim query As String = "SELECT COUNT(*) FROM reservations WHERE DATE(EventDate) = CURDATE() AND ReservationStatus IN ('Accepted', 'Confirmed')"
        Dim result As Object = modDB.ExecuteScalar(query)
        If result IsNot Nothing AndAlso IsNumeric(result) Then
            Return CInt(result)
        End If
        Return 0
    End Function

    Public Async Function GetTotalTodayReservationsCountAsync() As Task(Of Integer)
        Return Await Task.Run(Function() GetTotalTodayReservationsCount())
    End Function

    Private Function GetReservations(query As String) As List(Of Reservation)
        Dim reservations As New List(Of Reservation)
        Dim table As DataTable = modDB.ExecuteQuery(query)

        If table IsNot Nothing Then
            For Each row As DataRow In table.Rows
                Dim res As New Reservation()
                res.ReservationID = Convert.ToInt32(row("ReservationID"))
                res.CustomerName = If(IsDBNull(row("CustomerName")), "Unknown", row("CustomerName").ToString())
                res.EventTime = CType(row("EventTime"), TimeSpan)
                res.NumberOfGuests = Convert.ToInt32(row("NumberOfGuests"))
                res.ReservationStatus = row("ReservationStatus").ToString()

                ' Optional fields depending on query
                If table.Columns.Contains("CustomerID") Then res.CustomerID = Convert.ToInt32(row("CustomerID"))
                If table.Columns.Contains("FullName") Then res.FullName = If(IsDBNull(row("FullName")), "", row("FullName").ToString())
                If table.Columns.Contains("AssignedStaffID") AndAlso Not IsDBNull(row("AssignedStaffID")) Then res.AssignedStaffID = CInt(row("AssignedStaffID"))
                If table.Columns.Contains("EventDate") Then res.EventDate = Convert.ToDateTime(row("EventDate"))
                If table.Columns.Contains("EventType") Then res.EventType = row("EventType").ToString()
                If table.Columns.Contains("ContactNumber") Then res.ContactNumber = If(IsDBNull(row("ContactNumber")), "", row("ContactNumber").ToString())
                If table.Columns.Contains("Email") Then res.CustomerEmail = If(IsDBNull(row("Email")), "", row("Email").ToString())
                If table.Columns.Contains("ProductSelection") Then res.ProductSelection = If(IsDBNull(row("ProductSelection")), "", row("ProductSelection").ToString())
                If table.Columns.Contains("SpecialRequests") Then res.SpecialRequests = If(IsDBNull(row("SpecialRequests")), "", row("SpecialRequests").ToString())
                If table.Columns.Contains("DeliveryAddress") Then res.DeliveryAddress = If(IsDBNull(row("DeliveryAddress")), "", row("DeliveryAddress").ToString())
                If table.Columns.Contains("DeliveryOption") Then res.DeliveryOption = If(IsDBNull(row("DeliveryOption")), "", row("DeliveryOption").ToString())
                If table.Columns.Contains("TotalPrice") Then res.TotalPrice = Convert.ToDecimal(row("TotalPrice"))
                If table.Columns.Contains("PrepTime") Then res.PrepTime = Convert.ToInt32(row("PrepTime"))

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

        Dim query As String = "INSERT INTO reservations (CustomerID, FullName, AssignedStaffID, ReservationType, EventType, EventDate, EventTime, NumberOfGuests, ProductSelection, SpecialRequests, ReservationStatus, DeliveryAddress, DeliveryOption, ContactNumber) VALUES (@customerID, @fullName, @assignedStaffID, @reservationType, @eventType, @eventDate, @eventTime, @numberOfGuests, @productSelection, @specialRequests, @reservationStatus, @deliveryAddress, @deliveryOption, @contactNumber)"

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
            New MySqlParameter("@contactNumber", reservation.ContactNumber)
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

                ' **Deduct inventory ONLY if status is Confirmed or Accepted**
                If reservation.ReservationStatus = "Confirmed" OrElse reservation.ReservationStatus = "Accepted" Then
                    Try
                        DeductInventoryForReservation(reservationID)
                        System.Diagnostics.Debug.WriteLine($"Successfully deducted inventory for new Reservation #{reservationID}")
                    Catch ex As Exception
                        System.Diagnostics.Debug.WriteLine($"Inventory deduction failed for new Reservation #{reservationID}: {ex.Message}")
                        ' Don't fail the reservation creation, just log the error
                    End Try
                End If

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

    ''' <summary>
    ''' Updates reservation status and deducts inventory if changing TO Confirmed/Accepted
    ''' </summary>
    Public Function UpdateReservationStatus(reservationID As Integer, status As String) As Boolean
        ' Get current status before updating
        Dim currentStatus As String = GetReservationStatus(reservationID)

        ' Update the status
        Dim query As String = "UPDATE reservations SET ReservationStatus = @status, UpdatedDate = NOW() WHERE ReservationID = @reservationID"
        Dim parameters As MySqlParameter() = {
            New MySqlParameter("@status", status),
            New MySqlParameter("@reservationID", reservationID)
        }

        Dim success As Boolean = modDB.ExecuteNonQuery(query, parameters) > 0

        ' **Deduct inventory ONLY if status changed FROM Pending TO Confirmed/Accepted**
        If success AndAlso currentStatus <> "Confirmed" AndAlso currentStatus <> "Accepted" Then
            If status = "Confirmed" OrElse status = "Accepted" Then
                Try
                    DeductInventoryForReservation(reservationID)
                    System.Diagnostics.Debug.WriteLine($"Successfully deducted inventory for Reservation #{reservationID} (status changed to {status})")
                Catch ex As Exception
                    System.Diagnostics.Debug.WriteLine($"Inventory deduction failed for Reservation #{reservationID}: {ex.Message}")
                    ' Don't fail the status update, just log the error
                    Throw New Exception($"Status updated but inventory deduction failed: {ex.Message}", ex)
                End Try
            End If
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
        Dim query As String = "SELECT COUNT(*) FROM reservations WHERE DATE(EventDate) = CURDATE() AND ReservationStatus IN ('Accepted', 'Confirmed')"
        Dim result As Object = modDB.ExecuteScalar(query)
        If result IsNot Nothing AndAlso IsNumeric(result) Then
            Return CInt(result)
        End If
        Return 0
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