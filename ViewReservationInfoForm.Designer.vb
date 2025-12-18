<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class ViewReservationInfoForm
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()>
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
    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Panel3 = New Panel()
        dgvItems = New DataGridView()
        ColProduct = New DataGridViewTextBoxColumn()
        ColQuantity = New DataGridViewTextBoxColumn()
        ColPrice = New DataGridViewTextBoxColumn()
        ColTotal = New DataGridViewTextBoxColumn()
        Panel1 = New Panel()
        lblTitle = New Label()
        pnlInfo = New Panel()
        lblEventType = New Label()
        lblGuests = New Label()
        lblDateTime = New Label()
        lblEmail = New Label()
        lblPhone = New Label()
        lblName = New Label()
        Panel2 = New Panel()
        lblTotalAmount = New Label()
        btnClose = New Button()
        Panel3.SuspendLayout()
        CType(dgvItems, ComponentModel.ISupportInitialize).BeginInit()
        Panel1.SuspendLayout()
        pnlInfo.SuspendLayout()
        Panel2.SuspendLayout()
        SuspendLayout()
        ' 
        ' Panel3
        ' 
        Panel3.Controls.Add(dgvItems)
        Panel3.Location = New Point(16, 277)
        Panel3.Margin = New Padding(4, 5, 4, 5)
        Panel3.Name = "Panel3"
        Panel3.Size = New Size(779, 308)
        Panel3.TabIndex = 6
        ' 
        ' dgvItems
        ' 
        dgvItems.AllowUserToAddRows = False
        dgvItems.AllowUserToDeleteRows = False
        dgvItems.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
        dgvItems.BackgroundColor = Color.White
        dgvItems.BorderStyle = BorderStyle.None
        dgvItems.ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.AutoSize
        dgvItems.Columns.AddRange(New DataGridViewColumn() {ColProduct, ColQuantity, ColPrice, ColTotal})
        dgvItems.Dock = DockStyle.Fill
        dgvItems.Location = New Point(0, 0)
        dgvItems.Margin = New Padding(4, 5, 4, 5)
        dgvItems.Name = "dgvItems"
        dgvItems.ReadOnly = True
        dgvItems.RowHeadersVisible = False
        dgvItems.RowHeadersWidth = 51
        dgvItems.Size = New Size(779, 308)
        dgvItems.TabIndex = 0
        ' 
        ' ColProduct
        ' 
        ColProduct.HeaderText = "Product Name"
        ColProduct.MinimumWidth = 6
        ColProduct.Name = "ColProduct"
        ColProduct.ReadOnly = True
        ' 
        ' ColQuantity
        ' 
        ColQuantity.FillWeight = 40F
        ColQuantity.HeaderText = "Qty"
        ColQuantity.MinimumWidth = 6
        ColQuantity.Name = "ColQuantity"
        ColQuantity.ReadOnly = True
        ' 
        ' ColPrice
        ' 
        ColPrice.FillWeight = 60F
        ColPrice.HeaderText = "Unit Price"
        ColPrice.MinimumWidth = 6
        ColPrice.Name = "ColPrice"
        ColPrice.ReadOnly = True
        ' 
        ' ColTotal
        ' 
        ColTotal.FillWeight = 60F
        ColTotal.HeaderText = "Total"
        ColTotal.MinimumWidth = 6
        ColTotal.Name = "ColTotal"
        ColTotal.ReadOnly = True
        ' 
        ' Panel1
        ' 
        Panel1.BackColor = Color.FromArgb(CByte(251), CByte(239), CByte(236))
        Panel1.Controls.Add(lblTitle)
        Panel1.Dock = DockStyle.Top
        Panel1.Location = New Point(0, 0)
        Panel1.Margin = New Padding(4, 5, 4, 5)
        Panel1.Name = "Panel1"
        Panel1.Size = New Size(811, 77)
        Panel1.TabIndex = 7
        ' 
        ' lblTitle
        ' 
        lblTitle.AutoSize = True
        lblTitle.Font = New Font("Segoe UI", 12F, FontStyle.Bold)
        lblTitle.ForeColor = Color.Black
        lblTitle.Location = New Point(16, 23)
        lblTitle.Margin = New Padding(4, 0, 4, 0)
        lblTitle.Name = "lblTitle"
        lblTitle.Size = New Size(229, 28)
        lblTitle.TabIndex = 0
        lblTitle.Text = "RESERVATION DETAILS"
        ' 
        ' pnlInfo
        ' 
        pnlInfo.BackColor = Color.WhiteSmoke
        pnlInfo.Controls.Add(lblEventType)
        pnlInfo.Controls.Add(lblGuests)
        pnlInfo.Controls.Add(lblDateTime)
        pnlInfo.Controls.Add(lblEmail)
        pnlInfo.Controls.Add(lblPhone)
        pnlInfo.Controls.Add(lblName)
        pnlInfo.Location = New Point(16, 92)
        pnlInfo.Margin = New Padding(4, 5, 4, 5)
        pnlInfo.Name = "pnlInfo"
        pnlInfo.Size = New Size(779, 169)
        pnlInfo.TabIndex = 8
        ' 
        ' lblEventType
        ' 
        lblEventType.AutoSize = True
        lblEventType.Font = New Font("Segoe UI", 9F)
        lblEventType.Location = New Point(400, 108)
        lblEventType.Margin = New Padding(4, 0, 4, 0)
        lblEventType.Name = "lblEventType"
        lblEventType.Size = New Size(147, 20)
        lblEventType.TabIndex = 5
        lblEventType.Text = "Event Type: Wedding"
        ' 
        ' lblGuests
        ' 
        lblGuests.AutoSize = True
        lblGuests.Font = New Font("Segoe UI", 9F)
        lblGuests.Location = New Point(400, 62)
        lblGuests.Margin = New Padding(4, 0, 4, 0)
        lblGuests.Name = "lblGuests"
        lblGuests.Size = New Size(120, 20)
        lblGuests.TabIndex = 4
        lblGuests.Text = "No. of Guests: 15"
        ' 
        ' lblDateTime
        ' 
        lblDateTime.AutoSize = True
        lblDateTime.Font = New Font("Segoe UI", 9F)
        lblDateTime.Location = New Point(400, 15)
        lblDateTime.Margin = New Padding(4, 0, 4, 0)
        lblDateTime.Name = "lblDateTime"
        lblDateTime.Size = New Size(162, 20)
        lblDateTime.TabIndex = 3
        lblDateTime.Text = "Date/Time: 12/12 6 PM"
        ' 
        ' lblEmail
        ' 
        lblEmail.AutoSize = True
        lblEmail.Font = New Font("Segoe UI", 9F)
        lblEmail.Location = New Point(16, 108)
        lblEmail.Margin = New Padding(4, 0, 4, 0)
        lblEmail.Name = "lblEmail"
        lblEmail.Size = New Size(183, 20)
        lblEmail.TabIndex = 2
        lblEmail.Text = "Email: angelo@gmail.com"
        ' 
        ' lblPhone
        ' 
        lblPhone.AutoSize = True
        lblPhone.Font = New Font("Segoe UI", 9F)
        lblPhone.Location = New Point(16, 62)
        lblPhone.Margin = New Padding(4, 0, 4, 0)
        lblPhone.Name = "lblPhone"
        lblPhone.Size = New Size(137, 20)
        lblPhone.TabIndex = 1
        lblPhone.Text = "Phone: 0912345678"
        ' 
        ' lblName
        ' 
        lblName.AutoSize = True
        lblName.Font = New Font("Segoe UI", 10F, FontStyle.Bold)
        lblName.Location = New Point(16, 15)
        lblName.Margin = New Padding(4, 0, 4, 0)
        lblName.Name = "lblName"
        lblName.Size = New Size(205, 23)
        lblName.TabIndex = 0
        lblName.Text = "Name: Angelo MAlaluan"
        ' 
        ' Panel2
        ' 
        Panel2.BackColor = Color.FromArgb(CByte(248), CByte(249), CByte(250))
        Panel2.Controls.Add(lblTotalAmount)
        Panel2.Controls.Add(btnClose)
        Panel2.Dock = DockStyle.Bottom
        Panel2.Location = New Point(0, 606)
        Panel2.Margin = New Padding(4, 5, 4, 5)
        Panel2.Name = "Panel2"
        Panel2.Size = New Size(811, 92)
        Panel2.TabIndex = 9
        ' 
        ' lblTotalAmount
        ' 
        lblTotalAmount.AutoSize = True
        lblTotalAmount.Font = New Font("Segoe UI", 12F, FontStyle.Bold)
        lblTotalAmount.ForeColor = Color.Black
        lblTotalAmount.Location = New Point(16, 31)
        lblTotalAmount.Margin = New Padding(4, 0, 4, 0)
        lblTotalAmount.Name = "lblTotalAmount"
        lblTotalAmount.Size = New Size(165, 28)
        lblTotalAmount.TabIndex = 3
        lblTotalAmount.Text = "Total: ₱0,000.00"
        ' 
        ' btnClose
        ' 
        btnClose.BackColor = Color.FromArgb(CByte(231), CByte(76), CByte(60))
        btnClose.FlatStyle = FlatStyle.Flat
        btnClose.Font = New Font("Segoe UI Semibold", 9.75F, FontStyle.Bold)
        btnClose.ForeColor = Color.White
        btnClose.Location = New Point(677, 23)
        btnClose.Margin = New Padding(4, 5, 4, 5)
        btnClose.Name = "btnClose"
        btnClose.Size = New Size(117, 49)
        btnClose.TabIndex = 2
        btnClose.Text = "Close"
        btnClose.UseVisualStyleBackColor = False
        ' 
        ' ViewReservationInfoForm
        ' 
        AutoScaleDimensions = New SizeF(8F, 20F)
        AutoScaleMode = AutoScaleMode.Font
        BackColor = Color.White
        ClientSize = New Size(811, 698)
        Controls.Add(Panel2)
        Controls.Add(pnlInfo)
        Controls.Add(Panel1)
        Controls.Add(Panel3)
        FormBorderStyle = FormBorderStyle.FixedDialog
        Margin = New Padding(4, 5, 4, 5)
        MaximizeBox = False
        MinimizeBox = False
        Name = "ViewReservationInfoForm"
        StartPosition = FormStartPosition.CenterParent
        Text = "Reservation Details"
        Panel3.ResumeLayout(False)
        CType(dgvItems, ComponentModel.ISupportInitialize).EndInit()
        Panel1.ResumeLayout(False)
        Panel1.PerformLayout()
        pnlInfo.ResumeLayout(False)
        pnlInfo.PerformLayout()
        Panel2.ResumeLayout(False)
        Panel2.PerformLayout()
        ResumeLayout(False)

    End Sub

    Friend WithEvents Panel3 As Panel
    Friend WithEvents dgvItems As DataGridView
    Friend WithEvents ColProduct As DataGridViewTextBoxColumn
    Friend WithEvents ColQuantity As DataGridViewTextBoxColumn
    Friend WithEvents ColPrice As DataGridViewTextBoxColumn
    Friend WithEvents ColTotal As DataGridViewTextBoxColumn
    Friend WithEvents Panel1 As Panel
    Friend WithEvents lblTitle As Label
    Friend WithEvents pnlInfo As Panel
    Friend WithEvents lblEventType As Label
    Friend WithEvents lblGuests As Label
    Friend WithEvents lblDateTime As Label
    Friend WithEvents lblEmail As Label
    Friend WithEvents lblPhone As Label
    Friend WithEvents lblName As Label
    Friend WithEvents Panel2 As Panel
    Friend WithEvents lblTotalAmount As Label
    Friend WithEvents btnClose As Button
End Class
