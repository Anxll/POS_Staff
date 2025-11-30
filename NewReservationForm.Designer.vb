<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class NewReservationForm
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
    Private components As System.ComponentModel.IContainer = Nothing

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        lblHeader = New Label()
        btnClose = New Button()
        lblCustomerName = New Label()
        pnlName = New Panel()
        txtName = New TextBox()
        lblGuests = New Label()
        pnlGuests = New Panel()
        numGuests = New NumericUpDown()
        lblEventType = New Label()
        pnlEventType = New Panel()
        cmbEventType = New ComboBox()
        lblDate = New Label()
        pnlDate = New Panel()
        dtpDate = New DateTimePicker()
        lblTime = New Label()
        pnlTime = New Panel()
        dtpTime = New DateTimePicker()
        lblPhone = New Label()
        pnlPhone = New Panel()
        txtPhone = New TextBox()
        lblSpecialRequest = New Label()
        pnlSpecialRequest = New Panel()
        txtSpecialRequest = New TextBox()
        btnBookTable = New Button()
        Panel1 = New Panel()
        Button1 = New Button()
        pnlName.SuspendLayout()
        pnlGuests.SuspendLayout()
        CType(numGuests, ComponentModel.ISupportInitialize).BeginInit()
        pnlEventType.SuspendLayout()
        pnlDate.SuspendLayout()
        pnlTime.SuspendLayout()
        pnlPhone.SuspendLayout()
        pnlSpecialRequest.SuspendLayout()
        Panel1.SuspendLayout()
        SuspendLayout()
        ' 
        ' lblHeader
        ' 
        lblHeader.AutoSize = True
        lblHeader.Font = New Font("Segoe UI", 20F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        lblHeader.Location = New Point(40, 30)
        lblHeader.Name = "lblHeader"
        lblHeader.Size = New Size(346, 46)
        lblHeader.TabIndex = 0
        lblHeader.Text = "Make a Reservations"
        ' 
        ' btnClose
        ' 
        btnClose.Anchor = AnchorStyles.Top Or AnchorStyles.Right
        btnClose.FlatAppearance.BorderSize = 0
        btnClose.FlatStyle = FlatStyle.Flat
        btnClose.Font = New Font("Segoe UI", 14F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        btnClose.Location = New Point(880, 20)
        btnClose.Name = "btnClose"
        btnClose.Size = New Size(40, 40)
        btnClose.TabIndex = 1
        btnClose.Text = "X"
        btnClose.UseVisualStyleBackColor = True
        ' 
        ' lblCustomerName
        ' 
        lblCustomerName.AutoSize = True
        lblCustomerName.Font = New Font("Segoe UI", 10F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblCustomerName.Location = New Point(45, 100)
        lblCustomerName.Name = "lblCustomerName"
        lblCustomerName.Size = New Size(135, 23)
        lblCustomerName.TabIndex = 2
        lblCustomerName.Text = "Customer Name"
        ' 
        ' pnlName
        ' 
        pnlName.BackColor = Color.White
        pnlName.BorderStyle = BorderStyle.FixedSingle
        pnlName.Controls.Add(txtName)
        pnlName.Location = New Point(45, 130)
        pnlName.Name = "pnlName"
        pnlName.Size = New Size(400, 45)
        pnlName.TabIndex = 3
        ' 
        ' txtName
        ' 
        txtName.BorderStyle = BorderStyle.None
        txtName.Font = New Font("Segoe UI", 12F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        txtName.Location = New Point(10, 8)
        txtName.Name = "txtName"
        txtName.Size = New Size(380, 27)
        txtName.TabIndex = 0
        ' 
        ' lblGuests
        ' 
        lblGuests.AutoSize = True
        lblGuests.Font = New Font("Segoe UI", 10F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblGuests.Location = New Point(480, 100)
        lblGuests.Name = "lblGuests"
        lblGuests.Size = New Size(149, 23)
        lblGuests.TabIndex = 4
        lblGuests.Text = "Number of People"
        ' 
        ' pnlGuests
        ' 
        pnlGuests.BackColor = Color.White
        pnlGuests.BorderStyle = BorderStyle.FixedSingle
        pnlGuests.Controls.Add(numGuests)
        pnlGuests.Location = New Point(480, 130)
        pnlGuests.Name = "pnlGuests"
        pnlGuests.Size = New Size(400, 45)
        pnlGuests.TabIndex = 5
        ' 
        ' numGuests
        ' 
        numGuests.BorderStyle = BorderStyle.None
        numGuests.Font = New Font("Segoe UI", 12F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        numGuests.Location = New Point(10, 8)
        numGuests.Minimum = New Decimal(New Integer() {1, 0, 0, 0})
        numGuests.Name = "numGuests"
        numGuests.Size = New Size(380, 30)
        numGuests.TabIndex = 0
        numGuests.Value = New Decimal(New Integer() {1, 0, 0, 0})
        ' 
        ' lblEventType
        ' 
        lblEventType.AutoSize = True
        lblEventType.Font = New Font("Segoe UI", 10F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblEventType.Location = New Point(45, 200)
        lblEventType.Name = "lblEventType"
        lblEventType.Size = New Size(92, 23)
        lblEventType.TabIndex = 6
        lblEventType.Text = "Event Type"
        ' 
        ' pnlEventType
        ' 
        pnlEventType.BackColor = Color.White
        pnlEventType.BorderStyle = BorderStyle.FixedSingle
        pnlEventType.Controls.Add(cmbEventType)
        pnlEventType.Location = New Point(45, 230)
        pnlEventType.Name = "pnlEventType"
        pnlEventType.Size = New Size(400, 45)
        pnlEventType.TabIndex = 7
        ' 
        ' cmbEventType
        ' 
        cmbEventType.FlatStyle = FlatStyle.Flat
        cmbEventType.Font = New Font("Segoe UI", 12F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        cmbEventType.FormattingEnabled = True
        cmbEventType.Items.AddRange(New Object() {"Birthday", "Anniversary", "Business Meeting", "Casual Dining", "Other"})
        cmbEventType.Location = New Point(10, 4)
        cmbEventType.Name = "cmbEventType"
        cmbEventType.Size = New Size(380, 36)
        cmbEventType.TabIndex = 0
        cmbEventType.Text = "Select event type"
        ' 
        ' lblDate
        ' 
        lblDate.AutoSize = True
        lblDate.Font = New Font("Segoe UI", 10F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblDate.Location = New Point(480, 200)
        lblDate.Name = "lblDate"
        lblDate.Size = New Size(46, 23)
        lblDate.TabIndex = 8
        lblDate.Text = "Date"
        ' 
        ' pnlDate
        ' 
        pnlDate.BackColor = Color.White
        pnlDate.BorderStyle = BorderStyle.FixedSingle
        pnlDate.Controls.Add(dtpDate)
        pnlDate.Location = New Point(480, 230)
        pnlDate.Name = "pnlDate"
        pnlDate.Size = New Size(400, 45)
        pnlDate.TabIndex = 9
        ' 
        ' dtpDate
        ' 
        dtpDate.CalendarFont = New Font("Segoe UI", 12F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        dtpDate.Font = New Font("Segoe UI", 12F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        dtpDate.Format = DateTimePickerFormat.Short
        dtpDate.Location = New Point(10, 5)
        dtpDate.Name = "dtpDate"
        dtpDate.Size = New Size(380, 34)
        dtpDate.TabIndex = 0
        ' 
        ' lblTime
        ' 
        lblTime.AutoSize = True
        lblTime.Font = New Font("Segoe UI", 10F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblTime.Location = New Point(45, 300)
        lblTime.Name = "lblTime"
        lblTime.Size = New Size(47, 23)
        lblTime.TabIndex = 10
        lblTime.Text = "Time"
        ' 
        ' pnlTime
        ' 
        pnlTime.BackColor = Color.White
        pnlTime.BorderStyle = BorderStyle.FixedSingle
        pnlTime.Controls.Add(dtpTime)
        pnlTime.Location = New Point(45, 330)
        pnlTime.Name = "pnlTime"
        pnlTime.Size = New Size(400, 45)
        pnlTime.TabIndex = 11
        ' 
        ' dtpTime
        ' 
        dtpTime.CalendarFont = New Font("Segoe UI", 12F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        dtpTime.Font = New Font("Segoe UI", 12F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        dtpTime.Format = DateTimePickerFormat.Time
        dtpTime.Location = New Point(10, 5)
        dtpTime.Name = "dtpTime"
        dtpTime.ShowUpDown = True
        dtpTime.Size = New Size(380, 34)
        dtpTime.TabIndex = 0
        ' 
        ' lblPhone
        ' 
        lblPhone.AutoSize = True
        lblPhone.Font = New Font("Segoe UI", 10F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblPhone.Location = New Point(480, 300)
        lblPhone.Name = "lblPhone"
        lblPhone.Size = New Size(127, 23)
        lblPhone.TabIndex = 12
        lblPhone.Text = "Phone Number"
        ' 
        ' pnlPhone
        ' 
        pnlPhone.BackColor = Color.White
        pnlPhone.BorderStyle = BorderStyle.FixedSingle
        pnlPhone.Controls.Add(txtPhone)
        pnlPhone.Location = New Point(480, 330)
        pnlPhone.Name = "pnlPhone"
        pnlPhone.Size = New Size(400, 45)
        pnlPhone.TabIndex = 13
        ' 
        ' txtPhone
        ' 
        txtPhone.BorderStyle = BorderStyle.None
        txtPhone.Font = New Font("Segoe UI", 12F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        txtPhone.Location = New Point(10, 8)
        txtPhone.Name = "txtPhone"
        txtPhone.Size = New Size(380, 27)
        txtPhone.TabIndex = 0
        ' 
        ' lblSpecialRequest
        ' 
        lblSpecialRequest.AutoSize = True
        lblSpecialRequest.Font = New Font("Segoe UI", 10F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        lblSpecialRequest.Location = New Point(44, 479)
        lblSpecialRequest.Name = "lblSpecialRequest"
        lblSpecialRequest.Size = New Size(217, 23)
        lblSpecialRequest.TabIndex = 14
        lblSpecialRequest.Text = "Special Requests (Optional)"
        ' 
        ' pnlSpecialRequest
        ' 
        pnlSpecialRequest.BackColor = Color.White
        pnlSpecialRequest.BorderStyle = BorderStyle.FixedSingle
        pnlSpecialRequest.Controls.Add(txtSpecialRequest)
        pnlSpecialRequest.Location = New Point(44, 509)
        pnlSpecialRequest.Name = "pnlSpecialRequest"
        pnlSpecialRequest.Size = New Size(835, 150)
        pnlSpecialRequest.TabIndex = 15
        ' 
        ' txtSpecialRequest
        ' 
        txtSpecialRequest.BorderStyle = BorderStyle.None
        txtSpecialRequest.Font = New Font("Segoe UI", 10F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        txtSpecialRequest.Location = New Point(10, 10)
        txtSpecialRequest.Multiline = True
        txtSpecialRequest.Name = "txtSpecialRequest"
        txtSpecialRequest.PlaceholderText = "Any special requests..."
        txtSpecialRequest.Size = New Size(815, 130)
        txtSpecialRequest.TabIndex = 0
        ' 
        ' btnBookTable
        ' 
        btnBookTable.BackColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        btnBookTable.FlatAppearance.BorderColor = Color.Black
        btnBookTable.FlatStyle = FlatStyle.Flat
        btnBookTable.Font = New Font("Segoe UI", 12F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        btnBookTable.ForeColor = Color.White
        btnBookTable.Location = New Point(329, 689)
        btnBookTable.Name = "btnBookTable"
        btnBookTable.Size = New Size(265, 50)
        btnBookTable.TabIndex = 16
        btnBookTable.Text = "Submit Reservation"
        btnBookTable.UseVisualStyleBackColor = False
        ' 
        ' Panel1
        ' 
        Panel1.BorderStyle = BorderStyle.FixedSingle
        Panel1.Controls.Add(Button1)
        Panel1.Controls.Add(btnBookTable)
        Panel1.Controls.Add(pnlSpecialRequest)
        Panel1.Controls.Add(lblSpecialRequest)
        Panel1.Dock = DockStyle.Fill
        Panel1.Location = New Point(0, 0)
        Panel1.Name = "Panel1"
        Panel1.Size = New Size(940, 780)
        Panel1.TabIndex = 17
        ' 
        ' Button1
        ' 
        Button1.BackColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        Button1.FlatAppearance.BorderColor = Color.Black
        Button1.FlatStyle = FlatStyle.Flat
        Button1.Font = New Font("Segoe UI", 10F, FontStyle.Bold, GraphicsUnit.Point, CByte(0))
        Button1.ForeColor = Color.White
        Button1.Location = New Point(364, 418)
        Button1.Name = "Button1"
        Button1.Size = New Size(192, 43)
        Button1.TabIndex = 17
        Button1.Text = "Select Order"
        Button1.UseVisualStyleBackColor = False
        ' 
        ' NewReservationForm
        ' 
        AutoScaleDimensions = New SizeF(8F, 20F)
        AutoScaleMode = AutoScaleMode.Font
        BackColor = Color.FromArgb(CByte(255), CByte(248), CByte(248))
        ClientSize = New Size(940, 780)
        Controls.Add(pnlPhone)
        Controls.Add(lblPhone)
        Controls.Add(pnlTime)
        Controls.Add(lblTime)
        Controls.Add(pnlDate)
        Controls.Add(lblDate)
        Controls.Add(pnlEventType)
        Controls.Add(lblEventType)
        Controls.Add(pnlGuests)
        Controls.Add(lblGuests)
        Controls.Add(pnlName)
        Controls.Add(lblCustomerName)
        Controls.Add(btnClose)
        Controls.Add(lblHeader)
        Controls.Add(Panel1)
        FormBorderStyle = FormBorderStyle.None
        Name = "NewReservationForm"
        StartPosition = FormStartPosition.CenterParent
        Text = "New Reservation"
        pnlName.ResumeLayout(False)
        pnlName.PerformLayout()
        pnlGuests.ResumeLayout(False)
        CType(numGuests, ComponentModel.ISupportInitialize).EndInit()
        pnlEventType.ResumeLayout(False)
        pnlDate.ResumeLayout(False)
        pnlTime.ResumeLayout(False)
        pnlPhone.ResumeLayout(False)
        pnlPhone.PerformLayout()
        pnlSpecialRequest.ResumeLayout(False)
        pnlSpecialRequest.PerformLayout()
        Panel1.ResumeLayout(False)
        Panel1.PerformLayout()
        ResumeLayout(False)
        PerformLayout()

    End Sub

    Friend WithEvents lblHeader As Label
    Friend WithEvents btnClose As Button
    Friend WithEvents lblCustomerName As Label
    Friend WithEvents pnlName As Panel
    Friend WithEvents txtName As TextBox
    Friend WithEvents lblGuests As Label
    Friend WithEvents pnlGuests As Panel
    Friend WithEvents numGuests As NumericUpDown
    Friend WithEvents lblEventType As Label
    Friend WithEvents pnlEventType As Panel
    Friend WithEvents cmbEventType As ComboBox
    Friend WithEvents lblDate As Label
    Friend WithEvents pnlDate As Panel
    Friend WithEvents dtpDate As DateTimePicker
    Friend WithEvents lblTime As Label
    Friend WithEvents pnlTime As Panel
    Friend WithEvents dtpTime As DateTimePicker
    Friend WithEvents lblPhone As Label
    Friend WithEvents pnlPhone As Panel
    Friend WithEvents txtPhone As TextBox
    Friend WithEvents lblSpecialRequest As Label
    Friend WithEvents pnlSpecialRequest As Panel
    Friend WithEvents txtSpecialRequest As TextBox
    Friend WithEvents btnBookTable As Button
    Friend WithEvents Panel1 As Panel
    Friend WithEvents Button1 As Button
End Class
