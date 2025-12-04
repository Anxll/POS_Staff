Public Class PaymentDialog
    Private _totalAmount As Decimal
    Private _paymentMethod As String = "CASH"
    Private _amountGiven As Decimal = 0
    Private _change As Decimal = 0

    Public ReadOnly Property PaymentMethod As String
        Get
            Return _paymentMethod
        End Get
    End Property

    Public ReadOnly Property AmountGiven As Decimal
        Get
            Return _amountGiven
        End Get
    End Property

    Public ReadOnly Property ChangeAmount As Decimal
        Get
            Return _change
        End Get
    End Property

    Public Sub New(totalAmount As Decimal)
        InitializeComponent()
        _totalAmount = totalAmount
    End Sub

    Private Sub PaymentDialog_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        ' Center the form
        Me.StartPosition = FormStartPosition.CenterParent

        ' Initialize UI
        lblTotalAmount.Text = $"₱{_totalAmount:N2}"
        cmbPaymentMethod.Items.AddRange({"CASH", "GCASH"})
        cmbPaymentMethod.SelectedIndex = 0
        txtAmountGiven.Text = ""
        lblChange.Text = "₱0.00"
        btnConfirm.Enabled = False
    End Sub

    Private Sub cmbPaymentMethod_SelectedIndexChanged(sender As Object, e As EventArgs) Handles cmbPaymentMethod.SelectedIndexChanged
        _paymentMethod = cmbPaymentMethod.SelectedItem.ToString()
        CalculateChange()
    End Sub

    Private Sub txtAmountGiven_TextChanged(sender As Object, e As EventArgs) Handles txtAmountGiven.TextChanged
        CalculateChange()
    End Sub

    Private Sub CalculateChange()
        If Decimal.TryParse(txtAmountGiven.Text, _amountGiven) Then
            If _amountGiven >= _totalAmount Then
                _change = _amountGiven - _totalAmount
                lblChange.Text = $"₱{_change:N2}"
                lblChange.ForeColor = Color.Green
                btnConfirm.Enabled = True
            Else
                lblChange.Text = "Insufficient amount"
                lblChange.ForeColor = Color.Red
                btnConfirm.Enabled = False
            End If
        Else
            lblChange.Text = "₱0.00"
            lblChange.ForeColor = Color.Black
            btnConfirm.Enabled = False
        End If
    End Sub

    Private Sub btnConfirm_Click(sender As Object, e As EventArgs) Handles btnConfirm.Click
        Me.DialogResult = DialogResult.OK
        Me.Close()
    End Sub

    Private Sub btnCancel_Click(sender As Object, e As EventArgs) Handles btnCancel.Click
        Me.DialogResult = DialogResult.Cancel
        Me.Close()
    End Sub
End Class
