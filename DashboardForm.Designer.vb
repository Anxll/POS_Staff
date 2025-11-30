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
        pnlCardFeedback = New Panel()
        lblCardFeedbackCaption = New Label()
        lblCardFeedbackValue = New Label()
        lblCardFeedbackTitle = New Label()
        tlpBottom = New TableLayoutPanel()
        pnlActiveOrders = New Panel()
        pnlActiveOrdersPlaceholder = New Panel()
        TableLayoutPanel1 = New TableLayoutPanel()
        lblActiveOrdersSubtitle = New Label()
        lblActiveOrdersTitle = New Label()
        pnlTodayReservations = New Panel()
        pnlTodayReservationsPlaceholder = New Panel()
        TableLayoutPanel2 = New TableLayoutPanel()
        lblTodayReservationsSubtitle = New Label()
        lblTodayReservationsTitle = New Label()
        tlpRoot.SuspendLayout()
        pnlHeader.SuspendLayout()
        tlpCards.SuspendLayout()
        pnlCardOrders.SuspendLayout()
        pnlCardReservations.SuspendLayout()
        pnlCardTime.SuspendLayout()
        pnlCardFeedback.SuspendLayout()
        tlpBottom.SuspendLayout()
        pnlActiveOrders.SuspendLayout()
        pnlActiveOrdersPlaceholder.SuspendLayout()
        pnlTodayReservations.SuspendLayout()
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
        tlpRoot.Size = New Size(1120, 620)
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
        pnlHeader.Size = New Size(1072, 68)
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
        tlpCards.Controls.Add(pnlCardFeedback, 3, 0)
        tlpCards.Dock = DockStyle.Fill
        tlpCards.Location = New Point(24, 108)
        tlpCards.Margin = New Padding(0, 0, 0, 24)
        tlpCards.Name = "tlpCards"
        tlpCards.RowCount = 1
        tlpCards.RowStyles.Add(New RowStyle(SizeType.Percent, 100F))
        tlpCards.Size = New Size(1072, 144)
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
        pnlCardOrders.Size = New Size(256, 144)
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
        pnlCardReservations.Location = New Point(268, 0)
        pnlCardReservations.Margin = New Padding(0, 0, 12, 0)
        pnlCardReservations.Name = "pnlCardReservations"
        pnlCardReservations.Padding = New Padding(16)
        pnlCardReservations.Size = New Size(256, 144)
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
        pnlCardTime.Location = New Point(536, 0)
        pnlCardTime.Margin = New Padding(0, 0, 12, 0)
        pnlCardTime.Name = "pnlCardTime"
        pnlCardTime.Padding = New Padding(16)
        pnlCardTime.Size = New Size(256, 144)
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
        ' pnlCardFeedback
        ' 
        pnlCardFeedback.BackColor = Color.FromArgb(CByte(251), CByte(239), CByte(236))
        pnlCardFeedback.BorderStyle = BorderStyle.FixedSingle
        pnlCardFeedback.Controls.Add(lblCardFeedbackCaption)
        pnlCardFeedback.Controls.Add(lblCardFeedbackValue)
        pnlCardFeedback.Controls.Add(lblCardFeedbackTitle)
        pnlCardFeedback.Dock = DockStyle.Fill
        pnlCardFeedback.Location = New Point(804, 0)
        pnlCardFeedback.Margin = New Padding(0)
        pnlCardFeedback.Name = "pnlCardFeedback"
        pnlCardFeedback.Padding = New Padding(16)
        pnlCardFeedback.Size = New Size(268, 144)
        pnlCardFeedback.TabIndex = 3
        ' 
        ' lblCardFeedbackCaption
        ' 
        lblCardFeedbackCaption.AutoSize = True
        lblCardFeedbackCaption.Font = New Font("Segoe UI", 9F)
        lblCardFeedbackCaption.ForeColor = Color.FromArgb(CByte(85), CByte(85), CByte(85))
        lblCardFeedbackCaption.Location = New Point(16, 108)
        lblCardFeedbackCaption.Name = "lblCardFeedbackCaption"
        lblCardFeedbackCaption.Size = New Size(92, 20)
        lblCardFeedbackCaption.TabIndex = 2
        lblCardFeedbackCaption.Text = "New reviews"
        ' 
        ' lblCardFeedbackValue
        ' 
        lblCardFeedbackValue.AutoSize = True
        lblCardFeedbackValue.Font = New Font("Segoe UI", 18F, FontStyle.Bold)
        lblCardFeedbackValue.ForeColor = Color.Black
        lblCardFeedbackValue.Location = New Point(16, 62)
        lblCardFeedbackValue.Name = "lblCardFeedbackValue"
        lblCardFeedbackValue.Size = New Size(35, 41)
        lblCardFeedbackValue.TabIndex = 1
        lblCardFeedbackValue.Text = "3"
        ' 
        ' lblCardFeedbackTitle
        ' 
        lblCardFeedbackTitle.AutoSize = True
        lblCardFeedbackTitle.Font = New Font("Segoe UI", 11F, FontStyle.Bold)
        lblCardFeedbackTitle.ForeColor = Color.Black
        lblCardFeedbackTitle.Location = New Point(16, 16)
        lblCardFeedbackTitle.Name = "lblCardFeedbackTitle"
        lblCardFeedbackTitle.Size = New Size(96, 25)
        lblCardFeedbackTitle.TabIndex = 0
        lblCardFeedbackTitle.Text = "Feedback"
        ' 
        ' tlpBottom
        ' 
        tlpBottom.ColumnCount = 2
        tlpBottom.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 50F))
        tlpBottom.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 50F))
        tlpBottom.Controls.Add(pnlActiveOrders, 0, 0)
        tlpBottom.Controls.Add(pnlTodayReservations, 1, 0)
        tlpBottom.Dock = DockStyle.Fill
        tlpBottom.Location = New Point(24, 276)
        tlpBottom.Margin = New Padding(0)
        tlpBottom.Name = "tlpBottom"
        tlpBottom.RowCount = 1
        tlpBottom.RowStyles.Add(New RowStyle(SizeType.Percent, 100F))
        tlpBottom.Size = New Size(1072, 320)
        tlpBottom.TabIndex = 2
        ' 
        ' pnlActiveOrders
        ' 
        pnlActiveOrders.BackColor = Color.FromArgb(CByte(251), CByte(239), CByte(236))
        pnlActiveOrders.BorderStyle = BorderStyle.FixedSingle
        pnlActiveOrders.Controls.Add(pnlActiveOrdersPlaceholder)
        pnlActiveOrders.Controls.Add(lblActiveOrdersSubtitle)
        pnlActiveOrders.Controls.Add(lblActiveOrdersTitle)
        pnlActiveOrders.Dock = DockStyle.Fill
        pnlActiveOrders.Location = New Point(0, 0)
        pnlActiveOrders.Margin = New Padding(0, 0, 12, 0)
        pnlActiveOrders.Name = "pnlActiveOrders"
        pnlActiveOrders.Padding = New Padding(20)
        pnlActiveOrders.Size = New Size(524, 320)
        pnlActiveOrders.TabIndex = 0
        ' 
        ' pnlActiveOrdersPlaceholder
        ' 
        pnlActiveOrdersPlaceholder.Anchor = AnchorStyles.Top Or AnchorStyles.Bottom Or AnchorStyles.Left Or AnchorStyles.Right
        pnlActiveOrdersPlaceholder.AutoScroll = True
        pnlActiveOrdersPlaceholder.BackColor = Color.White
        pnlActiveOrdersPlaceholder.BorderStyle = BorderStyle.FixedSingle
        pnlActiveOrdersPlaceholder.Controls.Add(TableLayoutPanel1)
        pnlActiveOrdersPlaceholder.Location = New Point(20, 96)
        pnlActiveOrdersPlaceholder.Name = "pnlActiveOrdersPlaceholder"
        pnlActiveOrdersPlaceholder.Size = New Size(482, 204)
        pnlActiveOrdersPlaceholder.TabIndex = 2
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
        ' lblActiveOrdersSubtitle
        ' 
        lblActiveOrdersSubtitle.AutoSize = True
        lblActiveOrdersSubtitle.Font = New Font("Segoe UI", 10F)
        lblActiveOrdersSubtitle.ForeColor = Color.FromArgb(CByte(85), CByte(85), CByte(85))
        lblActiveOrdersSubtitle.Location = New Point(20, 60)
        lblActiveOrdersSubtitle.Name = "lblActiveOrdersSubtitle"
        lblActiveOrdersSubtitle.Size = New Size(262, 23)
        lblActiveOrdersSubtitle.TabIndex = 1
        lblActiveOrdersSubtitle.Text = "Orders currently being processed"
        ' 
        ' lblActiveOrdersTitle
        ' 
        lblActiveOrdersTitle.AutoSize = True
        lblActiveOrdersTitle.Font = New Font("Segoe UI", 14F, FontStyle.Bold)
        lblActiveOrdersTitle.ForeColor = Color.Black
        lblActiveOrdersTitle.Location = New Point(20, 20)
        lblActiveOrdersTitle.Name = "lblActiveOrdersTitle"
        lblActiveOrdersTitle.Size = New Size(169, 32)
        lblActiveOrdersTitle.TabIndex = 0
        lblActiveOrdersTitle.Text = "Active Orders"
        ' 
        ' pnlTodayReservations
        ' 
        pnlTodayReservations.BackColor = Color.FromArgb(CByte(251), CByte(239), CByte(236))
        pnlTodayReservations.BorderStyle = BorderStyle.FixedSingle
        pnlTodayReservations.Controls.Add(pnlTodayReservationsPlaceholder)
        pnlTodayReservations.Controls.Add(lblTodayReservationsSubtitle)
        pnlTodayReservations.Controls.Add(lblTodayReservationsTitle)
        pnlTodayReservations.Dock = DockStyle.Fill
        pnlTodayReservations.Location = New Point(548, 0)
        pnlTodayReservations.Margin = New Padding(12, 0, 0, 0)
        pnlTodayReservations.Name = "pnlTodayReservations"
        pnlTodayReservations.Padding = New Padding(20)
        pnlTodayReservations.Size = New Size(524, 320)
        pnlTodayReservations.TabIndex = 1
        ' 
        ' pnlTodayReservationsPlaceholder
        ' 
        pnlTodayReservationsPlaceholder.Anchor = AnchorStyles.Top Or AnchorStyles.Bottom Or AnchorStyles.Left Or AnchorStyles.Right
        pnlTodayReservationsPlaceholder.AutoScroll = True
        pnlTodayReservationsPlaceholder.BackColor = Color.White
        pnlTodayReservationsPlaceholder.BorderStyle = BorderStyle.FixedSingle
        pnlTodayReservationsPlaceholder.Controls.Add(TableLayoutPanel2)
        pnlTodayReservationsPlaceholder.Location = New Point(20, 96)
        pnlTodayReservationsPlaceholder.Name = "pnlTodayReservationsPlaceholder"
        pnlTodayReservationsPlaceholder.Size = New Size(482, 204)
        pnlTodayReservationsPlaceholder.TabIndex = 2
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
        ' lblTodayReservationsSubtitle
        ' 
        lblTodayReservationsSubtitle.AutoSize = True
        lblTodayReservationsSubtitle.Font = New Font("Segoe UI", 10F)
        lblTodayReservationsSubtitle.ForeColor = Color.FromArgb(CByte(85), CByte(85), CByte(85))
        lblTodayReservationsSubtitle.Location = New Point(20, 60)
        lblTodayReservationsSubtitle.Name = "lblTodayReservationsSubtitle"
        lblTodayReservationsSubtitle.Size = New Size(248, 23)
        lblTodayReservationsSubtitle.TabIndex = 1
        lblTodayReservationsSubtitle.Text = "Upcoming bookings to prepare"
        ' 
        ' lblTodayReservationsTitle
        ' 
        lblTodayReservationsTitle.AutoSize = True
        lblTodayReservationsTitle.Font = New Font("Segoe UI", 14F, FontStyle.Bold)
        lblTodayReservationsTitle.ForeColor = Color.Black
        lblTodayReservationsTitle.Location = New Point(20, 20)
        lblTodayReservationsTitle.Name = "lblTodayReservationsTitle"
        lblTodayReservationsTitle.Size = New Size(235, 32)
        lblTodayReservationsTitle.TabIndex = 0
        lblTodayReservationsTitle.Text = "Today Reservations"
        ' 
        ' DashboardForm
        ' 
        AutoScaleDimensions = New SizeF(9F, 23F)
        AutoScaleMode = AutoScaleMode.Font
        BackColor = Color.White
        ClientSize = New Size(1120, 620)
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
        pnlCardFeedback.ResumeLayout(False)
        pnlCardFeedback.PerformLayout()
        tlpBottom.ResumeLayout(False)
        pnlActiveOrders.ResumeLayout(False)
        pnlActiveOrders.PerformLayout()
        pnlActiveOrdersPlaceholder.ResumeLayout(False)
        pnlActiveOrdersPlaceholder.PerformLayout()
        pnlTodayReservations.ResumeLayout(False)
        pnlTodayReservations.PerformLayout()
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
    Friend WithEvents pnlCardFeedback As Panel
    Friend WithEvents lblCardFeedbackCaption As Label
    Friend WithEvents lblCardFeedbackValue As Label
    Friend WithEvents lblCardFeedbackTitle As Label
    Friend WithEvents tlpBottom As TableLayoutPanel
    Friend WithEvents pnlActiveOrders As Panel
    Friend WithEvents pnlActiveOrdersPlaceholder As Panel
    Friend WithEvents lblActiveOrdersSubtitle As Label
    Friend WithEvents lblActiveOrdersTitle As Label
    Friend WithEvents pnlTodayReservations As Panel
    Friend WithEvents pnlTodayReservationsPlaceholder As Panel
    Friend WithEvents lblTodayReservationsSubtitle As Label
    Friend WithEvents lblTodayReservationsTitle As Label
    Friend WithEvents TableLayoutPanel1 As TableLayoutPanel
    Friend WithEvents TableLayoutPanel2 As TableLayoutPanel
End Class

