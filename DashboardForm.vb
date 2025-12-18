Imports System.Collections.Generic

Public Class DashboardForm
    Private orderRepository As New OrderRepository()
    Private reservationRepository As New ReservationRepository()
    Private WithEvents dashboardTimer As New Timer()
    Private Shared UpdateLock As New System.Threading.SemaphoreSlim(1, 1)

    ' Active Orders Pagination
    Private activeOrdersPage As Integer = 1
    Private activeOrdersPageSize As Integer = 50
    Private activeOrdersTotalPages As Integer = 1

    ' Reservations Pagination
    Private reservationsPage As Integer = 1
    Private reservationsPageSize As Integer = 50
    Private reservationsTotalPages As Integer = 1

    ' Controls (Active Orders)
    Private btnPrevOrders As Button
    Private btnNextOrders As Button
    Private txtPageOrders As TextBox
    Private lblTotalPagesOrders As Label

    ' Controls (Reservations)
    Private btnPrevRes As Button
    Private btnNextRes As Button
    Private txtPageRes As TextBox
    Private lblTotalPagesRes As Label

    ''' <summary>
    ''' Loads dashboard statistics when form loads
    ''' </summary>
    ''' <summary>
    ''' Loads dashboard statistics when form loads
    ''' </summary>
    Private Async Sub DashboardForm_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        dashboardTimer.Interval = 1000
        dashboardTimer.Start()

        InitializePaginationControls()

        LoadDashboardStatistics()

        ' Load critical data in parallel
        Dim taskOrders = LoadActiveOrdersAsync()
        Dim taskReservations = LoadTodayReservationsAsync()

        Await Task.WhenAll(taskOrders, taskReservations)
    End Sub

    Private Async Sub DashboardForm_VisibleChanged(sender As Object, e As EventArgs) Handles MyBase.VisibleChanged
        If Me.Visible AndAlso Not Me.Disposing Then
            LoadDashboardStatistics()
            Dim taskOrders = LoadActiveOrdersAsync()
            Dim taskReservations = LoadTodayReservationsAsync()
            Await Task.WhenAll(taskOrders, taskReservations)
        End If
    End Sub

    Private Sub InitializePaginationControls()
        ' Active Orders Pagination Controls
        Dim pnlOrdersPager As New Panel With {
            .Height = 40,
            .Dock = DockStyle.Bottom,
            .BackColor = Color.White
        }

        btnPrevOrders = CreatePaginationButton("<", 10, 5)
        AddHandler btnPrevOrders.Click, AddressOf btnPrevOrders_Click

        btnNextOrders = CreatePaginationButton(">", 160, 5)
        AddHandler btnNextOrders.Click, AddressOf btnNextOrders_Click

        txtPageOrders = New TextBox With {
            .Text = "1",
            .Size = New Size(40, 25),
            .TextAlign = HorizontalAlignment.Center,
            .Font = New Font("Segoe UI", 9),
            .Location = New Point(60, 8)
        }
        AddHandler txtPageOrders.KeyDown, AddressOf txtPageOrders_KeyDown
        AddHandler txtPageOrders.Leave, Sub(s, ev) ValidateAndJumpOrders()

        lblTotalPagesOrders = New Label With {
            .Text = "/ 1",
            .AutoSize = False,
            .Size = New Size(50, 30),
            .TextAlign = ContentAlignment.MiddleLeft,
            .Location = New Point(105, 5),
            .Font = New Font("Segoe UI", 9)
        }

        pnlOrdersPager.Controls.AddRange({btnPrevOrders, btnNextOrders, txtPageOrders, lblTotalPagesOrders})

        ' Add to pnlActiveOrders (fixed at bottom) and adjust placeholder
        If pnlTodayOrders IsNot Nothing Then
            pnlTodayOrders.Controls.Add(pnlOrdersPager)
            pnlOrdersPager.BringToFront()

            ' Hide static template controls in placeholder
            Label1.Visible = False
            Label2.Visible = False
            Label3.Visible = False
            Label4.Visible = False
            Label5.Visible = False
            Label10.Visible = False
            btn.Visible = False
            Button1.Visible = False
            Panel20.Visible = False

            ' Reduce placeholder height to accommodate the pager
            pnlActiveOrdersPlaceholder.Height -= pnlOrdersPager.Height
        End If

        ' Reservations Pagination Controls
        Dim pnlResPager As New Panel With {
            .Height = 40,
            .Dock = DockStyle.Bottom,
            .BackColor = Color.White
        }

        btnPrevRes = CreatePaginationButton("<", 10, 5)
        AddHandler btnPrevRes.Click, AddressOf btnPrevRes_Click

        btnNextRes = CreatePaginationButton(">", 160, 5)
        AddHandler btnNextRes.Click, AddressOf btnNextRes_Click

        txtPageRes = New TextBox With {
            .Text = "1",
            .Size = New Size(40, 25),
            .TextAlign = HorizontalAlignment.Center,
            .Font = New Font("Segoe UI", 9),
            .Location = New Point(60, 8)
        }
        AddHandler txtPageRes.KeyDown, AddressOf txtPageRes_KeyDown
        AddHandler txtPageRes.Leave, Sub(s, ev) ValidateAndJumpReservations()

        lblTotalPagesRes = New Label With {
            .Text = "/ 1",
            .AutoSize = False,
            .Size = New Size(50, 30),
            .TextAlign = ContentAlignment.MiddleLeft,
            .Location = New Point(105, 5),
            .Font = New Font("Segoe UI", 9)
        }

        pnlResPager.Controls.AddRange({btnPrevRes, btnNextRes, txtPageRes, lblTotalPagesRes})

        If pnlTodayReservations IsNot Nothing Then
            pnlTodayReservations.Controls.Add(pnlResPager)
            pnlResPager.BringToFront()

            ' Hide static template controls in placeholder
            If TableLayoutPanel2 IsNot Nothing Then TableLayoutPanel2.Visible = False
            If Panel7 IsNot Nothing Then Panel7.Visible = False
            If LblTime IsNot Nothing Then LblTime.Visible = False
            If Button4 IsNot Nothing Then Button4.Visible = False
            If lblGuest IsNot Nothing Then lblGuest.Visible = False
            If Button5 IsNot Nothing Then Button5.Visible = False
            If lblName IsNot Nothing Then lblName.Visible = False

            ' Reduce placeholder height to accommodate the pager
            pnlTodayReservationsPlaceholder.Height -= pnlResPager.Height
        End If
    End Sub

    Private Function CreatePaginationButton(text As String, x As Integer, y As Integer) As Button
        Return New Button With {
            .Text = text,
            .Location = New Point(x, y),
            .Size = New Size(40, 30),
            .FlatStyle = FlatStyle.Flat,
            .BackColor = Color.WhiteSmoke
        }
    End Function

    ''' <summary>
    ''' Loads and displays dashboard statistics (orders, reservations, feedback counts)
    ''' </summary>
    ''' <summary>
    ''' Loads and displays dashboard statistics (orders, reservations, feedback counts)
    ''' </summary>
    Private Async Function LoadDashboardStatisticsAsync() As Task
        Try
            Dim todayOrdersCount As Integer
            Dim todayReservationsCount As Integer

            ' Run DB calls in background
            Await Task.Run(Sub()
                               todayOrdersCount = orderRepository.GetTodayOrdersCount()
                               todayReservationsCount = reservationRepository.GetTodayReservationsCount()
                           End Sub)

            ' Update UI
            lblCardOrdersValue.Text = todayOrdersCount.ToString()
            lblCardReservationsValue.Text = todayReservationsCount.ToString()

            ' Load current time
            Dim currentTime As String = DateTime.Now.ToString("h:mm tt")
            lblCardTimeValue.Text = currentTime

        Catch ex As Exception
            Console.WriteLine($"Error loading dashboard statistics: {ex.Message}")
        End Try
    End Function

    Private Async Sub LoadDashboardStatistics()
        ' Legacy wrapper or Event Handler variant
        Await LoadDashboardStatisticsAsync()
    End Sub

    ''' <summary>
    ''' Loads active orders (Buffered - All)
    ''' </summary>
    ' Buffer for client-side pagination
    Private allActiveOrders As New List(Of Order)()

    ''' <summary>
    ''' Loads active orders (Buffered - All)
    ''' </summary>
    Private Async Function LoadActiveOrdersAsync() As Task
        Try
            ' Load ALL active orders into buffer (Async)
            allActiveOrders = Await orderRepository.GetActiveOrdersPagedAsync(0, 0)

            ' Calculate pagination
            Dim count As Integer = allActiveOrders.Count
            activeOrdersTotalPages = Math.Max(1, CInt(Math.Ceiling(count / activeOrdersPageSize)))

            If activeOrdersPage > activeOrdersTotalPages Then activeOrdersPage = activeOrdersTotalPages
            If activeOrdersPage < 1 Then activeOrdersPage = 1

            DisplayActiveOrdersPage()

            ' Show pagination controls if needed
            If txtPageOrders IsNot Nothing AndAlso txtPageOrders.Parent IsNot Nothing Then
                Dim pnlPager As Control = txtPageOrders.Parent
                pnlPager.Visible = True
            End If

        Catch ex As Exception
            Console.WriteLine($"Error loading active orders: {ex.Message}")
        End Try
    End Function

    ''' <summary>
    ''' Public method to refresh active orders from external forms
    ''' </summary>
    Public Async Sub RefreshActiveOrders()
        Await LoadActiveOrdersAsync()
    End Sub

    Private Sub DisplayActiveOrdersPage()
        Dim pageData = allActiveOrders.Skip((activeOrdersPage - 1) * activeOrdersPageSize).Take(activeOrdersPageSize).ToList()
        DisplayActiveOrders(pageData)
        UpdateActiveOrdersControls()
    End Sub



    Private Sub UpdateActiveOrdersControls()
        If txtPageOrders IsNot Nothing Then
            txtPageOrders.Text = activeOrdersPage.ToString()
            lblTotalPagesOrders.Text = $"/ {activeOrdersTotalPages}"
            btnPrevOrders.Enabled = (activeOrdersPage > 1)
            btnNextOrders.Enabled = (activeOrdersPage < activeOrdersTotalPages)
        End If
    End Sub

    Private Sub txtPageOrders_KeyDown(sender As Object, e As KeyEventArgs)
        If e.KeyCode = Keys.Enter Then
            e.SuppressKeyPress = True
            e.Handled = True
            ValidateAndJumpOrders()
        End If
    End Sub

    Private Sub ValidateAndJumpOrders()
        Dim newPage As Integer
        If Integer.TryParse(txtPageOrders.Text, newPage) Then
            If newPage < 1 Then newPage = 1
            If newPage > activeOrdersTotalPages Then newPage = activeOrdersTotalPages

            If newPage <> activeOrdersPage Then
                activeOrdersPage = newPage
                DisplayActiveOrdersPage()
            Else
                txtPageOrders.Text = activeOrdersPage.ToString()
            End If
        Else
            txtPageOrders.Text = activeOrdersPage.ToString()
        End If
    End Sub

    Private Sub btnPrevOrders_Click(sender As Object, e As EventArgs)
        If activeOrdersPage > 1 Then
            activeOrdersPage -= 1
            DisplayActiveOrdersPage()
        End If
    End Sub

    Private Sub btnNextOrders_Click(sender As Object, e As EventArgs)
        If activeOrdersPage < activeOrdersTotalPages Then
            activeOrdersPage += 1
            DisplayActiveOrdersPage()
        End If
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
        TableLayoutPanel1.Dock = DockStyle.Top
        TableLayoutPanel1.AutoSize = True
        TableLayoutPanel1.AutoSizeMode = AutoSizeMode.GrowAndShrink

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
            TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Absolute, 70.0F)) ' Match user's 70px preference

            ' Parent panel for each order
            Dim itemPanel As New Panel With {
                .BackColor = Color.White,
                .Margin = New Padding(0),
                .Dock = DockStyle.Fill,
                .Tag = order
            }

            ' Order ID - Vertically Centered (70-28)/2 = 21
            Dim lblID As New Label With {
                .Text = $"#{order.OrderID}",
                .Font = New Font("Segoe UI", 10, FontStyle.Bold),
                .ForeColor = Color.Black,
                .AutoSize = True,
                .Location = New Point(16, 21),
                .TextAlign = ContentAlignment.MiddleLeft
            }

            ' Time/Type Stack - Centered (70-35)/2 = 17
            Dim lblTime As New Label With {
                .Text = DateTime.Today.Add(order.OrderTime).ToString("h:mm tt"),
                .Font = New Font("Segoe UI", 8.5, FontStyle.Regular),
                .ForeColor = Color.Black,
                .AutoSize = True,
                .Location = New Point(120, 15)
            }

            Dim lblType As New Label With {
                .Text = order.OrderType,
                .Font = New Font("Segoe UI", 8.5, FontStyle.Regular),
                .ForeColor = Color.DimGray,
                .AutoSize = True,
                .Location = New Point(120, 35)
            }

            ' Prep Time Label (Static) - Displaying like Designer (ex. 15mins)
            Dim prepMinutes As Integer = If(order.PreparationTimeEstimate.HasValue, order.PreparationTimeEstimate.Value, 15)

            Dim lblPrepTime As New Label With {
                .Name = "lblPrepTime",
                .Text = $"{prepMinutes}mins",
                .Font = New Font("Segoe UI", 10),
                .ForeColor = Color.Black,
                .AutoSize = True,
                .Location = New Point(210, 23)
            }

            ' Action Buttons - Vertically Centered (70-35)/2 = 17
            Dim orangeColor As Color = Color.FromArgb(255, 127, 39)
            Dim greenColor As Color = Color.FromArgb(40, 167, 69)
            Dim redColor As Color = Color.FromArgb(220, 53, 69)

            Dim btnComplete As New Button With {
                .Name = "btnComplete",
                .FlatStyle = FlatStyle.Flat,
                .Font = New Font("Segoe UI", 9, FontStyle.Bold),
                .Size = New Size(116, 35),
                .Location = New Point(330, 17),
                .BackColor = Color.WhiteSmoke
            }
            btnComplete.FlatAppearance.BorderSize = 1

            If order.OrderStatus = "Completed" Then
                btnComplete.Text = "Completed"
                btnComplete.BackColor = greenColor
                btnComplete.ForeColor = Color.White
                btnComplete.Enabled = False
            ElseIf order.OrderStatus = "Cancelled" Then
                btnComplete.Text = "Complete"
                btnComplete.ForeColor = Color.Gray
                btnComplete.FlatAppearance.BorderColor = Color.LightGray
                btnComplete.Enabled = False
            Else
                btnComplete.Text = "Complete"
                btnComplete.ForeColor = greenColor
                btnComplete.FlatAppearance.BorderColor = greenColor
                AddHandler btnComplete.Click, Sub(s, ev) CompleteOrder(order)
            End If

            Dim btnCancel As New Button With {
                .Name = "btnCancel",
                .FlatStyle = FlatStyle.Flat,
                .Font = New Font("Segoe UI", 9, FontStyle.Bold),
                .Size = New Size(100, 35),
                .Location = New Point(460, 17),
                .BackColor = Color.WhiteSmoke
            }
            btnCancel.FlatAppearance.BorderSize = 1

            If order.OrderStatus = "Completed" Then
                Dim btnViewOrder As New Button With {
                   .Text = "View Order",
                   .FlatStyle = FlatStyle.Flat,
                   .Font = New Font("Segoe UI", 9, FontStyle.Bold),
                   .Size = New Size(100, 35),
                   .Location = New Point(460, 17),
                   .BackColor = Color.WhiteSmoke,
                   .ForeColor = Color.SteelBlue
               }
                btnViewOrder.FlatAppearance.BorderColor = Color.SteelBlue
                AddHandler btnViewOrder.Click, Sub(s, ev)
                                                   Try
                                                       Dim items As List(Of OrderItem) = orderRepository.GetOrderItems(order.OrderID)
                                                       Dim viewForm As New ViewOrderPOSForms(order.OrderID, order.OrderID.ToString(), order.CustomerName, items, order.TotalAmount)
                                                       viewForm.ShowDialog()
                                                   Catch ex As Exception
                                                       MessageBox.Show($"Error viewing order: {ex.Message}", "Error")
                                                   End Try
                                               End Sub
                itemPanel.Controls.Add(btnViewOrder)
            Else
                ' Logic for Cancel Button (using the already defined btnCancel)
                If order.OrderStatus = "Cancelled" Then
                    btnCancel.Text = "Cancelled"
                    btnCancel.BackColor = redColor
                    btnCancel.ForeColor = Color.White
                    btnCancel.Enabled = False
                Else
                    btnCancel.Text = "Cancel"
                    btnCancel.ForeColor = redColor
                    btnCancel.FlatAppearance.BorderColor = redColor
                    AddHandler btnCancel.Click, Sub(s, ev) CancelOrder(order)
                End If
                itemPanel.Controls.Add(btnCancel)
            End If

            ' Amount - Vertically Centered (70-28)/2 = 21
            Dim lblAmount As New Label With {
                .Text = $"₱{order.TotalAmount:F2}",
                .Font = New Font("Segoe UI", 10, FontStyle.Bold),
                .ForeColor = orangeColor,
                .AutoSize = False,
                .Size = New Size(120, 35),
                .Location = New Point(580, 20),
                .TextAlign = ContentAlignment.MiddleRight
            }

            ' Status Label
            Dim lblStatus As New Label With {
                .Name = "lblStatus",
                .Text = order.OrderStatus,
                .Visible = False
            }

            ' Add controls to panel (Removed divider as TableLayoutPanel provides border)
            itemPanel.Controls.AddRange({lblID, lblStatus, lblTime, lblType, lblPrepTime, btnComplete, lblAmount})

            ' Add final panel to list
            TableLayoutPanel1.Controls.Add(itemPanel)
        Next
    End Sub

    Private Async Sub CompleteOrder(order As Order)
        If MessageBox.Show($"Are you sure you want to mark Order #{order.OrderID} as Completed?", "Confirm Complete", MessageBoxButtons.YesNo, MessageBoxIcon.Question) = DialogResult.Yes Then
            Try
                orderRepository.UpdateOrderStatus(order.OrderID, "Completed")
                Await LoadActiveOrdersAsync() ' Refresh list
            Catch ex As Exception
                MessageBox.Show($"Error completing order: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            End Try
        End If
    End Sub


    ''' <summary>
    ''' Loads today's reservations and displays them in the reservations panel
    ''' </summary>
    ''' <summary>
    ''' Loads today's reservations and displays them in the reservations panel
    ''' </summary>
    ' Buffer for client-side pagination (Reservations)
    Private allTodayReservations As New List(Of Reservation)()

    Private Async Function LoadTodayReservationsAsync() As Task
        Try
            ' Load ALL today's reservations into buffer (Async)
            allTodayReservations = Await reservationRepository.GetTodayReservationsPagedAsync(0, 0)

            ' Calculate pagination
            Dim count As Integer = allTodayReservations.Count
            reservationsTotalPages = Math.Max(1, CInt(Math.Ceiling(count / reservationsPageSize)))

            If reservationsPage > reservationsTotalPages Then reservationsPage = reservationsTotalPages
            If reservationsPage < 1 Then reservationsPage = 1

            DisplayTodayReservationsPage()

            ' Show pagination controls
            If txtPageRes IsNot Nothing AndAlso txtPageRes.Parent IsNot Nothing Then
                Dim pnlPager As Control = txtPageRes.Parent
                pnlPager.Visible = True
            End If

        Catch ex As Exception
            Console.WriteLine($"Error loading reservations: {ex.Message}")
        End Try
    End Function

    Private Sub DisplayTodayReservationsPage()
        Dim pageData = allTodayReservations.Skip((reservationsPage - 1) * reservationsPageSize).Take(reservationsPageSize).ToList()
        DisplayTodayReservations(pageData)
        UpdateReservationsControls()
    End Sub



    Private Sub UpdateReservationsControls()
        If txtPageRes IsNot Nothing Then
            txtPageRes.Text = reservationsPage.ToString()
            lblTotalPagesRes.Text = $"/ {reservationsTotalPages}"
            btnPrevRes.Enabled = (reservationsPage > 1)
            btnNextRes.Enabled = (reservationsPage < reservationsTotalPages)
        End If
    End Sub

    Private Sub txtPageRes_KeyDown(sender As Object, e As KeyEventArgs)
        If e.KeyCode = Keys.Enter Then
            e.SuppressKeyPress = True
            e.Handled = True
            ValidateAndJumpReservations()
        End If
    End Sub

    Private Sub ValidateAndJumpReservations()
        Dim newPage As Integer
        If Integer.TryParse(txtPageRes.Text, newPage) Then
            If newPage < 1 Then newPage = 1
            If newPage > reservationsTotalPages Then newPage = reservationsTotalPages

            If newPage <> reservationsPage Then
                reservationsPage = newPage
                DisplayTodayReservationsPage()
            Else
                txtPageRes.Text = reservationsPage.ToString()
            End If
        Else
            txtPageRes.Text = reservationsPage.ToString()
        End If
    End Sub

    Private Sub btnPrevRes_Click(sender As Object, e As EventArgs)
        If reservationsPage > 1 Then
            reservationsPage -= 1
            DisplayTodayReservationsPage()
        End If
    End Sub

    Private Sub btnNextRes_Click(sender As Object, e As EventArgs)
        If reservationsPage < reservationsTotalPages Then
            reservationsPage += 1
            DisplayTodayReservationsPage()
        End If
    End Sub

    Private Sub DisplayTodayReservations(reservations As List(Of Reservation))
        pnlTodayReservationsPlaceholder.SuspendLayout()
        pnlTodayReservationsPlaceholder.Controls.Clear()

        If reservations.Count = 0 Then
            Dim lblEmpty As New Label With {
                .Text = "No reservations today",
                .Dock = DockStyle.Fill,
                .TextAlign = ContentAlignment.MiddleCenter,
                .Font = New Font("Segoe UI", 10, FontStyle.Italic),
                .ForeColor = Color.Gray
            }
            pnlTodayReservationsPlaceholder.Controls.Add(lblEmpty)
            pnlTodayReservationsPlaceholder.ResumeLayout()
            Return
        End If

        Try
            ' Create a TableLayoutPanel for consistent list layout (like Orders)
            Dim tlpReservations As New TableLayoutPanel With {
                .ColumnCount = 1,
                .Dock = DockStyle.Top,
                .AutoSize = True,
                .AutoSizeMode = AutoSizeMode.GrowAndShrink,
                .Padding = New Padding(0)
            }
            tlpReservations.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100.0F))

            For Each res In reservations
                tlpReservations.RowCount += 1
                tlpReservations.RowStyles.Add(New RowStyle(SizeType.Absolute, 70.0F))

                ' Parent panel for each reservation (matching Orders itemPanel)
                Dim itemPanel As New Panel With {
                    .BackColor = Color.White,
                    .Margin = New Padding(0),
                    .Dock = DockStyle.Fill,
                    .Tag = res
                }

                ' Border line at bottom
                Dim line As New Panel With {
                    .Height = 1,
                    .BackColor = Color.Gray,
                    .Dock = DockStyle.Bottom
                }
                itemPanel.Controls.Add(line)

                ' Customer Name (Matches Order ID/Name positioning)
                Dim lblName As New Label With {
                    .Text = res.CustomerName,
                    .Font = New Font("Segoe UI", 10, FontStyle.Bold),
                    .ForeColor = Color.Black,
                    .AutoSize = True,
                    .Location = New Point(16, 21),
                    .TextAlign = ContentAlignment.MiddleLeft
                }

                ' Time/Type - Centered style
                Dim lblTime As New Label With {
                    .Text = DateTime.Today.Add(res.EventTime).ToString("h:mm tt"),
                    .Font = New Font("Segoe UI", 8.5, FontStyle.Regular),
                    .ForeColor = Color.Black,
                    .AutoSize = True,
                    .Location = New Point(280, 15)
                }

                Dim lblGuests As New Label With {
                    .Text = $"{res.NumberOfGuests} Guests",
                    .Font = New Font("Segoe UI", 8.5, FontStyle.Regular),
                    .ForeColor = Color.DimGray,
                    .AutoSize = True,
                    .Location = New Point(280, 35)
                }

                ' Action Buttons - Vertically Centered (70-35)/2 = 17
                Dim greenColor As Color = Color.FromArgb(40, 167, 69)
                Dim redColor As Color = Color.FromArgb(220, 53, 69)

                ' Complete Button
                Dim btnComplete As New Button With {
                    .Name = "btnComplete",
                    .FlatStyle = FlatStyle.Flat,
                    .Font = New Font("Segoe UI", 9, FontStyle.Bold),
                    .Size = New Size(116, 35),
                    .Location = New Point(480, 17),
                    .BackColor = Color.WhiteSmoke
                }
                btnComplete.FlatAppearance.BorderSize = 1

                ' Cancel Button
                Dim btnCancel As New Button With {
                    .Name = "btnCancel",
                    .FlatStyle = FlatStyle.Flat,
                    .Font = New Font("Segoe UI", 9, FontStyle.Bold),
                    .Size = New Size(100, 35),
                    .Location = New Point(610, 17),
                    .BackColor = Color.WhiteSmoke
                }
                btnCancel.FlatAppearance.BorderSize = 1

                ' logic for buttons
                If res.ReservationStatus = "Completed" Then
                    btnComplete.Text = "Completed"
                    btnComplete.BackColor = greenColor
                    btnComplete.ForeColor = Color.White
                    btnComplete.Enabled = False

                    btnCancel.Text = "View Info"
                    btnCancel.ForeColor = Color.SteelBlue
                    btnCancel.FlatAppearance.BorderColor = Color.SteelBlue
                    AddHandler btnCancel.Click, Sub(s, ev)
                                                    Dim infoForm As New ViewReservationInfoForm(res)
                                                    infoForm.ShowDialog()
                                                End Sub
                ElseIf res.ReservationStatus = "Cancelled" Then
                    btnComplete.Enabled = False
                    btnCancel.Text = "Cancelled"
                    btnCancel.BackColor = redColor
                    btnCancel.ForeColor = Color.White
                    btnCancel.Enabled = False
                Else
                    ' Active
                    btnComplete.Text = "Complete"
                    btnComplete.ForeColor = greenColor
                    btnComplete.FlatAppearance.BorderColor = greenColor
                    AddHandler btnComplete.Click, Sub(s, ev) UpdateReservation(res, "Completed")

                    btnCancel.Text = "Cancel"
                    btnCancel.ForeColor = redColor
                    btnCancel.FlatAppearance.BorderColor = redColor
                    AddHandler btnCancel.Click, Sub(s, ev) UpdateReservation(res, "Cancelled")
                End If

                itemPanel.Controls.AddRange({lblName, lblTime, lblGuests, btnComplete, btnCancel})
                tlpReservations.Controls.Add(itemPanel)
            Next

            pnlTodayReservationsPlaceholder.Controls.Add(tlpReservations)
            pnlTodayReservationsPlaceholder.ResumeLayout()
        Catch ex As Exception
            MessageBox.Show($"Error displaying reservations: {ex.Message}", "Display Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    ' Helper to update reservation status (if not exists, we add it)
    Private Async Sub UpdateReservation(res As Reservation, newStatus As String)
        If MessageBox.Show($"Are you sure you want to mark reservation as {newStatus}?", "Confirm", MessageBoxButtons.YesNo, MessageBoxIcon.Question) = DialogResult.Yes Then
            Try
                Await Task.Run(Sub() reservationRepository.UpdateReservationStatus(res.ReservationID, newStatus, True))
                Await LoadTodayReservationsAsync()
            Catch ex As Exception
                MessageBox.Show($"Error: {ex.Message}")
            End Try
        End If
    End Sub



    Private Sub pnlTodayReservationsPlaceholder_Paint(sender As Object, e As PaintEventArgs) Handles pnlTodayReservationsPlaceholder.Paint

    End Sub
    Private Async Sub CancelOrder(order As Order)
        If MessageBox.Show($"Are you sure you want to cancel Order #{order.OrderID}?", "Confirm Cancel", MessageBoxButtons.YesNo, MessageBoxIcon.Question) = DialogResult.Yes Then
            Try
                orderRepository.UpdateOrderStatus(order.OrderID, "Cancelled")
                Await LoadActiveOrdersAsync() ' Refresh list
            Catch ex As Exception
                MessageBox.Show($"Error cancelling order: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            End Try
        End If
    End Sub

    Private Async Sub dashboardTimer_Tick(sender As Object, e As EventArgs) Handles dashboardTimer.Tick
        ' Prevent overlapping execution of heavy timer logic
        If UpdateLock.CurrentCount = 0 Then Exit Sub

        Try
            Await UpdateLock.WaitAsync()
            ' Order Timers logic removed as per user request (static prep time)


            ' Handle Reservation Timers (TableLayoutPanel2)
            For Each itemPanel As Control In TableLayoutPanel2.Controls
                If TypeOf itemPanel Is Panel AndAlso itemPanel.Tag IsNot Nothing Then
                    Dim reservation As Reservation = TryCast(itemPanel.Tag, Reservation)
                    If reservation Is Nothing Then Continue For

                    Dim lblStatus As Label = itemPanel.Controls.OfType(Of Label).FirstOrDefault(Function(l) l.Name = "lblStatus")
                    Dim lblCountdown As Label = itemPanel.Controls.OfType(Of Label).FirstOrDefault(Function(l) l.Name = "lblCountdown")

                    If lblStatus Is Nothing OrElse lblCountdown Is Nothing Then Continue For

                    ' Calculate times
                    Dim eventDateTime As DateTime = DateTime.Today.Add(reservation.EventTime)
                    Dim prepMinutes As Integer = If(reservation.PrepTime > 0, reservation.PrepTime, 15) ' Default 15 if no prep time
                    Dim startTime As DateTime = eventDateTime.AddMinutes(-prepMinutes)
                    Dim now As DateTime = DateTime.Now

                    ' Timer logic
                    If now < startTime Then
                        ' Before prep should start - show waiting time
                        Dim waitTime As TimeSpan = startTime - now
                        lblCountdown.Text = String.Format("Starts in {0:mm\:ss}", waitTime)
                        lblCountdown.ForeColor = Color.Gray
                    ElseIf now >= startTime AndAlso now < eventDateTime Then
                        ' During prep - countdown to event time
                        Dim remaining As TimeSpan = eventDateTime - now
                        If remaining.TotalHours >= 1 Then
                            lblCountdown.Text = String.Format("{0:h\:mm\:ss}", remaining)
                        Else
                            lblCountdown.Text = String.Format("{0:mm\:ss}", remaining)
                        End If
                        lblCountdown.ForeColor = Color.Orange
                        lblStatus.ForeColor = Color.Orange
                    Else
                        ' Event time reached or passed - mark as completed
                        lblCountdown.Text = "Completed"
                        lblCountdown.ForeColor = Color.Gray

                        ' Auto-update status to Completed if not already
                        If lblStatus.Text <> "Completed" Then
                            lblStatus.Text = "Completed"
                            lblStatus.ForeColor = Color.Gray

                            ' Update database status
                            If reservation.ReservationStatus <> "Completed" Then
                                reservation.ReservationStatus = "Completed"
                                Dim resId = reservation.ReservationID
                                Await Task.Run(Sub() reservationRepository.UpdateReservationStatus(resId, "Completed", True))
                            End If
                        End If
                    End If
                End If
            Next
        Finally
            UpdateLock.Release()
        End Try
    End Sub

    Private Sub Label1_Click(sender As Object, e As EventArgs) Handles Label1.Click

    End Sub

    Private Sub tlpRoot_Paint(sender As Object, e As PaintEventArgs) Handles tlpRoot.Paint

    End Sub

    Private Sub pnlActiveOrdersPlaceholder_Paint(sender As Object, e As PaintEventArgs) Handles pnlActiveOrdersPlaceholder.Paint

    End Sub

    Private Sub Label5_Click(sender As Object, e As EventArgs) Handles Label5.Click

    End Sub
End Class
