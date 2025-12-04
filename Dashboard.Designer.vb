<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class Dashboard
    Inherits System.Windows.Forms.Form

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

    Private components As System.ComponentModel.IContainer

    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        tlpRoot = New TableLayoutPanel()
        pnlSidebar = New Panel()
        tlpSidebar = New TableLayoutPanel()
        pnlLogo = New Panel()
        tlpLogo = New TableLayoutPanel()
        logo = New PictureBox()
        lblBrand = New Label()
        flpNav = New FlowLayoutPanel()
        btnDashboard = New Button()
        btnPlaceOrder = New Button()
        btnReservations = New Button()
        btnReports = New Button()
        btnLogout = New Button()
        tlpRight = New TableLayoutPanel()
        pnlHeader = New Panel()
        lblHeaderTitle = New Label()
        pnlContent = New Panel()
        tlpRoot.SuspendLayout()
        pnlSidebar.SuspendLayout()
        tlpSidebar.SuspendLayout()
        pnlLogo.SuspendLayout()
        tlpLogo.SuspendLayout()
        CType(logo, ComponentModel.ISupportInitialize).BeginInit()
        flpNav.SuspendLayout()
        tlpRight.SuspendLayout()
        pnlHeader.SuspendLayout()
        SuspendLayout()
        ' 
        ' tlpRoot
        ' 
        tlpRoot.ColumnCount = 2
        tlpRoot.ColumnStyles.Add(New ColumnStyle(SizeType.Absolute, 220F))
        tlpRoot.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        tlpRoot.Controls.Add(pnlSidebar, 0, 0)
        tlpRoot.Controls.Add(tlpRight, 1, 0)
        tlpRoot.Dock = DockStyle.Fill
        tlpRoot.Location = New Point(0, 0)
        tlpRoot.Margin = New Padding(0)
        tlpRoot.Name = "tlpRoot"
        tlpRoot.RowCount = 1
        tlpRoot.RowStyles.Add(New RowStyle(SizeType.Percent, 100F))
        tlpRoot.Size = New Size(1180, 640)
        tlpRoot.TabIndex = 0
        ' 
        ' pnlSidebar
        ' 
        pnlSidebar.BackColor = Color.FromArgb(CByte(59), CByte(42), CByte(32))
        pnlSidebar.Controls.Add(tlpSidebar)
        pnlSidebar.Dock = DockStyle.Fill
        pnlSidebar.Location = New Point(0, 0)
        pnlSidebar.Margin = New Padding(0)
        pnlSidebar.Name = "pnlSidebar"
        pnlSidebar.Padding = New Padding(16, 24, 16, 24)
        pnlSidebar.Size = New Size(220, 640)
        pnlSidebar.TabIndex = 0
        ' 
        ' tlpSidebar
        ' 
        tlpSidebar.ColumnCount = 1
        tlpSidebar.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        tlpSidebar.Controls.Add(pnlLogo, 0, 0)
        tlpSidebar.Controls.Add(flpNav, 0, 1)
        tlpSidebar.Dock = DockStyle.Fill
        tlpSidebar.Location = New Point(16, 24)
        tlpSidebar.Margin = New Padding(0)
        tlpSidebar.Name = "tlpSidebar"
        tlpSidebar.RowCount = 3
        tlpSidebar.RowStyles.Add(New RowStyle())
        tlpSidebar.RowStyles.Add(New RowStyle(SizeType.Percent, 100F))
        tlpSidebar.RowStyles.Add(New RowStyle(SizeType.Absolute, 20F))
        tlpSidebar.Size = New Size(188, 592)
        tlpSidebar.TabIndex = 0
        ' 
        ' pnlLogo
        ' 
        pnlLogo.Controls.Add(tlpLogo)
        pnlLogo.Dock = DockStyle.Fill
        pnlLogo.Location = New Point(0, 0)
        pnlLogo.Margin = New Padding(0, 0, 0, 24)
        pnlLogo.Name = "pnlLogo"
        pnlLogo.Size = New Size(188, 72)
        pnlLogo.TabIndex = 0
        ' 
        ' tlpLogo
        ' 
        tlpLogo.ColumnCount = 2
        tlpLogo.ColumnStyles.Add(New ColumnStyle(SizeType.Absolute, 67F))
        tlpLogo.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        tlpLogo.Controls.Add(logo, 0, 0)
        tlpLogo.Controls.Add(lblBrand, 1, 0)
        tlpLogo.Dock = DockStyle.Fill
        tlpLogo.Location = New Point(0, 0)
        tlpLogo.Margin = New Padding(0)
        tlpLogo.Name = "tlpLogo"
        tlpLogo.RowCount = 1
        tlpLogo.RowStyles.Add(New RowStyle(SizeType.Percent, 100F))
        tlpLogo.Size = New Size(188, 72)
        tlpLogo.TabIndex = 0
        ' 
        ' logo
        ' 
        logo.Anchor = AnchorStyles.Left
        logo.BackColor = Color.Transparent
        logo.Image = My.Resources.Resources._291136637_456626923131971_8250989517364923746_n_removebg_preview1
        logo.Location = New Point(0, 11)
        logo.Margin = New Padding(0, 9, 0, 0)
        logo.Name = "logo"
        logo.Size = New Size(67, 59)
        logo.SizeMode = PictureBoxSizeMode.Zoom
        logo.TabIndex = 0
        logo.TabStop = False
        ' 
        ' lblBrand
        ' 
        lblBrand.Anchor = AnchorStyles.Left
        lblBrand.AutoSize = True
        lblBrand.Font = New Font("Segoe UI Semibold", 16F, FontStyle.Bold)
        lblBrand.ForeColor = Color.White
        lblBrand.Location = New Point(68, 17)
        lblBrand.Margin = New Padding(1, 0, 0, 0)
        lblBrand.Name = "lblBrand"
        lblBrand.Size = New Size(101, 37)
        lblBrand.TabIndex = 1
        lblBrand.Text = "Tabeya"
        ' 
        ' flpNav
        ' 
        flpNav.Controls.Add(btnDashboard)
        flpNav.Controls.Add(btnPlaceOrder)
        flpNav.Controls.Add(btnReservations)
        flpNav.Controls.Add(btnReports)
        flpNav.Controls.Add(btnLogout)
        flpNav.Dock = DockStyle.Fill
        flpNav.FlowDirection = FlowDirection.TopDown
        flpNav.Location = New Point(0, 96)
        flpNav.Margin = New Padding(0)
        flpNav.Name = "flpNav"
        flpNav.Padding = New Padding(0, 8, 0, 0)
        flpNav.Size = New Size(188, 476)
        flpNav.TabIndex = 1
        flpNav.WrapContents = False
        ' 
        ' btnDashboard
        ' 
        btnDashboard.BackColor = Color.FromArgb(CByte(124), CByte(94), CByte(69))
        btnDashboard.Cursor = Cursors.Hand
        btnDashboard.FlatAppearance.BorderSize = 0
        btnDashboard.FlatStyle = FlatStyle.Flat
        btnDashboard.Font = New Font("Segoe UI", 10F)
        btnDashboard.ForeColor = Color.White
        btnDashboard.ImageAlign = ContentAlignment.MiddleLeft
        btnDashboard.Location = New Point(0, 8)
        btnDashboard.Margin = New Padding(0, 0, 0, 8)
        btnDashboard.Name = "btnDashboard"
        btnDashboard.Padding = New Padding(12, 10, 12, 10)
        btnDashboard.Size = New Size(188, 48)
        btnDashboard.TabIndex = 0
        btnDashboard.Tag = "Dashboard"
        btnDashboard.Text = "Dashboard"
        btnDashboard.TextAlign = ContentAlignment.MiddleLeft
        btnDashboard.TextImageRelation = TextImageRelation.ImageBeforeText
        btnDashboard.UseVisualStyleBackColor = False
        ' 
        ' btnPlaceOrder
        ' 
        btnPlaceOrder.BackColor = Color.Transparent
        btnPlaceOrder.Cursor = Cursors.Hand
        btnPlaceOrder.FlatAppearance.BorderSize = 0
        btnPlaceOrder.FlatStyle = FlatStyle.Flat
        btnPlaceOrder.Font = New Font("Segoe UI", 10F)
        btnPlaceOrder.ForeColor = Color.White
        btnPlaceOrder.ImageAlign = ContentAlignment.MiddleLeft
        btnPlaceOrder.Location = New Point(0, 64)
        btnPlaceOrder.Margin = New Padding(0, 0, 0, 8)
        btnPlaceOrder.Name = "btnPlaceOrder"
        btnPlaceOrder.Padding = New Padding(12, 10, 12, 10)
        btnPlaceOrder.Size = New Size(188, 48)
        btnPlaceOrder.TabIndex = 1
        btnPlaceOrder.Tag = "Place Order"
        btnPlaceOrder.Text = "Place Order"
        btnPlaceOrder.TextAlign = ContentAlignment.MiddleLeft
        btnPlaceOrder.TextImageRelation = TextImageRelation.ImageBeforeText
        btnPlaceOrder.UseVisualStyleBackColor = False
        ' 
        ' btnReservations
        ' 
        btnReservations.BackColor = Color.Transparent
        btnReservations.Cursor = Cursors.Hand
        btnReservations.FlatAppearance.BorderSize = 0
        btnReservations.FlatStyle = FlatStyle.Flat
        btnReservations.Font = New Font("Segoe UI", 10F)
        btnReservations.ForeColor = Color.White
        btnReservations.ImageAlign = ContentAlignment.MiddleLeft
        btnReservations.Location = New Point(0, 120)
        btnReservations.Margin = New Padding(0, 0, 0, 8)
        btnReservations.Name = "btnReservations"
        btnReservations.Padding = New Padding(12, 10, 12, 10)
        btnReservations.Size = New Size(188, 48)
        btnReservations.TabIndex = 2
        btnReservations.Tag = "Reservations"
        btnReservations.Text = "Reservations"
        btnReservations.TextAlign = ContentAlignment.MiddleLeft
        btnReservations.TextImageRelation = TextImageRelation.ImageBeforeText
        btnReservations.UseVisualStyleBackColor = False
        ' 
        ' btnReports
        ' 
        btnReports.BackColor = Color.Transparent
        btnReports.Cursor = Cursors.Hand
        btnReports.FlatAppearance.BorderSize = 0
        btnReports.FlatStyle = FlatStyle.Flat
        btnReports.Font = New Font("Segoe UI", 10F)
        btnReports.ForeColor = Color.White
        btnReports.ImageAlign = ContentAlignment.MiddleLeft
        btnReports.Location = New Point(0, 176)
        btnReports.Margin = New Padding(0, 0, 0, 8)
        btnReports.Name = "btnReports"
        btnReports.Padding = New Padding(12, 10, 12, 10)
        btnReports.Size = New Size(188, 48)
        btnReports.TabIndex = 4
        btnReports.Tag = "Reports"
        btnReports.Text = "Reports"
        btnReports.TextAlign = ContentAlignment.MiddleLeft
        btnReports.TextImageRelation = TextImageRelation.ImageBeforeText
        btnReports.UseVisualStyleBackColor = False
        ' 
        ' btnLogout
        ' 
        btnLogout.BackColor = Color.FromArgb(CByte(200), CByte(50), CByte(50))
        btnLogout.Cursor = Cursors.Hand
        btnLogout.FlatAppearance.BorderSize = 0
        btnLogout.FlatStyle = FlatStyle.Flat
        btnLogout.Font = New Font("Segoe UI", 10F, FontStyle.Bold)
        btnLogout.ForeColor = Color.White
        btnLogout.ImageAlign = ContentAlignment.MiddleLeft
        btnLogout.Location = New Point(0, 232)
        btnLogout.Margin = New Padding(0, 0, 0, 8)
        btnLogout.Name = "btnLogout"
        btnLogout.Padding = New Padding(12, 10, 12, 10)
        btnLogout.Size = New Size(188, 48)
        btnLogout.TabIndex = 5
        btnLogout.Text = "Logout"
        btnLogout.TextAlign = ContentAlignment.MiddleLeft
        btnLogout.TextImageRelation = TextImageRelation.ImageBeforeText
        btnLogout.UseVisualStyleBackColor = False
        ' 
        ' tlpRight
        ' 
        tlpRight.ColumnCount = 1
        tlpRight.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        tlpRight.Controls.Add(pnlHeader, 0, 0)
        tlpRight.Controls.Add(pnlContent, 0, 1)
        tlpRight.Dock = DockStyle.Fill
        tlpRight.Location = New Point(220, 0)
        tlpRight.Margin = New Padding(0)
        tlpRight.Name = "tlpRight"
        tlpRight.RowCount = 2
        tlpRight.RowStyles.Add(New RowStyle(SizeType.Absolute, 72F))
        tlpRight.RowStyles.Add(New RowStyle(SizeType.Percent, 100F))
        tlpRight.Size = New Size(960, 640)
        tlpRight.TabIndex = 1
        ' 
        ' pnlHeader
        ' 
        pnlHeader.BackColor = Color.FromArgb(CByte(255), CByte(246), CByte(245))
        pnlHeader.Controls.Add(lblHeaderTitle)
        pnlHeader.Dock = DockStyle.Fill
        pnlHeader.Location = New Point(0, 0)
        pnlHeader.Margin = New Padding(0)
        pnlHeader.Name = "pnlHeader"
        pnlHeader.Padding = New Padding(24, 16, 24, 16)
        pnlHeader.Size = New Size(960, 72)
        pnlHeader.TabIndex = 0
        ' 
        ' lblHeaderTitle
        ' 
        lblHeaderTitle.AutoSize = True
        lblHeaderTitle.Font = New Font("Segoe UI Semibold", 18F, FontStyle.Bold)
        lblHeaderTitle.ForeColor = Color.Black
        lblHeaderTitle.Location = New Point(24, 19)
        lblHeaderTitle.Name = "lblHeaderTitle"
        lblHeaderTitle.Size = New Size(170, 41)
        lblHeaderTitle.TabIndex = 0
        lblHeaderTitle.Text = "Staff Portal"
        ' 
        ' pnlContent
        ' 
        pnlContent.BackColor = Color.White
        pnlContent.Dock = DockStyle.Fill
        pnlContent.Location = New Point(0, 72)
        pnlContent.Margin = New Padding(0)
        pnlContent.Name = "pnlContent"
        pnlContent.Padding = New Padding(24)
        pnlContent.Size = New Size(960, 568)
        pnlContent.TabIndex = 1
        ' 
        ' Dashboard
        ' 
        AutoScaleDimensions = New SizeF(9F, 23F)
        AutoScaleMode = AutoScaleMode.Font
        BackColor = Color.White
        ClientSize = New Size(1180, 640)
        Controls.Add(tlpRoot)
        Font = New Font("Segoe UI", 10F)
        MinimumSize = New Size(900, 600)
        Name = "Dashboard"
        StartPosition = FormStartPosition.WindowsDefaultBounds
        Text = "Tabeya Staff Portal"
        WindowState = FormWindowState.Maximized
        tlpRoot.ResumeLayout(False)
        pnlSidebar.ResumeLayout(False)
        tlpSidebar.ResumeLayout(False)
        pnlLogo.ResumeLayout(False)
        tlpLogo.ResumeLayout(False)
        tlpLogo.PerformLayout()
        CType(logo, ComponentModel.ISupportInitialize).EndInit()
        flpNav.ResumeLayout(False)
        tlpRight.ResumeLayout(False)
        pnlHeader.ResumeLayout(False)
        pnlHeader.PerformLayout()
        ResumeLayout(False)
    End Sub

    Friend WithEvents tlpRoot As TableLayoutPanel
    Friend WithEvents pnlSidebar As Panel
    Friend WithEvents tlpSidebar As TableLayoutPanel
    Friend WithEvents pnlLogo As Panel
    Friend WithEvents tlpLogo As TableLayoutPanel
    Friend WithEvents logo As PictureBox
    Friend WithEvents lblBrand As Label
    Friend WithEvents flpNav As FlowLayoutPanel
    Friend WithEvents btnDashboard As Button
    Friend WithEvents btnPlaceOrder As Button
    Friend WithEvents btnReports As Button
    Friend WithEvents tlpRight As TableLayoutPanel
    Friend WithEvents pnlHeader As Panel
    Friend WithEvents lblHeaderTitle As Label
    Friend WithEvents pnlContent As Panel
    Friend WithEvents btnReservations As Button
    Friend WithEvents btnLogout As Button
End Class
