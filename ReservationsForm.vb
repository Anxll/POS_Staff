Imports System.Collections.Generic
Imports System.Reflection
Imports System.Threading.Tasks
Imports System.Text

Public Class ReservationsForm
    Private reservationRepository As New ReservationRepository()
    Private isLoading As Boolean = False
    
    ' Pagination variables
    Private currentPage As Integer = 1
    Private pageSize As Integer = 100 ' Updated to 100
    Private totalPages As Integer = 1
    Private totalRecords As Integer = 0
    
    ' Pagination controls
    Private pnlPagination As Panel
    Private btnPrevPage As Button
    Private btnNextPage As Button
    Private txtPageNumber As TextBox
    Private lblTotalPages As Label

    Private Async Sub ReservationsForm_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        ' Enable double buffering for smoother scrolling
        GetType(Control).GetProperty("DoubleBuffered", BindingFlags.NonPublic Or BindingFlags.Instance).SetValue(Panel1, True, Nothing)

        ' Hide the template
        ResTemplate.Visible = False
        
        ' Initialize pagination controls
        InitializePaginationControls()
        
        ' Load asynchronously
        Await LoadReservationsAsync()
    End Sub

    Private Sub InitializePaginationControls()
        ' Create pagination panel
        pnlPagination = New Panel With {
            .Height = 50,
            .Dock = DockStyle.Bottom,
            .BackColor = Color.WhiteSmoke
        }
        
        ' Previous Button
        btnPrevPage = New Button With {
            .Text = "< Previous",
            .Size = New Size(100, 35),
            .Location = New Point(20, 8),
            .BackColor = Color.White,
            .FlatStyle = FlatStyle.Flat,
            .Font = New Font("Segoe UI", 9)
        }
        AddHandler btnPrevPage.Click, AddressOf btnPrevPage_Click
        
        ' Next Button
        btnNextPage = New Button With {
            .Text = "Next >",
            .Size = New Size(100, 35),
            .Location = New Point(pnlPagination.Width - 140, 8), ' Initial guess
            .BackColor = Color.White,
            .FlatStyle = FlatStyle.Flat,
            .Font = New Font("Segoe UI", 9)
        }
        AddHandler btnNextPage.Click, AddressOf btnNextPage_Click
        
        ' Page Number TextBox (Editable)
        txtPageNumber = New TextBox With {
            .Text = "1",
            .Size = New Size(50, 25),
            .TextAlign = HorizontalAlignment.Center,
            .Font = New Font("Segoe UI", 10),
            .Location = New Point((pnlPagination.Width - 120) \ 2, 8)
        }
        AddHandler txtPageNumber.KeyDown, AddressOf txtPageNumber_KeyDown
        AddHandler txtPageNumber.Leave, Sub(s, ev) ValidateAndJumpToPage()

        ' Total Pages Label
        lblTotalPages = New Label With {
            .Text = "of 1",
            .AutoSize = False,
            .Size = New Size(70, 25),
            .TextAlign = ContentAlignment.MiddleLeft,
            .Font = New Font("Segoe UI", 10, FontStyle.Bold),
            .Location = New Point(txtPageNumber.Right + 5, 8)
        }
        
        ' Add Resize Handler to keep buttons in place
        AddHandler pnlPagination.Resize, Sub(s, ev)
                                             btnNextPage.Location = New Point(pnlPagination.Width - 120, 8)
                                             txtPageNumber.Location = New Point((pnlPagination.Width - 120) \ 2, 8)
                                             lblTotalPages.Location = New Point(txtPageNumber.Right + 5, 8)
                                         End Sub
        
        pnlPagination.Controls.AddRange({btnPrevPage, btnNextPage, txtPageNumber, lblTotalPages})
        Me.Controls.Add(pnlPagination)
        pnlPagination.BringToFront()
        
        ' Adjust Panel1 to not overlap with pagination
        Panel1.Height -= pnlPagination.Height
    End Sub

    ' Database-level pagination - NO client-side buffer
    
    Private Async Function LoadReservationsAsync() As Task
        If isLoading Then Return
        isLoading = True
        
        Try
            ' Get total count first (fast query)
            Await Task.Run(Sub()
                               totalRecords = reservationRepository.GetTotalReservationsCount()
                           End Sub)
            
            ' Calculate pagination
            totalPages = Math.Max(1, CInt(Math.Ceiling(totalRecords / pageSize)))
            
            If currentPage > totalPages Then currentPage = totalPages
            If currentPage < 1 Then currentPage = 1
            
            ' Load only current page from database
            Await LoadCurrentPageFromDatabase()
            
            ' Show pagination controls
            If pnlPagination IsNot Nothing Then pnlPagination.Visible = True
            
        Catch ex As Exception
            MessageBox.Show($"Error loading reservations: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            isLoading = False
        End Try
    End Function
    
    Private Async Function LoadCurrentPageFromDatabase() As Task
        Dim offset As Integer = (currentPage - 1) * pageSize
        Dim pageData As List(Of Reservation) = Nothing
        
        Await Task.Run(Sub()
                           pageData = reservationRepository.GetAllReservationsPaged(pageSize, offset)
                       End Sub)
        
        DisplayReservations(pageData)
        UpdatePaginationControls()
    End Function

    Private Async Sub DisplayCurrentPage()
        ' Load current page from database
        Await LoadCurrentPageFromDatabase()
    End Sub

    Private Sub UpdatePaginationControls()
        If txtPageNumber IsNot Nothing Then
            txtPageNumber.Text = currentPage.ToString()
            lblTotalPages.Text = $"of {totalPages}"
            btnPrevPage.Enabled = (currentPage > 1)
            btnNextPage.Enabled = (currentPage < totalPages)
        End If
    End Sub

    Private Sub txtPageNumber_KeyDown(sender As Object, e As KeyEventArgs)
        If e.KeyCode = Keys.Enter Then
            ' Prevent beep sound
            e.SuppressKeyPress = True
            e.Handled = True
            ValidateAndJumpToPage()
        End If
    End Sub

    Private Sub ValidateAndJumpToPage()
        Dim newPage As Integer
        If Integer.TryParse(txtPageNumber.Text, newPage) Then
            If newPage < 1 Then newPage = 1
            If newPage > totalPages Then newPage = totalPages
            
            If newPage <> currentPage Then
                currentPage = newPage
                DisplayCurrentPage()
            Else
                txtPageNumber.Text = currentPage.ToString()
            End If
        Else
            txtPageNumber.Text = currentPage.ToString()
        End If
    End Sub
    
    Private Sub btnPrevPage_Click(sender As Object, e As EventArgs)
        If currentPage > 1 Then
            currentPage -= 1
            DisplayCurrentPage()
        End If
    End Sub

    Private Sub btnNextPage_Click(sender As Object, e As EventArgs)
        If currentPage < totalPages Then
            currentPage += 1
            DisplayCurrentPage()
        End If
    End Sub

    Private Async Sub LoadReservations()
        ' Legacy method kept for compatibility if needed, but redirects to async
        Await LoadReservationsAsync()
    End Sub

    Private Sub DisplayReservations(reservations As List(Of Reservation))
        ' Panel2 is the scrollable content area for cards
        ' Panel1 is the fixed header with buttons (managed by Designer)
        
        ' Keep only the template
        Dim controlsKeep As New List(Of Control)
        For Each ctrl As Control In Panel2.Controls
            If ctrl Is ResTemplate Then
                controlsKeep.Add(ctrl)
            End If
        Next

        Panel2.Controls.Clear()

        ' Re-add template
        For Each ctrl In controlsKeep
            Panel2.Controls.Add(ctrl)
        Next

        Dim xPos As Integer = 38
        Dim yPos As Integer = 20  ' Start closer to top since Panel2 is just for cards
        Dim colCount As Integer = 0
        Dim maxCols As Integer = 3 ' Adjust based on screen width

        For Each res As Reservation In reservations
            Dim panel As Panel = CreateReservationPanel(res)
            panel.Location = New Point(xPos, yPos)
            Panel2.Controls.Add(panel)

            colCount += 1
            If colCount >= maxCols Then
                colCount = 0
                xPos = 38
                yPos += 370 ' Height + Margin
            Else
                xPos += 455 ' Width + Margin
            End If
        Next
    End Sub

    Private Function CreateReservationPanel(res As Reservation) As Panel
        ' Clone the ResTemplate panel
        Dim panel As New Panel With {
            .Size = ResTemplate.Size,
            .BackColor = ResTemplate.BackColor,
            .BorderStyle = ResTemplate.BorderStyle
        }

        ' Clone and populate labels from template
        Dim lblName As Label = CloneLabel(lblName2)
        ' Show FullName if available, otherwise show CustomerName from customers table
        lblName.Text = If(String.IsNullOrEmpty(res.FullName), res.CustomerName, res.FullName)

        Dim lblCode As Label = CloneLabel(lblCode2)
        lblCode.Text = $"RES-{res.ReservationID:D3}"

        ' Clone email label from template
        Dim lblEmailClone As Label = CloneLabel(Me.lblEmail)
        lblEmailClone.Text = If(String.IsNullOrEmpty(res.CustomerEmail), "N/A", res.CustomerEmail)

        Dim lblPhone As Label = CloneLabel(lblPhone2)
        lblPhone.Text = If(String.IsNullOrEmpty(res.ContactNumber), "N/A", res.ContactNumber)

        Dim lblPeople As Label = CloneLabel(lblPeople2)
        lblPeople.Text = res.NumberOfGuests.ToString()

        Dim lblDate As Label = CloneLabel(lblDate2)
        lblDate.Text = res.EventDate.ToString("yyyy-MM-dd")

        Dim lblTime As Label = CloneLabel(lblTime2)
        lblTime.Text = DateTime.Today.Add(res.EventTime).ToString("h:mm tt")

        Dim lblEvent As Label = CloneLabel(lblEvent2)
        lblEvent.Text = res.EventType

        ' Clone status button
        Dim btnStatus As Button = CloneButton(Button3)
        btnStatus.Text = res.ReservationStatus

        ' Set status color - Confirmed and Accepted both show green
        If res.ReservationStatus = "Confirmed" OrElse res.ReservationStatus = "Accepted" Then
            btnStatus.ForeColor = Color.FromArgb(0, 200, 83)
        ElseIf res.ReservationStatus = "Pending" Then
            btnStatus.ForeColor = Color.Orange
        Else
            btnStatus.ForeColor = Color.Red
        End If

        ' Clone icons
        Dim iconEmail As PictureBox = ClonePictureBox(PictureBox8)
        Dim iconPhone As PictureBox = ClonePictureBox(PictureBox3)
        Dim iconPeople As PictureBox = ClonePictureBox(PictureBox4)
        Dim iconDate As PictureBox = ClonePictureBox(PictureBox5)
        Dim iconTime As PictureBox = ClonePictureBox(PictureBox6)
        Dim iconEvent As PictureBox = ClonePictureBox(PictureBox7)

        ' Add all controls to panel
        panel.Controls.AddRange({
            lblName, lblCode, lblEmailClone, iconEmail, lblPhone, iconPhone,
            lblPeople, iconPeople, lblDate, iconDate, lblTime, iconTime,
            lblEvent, iconEvent, btnStatus
        })

        ' Add View Order button for all reservations
        Dim btnViewOrder As Button = CloneButton(Button4)
        btnViewOrder.Text = "View Order"
        btnViewOrder.BackColor = Color.FromArgb(52, 152, 219) ' Blue color
        AddHandler btnViewOrder.Click, Sub(sender, e)
                                           ShowReservationItems(res)
                                       End Sub
        panel.Controls.Add(btnViewOrder)

        ' Add Receipt Preview button (New Feature)
        ' We create this programmatically since it might not be in the template yet
        Dim btnPreview As Button = CloneButton(Button4) ' Clone View Order button style
        btnPreview.Text = "Receipt Preview"
        btnPreview.BackColor = Color.FromArgb(224, 224, 224)
        btnPreview.ForeColor = Color.Black
        btnPreview.Location = New Point(178, 285) ' Position it next to View Order
        btnPreview.Size = New Size(104, 38)
        
        AddHandler btnPreview.Click, Sub(sender, e)
                                         ShowReceiptPreview(res)
                                     End Sub
        panel.Controls.Add(btnPreview)

        Return panel
    End Function

    Private Sub ShowReceiptPreview(res As Reservation)
        Try
            ' Get items for the receipt
            Dim items As List(Of ReservationItem) = reservationRepository.GetReservationItems(res.ReservationID)
            
            ' Generate text content matching the image format
            Dim sb As New StringBuilder()
            Dim w As Integer = 60 ' Width for separators
            Dim line As String = New String("-"c, w)
            Dim dblLine As String = New String("="c, w)
            
            sb.AppendLine(dblLine)
            sb.AppendLine(CenterText("TABEYA RESTAURANT", w))
            sb.AppendLine(CenterText("Official Sales Receipt", w))
            sb.AppendLine(dblLine)
            sb.AppendLine()
            
            sb.AppendLine($"Order No.:   RES-{res.ReservationID:D3}")
            ' Use Event Date/Time or current datestamp? Usually a receipt has the print date. 
            ' But keeping Event info is useful. Let's stick to the image style: Date | Time
            sb.AppendLine($"Date:        {DateTime.Now:yyyy-MM-dd}   |   Time: {DateTime.Now:HH:mm tt}")
            sb.AppendLine($"Cashier:     Reservation System")
            sb.AppendLine($"Customer:    {res.CustomerName}")
            sb.AppendLine()
            
            sb.AppendLine(line)
            sb.AppendLine(CenterText("ITEMS PURCHASED", w))
            sb.AppendLine(line)
            sb.AppendLine()
            
            Dim totalAmount As Decimal = 0
            
            For Each item In items
                Dim lineTotal As Decimal = item.UnitPrice * item.Quantity
                totalAmount += lineTotal
                
                ' Format: 1 x Item Name ............. P 100.00
                Dim itemStr As String = $"{item.Quantity} x {item.ProductName}"
                Dim priceStr As String = $"P {lineTotal:N2}"
                
                ' padding calculation
                Dim padding As Integer = w - itemStr.Length - priceStr.Length
                If padding < 1 Then padding = 1
                
                sb.AppendLine($"{itemStr}{New String(" "c, padding)}{priceStr}")
                
                 ' Add fake batch info to match image style
                sb.AppendLine($"   - Batch: N/A") 
                sb.AppendLine($"   - Qty Deducted: {item.Quantity}")
                sb.AppendLine()
            Next
            
            sb.AppendLine(line)
            Dim subtotalStr As String = $"P {totalAmount:N2}"
            sb.AppendLine($"SUBTOTAL:{New String(" "c, w - 9 - subtotalStr.Length)}{subtotalStr}")
            sb.AppendLine(line)
            
            Dim totalStr As String = $"P {totalAmount:N2}"
            sb.AppendLine($"TOTAL:{New String(" "c, w - 6 - totalStr.Length)}{totalStr}")
            sb.AppendLine(line)
            sb.AppendLine()
            
            ' Reservation specific footer info
            sb.AppendLine($"Payment Method: {res.ReservationStatus.ToUpper()}")
            sb.AppendLine($"Amount Given:   P {totalAmount:N2}") 
            sb.AppendLine($"Change:         P 0.00")
            sb.AppendLine()
            sb.AppendLine(line)
            sb.AppendLine()
            sb.AppendLine(CenterText("THANK YOU FOR YOUR BOOKING!", w))
            sb.AppendLine(dblLine)
            
            ' Show Preview Form
            Dim previewForm As New ReceiptPreviewForm(res.ReservationID, "Reservation", sb.ToString())
            previewForm.ShowDialog()
            
        Catch ex As Exception
            MessageBox.Show($"Error generating preview: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Function CenterText(text As String, width As Integer) As String
        If text.Length >= width Then Return text
        Dim leftPadding As Integer = (width - text.Length) \ 2
        Return New String(" "c, leftPadding) & text
    End Function

    Private Sub ShowReservationItems(reservation As Reservation)
        Try
            ' Fetch reservation items from database
            Dim items As List(Of ReservationItem) = reservationRepository.GetReservationItems(reservation.ReservationID)

            If items Is Nothing OrElse items.Count = 0 Then
                MessageBox.Show("No items found for this reservation.", "Information", MessageBoxButtons.OK, MessageBoxIcon.Information)
                Return
            End If

            ' Show popup form with items
            Dim viewForm As New ViewReservationItemsForm(
                reservation.ReservationID,
                $"RES-{reservation.ReservationID:D3}",
                items
            )
            viewForm.ShowDialog()
        Catch ex As Exception
            MessageBox.Show($"Error loading reservation items: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Function CloneLabel(template As Label) As Label
        Return New Label With {
            .Text = template.Text,
            .Font = template.Font,
            .ForeColor = template.ForeColor,
            .BackColor = template.BackColor,
            .Location = template.Location,
            .Size = template.Size,
            .AutoSize = template.AutoSize,
            .Padding = template.Padding
        }
    End Function

    Private Function ClonePictureBox(template As PictureBox) As PictureBox
        Return New PictureBox With {
            .Image = template.Image,
            .Location = template.Location,
            .Size = template.Size,
            .SizeMode = template.SizeMode
        }
    End Function

    Private Function CloneButton(template As Button) As Button
        Return New Button With {
            .Text = template.Text,
            .Font = template.Font,
            .BackColor = template.BackColor,
            .ForeColor = template.ForeColor,
            .FlatStyle = template.FlatStyle,
            .Location = template.Location,
            .Size = template.Size
        }
    End Function

    Private Async Sub btnNewReservation_Click(sender As Object, e As EventArgs) Handles btnNewReservation.Click
        Dim newResForm As New NewReservationForm
        If newResForm.ShowDialog = DialogResult.OK Then
            Await LoadReservationsAsync
        End If
    End Sub

    Private Async Sub btnRefresh_Click(sender As Object, e As EventArgs) Handles btnRefresh.Click
        currentPage = 1 ' Reset to first page on refresh
        Await LoadReservationsAsync
    End Sub

    Private Sub lblTime2_Click(sender As Object, e As EventArgs)

    End Sub
End Class
