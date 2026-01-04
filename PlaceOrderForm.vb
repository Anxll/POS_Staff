Imports System.IO
Imports System.Collections.Generic
Imports System.Linq
Imports System.Reflection

Public Class PlaceOrderForm
    Private productRepository As New ProductRepository()
    Private orderRepository As New OrderRepository()
    Private inventoryService As New InventoryService()

    ' Store current order items
    Private orderItems As New List(Of OrderItem)
    Private currentOrderType As String = "" ' "Dine-in" or "Takeout"
    Private isLoading As Boolean = False

    ''' <summary>
    ''' Loads products from database when form loads
    ''' </summary>
    Private Async Sub PlaceOrderForm_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        ' Enable double buffering for smoother scrolling
        GetType(Control).GetProperty("DoubleBuffered", BindingFlags.NonPublic Or BindingFlags.Instance).SetValue(TableLayoutPanel3, True, Nothing)

        ' Initialize order items list
        orderItems = New List(Of OrderItem)

        ' Load all products asynchronously
        Await LoadProductsAsync("All")

        ' Set default total to 0
        UpdateTotal()
    End Sub

    ''' <summary>
    ''' Async version of LoadProducts for non-blocking UI
    ''' </summary>
    Private Async Function LoadProductsAsync(category As String) As Task
        If isLoading Then Return
        isLoading = True

        Try
            ' Show loading indicator
            ShowLoadingIndicator(True)

            ' Load products in background thread
            Dim products As List(Of Product) = Await productRepository.GetProductsByCategoryAsync(category)

            ' Validate inventory status for all loaded products
            Await Task.Run(Sub()
                               inventoryService.CheckInventoryForProducts(products)
                           End Sub)

            ' Update UI on UI thread
            DisplayProducts(products)

        Catch ex As Exception
            MessageBox.Show($"Error loading products: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            ShowLoadingIndicator(False)
            isLoading = False
        End Try
    End Function

    ''' <summary>
    ''' Shows/hides loading indicator
    ''' </summary>
    Private Sub ShowLoadingIndicator(show As Boolean)
        If show Then
            lblSubHeader.Text = "Loading products..."
            TableLayoutPanel3.Visible = False
        Else
            lblSubHeader.Text = "Create new dine-in or takeout orders"
            TableLayoutPanel3.Visible = True
        End If
        Application.DoEvents()
    End Sub

    ''' <summary>
    ''' Loads products from database and displays them
    ''' </summary>
    Private Sub LoadProducts(category As String)
        Try
            Dim products As List(Of Product)
            If category = "All" Then
                products = productRepository.GetAllProducts()
            Else
                products = productRepository.GetProductsByCategory(category)
            End If

            ' Validate inventory status
            inventoryService.CheckInventoryForProducts(products)

            DisplayProducts(products)
        Catch ex As Exception
            MessageBox.Show($"Error loading products: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    ''' <summary>
    ''' Displays products in the TableLayoutPanel3
    ''' </summary>
    Private Sub DisplayProducts(products As List(Of Product))
        TableLayoutPanel3.Controls.Clear()
        TableLayoutPanel3.RowStyles.Clear()
        TableLayoutPanel3.ColumnStyles.Clear()

        ' Set up 4 columns with equal percentage width
        TableLayoutPanel3.ColumnCount = 4
        For i As Integer = 0 To 3
            TableLayoutPanel3.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 25.0F))
        Next

        Dim rowCount As Integer = Math.Ceiling(products.Count / 4.0)
        TableLayoutPanel3.RowCount = Math.Max(rowCount, 1)

        For i As Integer = 0 To rowCount - 1
            TableLayoutPanel3.RowStyles.Add(New RowStyle(SizeType.AutoSize))
        Next

        Dim col As Integer = 0
        Dim row As Integer = 0

        For Each product As Product In products
            Dim productPanel As Panel = CreateProductPanel(product)
            productPanel.Dock = DockStyle.None
            productPanel.Anchor = AnchorStyles.Top
            productPanel.Margin = New Padding(10)
            TableLayoutPanel3.Controls.Add(productPanel, col, row)

            col += 1
            If col >= 4 Then
                col = 0
                row += 1
            End If
        Next
    End Sub

    Private Function CreateProductPanel(product As Product) As Panel
        Dim panel As New Panel With {
            .Size = New Size(250, 260),
            .BorderStyle = BorderStyle.FixedSingle,
            .Margin = New Padding(5),
            .BackColor = Color.White,
            .Tag = product ' Store product object in Tag
        }

        ' Image
        Dim pb As New PictureBox With {
            .Size = New Size(250, 170),
            .Location = New Point(0, 0),
            .SizeMode = PictureBoxSizeMode.StretchImage,
            .Cursor = Cursors.Hand
        }


        ' Set initial placeholder
        pb.BackColor = Color.LightGray

        ' Load image asynchronously
        If Not String.IsNullOrEmpty(product.Image) Then
            LoadImageAsync(pb, product.Image)
        End If

        ' Handle click events
        AddHandler pb.Click, Sub(sender, e) HandleProductClick(product)

        ' Name
        Dim lblName As New Label With {
            .Text = product.ProductName,
            .Font = New Font("Segoe UI Semibold", 9, FontStyle.Bold),
            .Location = New Point(10, 180),
            .AutoSize = True,
            .MaximumSize = New Size(230, 40)
        }

        ' Price
        Dim lblPrice As New Label With {
            .Text = $"₱{product.Price:F2}",
            .Font = New Font("Segoe UI Black", 11, FontStyle.Bold),
            .ForeColor = Color.FromArgb(255, 127, 39),
            .Location = New Point(10, 220),
            .AutoSize = True
        }

        ' Category
        Dim lblCat As New Label With {
            .Text = product.Category,
            .Font = New Font("Segoe UI", 8),
            .ForeColor = Color.Gray,
            .Location = New Point(150, 225),
            .AutoSize = True
        }

        ' Check inventory status
        If Not product.HasSufficientInventory Then
            panel.BackColor = Color.FromArgb(240, 240, 240) ' Light gray
            lblPrice.ForeColor = Color.Gray

            ' Add Out of Stock label
            Dim lblStock As New Label With {
                .Text = "OUT OF STOCK",
                .ForeColor = Color.Red,
                .Font = New Font("Segoe UI", 9, FontStyle.Bold),
                .Location = New Point(10, 160),
                .AutoSize = True,
                .BackColor = Color.Transparent
            }
            panel.Controls.Add(lblStock)

            ' Disable cursor hand
            pb.Cursor = Cursors.Default
        End If

        panel.Controls.AddRange({pb, lblName, lblPrice, lblCat})

        ' Make entire panel clickable
        AddHandler panel.Click, Sub(sender, e) HandleProductClick(product)
        AddHandler lblName.Click, Sub(sender, e) HandleProductClick(product)
        AddHandler lblPrice.Click, Sub(sender, e) HandleProductClick(product)

        Return panel
    End Function

    Private Sub HandleProductClick(product As Product)
        If Not product.HasSufficientInventory Then
            MessageBox.Show("This product cannot be ordered due to insufficient inventory." & vbCrLf & "See @Inventory_alerts.sql for details.", "Out of Stock", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        AddProductToOrder(product)
    End Sub

    ''' <summary>
    ''' Loads image in background thread to avoid UI freeze
    ''' </summary>
    Private Async Sub LoadImageAsync(pb As PictureBox, imagePath As String)
        Try
            Await Task.Run(Sub()
                               Try
                                   ' Extract filename and build path
                                   Dim filename As String = Path.GetFileName(imagePath)
                                   Dim fullPath As String = Path.Combine("C:\xampp\htdocs\products_image\products", filename)

                                   If File.Exists(fullPath) Then
                                       ' Load image into memory stream to avoid locking file
                                       Dim bytes = File.ReadAllBytes(fullPath)
                                       Dim ms As New MemoryStream(bytes)
                                       Dim img = Image.FromStream(ms)

                                       ' Update UI safely
                                       pb.Invoke(Sub()
                                                     pb.Image = img
                                                 End Sub)
                                   End If
                               Catch ex As Exception
                                   ' Ignore errors, keep placeholder
                               End Try
                           End Sub)
        Catch ex As Exception
            ' Ignore task errors
        End Try
    End Sub

    ''' <summary>
    ''' Adds a product to the order
    ''' </summary>
    Private Sub AddProductToOrder(product As Product)
        Dim existingItem = orderItems.FirstOrDefault(Function(item) item.ProductName = product.ProductName)

        If existingItem IsNot Nothing Then
            existingItem.Quantity += 1
        Else
            Dim newItem As New OrderItem With {
                .ProductID = product.ProductID,
                .ProductName = product.ProductName,
                .Quantity = 1,
                .UnitPrice = product.Price,
                .Category = product.Category,
                .PrepTime = product.PrepTime
            }
            orderItems.Add(newItem)
        End If

        UpdateOrderDisplay()
        UpdateTotal()
    End Sub

    ''' <summary>
    ''' Updates the order items display in Panel13
    ''' </summary>
    Private Sub UpdateOrderDisplay()
        Panel13.Controls.Clear()
        Panel13.AutoScroll = True

        Dim yPos As Integer = 0

        For Each item In orderItems
            ' Main Item Panel
            Dim itemPanel As New Panel With {
                .Size = New Size(Panel13.Width - 25, 70),
                .Location = New Point(5, yPos),
                .BackColor = Color.White
            }

            ' Separator Line (Top)
            Dim separator As New Panel With {
                .Size = New Size(itemPanel.Width, 1),
                .Location = New Point(0, 0),
                .BackColor = Color.LightGray,
                .Dock = DockStyle.Top
            }
            itemPanel.Controls.Add(separator)

            ' Product Name
            Dim lblName As New Label With {
                .Text = item.ProductName,
                .Font = New Font("Segoe UI", 8, FontStyle.Bold),
                .Location = New Point(10, 15),
                .AutoSize = False,
                .Size = New Size(180, 25),
                .AutoEllipsis = True
            }

            ' Price
            Dim lblPrice As New Label With {
                .Text = $"₱{item.UnitPrice:F2}",
                .Font = New Font("Segoe UI", 7),
                .ForeColor = Color.Gray,
                .Location = New Point(10, 40),
                .AutoSize = True
            }

            ' Quantity Controls Panel (Right Aligned)
            Dim pnlQty As New Panel With {
                .Size = New Size(110, 40),
                .Location = New Point(itemPanel.Width - 120, 15)
            }

            ' Plus Button (PictureBox)
            Dim btnPlus As New PictureBox With {
                .Size = New Size(30, 30),
                .Location = New Point(70, 5),
                .Image = My.Resources.add,
                .SizeMode = PictureBoxSizeMode.StretchImage,
                .Cursor = Cursors.Hand
            }

            ' Quantity TextBox (Editable)
            Dim txtQty As New TextBox With {
                .Text = item.Quantity.ToString(),
                .Font = New Font("Segoe UI", 11, FontStyle.Bold),
                .Location = New Point(35, 8),
                .Size = New Size(35, 25),
                .TextAlign = HorizontalAlignment.Center,
                .BorderStyle = BorderStyle.None
            }

            ' Minus Button (PictureBox)
            Dim btnMinus As New PictureBox With {
                .Size = New Size(30, 30),
                .Location = New Point(5, 5),
                .Image = My.Resources.minus_circle,
                .SizeMode = PictureBoxSizeMode.StretchImage,
                .Cursor = Cursors.Hand
            }

            ' Logic
            Dim currentItem = item

            ' Handle manual text change
            AddHandler txtQty.TextChanged, Sub(sender, e)
                                               Dim newQty As Integer
                                               If Integer.TryParse(txtQty.Text, newQty) AndAlso newQty > 0 Then
                                                   currentItem.Quantity = newQty
                                                   UpdateTotal()
                                               End If
                                           End Sub

            AddHandler btnPlus.Click, Sub(sender, e)
                                          currentItem.Quantity += 1
                                          txtQty.Text = currentItem.Quantity.ToString() ' Update text triggers TextChanged
                                      End Sub

            AddHandler btnMinus.Click, Sub(sender, e)
                                           If currentItem.Quantity > 1 Then
                                               currentItem.Quantity -= 1
                                               txtQty.Text = currentItem.Quantity.ToString()
                                           Else
                                               orderItems.Remove(currentItem)
                                               UpdateOrderDisplay() ' Remove item needs full refresh
                                               UpdateTotal()
                                           End If
                                       End Sub

            pnlQty.Controls.AddRange({btnPlus, txtQty, btnMinus})
            itemPanel.Controls.AddRange({lblName, lblPrice, pnlQty})
            Panel13.Controls.Add(itemPanel)

            yPos += 70
        Next
    End Sub

    Private Sub UpdateTotal()
        Dim total As Decimal = orderItems.Sum(Function(i) i.UnitPrice * i.Quantity)
        
        ' Update generic label if it exists
        If lblTotalValue IsNot Nothing Then
            lblTotalValue.Text = $"₱{total:F2}"
        End If
        
        ' Update Label41 specifically as requested
        If Label41 IsNot Nothing Then
            Label41.Text = $"₱{total:F2}"
        End If
    End Sub

    Private Async Sub btnAll_Click(sender As Object, e As EventArgs) Handles btnAll.Click
        Await LoadProductsAsync("All")
        HighlightCategoryButton(btnAll)
    End Sub

    Private Async Sub btnPlatter_Click(sender As Object, e As EventArgs) Handles btnPlatter.Click
        Await LoadProductsAsync("Platter") ' Ensure DB category matches
        HighlightCategoryButton(btnPlatter)
    End Sub

    Private Async Sub btnSpaghetti_Click(sender As Object, e As EventArgs) Handles btnSpaghetti.Click
        Await LoadProductsAsync("SPAGHETTI MEAL")
        HighlightCategoryButton(btnSpaghetti)
    End Sub

    Private Async Sub btnDessert_Click(sender As Object, e As EventArgs) Handles btnDessert.Click
        Await LoadProductsAsync("DESSERT")
        HighlightCategoryButton(btnDessert)
    End Sub

    Private Async Sub btnRiceMeal_Click(sender As Object, e As EventArgs) Handles btnRiceMeal.Click
        Await LoadProductsAsync("RICE MEAL")
        HighlightCategoryButton(btnRiceMeal)
    End Sub

    Private Async Sub btnSnacks_Click(sender As Object, e As EventArgs) Handles btnSnacks.Click
        Await LoadProductsAsync("SNACKS")
        HighlightCategoryButton(btnSnacks)
    End Sub

    Private Async Sub btnRice_Click(sender As Object, e As EventArgs) Handles btnRice.Click
        Await LoadProductsAsync("RICE")
        HighlightCategoryButton(btnRice)
    End Sub

    Private Async Sub btnDrinksAndBeverages_Click(sender As Object, e As EventArgs) Handles Button2.Click
        Await LoadProductsAsync("DRINKS & BEVERAGES")
        HighlightCategoryButton(Button2)
    End Sub

    Private Async Sub btnBilao_Click(sender As Object, e As EventArgs) Handles Button3.Click
        Await LoadProductsAsync("NOODLES & PASTA")
        HighlightCategoryButton(Button3)
    End Sub

    Private Sub HighlightCategoryButton(selectedButton As Button)
        ' Reset all category buttons
        btnAll.BackColor = Color.White
        btnPlatter.BackColor = Color.White
        btnSpaghetti.BackColor = Color.White
        btnDessert.BackColor = Color.White
        btnRiceMeal.BackColor = Color.White
        btnSnacks.BackColor = Color.White
        btnRice.BackColor = Color.White
        Button2.BackColor = Color.White
        Button3.BackColor = Color.White

        btnAll.ForeColor = Color.Black
        btnPlatter.ForeColor = Color.Black
        btnSpaghetti.ForeColor = Color.Black
        btnDessert.ForeColor = Color.Black
        btnRiceMeal.ForeColor = Color.Black
        btnSnacks.ForeColor = Color.Black
        btnRice.ForeColor = Color.Black
        Button2.ForeColor = Color.Black
        Button3.ForeColor = Color.Black

        ' Highlight selected button
        selectedButton.BackColor = Color.FromArgb(255, 127, 39)
        selectedButton.ForeColor = Color.White
    End Sub

    Private Sub btnDineIn_Click(sender As Object, e As EventArgs) Handles btnDineIn.Click
        currentOrderType = "Dine-in"
        btnDineIn.BackColor = Color.FromArgb(255, 127, 39)
        btnTakeOut.BackColor = Color.WhiteSmoke
    End Sub

    Private Sub btnTakeOut_Click(sender As Object, e As EventArgs) Handles btnTakeOut.Click
        currentOrderType = "Takeout"
        btnTakeOut.BackColor = Color.FromArgb(255, 127, 39)
        btnDineIn.BackColor = Color.WhiteSmoke
    End Sub

    Private Sub btnCheckout_Click(sender As Object, e As EventArgs) Handles btnCheckout.Click
        If orderItems.Count = 0 Then
            MessageBox.Show("Please add items to the order before checkout.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        If String.IsNullOrEmpty(currentOrderType) Then
            MessageBox.Show("Please select order type (Dine-In or Takeout).", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        Try
            ' Validate inventory before creating order
            Dim inventoryService As New InventoryService()
            Dim validationResult = inventoryService.ValidateInventoryForOrder(orderItems)

            ' If items need to be removed due to insufficient inventory
            If Not validationResult.IsValid AndAlso validationResult.ItemsToRemove.Count > 0 Then
                ' Show warning to user
                MessageBox.Show(
                    validationResult.WarningMessage & vbCrLf & vbCrLf & "These items will be removed from your order.",
                    "Inventory Alert",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning
                )

                ' Remove items with insufficient inventory
                Dim itemsToRemove As List(Of String) = validationResult.ItemsToRemove
                For i As Integer = 0 To itemsToRemove.Count - 1
                    Dim productName As String = itemsToRemove(i)
                    orderItems.RemoveAll(Function(item) item.ProductName = productName)
                Next

                ' Refresh display
                UpdateOrderDisplay()

                ' Stop checkout - let user review and try again
                Return
            End If

            ' Recalculate totals with remaining items
            Dim totalAmount As Decimal = orderItems.Sum(Function(i) i.UnitPrice * i.Quantity)
            Dim itemsCount As Integer = orderItems.Sum(Function(i) i.Quantity)

            ' Show payment dialog
            Dim paymentDialog As New PaymentDialog(totalAmount)
            If paymentDialog.ShowDialog() <> DialogResult.OK Then
                ' User canceled payment
                Return
            End If

            ' Get payment details
            Dim paymentMethod As String = paymentDialog.PaymentMethod
            Dim amountGiven As Decimal = paymentDialog.AmountGiven
            Dim changeAmount As Decimal = paymentDialog.ChangeAmount

            Dim newOrder As New Order With {
                .OrderType = currentOrderType,
                .OrderSource = "POS",
                .OrderDate = DateTime.Now.Date,
                .OrderTime = DateTime.Now.TimeOfDay,
                .ItemsOrderedCount = itemsCount,
                .TotalAmount = totalAmount,
                .EmployeeID = CurrentSession.EmployeeID, ' Set EmployeeID
                .OrderStatus = "Preparing"
            }

            Dim orderID As Integer = orderRepository.CreateOrder(newOrder, orderItems)

            If orderID > 0 Then
                ' Deduct inventory for the order
                Dim inventoryDeducted As Boolean = False
                Try
                    inventoryDeducted = inventoryService.DeductInventoryForOrder(orderID, orderItems)
                Catch invEx As Exception
                    System.Diagnostics.Debug.WriteLine($"Inventory deduction failed for Order #{orderID}: {invEx.Message}")
                    ' Continue even if inventory deduction fails - order is already created
                End Try
                
                Try
                    ' Generate order number in format VT-YYYY-NNNNNN
                    Dim orderNumber As String = $"VT-{DateTime.Now:yyyy}-{orderID:D6}"

                    ' Insert receipt data into database
                    Dim receiptRepo As New ReceiptRepository()
                    Dim receiptID As Integer = receiptRepo.InsertReceiptHeader(
                        orderID, orderNumber, totalAmount, paymentMethod, amountGiven, changeAmount
                    )

                    ' Insert receipt items with batch information
                    receiptRepo.InsertReceiptItems(receiptID, orderID, orderItems)

                    ' Generate PDF receipt
                    Dim pdfGenerator As New ReceiptPDFGenerator()
                    Dim pdfPath As String = pdfGenerator.GenerateReceipt(receiptID)
                    
                    ' Update Receipt Number in Orders table
                    orderRepository.UpdateOrderReceiptNumber(orderID, orderNumber)

                    ' Show success message with inventory confirmation
                    Dim successMessage As String = $"Order #{orderID} has been placed successfully!" & vbCrLf & vbCrLf
                    
                    If inventoryDeducted Then
                        successMessage &= "✓ Inventory deducted successfully" & vbCrLf
                    Else
                        successMessage &= "⚠ Warning: Inventory deduction may have failed" & vbCrLf
                    End If
                    
                    successMessage &= vbCrLf & $"Receipt saved to: {pdfPath}"
                    
                    MessageBox.Show(
                        successMessage,
                        "Success",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Information
                    )

                    ' Automatically open PDF
                    Try
                        Process.Start(pdfPath)
                    Catch ex As Exception
                        ' If PDF can't be opened automatically, just continue
                        MessageBox.Show(
                            "Receipt PDF was created but could not be opened automatically." & vbCrLf &
                            $"You can find it at: {pdfPath}",
                            "Information",
                            MessageBoxButtons.OK,
                            MessageBoxIcon.Information
                        )
                    End Try

                    ' Reset order
                    ResetOrder()

                Catch pdfEx As Exception
                    ' If PDF generation fails, still show success message but log error
                    MessageBox.Show(
                        $"Order #{orderID} has been placed successfully!" & vbCrLf & vbCrLf &
                        $"However, there was an error generating the PDF receipt:" & vbCrLf &
                        pdfEx.Message & vbCrLf & vbCrLf &
                        "The receipt data has been saved to the database.",
                        "Partial Success",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Warning
                    )

                    ' Reset order even if PDF fails
                    ResetOrder()
                End Try
            Else
                MessageBox.Show("Failed to create order. Please try again.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            End If
        Catch ex As Exception
            MessageBox.Show($"Error processing order: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub btnCancelOrder_Click(sender As Object, e As EventArgs) Handles btnCancelOrder.Click
        If MessageBox.Show("Are you sure you want to cancel this order?", "Confirm Cancel", MessageBoxButtons.YesNo, MessageBoxIcon.Question) = DialogResult.Yes Then
            ResetOrder()
        End If
    End Sub

    Private Sub ResetOrder()
        orderItems.Clear()
        currentOrderType = ""
        UpdateOrderDisplay()
        UpdateTotal()
        btnDineIn.BackColor = Color.WhiteSmoke
        btnTakeOut.BackColor = Color.WhiteSmoke
    End Sub

    Private Sub TableLayoutPanel3_Paint(sender As Object, e As PaintEventArgs)

    End Sub

    Private Sub PictureBox9_Click(sender As Object, e As EventArgs)

    End Sub
End Class
