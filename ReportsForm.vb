Imports System.Collections.Generic

Public Class ReportsForm
    Private orderRepository As New OrderRepository()
    Private reservationRepository As New ReservationRepository()

    Private Sub ReportsForm_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        LoadDailyReports()
    End Sub

    ''' <summary>
    ''' Loads all daily report data
    ''' </summary>
    Private Sub LoadDailyReports()
        Try
            LoadTodaySales()
            LoadOrdersHandled()
            LoadReservationsHandled()
            LoadTodayOrders()
        Catch ex As Exception
            MessageBox.Show($"Error loading daily reports: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    ''' <summary>
    ''' Loads today's total sales from orders
    ''' </summary>
    Private Sub LoadTodaySales()
        Try
            Dim query As String = "SELECT COALESCE(SUM(TotalAmount), 0) FROM orders WHERE DATE(OrderDate) = CURDATE() AND OrderStatus != 'Cancelled'"
            Dim result As Object = Database.ExecuteScalar(query)

            If result IsNot Nothing AndAlso IsNumeric(result) Then
                lblSalesValue.Text = $"₱ {CDec(result):N0}"
            Else
                lblSalesValue.Text = "₱ 0"
            End If
        Catch ex As Exception
            lblSalesValue.Text = "₱ 0"
            Console.WriteLine($"Error loading sales: {ex.Message}")
        End Try
    End Sub

    ''' <summary>
    ''' Loads count of today's orders
    ''' </summary>
    Private Sub LoadOrdersHandled()
        Try
            Dim query As String = "SELECT COUNT(*) FROM orders WHERE DATE(OrderDate) = CURDATE() AND OrderStatus != 'Cancelled'"
            Dim result As Object = Database.ExecuteScalar(query)

            If result IsNot Nothing AndAlso IsNumeric(result) Then
                lblOrdersValue.Text = result.ToString()
            Else
                lblOrdersValue.Text = "0"
            End If
        Catch ex As Exception
            lblOrdersValue.Text = "0"
            Console.WriteLine($"Error loading orders count: {ex.Message}")
        End Try
    End Sub

    ''' <summary>
    ''' Loads count of reservations confirmed/accepted today
    ''' </summary>
    Private Sub LoadReservationsHandled()
        Try
            ' Count reservations that were confirmed today
            Dim query As String = "SELECT COUNT(*) FROM reservations WHERE DATE(UpdatedDate) = CURDATE() AND ReservationStatus = 'Confirmed'"
            Dim result As Object = Database.ExecuteScalar(query)

            If result IsNot Nothing AndAlso IsNumeric(result) Then
                lblReservationsValue.Text = result.ToString()
            Else
                lblReservationsValue.Text = "0"
            End If
        Catch ex As Exception
            lblReservationsValue.Text = "0"
            Console.WriteLine($"Error loading reservations count: {ex.Message}")
        End Try
    End Sub

    ''' <summary>
    ''' Loads today's orders and reservations, and displays them in table
    ''' </summary>
    Private Sub LoadTodayOrders()
        Try
            Dim orders As List(Of Order) = orderRepository.GetTodayOrders()
            Dim reservations As List(Of Reservation) = reservationRepository.GetTodayReservations()
            DisplayTodayOrdersAndReservations(orders, reservations)
        Catch ex As Exception
            Console.WriteLine($"Error loading today's orders and reservations: {ex.Message}")
        End Try
    End Sub

    ''' <summary>
    ''' Displays today's orders and reservations in the table layout
    ''' </summary>
    Private Sub DisplayTodayOrdersAndReservations(orders As List(Of Order), reservations As List(Of Reservation))
        ' Clear all containers
        tlpOrdersRows.Controls.Clear()
        tlpOrdersRows.RowStyles.Clear()
        tlpOrdersRows.RowCount = 0
        pnlTableHeader.Controls.Clear()
        pnlTableTotal.Controls.Clear()

        If orders.Count = 0 AndAlso reservations.Count = 0 Then
            tlpOrdersRows.RowCount = 1
            tlpOrdersRows.RowStyles.Add(New RowStyle(SizeType.Absolute, 50.0F))

            Dim lblEmpty As New Label With {
                .Text = "No orders or reservations today",
                .Dock = DockStyle.Fill,
                .TextAlign = ContentAlignment.MiddleCenter,
                .Font = New Font("Segoe UI", 10, FontStyle.Italic),
                .ForeColor = Color.Gray
            }

            tlpOrdersRows.Controls.Add(lblEmpty, 0, 0)
            Return
        End If

        ' Add header row to fixed panel
        PopulateHeaderPanel()

        ' Add order rows to scrollable area
        For Each order As Order In orders
            AddOrderRow(order)
        Next

        ' Add reservation rows to scrollable area
        For Each reservation As Reservation In reservations
            AddReservationRow(reservation)
        Next

        ' Add total row to fixed panel
        PopulateTotalPanel(orders, reservations)
    End Sub

    ''' <summary>
    ''' Populates the fixed header panel with column headers
    ''' </summary>
    Private Sub PopulateHeaderPanel()
        pnlTableHeader.Controls.Clear()

        ' Use resize handler for responsive column positions
        AddHandler pnlTableHeader.Resize, Sub(sender, e)
                                              Dim panel As Panel = CType(sender, Panel)
                                              Dim width As Integer = panel.Width - 40 ' Account for padding

                                              ' Update label positions based on panel width
                                              If panel.Controls.Count >= 5 Then
                                                  panel.Controls(0).Left = 20  ' Order ID - 0%
                                                  panel.Controls(1).Left = CInt(width * 0.15) + 20  ' Type - 15%
                                                  panel.Controls(2).Left = CInt(width * 0.35) + 20  ' Items - 35%
                                                  panel.Controls(3).Left = CInt(width * 0.55) + 20  ' Time - 55%
                                                  panel.Controls(4).Left = CInt(width * 0.75) + 20  ' Amount - 75%
                                              End If
                                          End Sub

        ' Column headers
        Dim lblOrderID As New Label With {
            .Text = "Order ID",
            .Font = New Font("Segoe UI", 10, FontStyle.Bold),
            .AutoSize = True,
            .Location = New Point(20, 10)
        }

        Dim lblType As New Label With {
            .Text = "Type",
            .Font = New Font("Segoe UI", 10, FontStyle.Bold),
            .AutoSize = True,
            .Location = New Point(20, 10)
        }

        Dim lblItems As New Label With {
            .Text = "Items",
            .Font = New Font("Segoe UI", 10, FontStyle.Bold),
            .AutoSize = True,
            .Location = New Point(20, 10)
        }

        Dim lblTime As New Label With {
            .Text = "Time",
            .Font = New Font("Segoe UI", 10, FontStyle.Bold),
            .AutoSize = True,
            .Location = New Point(20, 10)
        }

        Dim lblAmount As New Label With {
            .Text = "Amount",
            .Font = New Font("Segoe UI", 10, FontStyle.Bold),
            .AutoSize = True,
            .Location = New Point(20, 10)
        }

        pnlTableHeader.Controls.AddRange({lblOrderID, lblType, lblItems, lblTime, lblAmount})
    End Sub

    ''' <summary>
    ''' Adds order data row
    ''' </summary>
    Private Sub AddOrderRow(order As Order)
        tlpOrdersRows.RowCount += 1
        tlpOrdersRows.RowStyles.Add(New RowStyle(SizeType.Absolute, 45.0F))

        Dim rowPanel As New Panel With {
            .Dock = DockStyle.Fill,
            .BackColor = Color.White,
            .Padding = New Padding(20, 10, 20, 10)
        }

        ' Get item count
        Dim itemCount As Integer = If(order.Items IsNot Nothing, order.Items.Sum(Function(i) i.Quantity), 0)

        ' Order ID
        Dim lblOrderID As New Label With {
            .Text = $"#{order.OrderID}",
            .Font = New Font("Segoe UI", 9),
            .ForeColor = Color.Gray,
            .AutoSize = True,
            .Location = New Point(20, 12)
        }

        ' Type
        Dim lblType As New Label With {
            .Text = order.OrderType,
            .Font = New Font("Segoe UI", 9),
            .AutoSize = True,
            .Location = New Point(20, 12)
        }

        ' Items count
        Dim lblItems As New Label With {
            .Text = itemCount.ToString(),
            .Font = New Font("Segoe UI", 9),
            .AutoSize = True,
            .Location = New Point(20, 12)
        }

        ' Time
        Dim lblTime As New Label With {
            .Text = DateTime.Today.Add(order.OrderTime).ToString("h:mm tt"),
            .Font = New Font("Segoe UI", 9),
            .AutoSize = True,
            .Location = New Point(20, 12)
        }

        ' Amount
        Dim lblAmount As New Label With {
            .Text = $"₱ {order.TotalAmount:N0}",
            .Font = New Font("Segoe UI", 9, FontStyle.Bold),
            .AutoSize = True,
            .Location = New Point(20, 12)
        }

        ' Use resize handler for responsive column positions
        AddHandler rowPanel.Resize, Sub(sender, e)
                                        Dim panel As Panel = CType(sender, Panel)
                                        Dim width As Integer = panel.Width - 40

                                        If panel.Controls.Count >= 5 Then
                                            panel.Controls(0).Left = 20
                                            panel.Controls(1).Left = CInt(width * 0.15) + 20
                                            panel.Controls(2).Left = CInt(width * 0.35) + 20
                                            panel.Controls(3).Left = CInt(width * 0.55) + 20
                                            panel.Controls(4).Left = CInt(width * 0.75) + 20
                                        End If
                                    End Sub

        rowPanel.Controls.AddRange({lblOrderID, lblType, lblItems, lblTime, lblAmount})
        tlpOrdersRows.Controls.Add(rowPanel, 0, tlpOrdersRows.RowCount - 1)
    End Sub

    ''' <summary>
    ''' Populates the fixed total panel
    ''' </summary>
    Private Sub PopulateTotalPanel(orders As List(Of Order), reservations As List(Of Reservation))
        pnlTableTotal.Controls.Clear()

        ' Calculate total from both orders and reservations
        Dim orderTotal As Decimal = orders.Sum(Function(o) o.TotalAmount)
        Dim reservationTotal As Decimal = If(reservations IsNot Nothing, reservations.Sum(Function(r) r.TotalPrice), 0)
        Dim total As Decimal = orderTotal + reservationTotal

        Dim lblTotalLabel As New Label With {
            .Text = "Total",
            .Font = New Font("Segoe UI", 13, FontStyle.Bold),
            .AutoSize = True,
            .Location = New Point(20, 15)
        }

        Dim lblTotalAmount As New Label With {
            .Text = $"₱ {total:N0}",
            .Font = New Font("Segoe UI", 13, FontStyle.Bold),
            .AutoSize = True,
            .Location = New Point(20, 13)
        }

        ' Use resize handler for responsive positioning
        AddHandler pnlTableTotal.Resize, Sub(sender, e)
                                             Dim panel As Panel = CType(sender, Panel)
                                             Dim width As Integer = panel.Width - 40

                                             If panel.Controls.Count >= 2 Then
                                                 panel.Controls(0).Left = 20
                                                 panel.Controls(1).Left = CInt(width * 0.75) + 20  ' Align with Amount column
                                             End If
                                         End Sub

        pnlTableTotal.Controls.AddRange({lblTotalLabel, lblTotalAmount})
    End Sub

    ''' <summary>
    ''' Adds reservation data row
    ''' </summary>
    Private Sub AddReservationRow(reservation As Reservation)
        tlpOrdersRows.RowCount += 1
        tlpOrdersRows.RowStyles.Add(New RowStyle(SizeType.Absolute, 45.0F))

        Dim rowPanel As New Panel With {
            .Dock = DockStyle.Fill,
            .BackColor = Color.White,
            .Padding = New Padding(20, 10, 20, 10)
        }

        ' Reservation ID
        Dim lblResID As New Label With {
            .Text = $"#RES-{reservation.ReservationID}",
            .Font = New Font("Segoe UI", 9),
            .ForeColor = Color.Gray,
            .AutoSize = True,
            .Location = New Point(20, 12)
        }

        ' Type
        Dim lblType As New Label With {
            .Text = "Reservation",
            .Font = New Font("Segoe UI", 9),
            .AutoSize = True,
            .Location = New Point(20, 12)
        }

        ' Guests count
        Dim lblGuests As New Label With {
            .Text = $"{reservation.NumberOfGuests} Guests",
            .Font = New Font("Segoe UI", 9),
            .AutoSize = True,
            .Location = New Point(20, 12)
        }

        ' Time
        Dim lblTime As New Label With {
            .Text = DateTime.Today.Add(reservation.EventTime).ToString("h:mm tt"),
            .Font = New Font("Segoe UI", 9),
            .AutoSize = True,
            .Location = New Point(20, 12)
        }

        ' Amount
        Dim lblAmount As New Label With {
            .Text = $"₱ {reservation.TotalPrice:N0}",
            .Font = New Font("Segoe UI", 9, FontStyle.Bold),
            .AutoSize = True,
            .Location = New Point(20, 12)
        }

        ' Use resize handler for responsive column positions
        AddHandler rowPanel.Resize, Sub(sender, e)
                                        Dim panel As Panel = CType(sender, Panel)
                                        Dim width As Integer = panel.Width - 40

                                        If panel.Controls.Count >= 5 Then
                                            panel.Controls(0).Left = 20
                                            panel.Controls(1).Left = CInt(width * 0.15) + 20
                                            panel.Controls(2).Left = CInt(width * 0.35) + 20
                                            panel.Controls(3).Left = CInt(width * 0.55) + 20
                                            panel.Controls(4).Left = CInt(width * 0.75) + 20
                                        End If
                                    End Sub

        rowPanel.Controls.AddRange({lblResID, lblType, lblGuests, lblTime, lblAmount})
        tlpOrdersRows.Controls.Add(rowPanel, 0, tlpOrdersRows.RowCount - 1)
    End Sub
End Class
