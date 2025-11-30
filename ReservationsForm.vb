Imports System.Collections.Generic

Public Class ReservationsForm
    Private reservationRepository As New ReservationRepository()

    Private Sub ReservationsForm_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        ' Hide the template
        ResTemplate.Visible = False
        LoadReservations()
    End Sub

    Private Sub LoadReservations()
        Try
            Dim reservations As List(Of Reservation) = reservationRepository.GetAllReservations()
            DisplayReservations(reservations)
        Catch ex As Exception
            MessageBox.Show($"Error loading reservations: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub DisplayReservations(reservations As List(Of Reservation))
        ' Keep the header controls (Button, PictureBox) and remove reservation panels
        Dim controlsKeep As New List(Of Control)
        For Each ctrl As Control In Panel1.Controls
            If ctrl Is btnNewReservation OrElse ctrl Is PictureBox1 OrElse ctrl Is ResTemplate OrElse ctrl Is btnRefresh Then
                controlsKeep.Add(ctrl)
            End If
        Next

        Panel1.Controls.Clear()

        ' Re-add kept controls
        For Each ctrl In controlsKeep
            Panel1.Controls.Add(ctrl)
        Next

        Dim xPos As Integer = 38
        Dim yPos As Integer = 119
        Dim colCount As Integer = 0
        Dim maxCols As Integer = 3 ' Adjust based on screen width

        For Each res As Reservation In reservations
            Dim panel As Panel = CreateReservationPanel(res)
            panel.Location = New Point(xPos, yPos)
            Panel1.Controls.Add(panel)

            colCount += 1
            If colCount >= maxCols Then
                colCount = 0
                xPos = 38
                yPos += 370 ' Height + Margin
            Else
                xPos += 455 ' Width + Margin
            End If
        Next
    End Sub

    Private Function CreateReservationPanel(res As Reservation) As Panel
        ' Clone the ResTemplate panel
        Dim panel As New Panel With {
            .Size = ResTemplate.Size,
            .BackColor = ResTemplate.BackColor,
            .BorderStyle = ResTemplate.BorderStyle
        }

        ' Clone and populate labels from template
        Dim lblName As Label = CloneLabel(lblName2)
        ' Show FullName if available, otherwise show CustomerName from customers table
        lblName.Text = If(String.IsNullOrEmpty(res.FullName), res.CustomerName, res.FullName)

        Dim lblCode As Label = CloneLabel(lblCode2)
        lblCode.Text = $"RES-{res.ReservationID:D3}"

        ' Clone email label from template
        Dim lblEmailClone As Label = CloneLabel(Me.lblEmail)
        lblEmailClone.Text = If(String.IsNullOrEmpty(res.CustomerEmail), "N/A", res.CustomerEmail)

        Dim lblPhone As Label = CloneLabel(lblPhone2)
        lblPhone.Text = If(String.IsNullOrEmpty(res.ContactNumber), "N/A", res.ContactNumber)

        Dim lblPeople As Label = CloneLabel(lblPeople2)
        lblPeople.Text = res.NumberOfGuests.ToString()

        Dim lblDate As Label = CloneLabel(lblDate2)
        lblDate.Text = res.EventDate.ToString("yyyy-MM-dd")

        Dim lblTime As Label = CloneLabel(lblTime2)
        lblTime.Text = DateTime.Today.Add(res.EventTime).ToString("h:mm tt")

        Dim lblEvent As Label = CloneLabel(lblEvent2)
        lblEvent.Text = res.EventType

        ' Clone status button
        Dim btnStatus As Button = CloneButton(Button2)
        btnStatus.Text = res.ReservationStatus

        ' Set status color
        If res.ReservationStatus = "Confirmed" Then
            btnStatus.ForeColor = Color.FromArgb(0, 200, 83)
        ElseIf res.ReservationStatus = "Pending" Then
            btnStatus.ForeColor = Color.Orange
        Else
            btnStatus.ForeColor = Color.Red
        End If

        ' Clone icons
        Dim iconEmail As PictureBox = ClonePictureBox(PictureBox8)
        Dim iconPhone As PictureBox = ClonePictureBox(PictureBox3)
        Dim iconPeople As PictureBox = ClonePictureBox(PictureBox4)
        Dim iconDate As PictureBox = ClonePictureBox(PictureBox5)
        Dim iconTime As PictureBox = ClonePictureBox(PictureBox6)
        Dim iconEvent As PictureBox = ClonePictureBox(PictureBox7)

        ' Add all controls to panel
        panel.Controls.AddRange({
            lblName, lblCode, lblEmailClone, iconEmail, lblPhone, iconPhone,
            lblPeople, iconPeople, lblDate, iconDate, lblTime, iconTime,
            lblEvent, iconEvent, btnStatus
        })

        ' Add View Order button for all reservations
        Dim btnViewOrder As Button = CloneButton(Button1)
        btnViewOrder.Text = "View Order"
        btnViewOrder.BackColor = Color.FromArgb(52, 152, 219) ' Blue color
        AddHandler btnViewOrder.Click, Sub(sender, e)
                                           ShowReservationItems(res)
                                       End Sub
        panel.Controls.Add(btnViewOrder)

        Return panel
    End Function

    Private Sub ShowReservationItems(reservation As Reservation)
        Try
            ' Fetch reservation items from database
            Dim items As List(Of ReservationItem) = reservationRepository.GetReservationItems(reservation.ReservationID)

            If items Is Nothing OrElse items.Count = 0 Then
                MessageBox.Show("No items found for this reservation.", "Information", MessageBoxButtons.OK, MessageBoxIcon.Information)
                Return
            End If

            ' Show popup form with items
            Dim viewForm As New ViewReservationItemsForm(
                reservation.ReservationID,
                $"RES-{reservation.ReservationID:D3}",
                items
            )
            viewForm.ShowDialog()
        Catch ex As Exception
            MessageBox.Show($"Error loading reservation items: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Function CloneLabel(template As Label) As Label
        Return New Label With {
            .Text = template.Text,
            .Font = template.Font,
            .ForeColor = template.ForeColor,
            .BackColor = template.BackColor,
            .Location = template.Location,
            .Size = template.Size,
            .AutoSize = template.AutoSize,
            .Padding = template.Padding
        }
    End Function

    Private Function ClonePictureBox(template As PictureBox) As PictureBox
        Return New PictureBox With {
            .Image = template.Image,
            .Location = template.Location,
            .Size = template.Size,
            .SizeMode = template.SizeMode
        }
    End Function

    Private Function CloneButton(template As Button) As Button
        Return New Button With {
            .Text = template.Text,
            .Font = template.Font,
            .BackColor = template.BackColor,
            .ForeColor = template.ForeColor,
            .FlatStyle = template.FlatStyle,
            .Location = template.Location,
            .Size = template.Size
        }
    End Function

    Private Sub btnNewReservation_Click(sender As Object, e As EventArgs) Handles btnNewReservation.Click
        Dim newResForm As New NewReservationForm()
        If newResForm.ShowDialog() = DialogResult.OK Then
            LoadReservations()
        End If
    End Sub

    Private Sub btnRefresh_Click(sender As Object, e As EventArgs) Handles btnRefresh.Click
        LoadReservations()
    End Sub

    Private Sub lblTime2_Click(sender As Object, e As EventArgs) Handles lblTime2.Click

    End Sub
End Class
