<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class PaymentDialog
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
        Me.Panel1 = New System.Windows.Forms.Panel()
        Me.lblTitle = New System.Windows.Forms.Label()
        Me.Panel2 = New System.Windows.Forms.Panel()
        Me.lblTotalLabel = New System.Windows.Forms.Label()
        Me.lblTotalAmount = New System.Windows.Forms.Label()
        Me.lblPaymentMethodLabel = New System.Windows.Forms.Label()
        Me.cmbPaymentMethod = New System.Windows.Forms.ComboBox()
        Me.lblAmountGivenLabel = New System.Windows.Forms.Label()
        Me.txtAmountGiven = New System.Windows.Forms.TextBox()
        Me.lblChangeLabel = New System.Windows.Forms.Label()
        Me.lblChange = New System.Windows.Forms.Label()
        Me.btnConfirm = New System.Windows.Forms.Button()
        Me.btnCancel = New System.Windows.Forms.Button()
        Me.Panel1.SuspendLayout()
        Me.Panel2.SuspendLayout()
        Me.SuspendLayout()
        '
        'Panel1
        '
        Me.Panel1.BackColor = System.Drawing.Color.FromArgb(CType(CType(255, Byte), Integer), CType(CType(127, Byte), Integer), CType(CType(39, Byte), Integer))
        Me.Panel1.Controls.Add(Me.lblTitle)
        Me.Panel1.Dock = System.Windows.Forms.DockStyle.Top
        Me.Panel1.Location = New System.Drawing.Point(0, 0)
        Me.Panel1.Name = "Panel1"
        Me.Panel1.Size = New System.Drawing.Size(400, 60)
        Me.Panel1.TabIndex = 0
        '
        'lblTitle
        '
        Me.lblTitle.AutoSize = True
        Me.lblTitle.Font = New System.Drawing.Font("Segoe UI", 14.0!, System.Drawing.FontStyle.Bold)
        Me.lblTitle.ForeColor = System.Drawing.Color.White
        Me.lblTitle.Location = New System.Drawing.Point(120, 18)
        Me.lblTitle.Name = "lblTitle"
        Me.lblTitle.Size = New System.Drawing.Size(160, 25)
        Me.lblTitle.TabIndex = 0
        Me.lblTitle.Text = "Payment Details"
        '
        'Panel2
        '
        Me.Panel2.BackColor = System.Drawing.Color.White
        Me.Panel2.Controls.Add(Me.btnCancel)
        Me.Panel2.Controls.Add(Me.btnConfirm)
        Me.Panel2.Controls.Add(Me.lblChange)
        Me.Panel2.Controls.Add(Me.lblChangeLabel)
        Me.Panel2.Controls.Add(Me.txtAmountGiven)
        Me.Panel2.Controls.Add(Me.lblAmountGivenLabel)
        Me.Panel2.Controls.Add(Me.cmbPaymentMethod)
        Me.Panel2.Controls.Add(Me.lblPaymentMethodLabel)
        Me.Panel2.Controls.Add(Me.lblTotalAmount)
        Me.Panel2.Controls.Add(Me.lblTotalLabel)
        Me.Panel2.Dock = System.Windows.Forms.DockStyle.Fill
        Me.Panel2.Location = New System.Drawing.Point(0, 60)
        Me.Panel2.Name = "Panel2"
        Me.Panel2.Padding = New System.Windows.Forms.Padding(30, 20, 30, 20)
        Me.Panel2.Size = New System.Drawing.Size(400, 290)
        Me.Panel2.TabIndex = 1
        '
        'lblTotalLabel
        '
        Me.lblTotalLabel.AutoSize = True
        Me.lblTotalLabel.Font = New System.Drawing.Font("Segoe UI", 10.0!)
        Me.lblTotalLabel.Location = New System.Drawing.Point(30, 30)
        Me.lblTotalLabel.Name = "lblTotalLabel"
        Me.lblTotalLabel.Size = New System.Drawing.Size(99, 19)
        Me.lblTotalLabel.TabIndex = 0
        Me.lblTotalLabel.Text = "Total Amount:"
        '
        'lblTotalAmount
        '
        Me.lblTotalAmount.AutoSize = True
        Me.lblTotalAmount.Font = New System.Drawing.Font("Segoe UI", 14.0!, System.Drawing.FontStyle.Bold)
        Me.lblTotalAmount.ForeColor = System.Drawing.Color.FromArgb(CType(CType(255, Byte), Integer), CType(CType(127, Byte), Integer), CType(CType(39, Byte), Integer))
        Me.lblTotalAmount.Location = New System.Drawing.Point(250, 25)
        Me.lblTotalAmount.Name = "lblTotalAmount"
        Me.lblTotalAmount.Size = New System.Drawing.Size(62, 25)
        Me.lblTotalAmount.TabIndex = 1
        Me.lblTotalAmount.Text = "₱0.00"
        '
        'lblPaymentMethodLabel
        '
        Me.lblPaymentMethodLabel.AutoSize = True
        Me.lblPaymentMethodLabel.Font = New System.Drawing.Font("Segoe UI", 10.0!)
        Me.lblPaymentMethodLabel.Location = New System.Drawing.Point(30, 70)
        Me.lblPaymentMethodLabel.Name = "lblPaymentMethodLabel"
        Me.lblPaymentMethodLabel.Size = New System.Drawing.Size(125, 19)
        Me.lblPaymentMethodLabel.TabIndex = 2
        Me.lblPaymentMethodLabel.Text = "Payment Method:"
        '
        'cmbPaymentMethod
        '
        Me.cmbPaymentMethod.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList
        Me.cmbPaymentMethod.Font = New System.Drawing.Font("Segoe UI", 10.0!)
        Me.cmbPaymentMethod.FormattingEnabled = True
        Me.cmbPaymentMethod.Location = New System.Drawing.Point(30, 95)
        Me.cmbPaymentMethod.Name = "cmbPaymentMethod"
        Me.cmbPaymentMethod.Size = New System.Drawing.Size(340, 25)
        Me.cmbPaymentMethod.TabIndex = 3
        '
        'lblAmountGivenLabel
        '
        Me.lblAmountGivenLabel.AutoSize = True
        Me.lblAmountGivenLabel.Font = New System.Drawing.Font("Segoe UI", 10.0!)
        Me.lblAmountGivenLabel.Location = New System.Drawing.Point(30, 135)
        Me.lblAmountGivenLabel.Name = "lblAmountGivenLabel"
        Me.lblAmountGivenLabel.Size = New System.Drawing.Size(107, 19)
        Me.lblAmountGivenLabel.TabIndex = 4
        Me.lblAmountGivenLabel.Text = "Amount Given:"
        '
        'txtAmountGiven
        '
        Me.txtAmountGiven.Font = New System.Drawing.Font("Segoe UI", 10.0!)
        Me.txtAmountGiven.Location = New System.Drawing.Point(30, 160)
        Me.txtAmountGiven.Name = "txtAmountGiven"
        Me.txtAmountGiven.Size = New System.Drawing.Size(340, 25)
        Me.txtAmountGiven.TabIndex = 5
        '
        'lblChangeLabel
        '
        Me.lblChangeLabel.AutoSize = True
        Me.lblChangeLabel.Font = New System.Drawing.Font("Segoe UI", 10.0!)
        Me.lblChangeLabel.Location = New System.Drawing.Point(30, 200)
        Me.lblChangeLabel.Name = "lblChangeLabel"
        Me.lblChangeLabel.Size = New System.Drawing.Size(61, 19)
        Me.lblChangeLabel.TabIndex = 6
        Me.lblChangeLabel.Text = "Change:"
        '
        'lblChange
        '
        Me.lblChange.AutoSize = True
        Me.lblChange.Font = New System.Drawing.Font("Segoe UI", 12.0!, System.Drawing.FontStyle.Bold)
        Me.lblChange.Location = New System.Drawing.Point(250, 198)
        Me.lblChange.Name = "lblChange"
        Me.lblChange.Size = New System.Drawing.Size(54, 21)
        Me.lblChange.TabIndex = 7
        Me.lblChange.Text = "₱0.00"
        '
        'btnConfirm
        '
        Me.btnConfirm.BackColor = System.Drawing.Color.FromArgb(CType(CType(255, Byte), Integer), CType(CType(127, Byte), Integer), CType(CType(39, Byte), Integer))
        Me.btnConfirm.FlatAppearance.BorderSize = 0
        Me.btnConfirm.FlatStyle = System.Windows.Forms.FlatStyle.Flat
        Me.btnConfirm.Font = New System.Drawing.Font("Segoe UI", 10.0!, System.Drawing.FontStyle.Bold)
        Me.btnConfirm.ForeColor = System.Drawing.Color.White
        Me.btnConfirm.Location = New System.Drawing.Point(220, 240)
        Me.btnConfirm.Name = "btnConfirm"
        Me.btnConfirm.Size = New System.Drawing.Size(150, 35)
        Me.btnConfirm.TabIndex = 8
        Me.btnConfirm.Text = "Confirm"
        Me.btnConfirm.UseVisualStyleBackColor = False
        '
        'btnCancel
        '
        Me.btnCancel.BackColor = System.Drawing.Color.WhiteSmoke
        Me.btnCancel.FlatAppearance.BorderColor = System.Drawing.Color.Gray
        Me.btnCancel.FlatStyle = System.Windows.Forms.FlatStyle.Flat
        Me.btnCancel.Font = New System.Drawing.Font("Segoe UI", 10.0!)
        Me.btnCancel.Location = New System.Drawing.Point(30, 240)
        Me.btnCancel.Name = "btnCancel"
        Me.btnCancel.Size = New System.Drawing.Size(150, 35)
        Me.btnCancel.TabIndex = 9
        Me.btnCancel.Text = "Cancel"
        Me.btnCancel.UseVisualStyleBackColor = False
        '
        'PaymentDialog
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(400, 350)
        Me.Controls.Add(Me.Panel2)
        Me.Controls.Add(Me.Panel1)
        Me.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog
        Me.MaximizeBox = False
        Me.MinimizeBox = False
        Me.Name = "PaymentDialog"
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent
        Me.Text = "Payment"
        Me.Panel1.ResumeLayout(False)
        Me.Panel1.PerformLayout()
        Me.Panel2.ResumeLayout(False)
        Me.Panel2.PerformLayout()
        Me.ResumeLayout(False)

    End Sub

    Friend WithEvents Panel1 As Panel
    Friend WithEvents lblTitle As Label
    Friend WithEvents Panel2 As Panel
    Friend WithEvents lblTotalAmount As Label
    Friend WithEvents lblTotalLabel As Label
    Friend WithEvents lblChange As Label
    Friend WithEvents lblChangeLabel As Label
    Friend WithEvents txtAmountGiven As TextBox
    Friend WithEvents lblAmountGivenLabel As Label
    Friend WithEvents cmbPaymentMethod As ComboBox
    Friend WithEvents lblPaymentMethodLabel As Label
    Friend WithEvents btnCancel As Button
    Friend WithEvents btnConfirm As Button
End Class
