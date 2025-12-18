<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class OnlineOrdersForm
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()> _
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
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
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        Dim resources As System.ComponentModel.ComponentResourceManager = New System.ComponentModel.ComponentResourceManager(GetType(OnlineOrdersForm))
        TableLayoutPanel1 = New TableLayoutPanel()
        pnlHeader = New Panel()
        lblSubHeader = New Label()
        lblHeader = New Label()
        TableLayoutPanel2 = New TableLayoutPanel()
        Panel2 = New Panel()
        ResTemplate = New Panel()
        Button3 = New Button()
        PictureBox8 = New PictureBox()
        Button2 = New Button()
        Button4 = New Button()
        PictureBox6 = New PictureBox()
        PictureBox5 = New PictureBox()
        PictureBox3 = New PictureBox()
        lblName2 = New Label()
        lblCode2 = New Label()
        lblEmail = New Label()
        lblPhone2 = New Label()
        lblDate2 = New Label()
        lblTime2 = New Label()
        lblCompleted = New Label()
        Panel1 = New Panel()
        btnRefresh = New Button()
        TableLayoutPanel1.SuspendLayout()
        pnlHeader.SuspendLayout()
        TableLayoutPanel2.SuspendLayout()
        Panel2.SuspendLayout()
        ResTemplate.SuspendLayout()
        CType(PictureBox8, ComponentModel.ISupportInitialize).BeginInit()
        CType(PictureBox6, ComponentModel.ISupportInitialize).BeginInit()
        CType(PictureBox5, ComponentModel.ISupportInitialize).BeginInit()
        CType(PictureBox3, ComponentModel.ISupportInitialize).BeginInit()
        Panel1.SuspendLayout()
        SuspendLayout()
        ' 
        ' TableLayoutPanel1
        ' 
        TableLayoutPanel1.BackColor = Color.White
        TableLayoutPanel1.ColumnCount = 1
        TableLayoutPanel1.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        TableLayoutPanel1.Controls.Add(pnlHeader, 0, 0)
        TableLayoutPanel1.Controls.Add(TableLayoutPanel2, 0, 1)
        TableLayoutPanel1.Dock = DockStyle.Fill
        TableLayoutPanel1.Location = New Point(0, 0)
        TableLayoutPanel1.Name = "TableLayoutPanel1"
        TableLayoutPanel1.Padding = New Padding(24)
        TableLayoutPanel1.RowCount = 2
        TableLayoutPanel1.RowStyles.Add(New RowStyle())
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Percent, 100F))
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Absolute, 20F))
        TableLayoutPanel1.Size = New Size(1629, 771)
        TableLayoutPanel1.TabIndex = 1
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
        pnlHeader.Size = New Size(1581, 68)
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
        lblSubHeader.Size = New Size(272, 23)
        lblSubHeader.TabIndex = 1
        lblSubHeader.Text = "Handle online orders from website"
        ' 
        ' lblHeader
        ' 
        lblHeader.AutoSize = True
        lblHeader.Font = New Font("Segoe UI", 18F, FontStyle.Bold)
        lblHeader.ForeColor = Color.Black
        lblHeader.Location = New Point(0, 0)
        lblHeader.Margin = New Padding(0)
        lblHeader.Name = "lblHeader"
        lblHeader.Size = New Size(417, 41)
        lblHeader.TabIndex = 0
        lblHeader.Text = "Manage Orders From Online"
        ' 
        ' TableLayoutPanel2
        ' 
        TableLayoutPanel2.ColumnCount = 1
        TableLayoutPanel2.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100F))
        TableLayoutPanel2.Controls.Add(Panel2, 0, 1)
        TableLayoutPanel2.Controls.Add(Panel1, 0, 0)
        TableLayoutPanel2.Dock = DockStyle.Fill
        TableLayoutPanel2.Location = New Point(27, 111)
        TableLayoutPanel2.Name = "TableLayoutPanel2"
        TableLayoutPanel2.RowCount = 2
        TableLayoutPanel2.RowStyles.Add(New RowStyle(SizeType.Percent, 15F))
        TableLayoutPanel2.RowStyles.Add(New RowStyle(SizeType.Percent, 85F))
        TableLayoutPanel2.Size = New Size(1575, 633)
        TableLayoutPanel2.TabIndex = 2
        ' 
        ' Panel2
        ' 
        Panel2.AutoScroll = True
        Panel2.BackColor = SystemColors.Window
        Panel2.Controls.Add(ResTemplate)
        Panel2.Location = New Point(3, 97)
        Panel2.Name = "Panel2"
        Panel2.Size = New Size(1569, 533)
        Panel2.TabIndex = 4
        ' 
        ' ResTemplate
        ' 
        ResTemplate.BackColor = Color.White
        ResTemplate.BorderStyle = BorderStyle.FixedSingle
        ResTemplate.Controls.Add(Button3)
        ResTemplate.Controls.Add(PictureBox8)
        ResTemplate.Controls.Add(Button2)
        ResTemplate.Controls.Add(Button4)
        ResTemplate.Controls.Add(PictureBox6)
        ResTemplate.Controls.Add(PictureBox5)
        ResTemplate.Controls.Add(PictureBox3)
        ResTemplate.Controls.Add(lblName2)
        ResTemplate.Controls.Add(lblCode2)
        ResTemplate.Controls.Add(lblEmail)
        ResTemplate.Controls.Add(lblPhone2)
        ResTemplate.Controls.Add(lblDate2)
        ResTemplate.Controls.Add(lblTime2)
        ResTemplate.Controls.Add(lblCompleted)
        ResTemplate.Location = New Point(38, 119)
        ResTemplate.Name = "ResTemplate"
        ResTemplate.Size = New Size(420, 317)
        ResTemplate.TabIndex = 2
        ' 
        ' Button3
        ' 
        Button3.BackColor = Color.FromArgb(CByte(224), CByte(224), CByte(224))
        Button3.FlatStyle = FlatStyle.Flat
        Button3.Font = New Font("Segoe UI Semibold", 7F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Button3.Location = New Point(178, 255)
        Button3.Name = "Button3"
        Button3.Size = New Size(104, 38)
        Button3.TabIndex = 26
        Button3.Text = "Reciept preview"
        Button3.UseVisualStyleBackColor = False
        ' 
        ' PictureBox8
        ' 
        PictureBox8.Image = CType(resources.GetObject("PictureBox8.Image"), Image)
        PictureBox8.Location = New Point(22, 85)
        PictureBox8.Name = "PictureBox8"
        PictureBox8.Size = New Size(31, 25)
        PictureBox8.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox8.TabIndex = 23
        PictureBox8.TabStop = False
        ' 
        ' Button2
        ' 
        Button2.BackColor = Color.White
        Button2.FlatAppearance.BorderSize = 0
        Button2.FlatStyle = FlatStyle.Flat
        Button2.Font = New Font("Segoe UI Semibold", 9F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Button2.ForeColor = Color.Orange
        Button2.Location = New Point(292, 18)
        Button2.Name = "Button2"
        Button2.Size = New Size(104, 38)
        Button2.TabIndex = 21
        Button2.Text = "Pending"
        Button2.UseVisualStyleBackColor = False
        ' 
        ' Button4
        ' 
        Button4.BackColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        Button4.FlatStyle = FlatStyle.Flat
        Button4.Font = New Font("Segoe UI Semibold", 9F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Button4.Location = New Point(292, 255)
        Button4.Name = "Button4"
        Button4.Size = New Size(104, 38)
        Button4.TabIndex = 20
        Button4.Text = "View Orders"
        Button4.UseVisualStyleBackColor = False
        ' 
        ' PictureBox6
        ' 
        PictureBox6.Image = My.Resources.Resources.clock_five
        PictureBox6.Location = New Point(22, 205)
        PictureBox6.Name = "PictureBox6"
        PictureBox6.Size = New Size(31, 25)
        PictureBox6.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox6.TabIndex = 16
        PictureBox6.TabStop = False
        ' 
        ' PictureBox5
        ' 
        PictureBox5.Image = My.Resources.Resources.calendar
        PictureBox5.Location = New Point(22, 168)
        PictureBox5.Name = "PictureBox5"
        PictureBox5.Size = New Size(31, 25)
        PictureBox5.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox5.TabIndex = 18
        PictureBox5.TabStop = False
        ' 
        ' PictureBox3
        ' 
        PictureBox3.Image = My.Resources.Resources.phone_call
        PictureBox3.Location = New Point(22, 125)
        PictureBox3.Name = "PictureBox3"
        PictureBox3.Size = New Size(31, 25)
        PictureBox3.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox3.TabIndex = 16
        PictureBox3.TabStop = False
        ' 
        ' lblName2
        ' 
        lblName2.AutoSize = True
        lblName2.Font = New Font("Segoe UI", 12F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        lblName2.Location = New Point(20, 20)
        lblName2.Name = "lblName2"
        lblName2.Size = New Size(173, 28)
        lblName2.TabIndex = 0
        lblName2.Text = "Angelo Malaluan"
        ' 
        ' lblCode2
        ' 
        lblCode2.AutoSize = True
        lblCode2.Font = New Font("Segoe UI", 9F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblCode2.ForeColor = Color.Gray
        lblCode2.Location = New Point(22, 50)
        lblCode2.Name = "lblCode2"
        lblCode2.Size = New Size(70, 20)
        lblCode2.TabIndex = 1
        lblCode2.Text = "ORD-001"
        ' 
        ' lblEmail
        ' 
        lblEmail.AutoSize = True
        lblEmail.Font = New Font("Segoe UI", 10F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblEmail.Location = New Point(69, 87)
        lblEmail.Name = "lblEmail"
        lblEmail.Size = New Size(159, 23)
        lblEmail.TabIndex = 3
        lblEmail.Text = "Angelo@gmail.com"
        ' 
        ' lblPhone2
        ' 
        lblPhone2.AutoSize = True
        lblPhone2.Font = New Font("Segoe UI", 9F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblPhone2.Location = New Point(69, 130)
        lblPhone2.Name = "lblPhone2"
        lblPhone2.Size = New Size(97, 20)
        lblPhone2.TabIndex = 5
        lblPhone2.Text = "09630834678"
        ' 
        ' lblDate2
        ' 
        lblDate2.AutoSize = True
        lblDate2.Font = New Font("Segoe UI", 9F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblDate2.Location = New Point(69, 174)
        lblDate2.Name = "lblDate2"
        lblDate2.Size = New Size(85, 20)
        lblDate2.TabIndex = 9
        lblDate2.Text = "2023-11-16"
        ' 
        ' lblTime2
        ' 
        lblTime2.AutoSize = True
        lblTime2.Font = New Font("Segoe UI", 9F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblTime2.Location = New Point(69, 210)
        lblTime2.Name = "lblTime2"
        lblTime2.Size = New Size(61, 20)
        lblTime2.TabIndex = 11
        lblTime2.Text = "8:00 PM"
        ' 
        ' lblCompleted
        ' 
        lblCompleted.Anchor = AnchorStyles.Top Or AnchorStyles.Right
        lblCompleted.AutoSize = True
        lblCompleted.BackColor = Color.FromArgb(CByte(0), CByte(200), CByte(83))
        lblCompleted.Font = New Font("Segoe UI", 7.8F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        lblCompleted.ForeColor = Color.White
        lblCompleted.Location = New Point(1372, 25)
        lblCompleted.Name = "lblCompleted"
        lblCompleted.Padding = New Padding(10, 3, 10, 3)
        lblCompleted.Size = New Size(105, 23)
        lblCompleted.TabIndex = 14
        lblCompleted.Text = "COMPLETED"
        ' 
        ' Panel1
        ' 
        Panel1.Controls.Add(btnRefresh)
        Panel1.Dock = DockStyle.Fill
        Panel1.Location = New Point(3, 3)
        Panel1.Name = "Panel1"
        Panel1.Size = New Size(1569, 88)
        Panel1.TabIndex = 0
        ' 
        ' btnRefresh
        ' 
        btnRefresh.BackColor = Color.FromArgb(CByte(52), CByte(152), CByte(219))
        btnRefresh.FlatAppearance.BorderColor = Color.Black
        btnRefresh.FlatAppearance.MouseDownBackColor = Color.FromArgb(CByte(250), CByte(186), CByte(142))
        btnRefresh.FlatStyle = FlatStyle.Flat
        btnRefresh.Font = New Font("Segoe UI", 10F, FontStyle.Bold)
        btnRefresh.ForeColor = Color.White
        btnRefresh.Location = New Point(1341, 17)
        btnRefresh.Margin = New Padding(25)
        btnRefresh.Name = "btnRefresh"
        btnRefresh.Size = New Size(154, 46)
        btnRefresh.TabIndex = 7
        btnRefresh.Text = "Refresh"
        btnRefresh.UseVisualStyleBackColor = False
        ' 
        ' OnlineOrdersForm
        ' 
        AutoScaleDimensions = New SizeF(8F, 20F)
        AutoScaleMode = AutoScaleMode.Font
        ClientSize = New Size(1629, 771)
        Controls.Add(TableLayoutPanel1)
        Name = "OnlineOrdersForm"
        Text = "OnlineOrdersForm"
        TableLayoutPanel1.ResumeLayout(False)
        TableLayoutPanel1.PerformLayout()
        pnlHeader.ResumeLayout(False)
        pnlHeader.PerformLayout()
        TableLayoutPanel2.ResumeLayout(False)
        Panel2.ResumeLayout(False)
        ResTemplate.ResumeLayout(False)
        ResTemplate.PerformLayout()
        CType(PictureBox8, ComponentModel.ISupportInitialize).EndInit()
        CType(PictureBox6, ComponentModel.ISupportInitialize).EndInit()
        CType(PictureBox5, ComponentModel.ISupportInitialize).EndInit()
        CType(PictureBox3, ComponentModel.ISupportInitialize).EndInit()
        Panel1.ResumeLayout(False)
        ResumeLayout(False)
    End Sub

    Friend WithEvents TableLayoutPanel1 As TableLayoutPanel
    Friend WithEvents pnlHeader As Panel
    Friend WithEvents lblSubHeader As Label
    Friend WithEvents lblHeader As Label
    Friend WithEvents TableLayoutPanel2 As TableLayoutPanel
    Friend WithEvents Panel1 As Panel
    Friend WithEvents btnRefresh As Button
    Friend WithEvents Panel2 As Panel
    Private WithEvents ResTemplate As Panel
    Friend WithEvents Button3 As Button
    Friend WithEvents PictureBox8 As PictureBox
    Friend WithEvents Button2 As Button
    Friend WithEvents Button4 As Button
    Friend WithEvents PictureBox6 As PictureBox
    Friend WithEvents PictureBox5 As PictureBox
    Friend WithEvents PictureBox3 As PictureBox
    Private WithEvents lblName2 As Label
    Private WithEvents lblCode2 As Label
    Private WithEvents lblEmail As Label
    Private WithEvents lblPhone2 As Label
    Private WithEvents lblDate2 As Label
    Private WithEvents lblTime2 As Label
    Private WithEvents lblCompleted As Label
End Class
