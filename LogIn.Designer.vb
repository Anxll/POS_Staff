<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class LogIn
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
        TableLayoutPanel1 = New TableLayoutPanel()
        pnlHeader = New Panel()
        Panel6 = New Panel()
        lblHeaderTitle = New Label()
        logo = New PictureBox()
        Panel2 = New Panel()
        Panel3 = New Panel()
        btnServerSettings = New Button()
        btnLoginTimein = New Button()
        chkShowPassword = New CheckBox()
        Label3 = New Label()
        Label2 = New Label()
        Panel5 = New Panel()
        txtPassword = New TextBox()
        Panel4 = New Panel()
        txtUsername = New TextBox()
        lblSubHeader = New Label()
        Label1 = New Label()
        Panel1 = New Panel()
        TableLayoutPanel1.SuspendLayout()
        pnlHeader.SuspendLayout()
        Panel6.SuspendLayout()
        CType(logo, ComponentModel.ISupportInitialize).BeginInit()
        Panel2.SuspendLayout()
        Panel3.SuspendLayout()
        Panel5.SuspendLayout()
        Panel4.SuspendLayout()
        Panel1.SuspendLayout()
        SuspendLayout()
        ' 
        ' TableLayoutPanel1
        ' 
        TableLayoutPanel1.ColumnCount = 1
        TableLayoutPanel1.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100.0F))
        TableLayoutPanel1.Controls.Add(pnlHeader, 0, 0)
        TableLayoutPanel1.Controls.Add(Panel2, 0, 1)
        TableLayoutPanel1.Dock = DockStyle.Fill
        TableLayoutPanel1.Location = New Point(0, 0)
        TableLayoutPanel1.Margin = New Padding(0)
        TableLayoutPanel1.Name = "TableLayoutPanel1"
        TableLayoutPanel1.RowCount = 2
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Absolute, 88.0F))
        TableLayoutPanel1.RowStyles.Add(New RowStyle(SizeType.Percent, 100.0F))
        TableLayoutPanel1.Size = New Size(1280, 720)
        TableLayoutPanel1.TabIndex = 0
        ' 
        ' pnlHeader
        ' 
        pnlHeader.BackColor = Color.FromArgb(CByte(59), CByte(42), CByte(32))
        pnlHeader.Controls.Add(Panel6)
        pnlHeader.Dock = DockStyle.Fill
        pnlHeader.Location = New Point(0, 0)
        pnlHeader.Margin = New Padding(0)
        pnlHeader.Name = "pnlHeader"
        pnlHeader.Padding = New Padding(24, 16, 24, 16)
        pnlHeader.Size = New Size(1280, 88)
        pnlHeader.TabIndex = 1
        ' 
        ' Panel6
        ' 
        Panel6.Controls.Add(lblHeaderTitle)
        Panel6.Controls.Add(logo)
        Panel6.Dock = DockStyle.Fill
        Panel6.Location = New Point(24, 16)
        Panel6.Name = "Panel6"
        Panel6.Size = New Size(1232, 56)
        Panel6.TabIndex = 0
        ' 
        ' lblHeaderTitle
        ' 
        lblHeaderTitle.Anchor = AnchorStyles.None
        lblHeaderTitle.AutoSize = True
        lblHeaderTitle.Font = New Font("Segoe UI Semibold", 14.0F, FontStyle.Bold)
        lblHeaderTitle.ForeColor = SystemColors.Window
        lblHeaderTitle.Location = New Point(594, 15)
        lblHeaderTitle.Name = "lblHeaderTitle"
        lblHeaderTitle.Size = New Size(147, 32)
        lblHeaderTitle.TabIndex = 0
        lblHeaderTitle.Text = "Tabeya Staff"
        ' 
        ' logo
        ' 
        logo.Anchor = AnchorStyles.None
        logo.BackColor = Color.Transparent
        logo.Image = My.Resources.Resources._291136637_456626923131971_8250989517364923746_n_removebg_preview1
        logo.Location = New Point(518, 2)
        logo.Margin = New Padding(0, 9, 0, 0)
        logo.Name = "logo"
        logo.Size = New Size(67, 59)
        logo.SizeMode = PictureBoxSizeMode.Zoom
        logo.TabIndex = 1
        logo.TabStop = False
        ' 
        ' Panel2
        ' 
        Panel2.BackColor = Color.FromArgb(CByte(255), CByte(246), CByte(245))
        Panel2.Controls.Add(Panel3)
        Panel2.Dock = DockStyle.Fill
        Panel2.Location = New Point(0, 88)
        Panel2.Margin = New Padding(0)
        Panel2.Name = "Panel2"
        Panel2.Size = New Size(1280, 632)
        Panel2.TabIndex = 2
        ' 
        ' Panel3
        ' 
        Panel3.Anchor = AnchorStyles.None
        Panel3.BorderStyle = BorderStyle.FixedSingle
        Panel3.Controls.Add(btnServerSettings)
        Panel3.Controls.Add(btnLoginTimein)
        Panel3.Controls.Add(chkShowPassword)
        Panel3.Controls.Add(Label3)
        Panel3.Controls.Add(Label2)
        Panel3.Controls.Add(Panel5)
        Panel3.Controls.Add(Panel4)
        Panel3.Controls.Add(lblSubHeader)
        Panel3.Controls.Add(Label1)
        Panel3.Location = New Point(1040, 346)
        Panel3.Name = "Panel3"
        Panel3.Size = New Size(501, 476)
        Panel3.TabIndex = 0
        ' 
        ' btnServerSettings
        ' 
        btnServerSettings.BackColor = Color.FromArgb(CByte(100), CByte(100), CByte(100))
        btnServerSettings.FlatStyle = FlatStyle.Flat
        btnServerSettings.ForeColor = Color.White
        btnServerSettings.Location = New Point(37, 435)
        btnServerSettings.Name = "btnServerSettings"
        btnServerSettings.Size = New Size(140, 30)
        btnServerSettings.TabIndex = 8
        btnServerSettings.Text = "⚙ Server Settings"
        btnServerSettings.UseVisualStyleBackColor = False
        ' 
        ' btnLoginTimein
        ' 
        btnLoginTimein.BackColor = Color.FromArgb(CByte(255), CByte(127), CByte(39))
        btnLoginTimein.FlatStyle = FlatStyle.Popup
        btnLoginTimein.Location = New Point(167, 379)
        btnLoginTimein.Name = "btnLoginTimein"
        btnLoginTimein.Size = New Size(176, 50)
        btnLoginTimein.TabIndex = 7
        btnLoginTimein.Text = "Login/Time-In"
        btnLoginTimein.UseVisualStyleBackColor = False
        ' 
        ' chkShowPassword
        ' 
        chkShowPassword.AutoSize = True
        chkShowPassword.Font = New Font("Segoe UI", 9.0F)
        chkShowPassword.Location = New Point(40, 350)
        chkShowPassword.Name = "chkShowPassword"
        chkShowPassword.Size = New Size(129, 24)
        chkShowPassword.TabIndex = 6
        chkShowPassword.Text = "Show Password"
        chkShowPassword.UseVisualStyleBackColor = True
        ' 
        ' Label3
        ' 
        Label3.AutoSize = True
        Label3.Font = New Font("Segoe UI", 10.0F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        Label3.Location = New Point(27, 260)
        Label3.Name = "Label3"
        Label3.Size = New Size(106, 23)
        Label3.TabIndex = 6
        Label3.Text = "Password"
        ' 
        ' Label2
        ' 
        Label2.AutoSize = True
        Label2.Font = New Font("Segoe UI", 10.0F, FontStyle.Regular, GraphicsUnit.Point, CByte(0))
        Label2.Location = New Point(27, 140)
        Label2.Name = "Label2"
        Label2.Size = New Size(51, 23)
        Label2.TabIndex = 4
        Label2.Text = "Username"
        ' 
        ' Panel5
        ' 
        Panel5.BackColor = SystemColors.Window
        Panel5.BorderStyle = BorderStyle.FixedSingle
        Panel5.Controls.Add(txtPassword)
        Panel5.Location = New Point(37, 295)
        Panel5.Name = "Panel5"
        Panel5.Size = New Size(410, 50)
        Panel5.TabIndex = 5
        ' 
        ' txtPassword
        ' 
        txtPassword.BorderStyle = BorderStyle.None
        txtPassword.Font = New Font("Segoe UI", 12.0F)
        txtPassword.Location = New Point(15, 11)
        txtPassword.Name = "txtPassword"
        txtPassword.Size = New Size(378, 27)
        txtPassword.TabIndex = 4
        txtPassword.UseSystemPasswordChar = True
        ' 
        ' Panel4
        ' 
        Panel4.BackColor = SystemColors.Window
        Panel4.BorderStyle = BorderStyle.FixedSingle
        Panel4.Controls.Add(txtUsername)
        Panel4.Location = New Point(37, 175)
        Panel4.Name = "Panel4"
        Panel4.Size = New Size(410, 50)
        Panel4.TabIndex = 3
        ' 
        ' txtUsername
        ' 
        txtUsername.BorderStyle = BorderStyle.None
        txtUsername.Font = New Font("Segoe UI", 12.0F)
        txtUsername.Location = New Point(15, 11)
        txtUsername.Name = "txtUsername"
        txtUsername.Size = New Size(378, 27)
        txtUsername.TabIndex = 4
        ' 
        ' lblSubHeader
        ' 
        lblSubHeader.AutoSize = True
        lblSubHeader.Font = New Font("Segoe UI", 8.0F)
        lblSubHeader.ForeColor = Color.FromArgb(CByte(85), CByte(85), CByte(85))
        lblSubHeader.Location = New Point(175, 85)
        lblSubHeader.Margin = New Padding(0)
        lblSubHeader.Name = "lblSubHeader"
        lblSubHeader.Size = New Size(149, 19)
        lblSubHeader.TabIndex = 2
        lblSubHeader.Text = "Log In to your account"
        ' 
        ' Label1
        ' 
        Label1.AutoSize = True
        Label1.Font = New Font("Segoe UI Semibold", 14.0F, FontStyle.Bold)
        Label1.ForeColor = Color.Black
        Label1.Location = New Point(211, 51)
        Label1.Name = "Label1"
        Label1.Size = New Size(82, 32)
        Label1.TabIndex = 1
        Label1.Text = "Log In"
        ' 
        ' Panel1
        ' 
        Panel1.Controls.Add(TableLayoutPanel1)
        Panel1.Dock = DockStyle.Fill
        Panel1.Location = New Point(0, 0)
        Panel1.Name = "Panel1"
        Panel1.Size = New Size(1280, 720)
        Panel1.TabIndex = 0
        ' 
        ' LogIn
        ' 
        AutoScaleDimensions = New SizeF(8.0F, 20.0F)
        AutoScaleMode = AutoScaleMode.Font
        ClientSize = New Size(1280, 720)
        Controls.Add(Panel1)
        MinimumSize = New Size(800, 600)
        Name = "LogIn"
        StartPosition = FormStartPosition.CenterScreen
        Text = "Tabeya Staff Login"
        WindowState = FormWindowState.Maximized
        TableLayoutPanel1.ResumeLayout(False)
        pnlHeader.ResumeLayout(False)
        Panel6.ResumeLayout(False)
        Panel6.PerformLayout()
        CType(logo, ComponentModel.ISupportInitialize).EndInit()
        Panel2.ResumeLayout(False)
        Panel3.ResumeLayout(False)
        Panel3.PerformLayout()
        Panel5.ResumeLayout(False)
        Panel5.PerformLayout()
        Panel4.ResumeLayout(False)
        Panel4.PerformLayout()
        Panel1.ResumeLayout(False)
        ResumeLayout(False)
    End Sub

    Friend WithEvents TableLayoutPanel1 As TableLayoutPanel
    Friend WithEvents Panel1 As Panel
    Friend WithEvents pnlHeader As Panel
    Friend WithEvents lblHeaderTitle As Label
    Friend WithEvents logo As PictureBox
    Friend WithEvents Panel2 As Panel
    Friend WithEvents Panel3 As Panel
    Friend WithEvents Label1 As Label
    Friend WithEvents lblSubHeader As Label
    Friend WithEvents Panel4 As Panel
    Friend WithEvents txtUsername As TextBox
    Friend WithEvents Label3 As Label
    Friend WithEvents Label2 As Label
    Friend WithEvents Panel5 As Panel
    Friend WithEvents txtPassword As TextBox
    Friend WithEvents chkShowPassword As CheckBox
    Friend WithEvents btnLoginTimein As Button
    Friend WithEvents btnServerSettings As Button
    Friend WithEvents Panel6 As Panel
End Class
