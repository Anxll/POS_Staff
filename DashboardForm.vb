Imports System.Collections.Generic

Public Class DashboardForm
    Private orderRepository As New OrderRepository()
    Private reservationRepository As New ReservationRepository()
    Private WithEvents dashboardTimer As New Timer()

    ''' <summary>
    ''' Loads dashboard statistics when form loads
    ''' </summary>
    Private Sub DashboardForm_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        dashboardTimer.Interval = 1000
        dashboardTimer.Start()
        LoadDashboardStatistics()
        LoadActiveOrders()
        LoadTodayReservations()
    End Sub

    ''' <summary>
    ''' Loads and displays dashboard statistics (orders, reservations, feedback counts)
    ''' </summary>
    Private Sub LoadDashboardStatistics()
        Try
            ' Load today's orders count
            Dim todayOrdersCount As Integer = orderRepository.GetTodayOrdersCount()
            lblCardOrdersValue.Text = todayOrdersCount.ToString()

            ' Load today's reservations count
            Dim todayReservationsCount As Integer = reservationRepository.GetTodayReservationsCount()
            lblCardReservationsValue.Text = todayReservationsCount.ToString()

            ' Load current time
            Dim currentTime As String = DateTime.Now.ToString("h:mm tt")
            lblCardTimeValue.Text = currentTime

            ' Load feedback count (placeholder logic as per original)
            ' Assuming we might add FeedbackRepository later
            Dim feedbackQuery As String = "SELECT COUNT(*) FROM customers WHERE FeedbackCount > 0 AND DATE(LastTransactionDate) = CURDATE()"
            Dim feedbackCount As Object = Database.ExecuteScalar(feedbackQuery)
            If feedbackCount IsNot Nothing Then
                lblCardFeedbackValue.Text = feedbackCount.ToString()
            Else
                lblCardFeedbackValue.Text = "0"
            End If
        Catch ex As Exception
            MessageBox.Show($"Error loading dashboard statistics: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    ''' <summary>
    ''' Loads active orders (orders with status 'Preparing' or 'Served')
    ''' and displays them in the active orders panel
    ''' </summary>
    Private Sub LoadActiveOrders()
        Try
            Dim activeOrders As List(Of Order) = orderRepository.GetActiveOrders()
            DisplayActiveOrders(activeOrders)
        Catch ex As Exception
            ' Log error but don't crash dashboard
            Console.WriteLine($"Error loading active orders: {ex.Message}")
        End Try
    End Sub

    ''' <summary>
    ''' Displays active orders in the UI
    ''' </summary>
    Private Sub DisplayActiveOrders(orders As List(Of Order))
        TableLayoutPanel1.Controls.Clear()
        TableLayoutPanel1.RowStyles.Clear()
        TableLayoutPanel1.ColumnStyles.Clear()

        ' Setup main table
        TableLayoutPanel1.ColumnCount = 1
        TableLayoutPanel1.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100.0F))
        TableLayoutPanel1.RowCount = 0
        TableLayoutPanel1.Dock = DockStyle.Fill
        TableLayoutPanel1.AutoScroll = True

        If orders.Count = 0 Then
            TableLayoutPanel1.RowCount = 1
            TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Absolute, 50.0F))

            Dim lblEmpty As New Label With {
            .Text = "No active orders",
            .Dock = DockStyle.Fill,
            .TextAlign = ContentAlignment.MiddleCenter,
            .Font = New Font("Segoe UI", 10, FontStyle.Italic),
            .ForeColor = Color.Gray
        }

            TableLayoutPanel1.Controls.Add(lblEmpty, 0, 0)
            Return
        End If

        ' Add each order
        For Each order As Order In orders
            TableLayoutPanel1.RowCount += 1
            TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Absolute, 65.0F))

            ' Parent panel for each order
            Dim itemPanel As New Panel With {
                .BackColor = Color.White,
                .Margin = New Padding(4),
                .Dock = DockStyle.Fill,
                .Tag = order, ' Store Order object
                .Padding = New Padding(15, 10, 15, 10)
            }

            ' Order ID (Top Left)
            Dim lblID As New Label With {
                .Text = $"#{order.OrderID}",
                .Font = New Font("Segoe UI", 11, FontStyle.Bold),
                .ForeColor = Color.Black,
                .AutoSize = True,
                .Location = New Point(20, 5)
            }

            ' Status (Below ID)
            Dim lblStatus As New Label With {
                .Name = "lblStatus",
                .Text = order.OrderStatus,
                .Font = New Font("Segoe UI", 9, FontStyle.Bold),
                .ForeColor = If(order.OrderStatus = "Preparing", Color.Orange, Color.Green),
                .AutoSize = True,
                .Location = New Point(20, 30)
            }

            ' Time (Center Left)
            Dim lblTime As New Label With {
                .Text = DateTime.Today.Add(order.OrderTime).ToString("h:mm tt"),
                .Font = New Font("Segoe UI", 9),
                .ForeColor = Color.Black,
                .AutoSize = True,
                .Location = New Point(200, 10)
            }

            ' Type (Below Time)
            Dim lblType As New Label With {
                .Text = order.OrderType,
                .Font = New Font("Segoe UI", 9),
                .ForeColor = Color.Gray,
                .AutoSize = True,
                .Location = New Point(200, 30)
            }

            ' Countdown (Center Right)
            Dim lblCountdown As New Label With {
                .Name = "lblCountdown",
                .Text = "...",
                .Font = New Font("Segoe UI", 10),
                .ForeColor = Color.Black,
                .AutoSize = True,
                .Location = New Point(330, 20)
            }

            ' Amount (Top Right)
            Dim lblAmount As New Label With {
                .Text = $"₱{order.TotalAmount:F2}",
                .Font = New Font("Segoe UI", 11, FontStyle.Bold),
                .ForeColor = Color.Black,
                .AutoSize = True,
                .Location = New Point(80, 15),
                .Anchor = AnchorStyles.Top Or AnchorStyles.Right
            }

            ' Cancel Button (Bottom Right)
            Dim btnCancel As New Button With {
                .Name = "btnCancel",
                .Text = "Cancel Order",
                .Font = New Font("Segoe UI", 8, FontStyle.Bold),
                .BackColor = Color.FromArgb(255, 127, 39),
                .ForeColor = Color.White,
                .FlatStyle = FlatStyle.Flat,
                .AutoSize = True,
                .Size = New Size(80, 30),
                .Location = New Point(-90, 15),
                .Anchor = AnchorStyles.Top Or AnchorStyles.Right,
                .Enabled = (order.OrderStatus = "Preparing")
            }
            btnCancel.FlatAppearance.BorderSize = 0

            AddHandler btnCancel.Click, Sub(s, ev) CancelOrder(order)

            ' Add controls to panel
            itemPanel.Controls.AddRange({lblID, lblStatus, lblTime, lblType, lblCountdown, lblAmount, btnCancel})

            ' Add final panel to list
            TableLayoutPanel1.Controls.Add(itemPanel)
        Next
    End Sub


    ''' <summary>
    ''' Loads today's reservations and displays them in the reservations panel
    ''' </summary>
    Private Sub LoadTodayReservations()
        Try
            Dim reservations As List(Of Reservation) = reservationRepository.GetTodayReservations()
            DisplayTodayReservations(reservations)
        Catch ex As Exception
            Console.WriteLine($"Error loading reservations: {ex.Message}")
        End Try
    End Sub

    ''' <summary>
    ''' Displays today's reservations in the UI
    ''' </summary>
    Private Sub DisplayTodayReservations(reservations As List(Of Reservation))
        TableLayoutPanel2.Controls.Clear()
        TableLayoutPanel2.RowStyles.Clear()
        TableLayoutPanel2.ColumnStyles.Clear()

        ' Setup main table
        TableLayoutPanel2.ColumnCount = 1
        TableLayoutPanel2.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100.0F))
        TableLayoutPanel2.RowCount = 0
        TableLayoutPanel2.Dock = DockStyle.Fill
        TableLayoutPanel2.AutoScroll = True

        If reservations.Count = 0 Then
            TableLayoutPanel2.RowCount = 1
            TableLayoutPanel2.RowStyles.Add(New RowStyle(SizeType.Absolute, 50.0F))

            Dim lblEmpty As New Label With {
            .Text = "No reservations today",
            .Dock = DockStyle.Fill,
            .TextAlign = ContentAlignment.MiddleCenter,
            .Font = New Font("Segoe UI", 10, FontStyle.Italic),
            .ForeColor = Color.Gray
        }

            TableLayoutPanel2.Controls.Add(lblEmpty, 0, 0)
            Return
        End If

        ' Add each reservation row
        For Each res As Reservation In reservations
            TableLayoutPanel2.RowCount += 1
            TableLayoutPanel2.RowStyles.Add(New RowStyle(SizeType.Absolute, 65.0F))

            ' Row panel
            Dim itemPanel As New Panel With {
                .BackColor = Color.White,
                .Margin = New Padding(4),
                .Dock = DockStyle.Fill,
                .Padding = New Padding(15, 10, 15, 10)
            }

            ' Left: Guest Name
            Dim lblName As New Label With {
                .Text = res.CustomerName,
                .Font = New Font("Segoe UI", 10, FontStyle.Bold),
                .ForeColor = Color.Black,
                .AutoSize = True,
                .Location = New Point(20, 20)
            }

            ' Center: Time
            Dim lblTime As New Label With {
                .Text = DateTime.Today.Add(res.EventTime).ToString("h:mm tt"),
                .Font = New Font("Segoe UI", 9, FontStyle.Regular),
                .ForeColor = Color.Black,
                .AutoSize = True,
                .Location = New Point(330, 10)
            }

            ' Center: Guests
            Dim lblGuests As New Label With {
                .Text = $"{res.NumberOfGuests} Guests",
                .Font = New Font("Segoe UI", 8, FontStyle.Regular),
                .ForeColor = Color.Gray,
                .AutoSize = True,
                .Location = New Point(330, 30)
            }

            ' Right: Status with color
            Dim statusColor As Color = Color.Gray
            Select Case res.ReservationStatus.ToLower()
                Case "confirmed"
                    statusColor = Color.FromArgb(40, 167, 69)  ' Green
                Case "pending"
                    statusColor = Color.FromArgb(255, 127, 39) ' Orange
                Case "cancelled"
                    statusColor = Color.FromArgb(220, 53, 69)  ' Red
            End Select

            Dim lblStatus As New Label With {
                .Text = res.ReservationStatus,
                .Font = New Font("Segoe UI", 10, FontStyle.Bold),
                .ForeColor = statusColor,
                .AutoSize = True,
                .Location = New Point(80, 20),
                .Anchor = AnchorStyles.Top Or AnchorStyles.Right
            }

            ' Add labels to panel
            itemPanel.Controls.Add(lblName)
            itemPanel.Controls.Add(lblTime)
            itemPanel.Controls.Add(lblGuests)
            itemPanel.Controls.Add(lblStatus)

            ' Add panel to table
            TableLayoutPanel2.Controls.Add(itemPanel)
        Next
    End Sub



    Private Sub pnlTodayReservationsPlaceholder_Paint(sender As Object, e As PaintEventArgs) Handles pnlTodayReservationsPlaceholder.Paint

    End Sub
    Private Sub CancelOrder(order As Order)
        If MessageBox.Show($"Are you sure you want to cancel Order #{order.OrderID}?", "Confirm Cancel", MessageBoxButtons.YesNo, MessageBoxIcon.Question) = DialogResult.Yes Then
            Try
                orderRepository.UpdateOrderStatus(order.OrderID, "Cancelled")
                LoadActiveOrders() ' Refresh list
            Catch ex As Exception
                MessageBox.Show($"Error cancelling order: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            End Try
        End If
    End Sub

    Private Sub dashboardTimer_Tick(sender As Object, e As EventArgs) Handles dashboardTimer.Tick
        For Each itemPanel As Control In TableLayoutPanel1.Controls
            If TypeOf itemPanel Is Panel AndAlso itemPanel.Tag IsNot Nothing Then
                Dim order As Order = TryCast(itemPanel.Tag, Order)
                If order Is Nothing Then Continue For

                Dim lblStatus As Label = itemPanel.Controls.OfType(Of Label).FirstOrDefault(Function(l) l.Name = "lblStatus")
                Dim lblCountdown As Label = itemPanel.Controls.OfType(Of Label).FirstOrDefault(Function(l) l.Name = "lblCountdown")
                Dim btnCancel As Button = itemPanel.Controls.OfType(Of Button).FirstOrDefault(Function(l) l.Name = "btnCancel")

                If lblStatus Is Nothing OrElse lblCountdown Is Nothing OrElse btnCancel Is Nothing Then Continue For

                Dim startTime As DateTime = order.OrderDate.Date + order.OrderTime
                Dim prepMinutes As Integer = If(order.PreparationTimeEstimate.HasValue, order.PreparationTimeEstimate.Value, 0)
                Dim elapsed As TimeSpan = DateTime.Now - startTime

                ' Logic
                If elapsed.TotalMinutes < prepMinutes Then
                    ' Preparing
                    Dim remaining As TimeSpan = TimeSpan.FromMinutes(prepMinutes) - elapsed
                    If remaining.TotalHours >= 1 Then
                        lblCountdown.Text = remaining.ToString("h\:mm\:ss")
                    Else
                        lblCountdown.Text = remaining.ToString("mm\:ss")
                    End If

                    If lblStatus.Text <> "Preparing" Then
                        lblStatus.Text = "Preparing"
                        lblStatus.ForeColor = Color.Orange
                        btnCancel.Enabled = True
                        If order.OrderStatus <> "Preparing" Then
                            order.OrderStatus = "Preparing"
                        End If
                    End If

                ElseIf elapsed.TotalMinutes < prepMinutes + 1.5 Then
                    ' Serving (1 min 30 sec fixed)
                    Dim servingElapsed As TimeSpan = elapsed - TimeSpan.FromMinutes(prepMinutes)
                    Dim servingRemaining As TimeSpan = TimeSpan.FromMinutes(1.5) - servingElapsed
                    
                    lblCountdown.Text = servingRemaining.ToString("h\:mm\:ss")

                    If lblStatus.Text <> "Serving" Then
                        lblStatus.Text = "Serving"
                        lblStatus.ForeColor = Color.Green

                        If order.OrderStatus <> "Serving" Then
                            order.OrderStatus = "Serving"
                            orderRepository.UpdateOrderStatus(order.OrderID, "Serving")
                        End If
                    End If
                Else
                    ' Completed
                    lblCountdown.Text = "00:00"

                    If lblStatus.Text <> "Completed" Then
                        lblStatus.Text = "Completed"
                        lblStatus.ForeColor = Color.Gray
                        btnCancel.Enabled = False

                        If order.OrderStatus <> "Completed" AndAlso order.OrderStatus <> "Served" Then
                            order.OrderStatus = "Completed"
                            orderRepository.UpdateOrderStatus(order.OrderID, "Completed")
                        End If
                    End If
                End If
            End If
        Next
    End Sub
End Class
