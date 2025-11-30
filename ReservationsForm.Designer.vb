<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class ReservationsForm
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
        Dim resources As System.ComponentModel.ComponentResourceManager = New System.ComponentModel.ComponentResourceManager(GetType(ReservationsForm))
        TableLayoutPanel1 = New TableLayoutPanel()
        pnlHeader = New Panel()
        lblSubHeader = New Label()
        lblHeader = New Label()
        Panel1 = New Panel()
        btnRefresh = New Button()
        PictureBox1 = New PictureBox()
        btnNewReservation = New Button()
        ResTemplate = New Panel()
        PictureBox8 = New PictureBox()
        Button2 = New Button()
        Button1 = New Button()
        PictureBox7 = New PictureBox()
        PictureBox6 = New PictureBox()
        PictureBox5 = New PictureBox()
        PictureBox4 = New PictureBox()
        PictureBox3 = New PictureBox()
        lblName2 = New Label()
        lblCode2 = New Label()
        lblEmail = New Label()
        lblPhone2 = New Label()
        lblPeople2 = New Label()
        lblDate2 = New Label()
        lblTime2 = New Label()
        lblEvent2 = New Label()
        lblCompleted = New Label()
        TableLayoutPanel1.SuspendLayout()
        pnlHeader.SuspendLayout()
        Panel1.SuspendLayout()
        CType(PictureBox1, ComponentModel.ISupportInitialize).BeginInit()
        ResTemplate.SuspendLayout()
        CType(PictureBox8, ComponentModel.ISupportInitialize).BeginInit()
        CType(PictureBox7, ComponentModel.ISupportInitialize).BeginInit()
        CType(PictureBox6, ComponentModel.ISupportInitialize).BeginInit()
        CType(PictureBox5, ComponentModel.ISupportInitialize).BeginInit()
        CType(PictureBox4, ComponentModel.ISupportInitialize).BeginInit()
        CType(PictureBox3, ComponentModel.ISupportInitialize).BeginInit()
        SuspendLayout()
        ' 
        ' TableLayoutPanel1
        ' 
        TableLayoutPanel1.BackColor = Color.White
        TableLayoutPanel1.ColumnCount = 1
        TableLayoutPanel1.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100.0F))
        TableLayoutPanel1.Controls.Add(pnlHeader, 0, 0)
        TableLayoutPanel1.Controls.Add(Panel1, 0, 1)
        TableLayoutPanel1.Dock = DockStyle.Fill
        TableLayoutPanel1.Location = New Point(0, 0)
        TableLayoutPanel1.Name = "TableLayoutPanel1"
        TableLayoutPanel1.Padding = New Padding(24)
        TableLayoutPanel1.RowCount = 2
        TableLayoutPanel1.RowStyles.Add(New RowStyle())
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Percent, 100.0F))
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Absolute, 20.0F))
        TableLayoutPanel1.Size = New Size(1789, 819)
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
        pnlHeader.Size = New Size(1741, 68)
        pnlHeader.TabIndex = 1
        ' 
        ' lblSubHeader
        ' 
        lblSubHeader.AutoSize = True
        lblSubHeader.Font = New Font("Segoe UI", 10.0F)
        lblSubHeader.ForeColor = Color.FromArgb(CByte(85), CByte(85), CByte(85))
        lblSubHeader.Location = New Point(0, 45)
        lblSubHeader.Margin = New Padding(0)
        lblSubHeader.Name = "lblSubHeader"
        lblSubHeader.Size = New Size(286, 23)
        lblSubHeader.TabIndex = 1
        lblSubHeader.Text = "Handle catering and event bookings"
        ' 
        ' lblHeader
        ' 
        lblHeader.AutoSize = True
        lblHeader.Font = New Font("Segoe UI", 18.0F, FontStyle.Bold)
        lblHeader.ForeColor = Color.Black
        lblHeader.Location = New Point(0, 0)
        lblHeader.Margin = New Padding(0)
        lblHeader.Name = "lblHeader"
        lblHeader.Size = New Size(319, 41)
        lblHeader.TabIndex = 0
        lblHeader.Text = "Manage Reservations"
        ' 
        ' Panel1
        ' 
        Panel1.AutoScroll = True
        Panel1.BackColor = SystemColors.Window
        Panel1.Controls.Add(btnRefresh)
        Panel1.Controls.Add(PictureBox1)
        Panel1.Controls.Add(btnNewReservation)
        Panel1.Controls.Add(ResTemplate)
        Panel1.Dock = DockStyle.Fill
        Panel1.Location = New Point(27, 111)
        Panel1.Name = "Panel1"
        Panel1.Size = New Size(1735, 681)
        Panel1.TabIndex = 2
        ' 
        ' btnRefresh
        ' 
        btnRefresh.BackColor = Color.FromArgb(CByte(52), CByte(152), CByte(219))
        btnRefresh.FlatAppearance.BorderColor = Color.Black
        btnRefresh.FlatAppearance.MouseDownBackColor = Color.FromArgb(CByte(250), CByte(186), CByte(142))
        btnRefresh.FlatStyle = FlatStyle.Flat
        btnRefresh.Font = New Font("Segoe UI", 10.0F, FontStyle.Bold)
        btnRefresh.ForeColor = Color.White
        btnRefresh.Location = New Point(1122, 33)
        btnRefresh.Margin = New Padding(25)
        btnRefresh.Name = "btnRefresh"
        btnRefresh.Size = New Size(154, 46)
        btnRefresh.TabIndex = 6
        btnRefresh.Text = "Refresh"
        btnRefresh.UseVisualStyleBackColor = False
        ' 
        ' PictureBox1
        ' 
        PictureBox1.BackColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        PictureBox1.Image = My.Resources.Resources.plus__2_
        PictureBox1.Location = New Point(1325, 40)
        PictureBox1.Name = "PictureBox1"
        PictureBox1.Size = New Size(32, 28)
        PictureBox1.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox1.TabIndex = 5
        PictureBox1.TabStop = False
        ' 
        ' btnNewReservation
        ' 
        btnNewReservation.BackColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        btnNewReservation.FlatAppearance.BorderColor = Color.Black
        btnNewReservation.FlatAppearance.MouseDownBackColor = Color.FromArgb(CByte(250), CByte(186), CByte(142))
        btnNewReservation.FlatStyle = FlatStyle.Flat
        btnNewReservation.Font = New Font("Segoe UI", 10.0F, FontStyle.Bold)
        btnNewReservation.ForeColor = Color.White
        btnNewReservation.Location = New Point(1308, 22)
        btnNewReservation.Margin = New Padding(25)
        btnNewReservation.Name = "btnNewReservation"
        btnNewReservation.Size = New Size(228, 64)
        btnNewReservation.TabIndex = 4
        btnNewReservation.Text = "       New Reservation"
        btnNewReservation.UseVisualStyleBackColor = False
        ' 
        ' ResTemplate
        ' 
        ResTemplate.BackColor = Color.White
        ResTemplate.BorderStyle = BorderStyle.FixedSingle
        ResTemplate.Controls.Add(PictureBox8)
        ResTemplate.Controls.Add(Button2)
        ResTemplate.Controls.Add(Button1)
        ResTemplate.Controls.Add(PictureBox7)
        ResTemplate.Controls.Add(PictureBox6)
        ResTemplate.Controls.Add(PictureBox5)
        ResTemplate.Controls.Add(PictureBox4)
        ResTemplate.Controls.Add(PictureBox3)
        ResTemplate.Controls.Add(lblName2)
        ResTemplate.Controls.Add(lblCode2)
        ResTemplate.Controls.Add(lblEmail)
        ResTemplate.Controls.Add(lblPhone2)
        ResTemplate.Controls.Add(lblPeople2)
        ResTemplate.Controls.Add(lblDate2)
        ResTemplate.Controls.Add(lblTime2)
        ResTemplate.Controls.Add(lblEvent2)
        ResTemplate.Controls.Add(lblCompleted)
        ResTemplate.Location = New Point(38, 119)
        ResTemplate.Name = "ResTemplate"
        ResTemplate.Size = New Size(420, 342)
        ResTemplate.TabIndex = 2
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
        Button2.Font = New Font("Segoe UI Semibold", 9.0F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Button2.ForeColor = Color.Orange
        Button2.Location = New Point(292, 18)
        Button2.Name = "Button2"
        Button2.Size = New Size(104, 38)
        Button2.TabIndex = 21
        Button2.Text = "Pending"
        Button2.UseVisualStyleBackColor = False
        ' 
        ' Button1
        ' 
        Button1.BackColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        Button1.FlatStyle = FlatStyle.Flat
        Button1.Font = New Font("Segoe UI Semibold", 9.0F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Button1.Location = New Point(292, 285)
        Button1.Name = "Button1"
        Button1.Size = New Size(104, 38)
        Button1.TabIndex = 20
        Button1.Text = "View Orders"
        Button1.UseVisualStyleBackColor = False
        ' 
        ' PictureBox7
        ' 
        PictureBox7.Image = My.Resources.Resources.schedule
        PictureBox7.Location = New Point(22, 285)
        PictureBox7.Name = "PictureBox7"
        PictureBox7.Size = New Size(31, 25)
        PictureBox7.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox7.TabIndex = 19
        PictureBox7.TabStop = False
        ' 
        ' PictureBox6
        ' 
        PictureBox6.Image = My.Resources.Resources.clock_five
        PictureBox6.Location = New Point(22, 244)
        PictureBox6.Name = "PictureBox6"
        PictureBox6.Size = New Size(31, 25)
        PictureBox6.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox6.TabIndex = 16
        PictureBox6.TabStop = False
        ' 
        ' PictureBox5
        ' 
        PictureBox5.Image = My.Resources.Resources.calendar
        PictureBox5.Location = New Point(22, 207)
        PictureBox5.Name = "PictureBox5"
        PictureBox5.Size = New Size(31, 25)
        PictureBox5.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox5.TabIndex = 18
        PictureBox5.TabStop = False
        ' 
        ' PictureBox4
        ' 
        PictureBox4.Image = My.Resources.Resources.users_alt
        PictureBox4.Location = New Point(22, 166)
        PictureBox4.Name = "PictureBox4"
        PictureBox4.Size = New Size(31, 25)
        PictureBox4.SizeMode = PictureBoxSizeMode.StretchImage
        PictureBox4.TabIndex = 17
        PictureBox4.TabStop = False
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
        lblName2.Font = New Font("Segoe UI", 12.0F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        lblName2.Location = New Point(20, 20)
        lblName2.Name = "lblName2"
        lblName2.Size = New Size(173, 28)
        lblName2.TabIndex = 0
        lblName2.Text = "Angelo Malaluan"
        ' 
        ' lblCode2
        ' 
        lblCode2.AutoSize = True
        lblCode2.Font = New Font("Segoe UI", 9.0F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblCode2.ForeColor = Color.Gray
        lblCode2.Location = New Point(22, 50)
        lblCode2.Name = "lblCode2"
        lblCode2.Size = New Size(64, 20)
        lblCode2.TabIndex = 1
        lblCode2.Text = "RES-001"
        ' 
        ' lblEmail
        ' 
        lblEmail.AutoSize = True
        lblEmail.Font = New Font("Segoe UI", 10.0F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblEmail.Location = New Point(69, 87)
        lblEmail.Name = "lblEmail"
        lblEmail.Size = New Size(159, 23)
        lblEmail.TabIndex = 3
        lblEmail.Text = "Angelo@gmail.com"
        ' 
        ' lblPhone2
        ' 
        lblPhone2.AutoSize = True
        lblPhone2.Font = New Font("Segoe UI", 9.0F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblPhone2.Location = New Point(69, 130)
        lblPhone2.Name = "lblPhone2"
        lblPhone2.Size = New Size(97, 20)
        lblPhone2.TabIndex = 5
        lblPhone2.Text = "09630834678"
        ' 
        ' lblPeople2
        ' 
        lblPeople2.AutoSize = True
        lblPeople2.Font = New Font("Segoe UI", 9.0F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblPeople2.Location = New Point(69, 171)
        lblPeople2.Name = "lblPeople2"
        lblPeople2.Size = New Size(17, 20)
        lblPeople2.TabIndex = 7
        lblPeople2.Text = "2"
        ' 
        ' lblDate2
        ' 
        lblDate2.AutoSize = True
        lblDate2.Font = New Font("Segoe UI", 9.0F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblDate2.Location = New Point(69, 213)
        lblDate2.Name = "lblDate2"
        lblDate2.Size = New Size(85, 20)
        lblDate2.TabIndex = 9
        lblDate2.Text = "2023-11-16"
        ' 
        ' lblTime2
        ' 
        lblTime2.AutoSize = True
        lblTime2.Font = New Font("Segoe UI", 9.0F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblTime2.Location = New Point(69, 249)
        lblTime2.Name = "lblTime2"
        lblTime2.Size = New Size(61, 20)
        lblTime2.TabIndex = 11
        lblTime2.Text = "8:00 PM"
        ' 
        ' lblEvent2
        ' 
        lblEvent2.AutoSize = True
        lblEvent2.Font = New Font("Segoe UI", 9.0F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblEvent2.Location = New Point(69, 290)
        lblEvent2.Name = "lblEvent2"
        lblEvent2.Size = New Size(85, 20)
        lblEvent2.TabIndex = 13
        lblEvent2.Text = "Anniversary"
        ' 
        ' lblCompleted
        ' 
        lblCompleted.Anchor = AnchorStyles.Top Or AnchorStyles.Right
        lblCompleted.AutoSize = True
        lblCompleted.BackColor = Color.FromArgb(CByte(0), CByte(200), CByte(83))
        lblCompleted.Font = New Font("Segoe UI", 7.8F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        lblCompleted.ForeColor = Color.White
        lblCompleted.Location = New Point(718, 25)
        lblCompleted.Name = "lblCompleted"
        lblCompleted.Padding = New Padding(10, 3, 10, 3)
        lblCompleted.Size = New Size(105, 23)
        lblCompleted.TabIndex = 14
        lblCompleted.Text = "COMPLETED"
        ' 
        ' ReservationsForm
        ' 
        AutoScaleDimensions = New SizeF(8.0F, 20.0F)
        AutoScaleMode = AutoScaleMode.Font
        BackColor = Color.FromArgb(CByte(248), CByte(248), CByte(252))
        ClientSize = New Size(1789, 819)
        Controls.Add(TableLayoutPanel1)
        FormBorderStyle = FormBorderStyle.None
        Name = "ReservationsForm"
        Text = "ReservationsForm"
        TableLayoutPanel1.ResumeLayout(False)
        TableLayoutPanel1.PerformLayout()
        pnlHeader.ResumeLayout(False)
        pnlHeader.PerformLayout()
        Panel1.ResumeLayout(False)
        CType(PictureBox1, ComponentModel.ISupportInitialize).EndInit()
        ResTemplate.ResumeLayout(False)
        ResTemplate.PerformLayout()
        CType(PictureBox8, ComponentModel.ISupportInitialize).EndInit()
        CType(PictureBox7, ComponentModel.ISupportInitialize).EndInit()
        CType(PictureBox6, ComponentModel.ISupportInitialize).EndInit()
        CType(PictureBox5, ComponentModel.ISupportInitialize).EndInit()
        CType(PictureBox4, ComponentModel.ISupportInitialize).EndInit()
        CType(PictureBox3, ComponentModel.ISupportInitialize).EndInit()
        ResumeLayout(False)
    End Sub

    Friend WithEvents TableLayoutPanel1 As TableLayoutPanel
    Friend WithEvents pnlHeader As Panel
    Friend WithEvents lblSubHeader As Label
    Friend WithEvents lblHeader As Label
    Friend WithEvents Panel1 As Panel
    Private WithEvents ResTemplate As Panel
    Private WithEvents lblName2 As Label
    Private WithEvents lblCode2 As Label
    Private WithEvents lblEmail As Label
    Private WithEvents lblPhone2 As Label
    Private WithEvents lblPeople2 As Label
    Private WithEvents lblDate2 As Label
    Private WithEvents lblTime2 As Label
    Private WithEvents lblEvent2 As Label
    Private WithEvents lblCompleted As Label
    Friend WithEvents PictureBox1 As PictureBox
    Friend WithEvents btnNewReservation As Button
    Friend WithEvents PictureBox3 As PictureBox
    Friend WithEvents PictureBox6 As PictureBox
    Friend WithEvents PictureBox5 As PictureBox
    Friend WithEvents PictureBox4 As PictureBox
    Friend WithEvents Button1 As Button
    Friend WithEvents PictureBox7 As PictureBox
    Friend WithEvents Button2 As Button
    Friend WithEvents PictureBox8 As PictureBox
    Friend WithEvents btnRefresh As Button
End Class

