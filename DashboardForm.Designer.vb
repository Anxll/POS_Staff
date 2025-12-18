<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class DashboardForm
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
        tlpRoot = New TableLayoutPanel()
        pnlHeader = New Panel()
        lblSubHeader = New Label()
        lblHeader = New Label()
        tlpCards = New TableLayoutPanel()
        pnlCardOrders = New Panel()
        lblCardOrdersCaption = New Label()
        lblCardOrdersValue = New Label()
        lblCardOrdersTitle = New Label()
        pnlCardReservations = New Panel()
        lblCardReservationsCaption = New Label()
        lblCardReservationsValue = New Label()
        lblCardReservationsTitle = New Label()
        pnlCardTime = New Panel()
        lblCardTimeCaption = New Label()
        lblCardTimeValue = New Label()
        lblCardTimeTitle = New Label()
        tlpBottom = New TableLayoutPanel()
        pnlTodayOrders = New Panel()
        TableLayoutPanel3 = New TableLayoutPanel()
        Panel1 = New Panel()
        lblActiveOrdersTitle = New Label()
        lblActiveOrdersSubtitle = New Label()
        Panel2 = New Panel()
        pnlActiveOrdersPlaceholder = New Panel()
        Panel20 = New Panel()
        Label5 = New Label()
        Label10 = New Label()
        TableLayoutPanel1 = New TableLayoutPanel()
        Label2 = New Label()
        Button1 = New Button()
        Label3 = New Label()
        btn = New Button()
        Label4 = New Label()
        Label1 = New Label()
        pnlTodayReservations = New Panel()
        TableLayoutPanel4 = New TableLayoutPanel()
        Panel3 = New Panel()
        lblTodayReservationsTitle = New Label()
        lblTodayReservationsSubtitle = New Label()
        Panel4 = New Panel()
        pnlTodayReservationsPlaceholder = New Panel()
        Panel7 = New Panel()
        LblTime = New Label()
        Button4 = New Button()
        lblGuest = New Label()
        Button5 = New Button()
        lblName = New Label()
        TableLayoutPanel2 = New TableLayoutPanel()
        tlpRoot.SuspendLayout()
        pnlHeader.SuspendLayout()
        tlpCards.SuspendLayout()
        pnlCardOrders.SuspendLayout()
        pnlCardReservations.SuspendLayout()
        pnlCardTime.SuspendLayout()
        tlpBottom.SuspendLayout()
        pnlTodayOrders.SuspendLayout()
        TableLayoutPanel3.SuspendLayout()
        Panel1.SuspendLayout()
        Panel2.SuspendLayout()
        pnlActiveOrdersPlaceholder.SuspendLayout()
        pnlTodayReservations.SuspendLayout()
        TableLayoutPanel4.SuspendLayout()
        Panel3.SuspendLayout()
        Panel4.SuspendLayout()
        pnlTodayReservationsPlaceholder.SuspendLayout()
        SuspendLayout()
        ' 
        ' tlpRoot
        ' 
        tlpRoot.ColumnCount = 1
        tlpRoot.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        tlpRoot.Controls.Add(pnlHeader, 0, 0)
        tlpRoot.Controls.Add(tlpCards, 0, 1)
        tlpRoot.Controls.Add(tlpBottom, 0, 2)
        tlpRoot.Dock = DockStyle.Fill
        tlpRoot.Location = New Point(0, 0)
        tlpRoot.Margin = New Padding(0)
        tlpRoot.Name = "tlpRoot"
        tlpRoot.Padding = New Padding(24)
        tlpRoot.RowCount = 3
        tlpRoot.RowStyles.Add(New RowStyle())
        tlpRoot.RowStyles.Add(New RowStyle())
        tlpRoot.RowStyles.Add(New RowStyle(SizeType.Percent, 100F))
        tlpRoot.Size = New Size(1783, 826)
        tlpRoot.TabIndex = 0
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
        pnlHeader.Size = New Size(1735, 68)
        pnlHeader.TabIndex = 0
        ' 
        ' lblSubHeader
        ' 
        lblSubHeader.AutoSize = True
        lblSubHeader.Font = New Font("Segoe UI", 10F)
        lblSubHeader.ForeColor = Color.FromArgb(CByte(85), CByte(85), CByte(85))
        lblSubHeader.Location = New Point(0, 45)
        lblSubHeader.Margin = New Padding(0)
        lblSubHeader.Name = "lblSubHeader"
        lblSubHeader.Size = New Size(276, 23)
        lblSubHeader.TabIndex = 1
        lblSubHeader.Text = "Your daily tasks and responsibilities"
        ' 
        ' lblHeader
        ' 
        lblHeader.AutoSize = True
        lblHeader.Font = New Font("Segoe UI", 18F, FontStyle.Bold)
        lblHeader.ForeColor = Color.Black
        lblHeader.Location = New Point(0, 0)
        lblHeader.Margin = New Padding(0)
        lblHeader.Name = "lblHeader"
        lblHeader.Size = New Size(247, 41)
        lblHeader.TabIndex = 0
        lblHeader.Text = "Staff Dashboard"
        ' 
        ' tlpCards
        ' 
        tlpCards.ColumnCount = 4
        tlpCards.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 25F))
        tlpCards.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 25F))
        tlpCards.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 25F))
        tlpCards.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 25F))
        tlpCards.Controls.Add(pnlCardOrders, 0, 0)
        tlpCards.Controls.Add(pnlCardReservations, 1, 0)
        tlpCards.Controls.Add(pnlCardTime, 2, 0)
        tlpCards.Dock = DockStyle.Fill
        tlpCards.Location = New Point(24, 108)
        tlpCards.Margin = New Padding(0, 0, 0, 24)
        tlpCards.Name = "tlpCards"
        tlpCards.RowCount = 1
        tlpCards.RowStyles.Add(New RowStyle(SizeType.Percent, 100F))
        tlpCards.Size = New Size(1735, 144)
        tlpCards.TabIndex = 1
        ' 
        ' pnlCardOrders
        ' 
        pnlCardOrders.BackColor = Color.FromArgb(CByte(251), CByte(239), CByte(236))
        pnlCardOrders.BorderStyle = BorderStyle.FixedSingle
        pnlCardOrders.Controls.Add(lblCardOrdersCaption)
        pnlCardOrders.Controls.Add(lblCardOrdersValue)
        pnlCardOrders.Controls.Add(lblCardOrdersTitle)
        pnlCardOrders.Dock = DockStyle.Fill
        pnlCardOrders.Location = New Point(0, 0)
        pnlCardOrders.Margin = New Padding(0, 0, 12, 0)
        pnlCardOrders.Name = "pnlCardOrders"
        pnlCardOrders.Padding = New Padding(16)
        pnlCardOrders.Size = New Size(421, 144)
        pnlCardOrders.TabIndex = 0
        ' 
        ' lblCardOrdersCaption
        ' 
        lblCardOrdersCaption.AutoSize = True
        lblCardOrdersCaption.Font = New Font("Segoe UI", 9F)
        lblCardOrdersCaption.ForeColor = Color.FromArgb(CByte(85), CByte(85), CByte(85))
        lblCardOrdersCaption.Location = New Point(16, 108)
        lblCardOrdersCaption.Name = "lblCardOrdersCaption"
        lblCardOrdersCaption.Size = New Size(111, 20)
        lblCardOrdersCaption.TabIndex = 2
        lblCardOrdersCaption.Text = "Orders handled"
        ' 
        ' lblCardOrdersValue
        ' 
        lblCardOrdersValue.AutoSize = True
        lblCardOrdersValue.Font = New Font("Segoe UI", 18F, FontStyle.Bold)
        lblCardOrdersValue.ForeColor = Color.Black
        lblCardOrdersValue.Location = New Point(16, 62)
        lblCardOrdersValue.Name = "lblCardOrdersValue"
        lblCardOrdersValue.Size = New Size(52, 41)
        lblCardOrdersValue.TabIndex = 1
        lblCardOrdersValue.Text = "25"
        ' 
        ' lblCardOrdersTitle
        ' 
        lblCardOrdersTitle.AutoSize = True
        lblCardOrdersTitle.Font = New Font("Segoe UI", 11F, FontStyle.Bold)
        lblCardOrdersTitle.ForeColor = Color.Black
        lblCardOrdersTitle.Location = New Point(16, 16)
        lblCardOrdersTitle.Name = "lblCardOrdersTitle"
        lblCardOrdersTitle.Size = New Size(163, 25)
        lblCardOrdersTitle.TabIndex = 0
        lblCardOrdersTitle.Text = "My Orders Today"
        ' 
        ' pnlCardReservations
        ' 
        pnlCardReservations.BackColor = Color.FromArgb(CByte(251), CByte(239), CByte(236))
        pnlCardReservations.BorderStyle = BorderStyle.FixedSingle
        pnlCardReservations.Controls.Add(lblCardReservationsCaption)
        pnlCardReservations.Controls.Add(lblCardReservationsValue)
        pnlCardReservations.Controls.Add(lblCardReservationsTitle)
        pnlCardReservations.Dock = DockStyle.Fill
        pnlCardReservations.Location = New Point(433, 0)
        pnlCardReservations.Margin = New Padding(0, 0, 12, 0)
        pnlCardReservations.Name = "pnlCardReservations"
        pnlCardReservations.Padding = New Padding(16)
        pnlCardReservations.Size = New Size(421, 144)
        pnlCardReservations.TabIndex = 1
        ' 
        ' lblCardReservationsCaption
        ' 
        lblCardReservationsCaption.AutoSize = True
        lblCardReservationsCaption.Font = New Font("Segoe UI", 9F)
        lblCardReservationsCaption.ForeColor = Color.FromArgb(CByte(85), CByte(85), CByte(85))
        lblCardReservationsCaption.Location = New Point(16, 108)
        lblCardReservationsCaption.Name = "lblCardReservationsCaption"
        lblCardReservationsCaption.Size = New Size(123, 20)
        lblCardReservationsCaption.TabIndex = 2
        lblCardReservationsCaption.Text = "Today's bookings"
        ' 
        ' lblCardReservationsValue
        ' 
        lblCardReservationsValue.AutoSize = True
        lblCardReservationsValue.Font = New Font("Segoe UI", 18F, FontStyle.Bold)
        lblCardReservationsValue.ForeColor = Color.Black
        lblCardReservationsValue.Location = New Point(16, 62)
        lblCardReservationsValue.Name = "lblCardReservationsValue"
        lblCardReservationsValue.Size = New Size(35, 41)
        lblCardReservationsValue.TabIndex = 1
        lblCardReservationsValue.Text = "7"
        ' 
        ' lblCardReservationsTitle
        ' 
        lblCardReservationsTitle.AutoSize = True
        lblCardReservationsTitle.Font = New Font("Segoe UI", 11F, FontStyle.Bold)
        lblCardReservationsTitle.ForeColor = Color.Black
        lblCardReservationsTitle.Location = New Point(16, 16)
        lblCardReservationsTitle.Name = "lblCardReservationsTitle"
        lblCardReservationsTitle.Size = New Size(125, 25)
        lblCardReservationsTitle.TabIndex = 0
        lblCardReservationsTitle.Text = "Reservations"
        ' 
        ' pnlCardTime
        ' 
        pnlCardTime.BackColor = Color.FromArgb(CByte(251), CByte(239), CByte(236))
        pnlCardTime.BorderStyle = BorderStyle.FixedSingle
        pnlCardTime.Controls.Add(lblCardTimeCaption)
        pnlCardTime.Controls.Add(lblCardTimeValue)
        pnlCardTime.Controls.Add(lblCardTimeTitle)
        pnlCardTime.Dock = DockStyle.Fill
        pnlCardTime.Location = New Point(866, 0)
        pnlCardTime.Margin = New Padding(0, 0, 12, 0)
        pnlCardTime.Name = "pnlCardTime"
        pnlCardTime.Padding = New Padding(16)
        pnlCardTime.Size = New Size(421, 144)
        pnlCardTime.TabIndex = 2
        ' 
        ' lblCardTimeCaption
        ' 
        lblCardTimeCaption.AutoSize = True
        lblCardTimeCaption.Font = New Font("Segoe UI", 9F)
        lblCardTimeCaption.ForeColor = Color.FromArgb(CByte(85), CByte(85), CByte(85))
        lblCardTimeCaption.Location = New Point(16, 108)
        lblCardTimeCaption.Name = "lblCardTimeCaption"
        lblCardTimeCaption.Size = New Size(108, 20)
        lblCardTimeCaption.TabIndex = 2
        lblCardTimeCaption.Text = "Latest time log"
        ' 
        ' lblCardTimeValue
        ' 
        lblCardTimeValue.AutoSize = True
        lblCardTimeValue.Font = New Font("Segoe UI", 18F, FontStyle.Bold)
        lblCardTimeValue.ForeColor = Color.Black
        lblCardTimeValue.Location = New Point(16, 62)
        lblCardTimeValue.Name = "lblCardTimeValue"
        lblCardTimeValue.Size = New Size(135, 41)
        lblCardTimeValue.TabIndex = 1
        lblCardTimeValue.Text = "8:00 AM"
        ' 
        ' lblCardTimeTitle
        ' 
        lblCardTimeTitle.AutoSize = True
        lblCardTimeTitle.Font = New Font("Segoe UI", 11F, FontStyle.Bold)
        lblCardTimeTitle.ForeColor = Color.Black
        lblCardTimeTitle.Location = New Point(16, 16)
        lblCardTimeTitle.Name = "lblCardTimeTitle"
        lblCardTimeTitle.Size = New Size(167, 25)
        lblCardTimeTitle.TabIndex = 0
        lblCardTimeTitle.Text = "Time In/Time Out"
        ' 
        ' tlpBottom
        ' 
        tlpBottom.ColumnCount = 2
        tlpBottom.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 50F))
        tlpBottom.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 50F))
        tlpBottom.Controls.Add(pnlTodayOrders, 0, 0)
        tlpBottom.Controls.Add(pnlTodayReservations, 1, 0)
        tlpBottom.Dock = DockStyle.Fill
        tlpBottom.Location = New Point(24, 276)
        tlpBottom.Margin = New Padding(0)
        tlpBottom.Name = "tlpBottom"
        tlpBottom.RowCount = 1
        tlpBottom.RowStyles.Add(New RowStyle(SizeType.Percent, 100F))
        tlpBottom.Size = New Size(1735, 526)
        tlpBottom.TabIndex = 2
        ' 
        ' pnlTodayOrders
        ' 
        pnlTodayOrders.BackColor = Color.FromArgb(CByte(251), CByte(239), CByte(236))
        pnlTodayOrders.BorderStyle = BorderStyle.FixedSingle
        pnlTodayOrders.Controls.Add(TableLayoutPanel3)
        pnlTodayOrders.Dock = DockStyle.Fill
        pnlTodayOrders.Location = New Point(0, 0)
        pnlTodayOrders.Margin = New Padding(0, 0, 12, 0)
        pnlTodayOrders.Name = "pnlTodayOrders"
        pnlTodayOrders.Padding = New Padding(20)
        pnlTodayOrders.Size = New Size(855, 526)
        pnlTodayOrders.TabIndex = 0
        ' 
        ' TableLayoutPanel3
        ' 
        TableLayoutPanel3.ColumnCount = 1
        TableLayoutPanel3.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        TableLayoutPanel3.Controls.Add(Panel1, 0, 0)
        TableLayoutPanel3.Controls.Add(Panel2, 0, 1)
        TableLayoutPanel3.Dock = DockStyle.Fill
        TableLayoutPanel3.Location = New Point(20, 20)
        TableLayoutPanel3.Name = "TableLayoutPanel3"
        TableLayoutPanel3.RowCount = 3
        TableLayoutPanel3.RowStyles.Add(New RowStyle(SizeType.Percent, 14.2857113F))
        TableLayoutPanel3.RowStyles.Add(New RowStyle(SizeType.Percent, 80.9523849F))
        TableLayoutPanel3.RowStyles.Add(New RowStyle(SizeType.Percent, 4.761905F))
        TableLayoutPanel3.Size = New Size(813, 484)
        TableLayoutPanel3.TabIndex = 0
        ' 
        ' Panel1
        ' 
        Panel1.Controls.Add(lblActiveOrdersTitle)
        Panel1.Controls.Add(lblActiveOrdersSubtitle)
        Panel1.Dock = DockStyle.Fill
        Panel1.Location = New Point(3, 3)
        Panel1.Name = "Panel1"
        Panel1.Size = New Size(807, 63)
        Panel1.TabIndex = 0
        ' 
        ' lblActiveOrdersTitle
        ' 
        lblActiveOrdersTitle.AutoSize = True
        lblActiveOrdersTitle.Font = New Font("Segoe UI", 14F, FontStyle.Bold)
        lblActiveOrdersTitle.ForeColor = Color.Black
        lblActiveOrdersTitle.Location = New Point(3, 1)
        lblActiveOrdersTitle.Name = "lblActiveOrdersTitle"
        lblActiveOrdersTitle.Size = New Size(166, 32)
        lblActiveOrdersTitle.TabIndex = 0
        lblActiveOrdersTitle.Text = "Today Orders"
        ' 
        ' lblActiveOrdersSubtitle
        ' 
        lblActiveOrdersSubtitle.AutoSize = True
        lblActiveOrdersSubtitle.Font = New Font("Segoe UI", 10F)
        lblActiveOrdersSubtitle.ForeColor = Color.FromArgb(CByte(85), CByte(85), CByte(85))
        lblActiveOrdersSubtitle.Location = New Point(3, 41)
        lblActiveOrdersSubtitle.Name = "lblActiveOrdersSubtitle"
        lblActiveOrdersSubtitle.Size = New Size(203, 23)
        lblActiveOrdersSubtitle.TabIndex = 1
        lblActiveOrdersSubtitle.Text = "Orders being order today"
        ' 
        ' Panel2
        ' 
        Panel2.Controls.Add(pnlActiveOrdersPlaceholder)
        Panel2.Dock = DockStyle.Fill
        Panel2.Location = New Point(3, 72)
        Panel2.Name = "Panel2"
        Panel2.Size = New Size(807, 385)
        Panel2.TabIndex = 1
        ' 
        ' pnlActiveOrdersPlaceholder
        ' 
        pnlActiveOrdersPlaceholder.AutoScroll = True
        pnlActiveOrdersPlaceholder.BackColor = Color.White
        pnlActiveOrdersPlaceholder.BorderStyle = BorderStyle.FixedSingle
        pnlActiveOrdersPlaceholder.Controls.Add(Panel20)
        pnlActiveOrdersPlaceholder.Controls.Add(Label5)
        pnlActiveOrdersPlaceholder.Controls.Add(Label10)
        pnlActiveOrdersPlaceholder.Controls.Add(TableLayoutPanel1)
        pnlActiveOrdersPlaceholder.Controls.Add(Label2)
        pnlActiveOrdersPlaceholder.Controls.Add(Button1)
        pnlActiveOrdersPlaceholder.Controls.Add(Label3)
        pnlActiveOrdersPlaceholder.Controls.Add(btn)
        pnlActiveOrdersPlaceholder.Controls.Add(Label4)
        pnlActiveOrdersPlaceholder.Controls.Add(Label1)
        pnlActiveOrdersPlaceholder.Dock = DockStyle.Fill
        pnlActiveOrdersPlaceholder.Location = New Point(0, 0)
        pnlActiveOrdersPlaceholder.Name = "pnlActiveOrdersPlaceholder"
        pnlActiveOrdersPlaceholder.Size = New Size(807, 385)
        pnlActiveOrdersPlaceholder.TabIndex = 2
        ' 
        ' Panel20
        ' 
        Panel20.BorderStyle = BorderStyle.FixedSingle
        Panel20.ForeColor = Color.Black
        Panel20.Location = New Point(2, 81)
        Panel20.Name = "Panel20"
        Panel20.Size = New Size(801, 1)
        Panel20.TabIndex = 25
        ' 
        ' Label5
        ' 
        Label5.AutoSize = True
        Label5.Font = New Font("Segoe UI", 7F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        Label5.ForeColor = Color.Black
        Label5.Location = New Point(290, 36)
        Label5.Name = "Label5"
        Label5.Size = New Size(35, 15)
        Label5.TabIndex = 33
        Label5.Text = "(ETC)"
        ' 
        ' Label10
        ' 
        Label10.AutoSize = True
        Label10.Font = New Font("Segoe UI Black", 12F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Label10.ForeColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        Label10.Location = New Point(685, 28)
        Label10.Name = "Label10"
        Label10.Size = New Size(93, 28)
        Label10.TabIndex = 32
        Label10.Text = "₱250.00"
        ' 
        ' TableLayoutPanel1
        ' 
        TableLayoutPanel1.AutoSize = True
        TableLayoutPanel1.AutoSizeMode = AutoSizeMode.GrowAndShrink
        TableLayoutPanel1.CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
        TableLayoutPanel1.ColumnCount = 1
        TableLayoutPanel1.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        TableLayoutPanel1.ColumnStyles.Add(New ColumnStyle(SizeType.Absolute, 20F))
        TableLayoutPanel1.Location = New Point(0, 0)
        TableLayoutPanel1.Name = "TableLayoutPanel1"
        TableLayoutPanel1.RowCount = 4
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Percent, 25F))
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Percent, 25F))
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Percent, 25F))
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Percent, 25F))
        TableLayoutPanel1.Size = New Size(2, 5)
        TableLayoutPanel1.TabIndex = 0
        ' 
        ' Label2
        ' 
        Label2.AutoSize = True
        Label2.Font = New Font("Segoe UI", 8.5F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        Label2.ForeColor = Color.Black
        Label2.Location = New Point(139, 21)
        Label2.Name = "Label2"
        Label2.Size = New Size(61, 20)
        Label2.TabIndex = 27
        Label2.Text = "6:19 PM"
        ' 
        ' Button1
        ' 
        Button1.BackColor = Color.WhiteSmoke
        Button1.FlatStyle = FlatStyle.Flat
        Button1.Font = New Font("Segoe UI", 10F, FontStyle.Bold)
        Button1.ForeColor = Color.Red
        Button1.Location = New Point(509, 22)
        Button1.Margin = New Padding(25)
        Button1.Name = "Button1"
        Button1.Size = New Size(116, 40)
        Button1.TabIndex = 31
        Button1.Text = "Cancel"
        Button1.UseVisualStyleBackColor = False
        ' 
        ' Label3
        ' 
        Label3.AutoSize = True
        Label3.Font = New Font("Segoe UI", 8.5F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        Label3.ForeColor = Color.Black
        Label3.Location = New Point(139, 41)
        Label3.Name = "Label3"
        Label3.Size = New Size(58, 20)
        Label3.TabIndex = 28
        Label3.Text = "Dine-In"
        ' 
        ' btn
        ' 
        btn.BackColor = Color.WhiteSmoke
        btn.FlatStyle = FlatStyle.Flat
        btn.Font = New Font("Segoe UI", 10F, FontStyle.Bold)
        btn.ForeColor = Color.FromArgb(CByte(0), CByte(192), CByte(0))
        btn.Location = New Point(375, 22)
        btn.Margin = New Padding(25)
        btn.Name = "btn"
        btn.Size = New Size(116, 40)
        btn.TabIndex = 30
        btn.Text = "Complete"
        btn.UseVisualStyleBackColor = False
        ' 
        ' Label4
        ' 
        Label4.AutoSize = True
        Label4.Font = New Font("Segoe UI", 9F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        Label4.ForeColor = Color.Black
        Label4.Location = New Point(237, 31)
        Label4.Name = "Label4"
        Label4.Size = New Size(56, 20)
        Label4.TabIndex = 29
        Label4.Text = "15mins"
        ' 
        ' Label1
        ' 
        Label1.AutoSize = True
        Label1.Font = New Font("Segoe UI", 11F, FontStyle.Bold)
        Label1.ForeColor = Color.Black
        Label1.Location = New Point(15, 28)
        Label1.Name = "Label1"
        Label1.Size = New Size(78, 25)
        Label1.TabIndex = 26
        Label1.Text = "#13013"
        ' 
        ' pnlTodayReservations
        ' 
        pnlTodayReservations.BackColor = Color.FromArgb(CByte(251), CByte(239), CByte(236))
        pnlTodayReservations.BorderStyle = BorderStyle.FixedSingle
        pnlTodayReservations.Controls.Add(TableLayoutPanel4)
        pnlTodayReservations.Dock = DockStyle.Fill
        pnlTodayReservations.Location = New Point(879, 0)
        pnlTodayReservations.Margin = New Padding(12, 0, 0, 0)
        pnlTodayReservations.Name = "pnlTodayReservations"
        pnlTodayReservations.Padding = New Padding(20)
        pnlTodayReservations.Size = New Size(856, 526)
        pnlTodayReservations.TabIndex = 1
        ' 
        ' TableLayoutPanel4
        ' 
        TableLayoutPanel4.ColumnCount = 1
        TableLayoutPanel4.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        TableLayoutPanel4.Controls.Add(Panel3, 0, 0)
        TableLayoutPanel4.Controls.Add(Panel4, 0, 1)
        TableLayoutPanel4.Dock = DockStyle.Fill
        TableLayoutPanel4.Location = New Point(20, 20)
        TableLayoutPanel4.Name = "TableLayoutPanel4"
        TableLayoutPanel4.RowCount = 2
        TableLayoutPanel4.RowStyles.Add(New RowStyle(SizeType.Percent, 15F))
        TableLayoutPanel4.RowStyles.Add(New RowStyle(SizeType.Percent, 85F))
        TableLayoutPanel4.Size = New Size(814, 484)
        TableLayoutPanel4.TabIndex = 0
        ' 
        ' Panel3
        ' 
        Panel3.Controls.Add(lblTodayReservationsTitle)
        Panel3.Controls.Add(lblTodayReservationsSubtitle)
        Panel3.Dock = DockStyle.Fill
        Panel3.Location = New Point(3, 3)
        Panel3.Name = "Panel3"
        Panel3.Size = New Size(808, 66)
        Panel3.TabIndex = 0
        ' 
        ' lblTodayReservationsTitle
        ' 
        lblTodayReservationsTitle.AutoSize = True
        lblTodayReservationsTitle.Font = New Font("Segoe UI", 14F, FontStyle.Bold)
        lblTodayReservationsTitle.ForeColor = Color.Black
        lblTodayReservationsTitle.Location = New Point(3, 1)
        lblTodayReservationsTitle.Name = "lblTodayReservationsTitle"
        lblTodayReservationsTitle.Size = New Size(235, 32)
        lblTodayReservationsTitle.TabIndex = 0
        lblTodayReservationsTitle.Text = "Today Reservations"
        ' 
        ' lblTodayReservationsSubtitle
        ' 
        lblTodayReservationsSubtitle.AutoSize = True
        lblTodayReservationsSubtitle.Font = New Font("Segoe UI", 10F)
        lblTodayReservationsSubtitle.ForeColor = Color.FromArgb(CByte(85), CByte(85), CByte(85))
        lblTodayReservationsSubtitle.Location = New Point(3, 41)
        lblTodayReservationsSubtitle.Name = "lblTodayReservationsSubtitle"
        lblTodayReservationsSubtitle.Size = New Size(248, 23)
        lblTodayReservationsSubtitle.TabIndex = 1
        lblTodayReservationsSubtitle.Text = "Upcoming bookings to prepare"
        ' 
        ' Panel4
        ' 
        Panel4.Controls.Add(pnlTodayReservationsPlaceholder)
        Panel4.Dock = DockStyle.Fill
        Panel4.Location = New Point(3, 75)
        Panel4.Name = "Panel4"
        Panel4.Size = New Size(808, 406)
        Panel4.TabIndex = 1
        ' 
        ' pnlTodayReservationsPlaceholder
        ' 
        pnlTodayReservationsPlaceholder.AutoScroll = True
        pnlTodayReservationsPlaceholder.BackColor = Color.White
        pnlTodayReservationsPlaceholder.BorderStyle = BorderStyle.FixedSingle
        pnlTodayReservationsPlaceholder.Controls.Add(Panel7)
        pnlTodayReservationsPlaceholder.Controls.Add(LblTime)
        pnlTodayReservationsPlaceholder.Controls.Add(Button4)
        pnlTodayReservationsPlaceholder.Controls.Add(lblGuest)
        pnlTodayReservationsPlaceholder.Controls.Add(Button5)
        pnlTodayReservationsPlaceholder.Controls.Add(lblName)
        pnlTodayReservationsPlaceholder.Controls.Add(TableLayoutPanel2)
        pnlTodayReservationsPlaceholder.Dock = DockStyle.Fill
        pnlTodayReservationsPlaceholder.Location = New Point(0, 0)
        pnlTodayReservationsPlaceholder.Name = "pnlTodayReservationsPlaceholder"
        pnlTodayReservationsPlaceholder.Size = New Size(808, 406)
        pnlTodayReservationsPlaceholder.TabIndex = 2
        ' 
        ' Panel7
        ' 
        Panel7.BorderStyle = BorderStyle.FixedSingle
        Panel7.Location = New Point(3, 78)
        Panel7.Name = "Panel7"
        Panel7.Size = New Size(801, 1)
        Panel7.TabIndex = 32
        ' 
        ' LblTime
        ' 
        LblTime.AutoSize = True
        LblTime.Font = New Font("Segoe UI", 8.5F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        LblTime.ForeColor = Color.Black
        LblTime.Location = New Point(304, 18)
        LblTime.Name = "LblTime"
        LblTime.Size = New Size(61, 20)
        LblTime.TabIndex = 34
        LblTime.Text = "6:19 PM"
        ' 
        ' Button4
        ' 
        Button4.BackColor = Color.WhiteSmoke
        Button4.FlatStyle = FlatStyle.Flat
        Button4.Font = New Font("Segoe UI", 10F, FontStyle.Bold)
        Button4.ForeColor = Color.Red
        Button4.Location = New Point(658, 19)
        Button4.Margin = New Padding(25)
        Button4.Name = "Button4"
        Button4.Size = New Size(116, 40)
        Button4.TabIndex = 37
        Button4.Text = "Cancel"
        Button4.UseVisualStyleBackColor = False
        ' 
        ' lblGuest
        ' 
        lblGuest.AutoSize = True
        lblGuest.Font = New Font("Segoe UI", 8.5F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblGuest.ForeColor = Color.Black
        lblGuest.Location = New Point(297, 38)
        lblGuest.Name = "lblGuest"
        lblGuest.Size = New Size(72, 20)
        lblGuest.TabIndex = 35
        lblGuest.Text = "14 Guests"
        ' 
        ' Button5
        ' 
        Button5.BackColor = Color.WhiteSmoke
        Button5.FlatStyle = FlatStyle.Flat
        Button5.Font = New Font("Segoe UI", 10F, FontStyle.Bold)
        Button5.ForeColor = Color.FromArgb(CByte(0), CByte(192), CByte(0))
        Button5.Location = New Point(524, 19)
        Button5.Margin = New Padding(25)
        Button5.Name = "Button5"
        Button5.Size = New Size(116, 40)
        Button5.TabIndex = 36
        Button5.Text = "Complete"
        Button5.UseVisualStyleBackColor = False
        ' 
        ' lblName
        ' 
        lblName.AutoSize = True
        lblName.Font = New Font("Segoe UI", 11F, FontStyle.Bold)
        lblName.ForeColor = Color.Black
        lblName.Location = New Point(26, 25)
        lblName.Name = "lblName"
        lblName.Size = New Size(163, 25)
        lblName.TabIndex = 33
        lblName.Text = "Angelo Malaluan"
        ' 
        ' TableLayoutPanel2
        ' 
        TableLayoutPanel2.AutoSize = True
        TableLayoutPanel2.AutoSizeMode = AutoSizeMode.GrowAndShrink
        TableLayoutPanel2.CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
        TableLayoutPanel2.ColumnCount = 1
        TableLayoutPanel2.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        TableLayoutPanel2.ColumnStyles.Add(New ColumnStyle(SizeType.Absolute, 20F))
        TableLayoutPanel2.Location = New Point(0, 0)
        TableLayoutPanel2.Name = "TableLayoutPanel2"
        TableLayoutPanel2.RowCount = 4
        TableLayoutPanel2.RowStyles.Add(New RowStyle(SizeType.Percent, 25F))
        TableLayoutPanel2.RowStyles.Add(New RowStyle(SizeType.Percent, 25F))
        TableLayoutPanel2.RowStyles.Add(New RowStyle(SizeType.Percent, 25F))
        TableLayoutPanel2.RowStyles.Add(New RowStyle(SizeType.Percent, 25F))
        TableLayoutPanel2.Size = New Size(2, 5)
        TableLayoutPanel2.TabIndex = 1
        ' 
        ' DashboardForm
        ' 
        AutoScaleDimensions = New SizeF(9F, 23F)
        AutoScaleMode = AutoScaleMode.Font
        BackColor = Color.White
        ClientSize = New Size(1783, 826)
        Controls.Add(tlpRoot)
        Font = New Font("Segoe UI", 10F)
        FormBorderStyle = FormBorderStyle.None
        Name = "DashboardForm"
        tlpRoot.ResumeLayout(False)
        tlpRoot.PerformLayout()
        pnlHeader.ResumeLayout(False)
        pnlHeader.PerformLayout()
        tlpCards.ResumeLayout(False)
        pnlCardOrders.ResumeLayout(False)
        pnlCardOrders.PerformLayout()
        pnlCardReservations.ResumeLayout(False)
        pnlCardReservations.PerformLayout()
        pnlCardTime.ResumeLayout(False)
        pnlCardTime.PerformLayout()
        tlpBottom.ResumeLayout(False)
        pnlTodayOrders.ResumeLayout(False)
        TableLayoutPanel3.ResumeLayout(False)
        Panel1.ResumeLayout(False)
        Panel1.PerformLayout()
        Panel2.ResumeLayout(False)
        pnlActiveOrdersPlaceholder.ResumeLayout(False)
        pnlActiveOrdersPlaceholder.PerformLayout()
        pnlTodayReservations.ResumeLayout(False)
        TableLayoutPanel4.ResumeLayout(False)
        Panel3.ResumeLayout(False)
        Panel3.PerformLayout()
        Panel4.ResumeLayout(False)
        pnlTodayReservationsPlaceholder.ResumeLayout(False)
        pnlTodayReservationsPlaceholder.PerformLayout()
        ResumeLayout(False)
    End Sub

    Friend WithEvents tlpRoot As TableLayoutPanel
    Friend WithEvents pnlHeader As Panel
    Friend WithEvents lblSubHeader As Label
    Friend WithEvents lblHeader As Label
    Friend WithEvents tlpCards As TableLayoutPanel
    Friend WithEvents pnlCardOrders As Panel
    Friend WithEvents lblCardOrdersCaption As Label
    Friend WithEvents lblCardOrdersValue As Label
    Friend WithEvents lblCardOrdersTitle As Label
    Friend WithEvents pnlCardReservations As Panel
    Friend WithEvents lblCardReservationsCaption As Label
    Friend WithEvents lblCardReservationsValue As Label
    Friend WithEvents lblCardReservationsTitle As Label
    Friend WithEvents pnlCardTime As Panel
    Friend WithEvents lblCardTimeCaption As Label
    Friend WithEvents lblCardTimeValue As Label
    Friend WithEvents lblCardTimeTitle As Label
    Friend WithEvents tlpBottom As TableLayoutPanel
    Friend WithEvents pnlTodayOrders As Panel
    Friend WithEvents pnlActiveOrdersPlaceholder As Panel
    Friend WithEvents lblActiveOrdersSubtitle As Label
    Friend WithEvents lblActiveOrdersTitle As Label
    Friend WithEvents pnlTodayReservations As Panel
    Friend WithEvents lblTodayReservationsSubtitle As Label
    Friend WithEvents lblTodayReservationsTitle As Label
    Friend WithEvents TableLayoutPanel1 As TableLayoutPanel
    Friend WithEvents Panel20 As Panel
    Friend WithEvents Label5 As Label
    Friend WithEvents Label10 As Label
    Friend WithEvents Label2 As Label
    Friend WithEvents Button1 As Button
    Friend WithEvents Label3 As Label
    Friend WithEvents btn As Button
    Friend WithEvents Label4 As Label
    Friend WithEvents Label1 As Label
    Friend WithEvents TableLayoutPanel3 As TableLayoutPanel
    Friend WithEvents Panel1 As Panel
    Friend WithEvents Panel2 As Panel
    Friend WithEvents TableLayoutPanel4 As TableLayoutPanel
    Friend WithEvents Panel3 As Panel
    Friend WithEvents Panel4 As Panel
    Friend WithEvents pnlTodayReservationsPlaceholder As Panel
    Friend WithEvents TableLayoutPanel2 As TableLayoutPanel
    Friend WithEvents Panel7 As Panel
    Friend WithEvents LblTime As Label
    Friend WithEvents Button4 As Button
    Friend WithEvents lblGuest As Label
    Friend WithEvents Button5 As Button
    Friend WithEvents lblName As Label
End Class

