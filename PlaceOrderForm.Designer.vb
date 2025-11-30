<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class PlaceOrderForm
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()>
    Protected Overrides Sub Dispose(disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        TableLayoutPanel1 = New TableLayoutPanel()
        pnlHeader = New Panel()
        lblSubHeader = New Label()
        lblHeader = New Label()
        Panel1 = New Panel()
        TableLayoutPanel2 = New TableLayoutPanel()
        Panel2 = New Panel()
        TableLayoutPanel3 = New TableLayoutPanel()
        Panel7 = New Panel()
        Label10 = New Label()
        Label11 = New Label()
        Label12 = New Label()
        PictureBox4 = New PictureBox()
        Panel6 = New Panel()
        Label7 = New Label()
        Label8 = New Label()
        Label9 = New Label()
        PictureBox3 = New PictureBox()
        Panel5 = New Panel()
        Label4 = New Label()
        Label5 = New Label()
        Label6 = New Label()
        PictureBox2 = New PictureBox()
        Panel4 = New Panel()
        Label3 = New Label()
        Label2 = New Label()
        Label1 = New Label()
        PictureBox1 = New PictureBox()
        flpCategories = New FlowLayoutPanel()
        btnAll = New Button()
        btnPlatter = New Button()
        btnSpaghetti = New Button()
        btnDessert = New Button()
        btnRiceMeal = New Button()
        btnSnacks = New Button()
        btnRice = New Button()
        Button2 = New Button()
        Button3 = New Button()
        Panel12 = New Panel()
        TableLayoutPanel4 = New TableLayoutPanel()
        Panel13 = New Panel()
        Panel3 = New Panel()
        TableLayoutPanel5 = New TableLayoutPanel()
        Panel15 = New Panel()
        Panel16 = New Panel()
        Label37 = New Label()
        TableLayoutPanel6 = New TableLayoutPanel()
        Panel18 = New Panel()
        btnCancelOrder = New Button()
        btnDineIn = New Button()
        btnTakeOut = New Button()
        btnCheckout = New Button()
        Panel19 = New Panel()
        Panel20 = New Panel()
        Label40 = New Label()
        lblTotal = New Label()
        lblTotalValue = New Label()
        Label41 = New Label()
        PictureBox5 = New PictureBox()
        Label27 = New Label()
        PictureBox10 = New PictureBox()
        Label13 = New Label()
        Label28 = New Label()
        TableLayoutPanel1.SuspendLayout()
        pnlHeader.SuspendLayout()
        Panel1.SuspendLayout()
        TableLayoutPanel2.SuspendLayout()
        Panel2.SuspendLayout()
        TableLayoutPanel3.SuspendLayout()
        Panel7.SuspendLayout()
        CType(PictureBox4, ComponentModel.ISupportInitialize).BeginInit()
        Panel6.SuspendLayout()
        CType(PictureBox3, ComponentModel.ISupportInitialize).BeginInit()
        Panel5.SuspendLayout()
        CType(PictureBox2, ComponentModel.ISupportInitialize).BeginInit()
        Panel4.SuspendLayout()
        CType(PictureBox1, ComponentModel.ISupportInitialize).BeginInit()
        flpCategories.SuspendLayout()
        Panel12.SuspendLayout()
        TableLayoutPanel4.SuspendLayout()
        Panel13.SuspendLayout()
        Panel15.SuspendLayout()
        TableLayoutPanel6.SuspendLayout()
        Panel18.SuspendLayout()
        Panel19.SuspendLayout()
        CType(PictureBox5, ComponentModel.ISupportInitialize).BeginInit()
        CType(PictureBox10, ComponentModel.ISupportInitialize).BeginInit()
        SuspendLayout()
        ' 
        ' TableLayoutPanel1
        ' 
        TableLayoutPanel1.ColumnCount = 2
        TableLayoutPanel1.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        TableLayoutPanel1.ColumnStyles.Add(New ColumnStyle())
        TableLayoutPanel1.Controls.Add(pnlHeader, 0, 0)
        TableLayoutPanel1.Controls.Add(Panel1, 0, 1)
        TableLayoutPanel1.Controls.Add(TableLayoutPanel6, 0, 2)
        TableLayoutPanel1.Dock = DockStyle.Fill
        TableLayoutPanel1.Location = New Point(0, 0)
        TableLayoutPanel1.Name = "TableLayoutPanel1"
        TableLayoutPanel1.Padding = New Padding(24, 24, 0, 24)
        TableLayoutPanel1.RowCount = 3
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Percent, 10F))
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Percent, 70F))
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Percent, 20F))
        TableLayoutPanel1.Size = New Size(1834, 948)
        TableLayoutPanel1.TabIndex = 0
        ' 
        ' pnlHeader
        ' 
        pnlHeader.AutoSize = True
        pnlHeader.Controls.Add(lblSubHeader)
        pnlHeader.Controls.Add(lblHeader)
        pnlHeader.Dock = DockStyle.Fill
        pnlHeader.Location = New Point(24, 24)
        pnlHeader.Margin = New Padding(0, 0, 0, 16)
        pnlHeader.Name = "pnlHeader"
        pnlHeader.Size = New Size(1810, 74)
        pnlHeader.TabIndex = 1
        ' 
        ' lblSubHeader
        ' 
        lblSubHeader.AutoSize = True
        lblSubHeader.Font = New Font("Segoe UI", 10F)
        lblSubHeader.ForeColor = Color.FromArgb(CByte(85), CByte(85), CByte(85))
        lblSubHeader.Location = New Point(0, 45)
        lblSubHeader.Margin = New Padding(0)
        lblSubHeader.Name = "lblSubHeader"
        lblSubHeader.Size = New Size(292, 23)
        lblSubHeader.TabIndex = 1
        lblSubHeader.Text = "Create new dine-in or takeout orders"
        ' 
        ' lblHeader
        ' 
        lblHeader.AutoSize = True
        lblHeader.Font = New Font("Segoe UI", 18F, FontStyle.Bold)
        lblHeader.ForeColor = Color.Black
        lblHeader.Location = New Point(0, 0)
        lblHeader.Margin = New Padding(0)
        lblHeader.Name = "lblHeader"
        lblHeader.Size = New Size(181, 41)
        lblHeader.TabIndex = 0
        lblHeader.Text = "Place Order"
        ' 
        ' Panel1
        ' 
        Panel1.Controls.Add(TableLayoutPanel2)
        Panel1.Dock = DockStyle.Fill
        Panel1.Location = New Point(27, 117)
        Panel1.Name = "Panel1"
        Panel1.Size = New Size(1804, 624)
        Panel1.TabIndex = 2
        ' 
        ' TableLayoutPanel2
        ' 
        TableLayoutPanel2.ColumnCount = 3
        TableLayoutPanel2.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 11.1235952F))
        TableLayoutPanel2.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 69.9277344F))
        TableLayoutPanel2.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 18.9549751F))
        TableLayoutPanel2.Controls.Add(Panel2, 1, 0)
        TableLayoutPanel2.Controls.Add(flpCategories, 0, 0)
        TableLayoutPanel2.Controls.Add(Panel12, 2, 0)
        TableLayoutPanel2.Dock = DockStyle.Fill
        TableLayoutPanel2.Location = New Point(0, 0)
        TableLayoutPanel2.Name = "TableLayoutPanel2"
        TableLayoutPanel2.RowCount = 1
        TableLayoutPanel2.RowStyles.Add(New RowStyle())
        TableLayoutPanel2.Size = New Size(1804, 624)
        TableLayoutPanel2.TabIndex = 1
        ' 
        ' Panel2
        ' 
        Panel2.AutoScroll = True
        Panel2.AutoSizeMode = AutoSizeMode.GrowAndShrink
        Panel2.BackColor = Color.White
        Panel2.BorderStyle = BorderStyle.FixedSingle
        Panel2.Controls.Add(TableLayoutPanel3)
        Panel2.Location = New Point(203, 3)
        Panel2.Name = "Panel2"
        Panel2.Padding = New Padding(20)
        Panel2.Size = New Size(1255, 609)
        Panel2.TabIndex = 4
        ' 
        ' TableLayoutPanel3
        ' 
        TableLayoutPanel3.AutoSize = True
        TableLayoutPanel3.ColumnCount = 4
        TableLayoutPanel3.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 25F))
        TableLayoutPanel3.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 25F))
        TableLayoutPanel3.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 25F))
        TableLayoutPanel3.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 25F))
        TableLayoutPanel3.Controls.Add(Panel7, 3, 0)
        TableLayoutPanel3.Controls.Add(Panel6, 2, 0)
        TableLayoutPanel3.Controls.Add(Panel5, 1, 0)
        TableLayoutPanel3.Controls.Add(Panel4, 0, 0)
        TableLayoutPanel3.Location = New Point(20, 20)
        TableLayoutPanel3.Name = "TableLayoutPanel3"
        TableLayoutPanel3.RowCount = 1
        TableLayoutPanel3.RowStyles.Add(New RowStyle())
        TableLayoutPanel3.Size = New Size(1076, 564)
        TableLayoutPanel3.TabIndex = 1
        ' 
        ' Panel7
        ' 
        Panel7.BorderStyle = BorderStyle.FixedSingle
        Panel7.Controls.Add(Label10)
        Panel7.Controls.Add(Label11)
        Panel7.Controls.Add(Label12)
        Panel7.Controls.Add(PictureBox4)
        Panel7.Location = New Point(810, 3)
        Panel7.Margin = New Padding(3, 3, 3, 15)
        Panel7.Name = "Panel7"
        Panel7.Size = New Size(251, 258)
        Panel7.TabIndex = 5
        ' 
        ' Label10
        ' 
        Label10.AutoSize = True
        Label10.Font = New Font("Segoe UI Black", 10.8F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Label10.ForeColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        Label10.Location = New Point(179, 194)
        Label10.Name = "Label10"
        Label10.Size = New Size(59, 25)
        Label10.TabIndex = 1
        Label10.Text = "₱250"
        ' 
        ' Label11
        ' 
        Label11.AutoSize = True
        Label11.Font = New Font("Segoe UI", 8F)
        Label11.ForeColor = Color.Gray
        Label11.Location = New Point(9, 219)
        Label11.Name = "Label11"
        Label11.Size = New Size(49, 19)
        Label11.TabIndex = 1
        Label11.Text = "Platter"
        ' 
        ' Label12
        ' 
        Label12.AutoSize = True
        Label12.Font = New Font("Segoe UI Semibold", 9F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Label12.Location = New Point(9, 194)
        Label12.Name = "Label12"
        Label12.Size = New Size(121, 20)
        Label12.TabIndex = 1
        Label12.Text = "Crispy Pork Sisig"
        ' 
        ' PictureBox4
        ' 
        PictureBox4.BorderStyle = BorderStyle.FixedSingle
        PictureBox4.Image = My.Resources.Resources._492532128_1238919221569400_8581796487275074167_n__1_
        PictureBox4.Location = New Point(-1, -1)
        PictureBox4.Name = "PictureBox4"
        PictureBox4.Size = New Size(251, 172)
        PictureBox4.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox4.TabIndex = 1
        PictureBox4.TabStop = False
        ' 
        ' Panel6
        ' 
        Panel6.BorderStyle = BorderStyle.FixedSingle
        Panel6.Controls.Add(Label7)
        Panel6.Controls.Add(Label8)
        Panel6.Controls.Add(Label9)
        Panel6.Controls.Add(PictureBox3)
        Panel6.Location = New Point(541, 3)
        Panel6.Margin = New Padding(3, 3, 3, 15)
        Panel6.Name = "Panel6"
        Panel6.Size = New Size(251, 258)
        Panel6.TabIndex = 4
        ' 
        ' Label7
        ' 
        Label7.AutoSize = True
        Label7.Font = New Font("Segoe UI Black", 10.8F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Label7.ForeColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        Label7.Location = New Point(179, 194)
        Label7.Name = "Label7"
        Label7.Size = New Size(59, 25)
        Label7.TabIndex = 1
        Label7.Text = "₱250"
        ' 
        ' Label8
        ' 
        Label8.AutoSize = True
        Label8.Font = New Font("Segoe UI", 8F)
        Label8.ForeColor = Color.Gray
        Label8.Location = New Point(9, 219)
        Label8.Name = "Label8"
        Label8.Size = New Size(49, 19)
        Label8.TabIndex = 1
        Label8.Text = "Platter"
        ' 
        ' Label9
        ' 
        Label9.AutoSize = True
        Label9.Font = New Font("Segoe UI Semibold", 9F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Label9.Location = New Point(9, 194)
        Label9.Name = "Label9"
        Label9.Size = New Size(121, 20)
        Label9.TabIndex = 1
        Label9.Text = "Crispy Pork Sisig"
        ' 
        ' PictureBox3
        ' 
        PictureBox3.BorderStyle = BorderStyle.FixedSingle
        PictureBox3.Image = My.Resources.Resources._492532128_1238919221569400_8581796487275074167_n__1_
        PictureBox3.Location = New Point(-1, -1)
        PictureBox3.Name = "PictureBox3"
        PictureBox3.Size = New Size(251, 172)
        PictureBox3.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox3.TabIndex = 1
        PictureBox3.TabStop = False
        ' 
        ' Panel5
        ' 
        Panel5.BorderStyle = BorderStyle.FixedSingle
        Panel5.Controls.Add(Label4)
        Panel5.Controls.Add(Label5)
        Panel5.Controls.Add(Label6)
        Panel5.Controls.Add(PictureBox2)
        Panel5.Location = New Point(272, 3)
        Panel5.Margin = New Padding(3, 3, 3, 15)
        Panel5.Name = "Panel5"
        Panel5.Size = New Size(251, 258)
        Panel5.TabIndex = 3
        ' 
        ' Label4
        ' 
        Label4.AutoSize = True
        Label4.Font = New Font("Segoe UI Black", 10.8F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Label4.ForeColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        Label4.Location = New Point(179, 194)
        Label4.Name = "Label4"
        Label4.Size = New Size(59, 25)
        Label4.TabIndex = 1
        Label4.Text = "₱250"
        ' 
        ' Label5
        ' 
        Label5.AutoSize = True
        Label5.Font = New Font("Segoe UI", 8F)
        Label5.ForeColor = Color.Gray
        Label5.Location = New Point(9, 219)
        Label5.Name = "Label5"
        Label5.Size = New Size(49, 19)
        Label5.TabIndex = 1
        Label5.Text = "Platter"
        ' 
        ' Label6
        ' 
        Label6.AutoSize = True
        Label6.Font = New Font("Segoe UI Semibold", 9F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Label6.Location = New Point(9, 194)
        Label6.Name = "Label6"
        Label6.Size = New Size(121, 20)
        Label6.TabIndex = 1
        Label6.Text = "Crispy Pork Sisig"
        ' 
        ' PictureBox2
        ' 
        PictureBox2.BorderStyle = BorderStyle.FixedSingle
        PictureBox2.Image = My.Resources.Resources._492532128_1238919221569400_8581796487275074167_n__1_
        PictureBox2.Location = New Point(-1, -1)
        PictureBox2.Name = "PictureBox2"
        PictureBox2.Size = New Size(251, 172)
        PictureBox2.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox2.TabIndex = 1
        PictureBox2.TabStop = False
        ' 
        ' Panel4
        ' 
        Panel4.BorderStyle = BorderStyle.FixedSingle
        Panel4.Controls.Add(Label3)
        Panel4.Controls.Add(Label2)
        Panel4.Controls.Add(Label1)
        Panel4.Controls.Add(PictureBox1)
        Panel4.Location = New Point(3, 3)
        Panel4.Margin = New Padding(3, 3, 3, 15)
        Panel4.Name = "Panel4"
        Panel4.Size = New Size(251, 258)
        Panel4.TabIndex = 2
        ' 
        ' Label3
        ' 
        Label3.AutoSize = True
        Label3.Font = New Font("Segoe UI Black", 10.8F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Label3.ForeColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        Label3.Location = New Point(179, 194)
        Label3.Name = "Label3"
        Label3.Size = New Size(59, 25)
        Label3.TabIndex = 1
        Label3.Text = "₱250"
        ' 
        ' Label2
        ' 
        Label2.AutoSize = True
        Label2.Font = New Font("Segoe UI", 8F)
        Label2.ForeColor = Color.Gray
        Label2.Location = New Point(9, 219)
        Label2.Name = "Label2"
        Label2.Size = New Size(49, 19)
        Label2.TabIndex = 1
        Label2.Text = "Platter"
        ' 
        ' Label1
        ' 
        Label1.AutoSize = True
        Label1.Font = New Font("Segoe UI Semibold", 9F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Label1.Location = New Point(9, 194)
        Label1.Name = "Label1"
        Label1.Size = New Size(121, 20)
        Label1.TabIndex = 1
        Label1.Text = "Crispy Pork Sisig"
        ' 
        ' PictureBox1
        ' 
        PictureBox1.BorderStyle = BorderStyle.FixedSingle
        PictureBox1.Image = My.Resources.Resources._492532128_1238919221569400_8581796487275074167_n__1_
        PictureBox1.Location = New Point(-1, -1)
        PictureBox1.Name = "PictureBox1"
        PictureBox1.Size = New Size(251, 172)
        PictureBox1.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox1.TabIndex = 1
        PictureBox1.TabStop = False
        ' 
        ' flpCategories
        ' 
        flpCategories.AutoScroll = True
        flpCategories.AutoSizeMode = AutoSizeMode.GrowAndShrink
        flpCategories.Controls.Add(btnAll)
        flpCategories.Controls.Add(btnPlatter)
        flpCategories.Controls.Add(btnSpaghetti)
        flpCategories.Controls.Add(btnDessert)
        flpCategories.Controls.Add(btnRiceMeal)
        flpCategories.Controls.Add(btnSnacks)
        flpCategories.Controls.Add(btnRice)
        flpCategories.Controls.Add(Button2)
        flpCategories.Controls.Add(Button3)
        flpCategories.Dock = DockStyle.Fill
        flpCategories.FlowDirection = FlowDirection.TopDown
        flpCategories.Location = New Point(3, 3)
        flpCategories.Name = "flpCategories"
        flpCategories.Size = New Size(194, 804)
        flpCategories.TabIndex = 1
        ' 
        ' btnAll
        ' 
        btnAll.AutoSize = True
        btnAll.BackColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        btnAll.FlatAppearance.BorderColor = Color.Black
        btnAll.FlatAppearance.MouseDownBackColor = Color.Black
        btnAll.FlatAppearance.MouseOverBackColor = Color.Black
        btnAll.FlatStyle = FlatStyle.Flat
        btnAll.Font = New Font("Segoe UI", 10.2F)
        btnAll.ForeColor = Color.White
        btnAll.Location = New Point(0, 0)
        btnAll.Margin = New Padding(0)
        btnAll.Name = "btnAll"
        btnAll.Size = New Size(169, 60)
        btnAll.TabIndex = 0
        btnAll.Text = "All"
        btnAll.UseVisualStyleBackColor = False
        ' 
        ' btnPlatter
        ' 
        btnPlatter.AutoSize = True
        btnPlatter.FlatStyle = FlatStyle.Flat
        btnPlatter.Font = New Font("Segoe UI", 10.2F)
        btnPlatter.Location = New Point(0, 60)
        btnPlatter.Margin = New Padding(0)
        btnPlatter.Name = "btnPlatter"
        btnPlatter.Size = New Size(169, 60)
        btnPlatter.TabIndex = 2
        btnPlatter.Text = "Platter"
        ' 
        ' btnSpaghetti
        ' 
        btnSpaghetti.AutoSize = True
        btnSpaghetti.FlatStyle = FlatStyle.Flat
        btnSpaghetti.Font = New Font("Segoe UI", 10.2F)
        btnSpaghetti.Location = New Point(0, 120)
        btnSpaghetti.Margin = New Padding(0)
        btnSpaghetti.Name = "btnSpaghetti"
        btnSpaghetti.Size = New Size(169, 60)
        btnSpaghetti.TabIndex = 3
        btnSpaghetti.Text = "Spaghetti Meal"
        ' 
        ' btnDessert
        ' 
        btnDessert.AutoSize = True
        btnDessert.FlatStyle = FlatStyle.Flat
        btnDessert.Font = New Font("Segoe UI", 10.2F)
        btnDessert.Location = New Point(0, 180)
        btnDessert.Margin = New Padding(0)
        btnDessert.Name = "btnDessert"
        btnDessert.Size = New Size(169, 60)
        btnDessert.TabIndex = 4
        btnDessert.Text = "Dessert"
        ' 
        ' btnRiceMeal
        ' 
        btnRiceMeal.AutoSize = True
        btnRiceMeal.FlatStyle = FlatStyle.Flat
        btnRiceMeal.Font = New Font("Segoe UI", 10.2F)
        btnRiceMeal.Location = New Point(0, 240)
        btnRiceMeal.Margin = New Padding(0)
        btnRiceMeal.Name = "btnRiceMeal"
        btnRiceMeal.Size = New Size(169, 60)
        btnRiceMeal.TabIndex = 1
        btnRiceMeal.Text = "Rice Meal"
        ' 
        ' btnSnacks
        ' 
        btnSnacks.AutoSize = True
        btnSnacks.FlatStyle = FlatStyle.Flat
        btnSnacks.Font = New Font("Segoe UI", 10.2F)
        btnSnacks.Location = New Point(0, 300)
        btnSnacks.Margin = New Padding(0)
        btnSnacks.Name = "btnSnacks"
        btnSnacks.Size = New Size(169, 60)
        btnSnacks.TabIndex = 5
        btnSnacks.Text = "Snacks"
        ' 
        ' btnRice
        ' 
        btnRice.AutoSize = True
        btnRice.FlatStyle = FlatStyle.Flat
        btnRice.Font = New Font("Segoe UI", 10.2F)
        btnRice.Location = New Point(0, 360)
        btnRice.Margin = New Padding(0)
        btnRice.Name = "btnRice"
        btnRice.Size = New Size(169, 60)
        btnRice.TabIndex = 6
        btnRice.Text = "Rice"
        ' 
        ' Button2
        ' 
        Button2.AutoSize = True
        Button2.FlatStyle = FlatStyle.Flat
        Button2.Font = New Font("Segoe UI", 9F)
        Button2.Location = New Point(0, 420)
        Button2.Margin = New Padding(0)
        Button2.Name = "Button2"
        Button2.Size = New Size(169, 60)
        Button2.TabIndex = 7
        Button2.Text = "Drings and Beverages"
        ' 
        ' Button3
        ' 
        Button3.AutoSize = True
        Button3.FlatStyle = FlatStyle.Flat
        Button3.Font = New Font("Segoe UI", 10.2F)
        Button3.Location = New Point(0, 480)
        Button3.Margin = New Padding(0)
        Button3.Name = "Button3"
        Button3.Size = New Size(169, 60)
        Button3.TabIndex = 8
        Button3.Text = "Bilao"
        ' 
        ' Panel12
        ' 
        Panel12.BorderStyle = BorderStyle.FixedSingle
        Panel12.Controls.Add(TableLayoutPanel4)
        Panel12.Location = New Point(1464, 3)
        Panel12.Name = "Panel12"
        Panel12.Size = New Size(337, 609)
        Panel12.TabIndex = 5
        ' 
        ' TableLayoutPanel4
        ' 
        TableLayoutPanel4.ColumnCount = 1
        TableLayoutPanel4.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 0F))
        TableLayoutPanel4.Controls.Add(Panel13, 0, 1)
        TableLayoutPanel4.Controls.Add(Panel15, 0, 0)
        TableLayoutPanel4.Location = New Point(0, 0)
        TableLayoutPanel4.Name = "TableLayoutPanel4"
        TableLayoutPanel4.RowCount = 2
        TableLayoutPanel4.RowStyles.Add(New RowStyle(SizeType.Percent, 8F))
        TableLayoutPanel4.RowStyles.Add(New RowStyle(SizeType.Percent, 92F))
        TableLayoutPanel4.Size = New Size(335, 608)
        TableLayoutPanel4.TabIndex = 0
        ' 
        ' Panel13
        ' 
        Panel13.Controls.Add(Panel3)
        Panel13.Controls.Add(PictureBox5)
        Panel13.Controls.Add(Label13)
        Panel13.Controls.Add(Label27)
        Panel13.Controls.Add(PictureBox10)
        Panel13.Controls.Add(Label28)
        Panel13.Controls.Add(TableLayoutPanel5)
        Panel13.Dock = DockStyle.Fill
        Panel13.Location = New Point(3, 51)
        Panel13.Name = "Panel13"
        Panel13.Size = New Size(331, 554)
        Panel13.TabIndex = 27
        ' 
        ' Panel3
        ' 
        Panel3.BorderStyle = BorderStyle.FixedSingle
        Panel3.Location = New Point(9, 3)
        Panel3.Name = "Panel3"
        Panel3.Size = New Size(270, 1)
        Panel3.TabIndex = 25
        ' 
        ' TableLayoutPanel5
        ' 
        TableLayoutPanel5.AutoSize = True
        TableLayoutPanel5.AutoSizeMode = AutoSizeMode.GrowAndShrink
        TableLayoutPanel5.ColumnCount = 1
        TableLayoutPanel5.ColumnStyles.Add(New ColumnStyle())
        TableLayoutPanel5.ColumnStyles.Add(New ColumnStyle(SizeType.Absolute, 20F))
        TableLayoutPanel5.Dock = DockStyle.Top
        TableLayoutPanel5.Location = New Point(0, 0)
        TableLayoutPanel5.Name = "TableLayoutPanel5"
        TableLayoutPanel5.RowCount = 1
        TableLayoutPanel5.RowStyles.Add(New RowStyle(SizeType.Percent, 0F))
        TableLayoutPanel5.RowStyles.Add(New RowStyle(SizeType.Absolute, 20F))
        TableLayoutPanel5.Size = New Size(331, 0)
        TableLayoutPanel5.TabIndex = 0
        ' 
        ' Panel15
        ' 
        Panel15.Controls.Add(Panel16)
        Panel15.Controls.Add(Label37)
        Panel15.Dock = DockStyle.Fill
        Panel15.Location = New Point(3, 3)
        Panel15.Name = "Panel15"
        Panel15.Size = New Size(331, 42)
        Panel15.TabIndex = 26
        ' 
        ' Panel16
        ' 
        Panel16.BorderStyle = BorderStyle.FixedSingle
        Panel16.Location = New Point(6, 51)
        Panel16.Name = "Panel16"
        Panel16.Size = New Size(350, 1)
        Panel16.TabIndex = 10
        ' 
        ' Label37
        ' 
        Label37.AutoSize = True
        Label37.Font = New Font("Segoe UI", 13.8F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Label37.Location = New Point(14, 10)
        Label37.Margin = New Padding(25)
        Label37.Name = "Label37"
        Label37.Size = New Size(162, 31)
        Label37.TabIndex = 11
        Label37.Text = "Current Order"
        ' 
        ' TableLayoutPanel6
        ' 
        TableLayoutPanel6.ColumnCount = 2
        TableLayoutPanel6.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 53.5393257F))
        TableLayoutPanel6.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 46.4606743F))
        TableLayoutPanel6.Controls.Add(Panel18, 0, 0)
        TableLayoutPanel6.Controls.Add(Panel19, 1, 0)
        TableLayoutPanel6.Dock = DockStyle.Fill
        TableLayoutPanel6.Location = New Point(27, 747)
        TableLayoutPanel6.Name = "TableLayoutPanel6"
        TableLayoutPanel6.RowCount = 1
        TableLayoutPanel6.RowStyles.Add(New RowStyle(SizeType.Percent, 50F))
        TableLayoutPanel6.RowStyles.Add(New RowStyle(SizeType.Absolute, 20F))
        TableLayoutPanel6.Size = New Size(1804, 174)
        TableLayoutPanel6.TabIndex = 3
        ' 
        ' Panel18
        ' 
        Panel18.Controls.Add(btnCancelOrder)
        Panel18.Controls.Add(btnDineIn)
        Panel18.Controls.Add(btnTakeOut)
        Panel18.Controls.Add(btnCheckout)
        Panel18.Dock = DockStyle.Fill
        Panel18.Location = New Point(3, 3)
        Panel18.Name = "Panel18"
        Panel18.Size = New Size(959, 168)
        Panel18.TabIndex = 0
        ' 
        ' btnCancelOrder
        ' 
        btnCancelOrder.BackColor = Color.WhiteSmoke
        btnCancelOrder.FlatStyle = FlatStyle.Flat
        btnCancelOrder.Font = New Font("Segoe UI", 10F)
        btnCancelOrder.Location = New Point(205, 61)
        btnCancelOrder.Margin = New Padding(25)
        btnCancelOrder.Name = "btnCancelOrder"
        btnCancelOrder.Size = New Size(154, 47)
        btnCancelOrder.TabIndex = 18
        btnCancelOrder.Text = "Cancel Order"
        btnCancelOrder.UseVisualStyleBackColor = False
        ' 
        ' btnDineIn
        ' 
        btnDineIn.BackColor = Color.WhiteSmoke
        btnDineIn.FlatStyle = FlatStyle.Flat
        btnDineIn.Font = New Font("Segoe UI", 10F)
        btnDineIn.Location = New Point(395, 23)
        btnDineIn.Margin = New Padding(25)
        btnDineIn.Name = "btnDineIn"
        btnDineIn.Size = New Size(154, 47)
        btnDineIn.TabIndex = 19
        btnDineIn.Text = "Dine-In"
        btnDineIn.UseVisualStyleBackColor = False
        ' 
        ' btnTakeOut
        ' 
        btnTakeOut.BackColor = Color.WhiteSmoke
        btnTakeOut.FlatStyle = FlatStyle.Flat
        btnTakeOut.Font = New Font("Segoe UI", 10F)
        btnTakeOut.Location = New Point(395, 99)
        btnTakeOut.Margin = New Padding(25)
        btnTakeOut.Name = "btnTakeOut"
        btnTakeOut.Size = New Size(154, 47)
        btnTakeOut.TabIndex = 20
        btnTakeOut.Text = "Takeout"
        btnTakeOut.UseVisualStyleBackColor = False
        ' 
        ' btnCheckout
        ' 
        btnCheckout.BackColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        btnCheckout.FlatAppearance.BorderColor = Color.Black
        btnCheckout.FlatAppearance.MouseDownBackColor = Color.FromArgb(CByte(250), CByte(186), CByte(142))
        btnCheckout.FlatStyle = FlatStyle.Flat
        btnCheckout.Font = New Font("Segoe UI", 10F, FontStyle.Bold)
        btnCheckout.ForeColor = Color.White
        btnCheckout.Location = New Point(627, 42)
        btnCheckout.Margin = New Padding(25)
        btnCheckout.Name = "btnCheckout"
        btnCheckout.Size = New Size(228, 85)
        btnCheckout.TabIndex = 21
        btnCheckout.Text = "Checkout/Receipt"
        btnCheckout.UseVisualStyleBackColor = False
        ' 
        ' Panel19
        ' 
        Panel19.Controls.Add(Panel20)
        Panel19.Controls.Add(Label40)
        Panel19.Controls.Add(lblTotal)
        Panel19.Controls.Add(lblTotalValue)
        Panel19.Controls.Add(Label41)
        Panel19.Dock = DockStyle.Fill
        Panel19.Location = New Point(968, 3)
        Panel19.Name = "Panel19"
        Panel19.Size = New Size(833, 168)
        Panel19.TabIndex = 1
        ' 
        ' Panel20
        ' 
        Panel20.BorderStyle = BorderStyle.FixedSingle
        Panel20.Location = New Point(106, 88)
        Panel20.Name = "Panel20"
        Panel20.Size = New Size(320, 1)
        Panel20.TabIndex = 24
        ' 
        ' Label40
        ' 
        Label40.AutoSize = True
        Label40.Font = New Font("Segoe UI", 10F)
        Label40.ForeColor = Color.Gray
        Label40.Location = New Point(103, 51)
        Label40.Margin = New Padding(25)
        Label40.Name = "Label40"
        Label40.Size = New Size(46, 23)
        Label40.TabIndex = 30
        Label40.Text = "Total"
        ' 
        ' lblTotal
        ' 
        lblTotal.AutoSize = True
        lblTotal.Font = New Font("Segoe UI", 13.8F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        lblTotal.Location = New Point(103, 95)
        lblTotal.Margin = New Padding(25)
        lblTotal.Name = "lblTotal"
        lblTotal.Size = New Size(67, 31)
        lblTotal.TabIndex = 29
        lblTotal.Text = "Total"
        ' 
        ' lblTotalValue
        ' 
        lblTotalValue.Font = New Font("Segoe UI Black", 14F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        lblTotalValue.ForeColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        lblTotalValue.Location = New Point(344, 95)
        lblTotalValue.Margin = New Padding(25)
        lblTotalValue.Name = "lblTotalValue"
        lblTotalValue.Size = New Size(100, 31)
        lblTotalValue.TabIndex = 28
        lblTotalValue.Text = "₱0"
        ' 
        ' Label41
        ' 
        Label41.Font = New Font("Segoe UI Semibold", 10.2F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Label41.ForeColor = Color.Gray
        Label41.Location = New Point(344, 51)
        Label41.Margin = New Padding(25)
        Label41.Name = "Label41"
        Label41.Size = New Size(100, 23)
        Label41.TabIndex = 27
        Label41.Text = "₱0"
        ' 
        ' PictureBox5
        ' 
        PictureBox5.Image = My.Resources.Resources.minus_circle__1_
        PictureBox5.Location = New Point(243, 18)
        PictureBox5.Name = "PictureBox5"
        PictureBox5.Size = New Size(30, 30)
        PictureBox5.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox5.TabIndex = 20
        PictureBox5.TabStop = False
        PictureBox5.Visible = False
        ' 
        ' Label27
        ' 
        Label27.AutoSize = True
        Label27.Font = New Font("Segoe UI Semibold", 11F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Label27.Location = New Point(214, 21)
        Label27.Name = "Label27"
        Label27.Size = New Size(23, 25)
        Label27.TabIndex = 17
        Label27.Text = "0"
        Label27.Visible = False
        ' 
        ' PictureBox10
        ' 
        PictureBox10.Image = My.Resources.Resources.add
        PictureBox10.Location = New Point(178, 18)
        PictureBox10.Name = "PictureBox10"
        PictureBox10.Size = New Size(30, 30)
        PictureBox10.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox10.TabIndex = 16
        PictureBox10.TabStop = False
        PictureBox10.Visible = False
        ' 
        ' Label13
        ' 
        Label13.AutoSize = True
        Label13.Font = New Font("Segoe UI", 8F)
        Label13.ForeColor = Color.Gray
        Label13.Location = New Point(12, 34)
        Label13.Name = "Label13"
        Label13.Size = New Size(41, 19)
        Label13.TabIndex = 19
        Label13.Text = "₱250"
        Label13.Visible = False
        ' 
        ' Label28
        ' 
        Label28.AutoSize = True
        Label28.Font = New Font("Segoe UI Semibold", 9F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Label28.Location = New Point(12, 14)
        Label28.Name = "Label28"
        Label28.Size = New Size(99, 20)
        Label28.TabIndex = 15
        Label28.Text = "Crispy Pork..."
        Label28.Visible = False
        ' 
        ' PlaceOrderForm
        ' 
        AutoScaleDimensions = New SizeF(8F, 20F)
        AutoScaleMode = AutoScaleMode.Font
        BackColor = Color.White
        ClientSize = New Size(1834, 948)
        Controls.Add(TableLayoutPanel1)
        Font = New Font("Segoe UI", 9F)
        FormBorderStyle = FormBorderStyle.None
        Name = "PlaceOrderForm"
        StartPosition = FormStartPosition.CenterScreen
        Text = "Place Order"
        TableLayoutPanel1.ResumeLayout(False)
        TableLayoutPanel1.PerformLayout()
        pnlHeader.ResumeLayout(False)
        pnlHeader.PerformLayout()
        Panel1.ResumeLayout(False)
        TableLayoutPanel2.ResumeLayout(False)
        Panel2.ResumeLayout(False)
        Panel2.PerformLayout()
        TableLayoutPanel3.ResumeLayout(False)
        Panel7.ResumeLayout(False)
        Panel7.PerformLayout()
        CType(PictureBox4, ComponentModel.ISupportInitialize).EndInit()
        Panel6.ResumeLayout(False)
        Panel6.PerformLayout()
        CType(PictureBox3, ComponentModel.ISupportInitialize).EndInit()
        Panel5.ResumeLayout(False)
        Panel5.PerformLayout()
        CType(PictureBox2, ComponentModel.ISupportInitialize).EndInit()
        Panel4.ResumeLayout(False)
        Panel4.PerformLayout()
        CType(PictureBox1, ComponentModel.ISupportInitialize).EndInit()
        flpCategories.ResumeLayout(False)
        flpCategories.PerformLayout()
        Panel12.ResumeLayout(False)
        TableLayoutPanel4.ResumeLayout(False)
        Panel13.ResumeLayout(False)
        Panel13.PerformLayout()
        Panel15.ResumeLayout(False)
        Panel15.PerformLayout()
        TableLayoutPanel6.ResumeLayout(False)
        Panel18.ResumeLayout(False)
        Panel19.ResumeLayout(False)
        Panel19.PerformLayout()
        CType(PictureBox5, ComponentModel.ISupportInitialize).EndInit()
        CType(PictureBox10, ComponentModel.ISupportInitialize).EndInit()
        ResumeLayout(False)
    End Sub

    Friend WithEvents TableLayoutPanel1 As TableLayoutPanel
    Friend WithEvents pnlHeader As Panel
    Friend WithEvents lblSubHeader As Label
    Friend WithEvents lblHeader As Label
    Friend WithEvents Panel1 As Panel
    Friend WithEvents TableLayoutPanel6 As TableLayoutPanel
    Friend WithEvents Panel18 As Panel
    Friend WithEvents btnCancelOrder As Button
    Friend WithEvents btnDineIn As Button
    Friend WithEvents btnTakeOut As Button
    Friend WithEvents btnCheckout As Button
    Friend WithEvents Panel19 As Panel
    Friend WithEvents Panel20 As Panel
    Friend WithEvents Label40 As Label
    Friend WithEvents lblTotal As Label
    Friend WithEvents lblTotalValue As Label
    Friend WithEvents Label41 As Label
    Friend WithEvents TableLayoutPanel2 As TableLayoutPanel
    Friend WithEvents Panel2 As Panel
    Friend WithEvents flpCategories As FlowLayoutPanel
    Friend WithEvents btnAll As Button
    Friend WithEvents btnPlatter As Button
    Friend WithEvents btnSpaghetti As Button
    Friend WithEvents btnDessert As Button
    Friend WithEvents btnRiceMeal As Button
    Friend WithEvents btnSnacks As Button
    Friend WithEvents Panel12 As Panel
    Friend WithEvents TableLayoutPanel4 As TableLayoutPanel
    Friend WithEvents Panel15 As Panel
    Friend WithEvents Panel16 As Panel
    Friend WithEvents Label37 As Label
    Friend WithEvents Panel13 As Panel
    Friend WithEvents TableLayoutPanel5 As TableLayoutPanel
    Friend WithEvents btnRice As Button
    Friend WithEvents Button2 As Button
    Friend WithEvents Button3 As Button
    Friend WithEvents TableLayoutPanel3 As TableLayoutPanel
    Friend WithEvents Panel7 As Panel
    Friend WithEvents Label10 As Label
    Friend WithEvents Label11 As Label
    Friend WithEvents Label12 As Label
    Friend WithEvents PictureBox4 As PictureBox
    Friend WithEvents Panel6 As Panel
    Friend WithEvents Label7 As Label
    Friend WithEvents Label8 As Label
    Friend WithEvents Label9 As Label
    Friend WithEvents PictureBox3 As PictureBox
    Friend WithEvents Panel5 As Panel
    Friend WithEvents Label4 As Label
    Friend WithEvents Label5 As Label
    Friend WithEvents Label6 As Label
    Friend WithEvents PictureBox2 As PictureBox
    Friend WithEvents Panel4 As Panel
    Friend WithEvents Label3 As Label
    Friend WithEvents Label2 As Label
    Friend WithEvents Label1 As Label
    Friend WithEvents PictureBox1 As PictureBox
    Friend WithEvents Panel3 As Panel
    Friend WithEvents PictureBox5 As PictureBox
    Friend WithEvents Label13 As Label
    Friend WithEvents Label27 As Label
    Friend WithEvents PictureBox10 As PictureBox
    Friend WithEvents Label28 As Label
End Class