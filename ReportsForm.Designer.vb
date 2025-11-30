<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class ReportsForm
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
    Private components As System.ComponentModel.IContainer = Nothing

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        tlpRoot = New TableLayoutPanel()
        pnlHeader = New Panel()
        lblSubHeader = New Label()
        lblHeader = New Label()
        tlpStatsCards = New TableLayoutPanel()
        pnlSalesCard = New Panel()
        lblSalesSubtitle = New Label()
        lblSalesValue = New Label()
        lblSalesTitle = New Label()
        pnlOrdersCard = New Panel()
        lblOrdersSubtitle = New Label()
        lblOrdersValue = New Label()
        lblOrdersTitle = New Label()
        pnlReservationsCard = New Panel()
        lblReservationsSubtitle = New Label()
        lblReservationsValue = New Label()
        lblReservationsTitle = New Label()
        pnlOrdersSection = New Panel()
        TableLayoutPanel1 = New TableLayoutPanel()
        Panel1 = New Panel()
        lblOrdersTableSubtitle = New Label()
        lblOrdersTableTitle = New Label()
        Panel2 = New Panel()
        tlpTableStructure = New TableLayoutPanel()
        pnlTableHeader = New Panel()
        pnlTableTotal = New Panel()
        pnlOrdersContainer = New Panel()
        tlpOrdersRows = New TableLayoutPanel()
        tlpRoot.SuspendLayout()
        pnlHeader.SuspendLayout()
        tlpStatsCards.SuspendLayout()
        pnlSalesCard.SuspendLayout()
        pnlOrdersCard.SuspendLayout()
        pnlReservationsCard.SuspendLayout()
        pnlOrdersSection.SuspendLayout()
        TableLayoutPanel1.SuspendLayout()
        Panel1.SuspendLayout()
        Panel2.SuspendLayout()
        tlpTableStructure.SuspendLayout()
        pnlOrdersContainer.SuspendLayout()
        SuspendLayout()
        ' 
        ' tlpRoot
        ' 
        tlpRoot.ColumnCount = 1
        tlpRoot.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        tlpRoot.Controls.Add(pnlHeader, 0, 0)
        tlpRoot.Controls.Add(tlpStatsCards, 0, 1)
        tlpRoot.Controls.Add(pnlOrdersSection, 0, 2)
        tlpRoot.Dock = DockStyle.Fill
        tlpRoot.Location = New Point(0, 0)
        tlpRoot.Name = "tlpRoot"
        tlpRoot.Padding = New Padding(24)
        tlpRoot.RowCount = 3
        tlpRoot.RowStyles.Add(New RowStyle())
        tlpRoot.RowStyles.Add(New RowStyle())
        tlpRoot.RowStyles.Add(New RowStyle(SizeType.Percent, 100F))
        tlpRoot.Size = New Size(1120, 700)
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
        lblSubHeader.Name = "lblSubHeader"
        lblSubHeader.Size = New Size(224, 23)
        lblSubHeader.TabIndex = 1
        lblSubHeader.Text = "View your shift performance"
        ' 
        ' lblHeader
        ' 
        lblHeader.AutoSize = True
        lblHeader.Font = New Font("Segoe UI", 18F, FontStyle.Bold)
        lblHeader.Location = New Point(0, 0)
        lblHeader.Name = "lblHeader"
        lblHeader.Size = New Size(208, 41)
        lblHeader.TabIndex = 0
        lblHeader.Text = "Daily Reports"
        ' 
        ' tlpStatsCards
        ' 
        tlpStatsCards.ColumnCount = 3
        tlpStatsCards.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 33.33F))
        tlpStatsCards.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 33.33F))
        tlpStatsCards.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 33.34F))
        tlpStatsCards.Controls.Add(pnlSalesCard, 0, 0)
        tlpStatsCards.Controls.Add(pnlOrdersCard, 1, 0)
        tlpStatsCards.Controls.Add(pnlReservationsCard, 2, 0)
        tlpStatsCards.Dock = DockStyle.Fill
        tlpStatsCards.Location = New Point(24, 108)
        tlpStatsCards.Margin = New Padding(0, 0, 0, 24)
        tlpStatsCards.Name = "tlpStatsCards"
        tlpStatsCards.RowCount = 1
        tlpStatsCards.RowStyles.Add(New RowStyle(SizeType.Absolute, 120F))
        tlpStatsCards.Size = New Size(1072, 120)
        tlpStatsCards.TabIndex = 1
        ' 
        ' pnlSalesCard
        ' 
        pnlSalesCard.BackColor = Color.FromArgb(CByte(251), CByte(243), CByte(236))
        pnlSalesCard.BorderStyle = BorderStyle.FixedSingle
        pnlSalesCard.Controls.Add(lblSalesSubtitle)
        pnlSalesCard.Controls.Add(lblSalesValue)
        pnlSalesCard.Controls.Add(lblSalesTitle)
        pnlSalesCard.Dock = DockStyle.Fill
        pnlSalesCard.Location = New Point(0, 0)
        pnlSalesCard.Margin = New Padding(0, 0, 12, 0)
        pnlSalesCard.Name = "pnlSalesCard"
        pnlSalesCard.Padding = New Padding(20)
        pnlSalesCard.Size = New Size(345, 120)
        pnlSalesCard.TabIndex = 0
        ' 
        ' lblSalesSubtitle
        ' 
        lblSalesSubtitle.AutoSize = True
        lblSalesSubtitle.Font = New Font("Segoe UI", 9F)
        lblSalesSubtitle.ForeColor = Color.Gray
        lblSalesSubtitle.Location = New Point(20, 88)
        lblSalesSubtitle.Name = "lblSalesSubtitle"
        lblSalesSubtitle.Size = New Size(234, 20)
        lblSalesSubtitle.TabIndex = 2
        lblSalesSubtitle.Text = "From your orders and reservations"
        ' 
        ' lblSalesValue
        ' 
        lblSalesValue.AutoSize = True
        lblSalesValue.Font = New Font("Segoe UI", 24F, FontStyle.Bold)
        lblSalesValue.ForeColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        lblSalesValue.Location = New Point(20, 38)
        lblSalesValue.Name = "lblSalesValue"
        lblSalesValue.Size = New Size(163, 54)
        lblSalesValue.TabIndex = 1
        lblSalesValue.Text = "₱ 1,810"
        ' 
        ' lblSalesTitle
        ' 
        lblSalesTitle.AutoSize = True
        lblSalesTitle.Font = New Font("Segoe UI", 11F)
        lblSalesTitle.Location = New Point(20, 10)
        lblSalesTitle.Name = "lblSalesTitle"
        lblSalesTitle.Size = New Size(109, 25)
        lblSalesTitle.TabIndex = 0
        lblSalesTitle.Text = "Today Sales"
        ' 
        ' pnlOrdersCard
        ' 
        pnlOrdersCard.BackColor = Color.White
        pnlOrdersCard.BorderStyle = BorderStyle.FixedSingle
        pnlOrdersCard.Controls.Add(lblOrdersSubtitle)
        pnlOrdersCard.Controls.Add(lblOrdersValue)
        pnlOrdersCard.Controls.Add(lblOrdersTitle)
        pnlOrdersCard.Dock = DockStyle.Fill
        pnlOrdersCard.Location = New Point(357, 0)
        pnlOrdersCard.Margin = New Padding(0, 0, 12, 0)
        pnlOrdersCard.Name = "pnlOrdersCard"
        pnlOrdersCard.Padding = New Padding(20)
        pnlOrdersCard.Size = New Size(345, 120)
        pnlOrdersCard.TabIndex = 1
        ' 
        ' lblOrdersSubtitle
        ' 
        lblOrdersSubtitle.AutoSize = True
        lblOrdersSubtitle.Font = New Font("Segoe UI", 9F)
        lblOrdersSubtitle.ForeColor = Color.Gray
        lblOrdersSubtitle.Location = New Point(20, 88)
        lblOrdersSubtitle.Name = "lblOrdersSubtitle"
        lblOrdersSubtitle.Size = New Size(96, 20)
        lblOrdersSubtitle.TabIndex = 2
        lblOrdersSubtitle.Text = "Today counts"
        ' 
        ' lblOrdersValue
        ' 
        lblOrdersValue.AutoSize = True
        lblOrdersValue.Font = New Font("Segoe UI", 28F, FontStyle.Bold)
        lblOrdersValue.Location = New Point(20, 35)
        lblOrdersValue.Name = "lblOrdersValue"
        lblOrdersValue.Size = New Size(54, 62)
        lblOrdersValue.TabIndex = 1
        lblOrdersValue.Text = "5"
        ' 
        ' lblOrdersTitle
        ' 
        lblOrdersTitle.AutoSize = True
        lblOrdersTitle.Font = New Font("Segoe UI", 11F)
        lblOrdersTitle.Location = New Point(20, 10)
        lblOrdersTitle.Name = "lblOrdersTitle"
        lblOrdersTitle.Size = New Size(145, 25)
        lblOrdersTitle.TabIndex = 0
        lblOrdersTitle.Text = "Orders Handled"
        ' 
        ' pnlReservationsCard
        ' 
        pnlReservationsCard.BackColor = Color.White
        pnlReservationsCard.BorderStyle = BorderStyle.FixedSingle
        pnlReservationsCard.Controls.Add(lblReservationsSubtitle)
        pnlReservationsCard.Controls.Add(lblReservationsValue)
        pnlReservationsCard.Controls.Add(lblReservationsTitle)
        pnlReservationsCard.Dock = DockStyle.Fill
        pnlReservationsCard.Location = New Point(714, 0)
        pnlReservationsCard.Margin = New Padding(0)
        pnlReservationsCard.Name = "pnlReservationsCard"
        pnlReservationsCard.Padding = New Padding(20)
        pnlReservationsCard.Size = New Size(358, 120)
        pnlReservationsCard.TabIndex = 2
        ' 
        ' lblReservationsSubtitle
        ' 
        lblReservationsSubtitle.AutoSize = True
        lblReservationsSubtitle.Font = New Font("Segoe UI", 9F)
        lblReservationsSubtitle.ForeColor = Color.Gray
        lblReservationsSubtitle.Location = New Point(20, 88)
        lblReservationsSubtitle.Name = "lblReservationsSubtitle"
        lblReservationsSubtitle.Size = New Size(101, 20)
        lblReservationsSubtitle.TabIndex = 2
        lblReservationsSubtitle.Text = "Today's Count"
        ' 
        ' lblReservationsValue
        ' 
        lblReservationsValue.AutoSize = True
        lblReservationsValue.Font = New Font("Segoe UI", 28F, FontStyle.Bold)
        lblReservationsValue.Location = New Point(20, 35)
        lblReservationsValue.Name = "lblReservationsValue"
        lblReservationsValue.Size = New Size(54, 62)
        lblReservationsValue.TabIndex = 1
        lblReservationsValue.Text = "2"
        ' 
        ' lblReservationsTitle
        ' 
        lblReservationsTitle.AutoSize = True
        lblReservationsTitle.Font = New Font("Segoe UI", 11F)
        lblReservationsTitle.Location = New Point(20, 10)
        lblReservationsTitle.Name = "lblReservationsTitle"
        lblReservationsTitle.Size = New Size(193, 25)
        lblReservationsTitle.TabIndex = 0
        lblReservationsTitle.Text = "Reservations Handled"
        ' 
        ' pnlOrdersSection
        ' 
        pnlOrdersSection.BackColor = Color.White
        pnlOrdersSection.BorderStyle = BorderStyle.FixedSingle
        pnlOrdersSection.Controls.Add(TableLayoutPanel1)
        pnlOrdersSection.Dock = DockStyle.Fill
        pnlOrdersSection.Location = New Point(24, 252)
        pnlOrdersSection.Margin = New Padding(0)
        pnlOrdersSection.Name = "pnlOrdersSection"
        pnlOrdersSection.Padding = New Padding(30, 20, 30, 20)
        pnlOrdersSection.Size = New Size(1072, 424)
        pnlOrdersSection.TabIndex = 2
        ' 
        ' TableLayoutPanel1
        ' 
        TableLayoutPanel1.ColumnCount = 1
        TableLayoutPanel1.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        TableLayoutPanel1.Controls.Add(Panel1, 0, 0)
        TableLayoutPanel1.Controls.Add(Panel2, 0, 1)
        TableLayoutPanel1.Dock = DockStyle.Fill
        TableLayoutPanel1.Location = New Point(30, 20)
        TableLayoutPanel1.Name = "TableLayoutPanel1"
        TableLayoutPanel1.RowCount = 2
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Percent, 15F))
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Percent, 85F))
        TableLayoutPanel1.Size = New Size(1010, 382)
        TableLayoutPanel1.TabIndex = 3
        ' 
        ' Panel1
        ' 
        Panel1.Controls.Add(lblOrdersTableSubtitle)
        Panel1.Controls.Add(lblOrdersTableTitle)
        Panel1.Dock = DockStyle.Fill
        Panel1.Location = New Point(3, 3)
        Panel1.Name = "Panel1"
        Panel1.Size = New Size(1004, 51)
        Panel1.TabIndex = 0
        ' 
        ' lblOrdersTableSubtitle
        ' 
        lblOrdersTableSubtitle.AutoSize = True
        lblOrdersTableSubtitle.Font = New Font("Segoe UI", 10F)
        lblOrdersTableSubtitle.ForeColor = Color.Gray
        lblOrdersTableSubtitle.Location = New Point(3, 38)
        lblOrdersTableSubtitle.Name = "lblOrdersTableSubtitle"
        lblOrdersTableSubtitle.Size = New Size(395, 23)
        lblOrdersTableSubtitle.TabIndex = 3
        lblOrdersTableSubtitle.Text = "All orders and reservations you've processed today"
        ' 
        ' lblOrdersTableTitle
        ' 
        lblOrdersTableTitle.AutoSize = True
        lblOrdersTableTitle.Font = New Font("Segoe UI", 14F, FontStyle.Bold)
        lblOrdersTableTitle.Location = New Point(3, 8)
        lblOrdersTableTitle.Name = "lblOrdersTableTitle"
        lblOrdersTableTitle.Size = New Size(361, 32)
        lblOrdersTableTitle.TabIndex = 2
        lblOrdersTableTitle.Text = "Today orders and reservations"
        ' 
        ' Panel2
        ' 
        Panel2.Controls.Add(tlpTableStructure)
        Panel2.Dock = DockStyle.Fill
        Panel2.Location = New Point(3, 60)
        Panel2.Name = "Panel2"
        Panel2.Size = New Size(1004, 319)
        Panel2.TabIndex = 1
        ' 
        ' tlpTableStructure
        ' 
        tlpTableStructure.ColumnCount = 1
        tlpTableStructure.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        tlpTableStructure.Controls.Add(pnlTableHeader, 0, 0)
        tlpTableStructure.Controls.Add(pnlOrdersContainer, 0, 1)
        tlpTableStructure.Controls.Add(pnlTableTotal, 0, 2)
        tlpTableStructure.Dock = DockStyle.Fill
        tlpTableStructure.Location = New Point(0, 0)
        tlpTableStructure.Name = "tlpTableStructure"
        tlpTableStructure.RowCount = 3
        tlpTableStructure.RowStyles.Add(New RowStyle(SizeType.Absolute, 40F))
        tlpTableStructure.RowStyles.Add(New RowStyle(SizeType.Percent, 100F))
        tlpTableStructure.RowStyles.Add(New RowStyle(SizeType.Absolute, 50F))
        tlpTableStructure.Size = New Size(1004, 319)
        tlpTableStructure.TabIndex = 0
        ' 
        ' pnlTableHeader
        ' 
        pnlTableHeader.BackColor = Color.FromArgb(CByte(248), CByte(248), CByte(248))
        pnlTableHeader.Dock = DockStyle.Fill
        pnlTableHeader.Location = New Point(0, 0)
        pnlTableHeader.Margin = New Padding(0)
        pnlTableHeader.Name = "pnlTableHeader"
        pnlTableHeader.Padding = New Padding(20, 10, 20, 10)
        pnlTableHeader.Size = New Size(1004, 40)
        pnlTableHeader.TabIndex = 0
        ' 
        ' pnlTableTotal
        ' 
        pnlTableTotal.BackColor = Color.White
        pnlTableTotal.Dock = DockStyle.Fill
        pnlTableTotal.Location = New Point(0, 269)
        pnlTableTotal.Margin = New Padding(0)
        pnlTableTotal.Name = "pnlTableTotal"
        pnlTableTotal.Padding = New Padding(20)
        pnlTableTotal.Size = New Size(1004, 50)
        pnlTableTotal.TabIndex = 2
        ' 
        ' pnlOrdersContainer
        ' 
        pnlOrdersContainer.AutoScroll = True
        pnlOrdersContainer.Controls.Add(tlpOrdersRows)
        pnlOrdersContainer.Dock = DockStyle.Fill
        pnlOrdersContainer.Location = New Point(0, 0)
        pnlOrdersContainer.Name = "pnlOrdersContainer"
        pnlOrdersContainer.Size = New Size(1004, 319)
        pnlOrdersContainer.TabIndex = 3
        ' 
        ' tlpOrdersRows
        ' 
        tlpOrdersRows.AutoSize = True
        tlpOrdersRows.AutoSizeMode = AutoSizeMode.GrowAndShrink
        tlpOrdersRows.CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
        tlpOrdersRows.ColumnCount = 1
        tlpOrdersRows.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        tlpOrdersRows.Dock = DockStyle.Top
        tlpOrdersRows.Location = New Point(0, 0)
        tlpOrdersRows.Name = "tlpOrdersRows"
        tlpOrdersRows.Size = New Size(1004, 1)
        tlpOrdersRows.TabIndex = 0
        ' 
        ' ReportsForm
        ' 
        AutoScaleDimensions = New SizeF(8F, 20F)
        AutoScaleMode = AutoScaleMode.Font
        BackColor = Color.White
        ClientSize = New Size(1120, 700)
        Controls.Add(tlpRoot)
        FormBorderStyle = FormBorderStyle.None
        Name = "ReportsForm"
        Text = "Daily Reports"
        tlpRoot.ResumeLayout(False)
        tlpRoot.PerformLayout()
        pnlHeader.ResumeLayout(False)
        pnlHeader.PerformLayout()
        tlpStatsCards.ResumeLayout(False)
        pnlSalesCard.ResumeLayout(False)
        pnlSalesCard.PerformLayout()
        pnlOrdersCard.ResumeLayout(False)
        pnlOrdersCard.PerformLayout()
        pnlReservationsCard.ResumeLayout(False)
        pnlReservationsCard.PerformLayout()
        pnlOrdersSection.ResumeLayout(False)
        TableLayoutPanel1.ResumeLayout(False)
        Panel1.ResumeLayout(False)
        Panel1.PerformLayout()
        Panel2.ResumeLayout(False)
        tlpTableStructure.ResumeLayout(False)
        pnlOrdersContainer.ResumeLayout(False)
        pnlOrdersContainer.PerformLayout()
        ResumeLayout(False)
    End Sub

    Friend WithEvents tlpRoot As TableLayoutPanel
    Friend WithEvents pnlHeader As Panel
    Friend WithEvents lblSubHeader As Label
    Friend WithEvents lblHeader As Label
    Friend WithEvents tlpStatsCards As TableLayoutPanel
    Friend WithEvents pnlSalesCard As Panel
    Friend WithEvents lblSalesSubtitle As Label
    Friend WithEvents lblSalesValue As Label
    Friend WithEvents lblSalesTitle As Label
    Friend WithEvents pnlOrdersCard As Panel
    Friend WithEvents lblOrdersSubtitle As Label
    Friend WithEvents lblOrdersValue As Label
    Friend WithEvents lblOrdersTitle As Label
    Friend WithEvents pnlReservationsCard As Panel
    Friend WithEvents lblReservationsSubtitle As Label
    Friend WithEvents lblReservationsValue As Label
    Friend WithEvents lblReservationsTitle As Label
    Friend WithEvents pnlOrdersSection As Panel
    Friend WithEvents TableLayoutPanel1 As TableLayoutPanel
    Friend WithEvents Panel1 As Panel
    Friend WithEvents lblOrdersTableSubtitle As Label
    Friend WithEvents lblOrdersTableTitle As Label
    Friend WithEvents Panel2 As Panel
    Friend WithEvents tlpTableStructure As TableLayoutPanel
    Friend WithEvents pnlTableHeader As Panel
    Friend WithEvents pnlTableTotal As Panel
    Friend WithEvents pnlOrdersContainer As Panel
    Friend WithEvents tlpOrdersRows As TableLayoutPanel
End Class
