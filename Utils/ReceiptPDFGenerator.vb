Imports PdfSharp.Pdf
Imports PdfSharp.Drawing
Imports System.IO

''' <summary>
''' Generates PDF receipts for completed orders using PDFSharp
''' </summary>
Public Class ReceiptPDFGenerator

    Private Const RECEIPT_WIDTH As Double = 300 ' Thermal receipt width in points
    Private Const MARGIN As Double = 10
    Private Const LINE_HEIGHT As Double = 15

    ''' <summary>
    ''' Generates a PDF receipt and returns the file path
    ''' </summary>
    Public Function GenerateReceipt(receiptID As Integer) As String
        Try
            ' Get receipt data
            Dim repo As New ReceiptRepository()
            Dim receiptData As ReceiptData = repo.GetReceiptDetails(receiptID)

            If receiptData Is Nothing Then
                Throw New Exception("Receipt data not found")
            End If

            ' Create receipts folder if it doesn't exist
            Dim receiptsFolder As String = "C:\Users\malal\OneDrive\Desktop\Visual Basic 2020\Staff\Tabeya_Receipts"
            If Not Directory.Exists(receiptsFolder) Then
                Directory.CreateDirectory(receiptsFolder)
            End If

            ' Generate file name
            Dim fileName As String = $"Receipt_{receiptData.OrderNumber}_{DateTime.Now:yyyyMMdd_HHmmss}.pdf"
            Dim filePath As String = Path.Combine(receiptsFolder, fileName)

            ' Create PDF document
            Dim document As New PdfDocument()
            document.Info.Title = $"Receipt {receiptData.OrderNumber}"

            ' Add a page
            Dim page As PdfPage = document.AddPage()
            page.Width = XUnit.FromPoint(RECEIPT_WIDTH)

            ' Calculate page height based on content
            Dim contentHeight As Double = CalculateContentHeight(receiptData)
            page.Height = XUnit.FromPoint(contentHeight + 40) ' Add some bottom margin

            ' Get graphics object
            Dim gfx As XGraphics = XGraphics.FromPdfPage(page)

            ' Draw receipt content
            DrawReceipt(gfx, receiptData)

            ' Save document
            document.Save(filePath)
            document.Close()

            Return filePath

        Catch ex As Exception
            Throw New Exception($"Error generating PDF receipt: {ex.Message}", ex)
        End Try
    End Function

    ''' <summary>
    ''' Calculates the total height needed for the receipt content
    ''' </summary>
    Private Function CalculateContentHeight(data As ReceiptData) As Double
        Dim baseHeight As Double = 350 ' Header + footer sections
        Dim itemsHeight As Double = data.Items.Count * 60 ' ~60 points per item (3 lines)
        Return baseHeight + itemsHeight
    End Function

    ''' <summary>
    ''' Draws the complete receipt on the PDF page
    ''' </summary>
    Private Sub DrawReceipt(gfx As XGraphics, data As ReceiptData)
        Dim yPos As Double = MARGIN

        ' Define fonts
        Dim fontBold As New XFont("Courier New", 10, XFontStyleEx.Bold)
        Dim fontRegular As New XFont("Courier New", 8, XFontStyleEx.Regular)
        Dim fontSmall As New XFont("Courier New", 7, XFontStyleEx.Regular)
        Dim fontHeader As New XFont("Courier New", 11, XFontStyleEx.Bold)

        ' Header separator
        yPos = DrawLine(gfx, "==================================================", yPos, fontRegular)
        
        ' Restaurant name
        yPos = DrawCenteredText(gfx, "TABEYA RESTAURANT", yPos, fontHeader)
        yPos = DrawCenteredText(gfx, "Official Sales Receipt", yPos, fontRegular)
        
        yPos = DrawLine(gfx, "==================================================", yPos, fontRegular)
        yPos += 5

        ' Order details
        yPos = DrawText(gfx, $"Order No.:  {data.OrderNumber}", yPos, fontRegular)
        yPos = DrawText(gfx, $"Date:       {data.ReceiptDate:yyyy-MM-dd}  |  Time: {data.ReceiptTime:hh\:mm} {If(data.ReceiptTime.Hours >= 12, "PM", "AM")}", yPos, fontRegular)
        yPos = DrawText(gfx, $"Cashier:    {data.CashierName}", yPos, fontRegular)
        yPos = DrawText(gfx, $"Customer:   {data.CustomerName}", yPos, fontRegular)
        yPos += 5

        ' Items section header
        yPos = DrawLine(gfx, "--------------------------------------------------", yPos, fontRegular)
        yPos = DrawCenteredText(gfx, "ITEMS PURCHASED", yPos, fontBold)
        yPos = DrawLine(gfx, "--------------------------------------------------", yPos, fontRegular)

        ' Draw each item
        For Each item In data.Items
            ' Item line: quantity × name and price (right-aligned)
            Dim itemLine As String = $"{item.Quantity} × {item.ItemName}"
            Dim priceText As String = $"₱ {item.LineTotal:N2}"
            
            yPos = DrawLeftRightText(gfx, itemLine, priceText, yPos, fontRegular)
            
            ' Batch info
            yPos = DrawText(gfx, $"   - Batch: {item.BatchNumber}", yPos, fontSmall)
            
            ' Qty deducted
            yPos = DrawText(gfx, $"   - Qty Deducted: {item.QtyDeducted}", yPos, fontSmall)
            yPos += 3 ' Small spacing between items
        Next

        yPos += 5
        yPos = DrawLine(gfx, "--------------------------------------------------", yPos, fontRegular)
        
        ' Subtotal
        yPos = DrawLeftRightText(gfx, "SUBTOTAL:", $"₱ {data.Subtotal:N2}", yPos, fontBold)
        yPos += 5

        yPos = DrawLine(gfx, "--------------------------------------------------", yPos, fontRegular)
        
        ' Total
        yPos = DrawLeftRightText(gfx, "TOTAL:", $"₱ {data.TotalAmount:N2}", yPos, fontHeader)
        
        yPos = DrawLine(gfx, "--------------------------------------------------", yPos, fontRegular)
        yPos += 3

        ' Payment details
        yPos = DrawText(gfx, $"Payment Method: {data.PaymentMethod}", yPos, fontRegular)
        yPos = DrawText(gfx, $"Amount Given:   ₱ {data.AmountGiven:N2}", yPos, fontRegular)
        yPos = DrawText(gfx, $"Change:         ₱ {data.ChangeAmount:N2}", yPos, fontRegular)
        yPos += 5

        yPos = DrawLine(gfx, "--------------------------------------------------", yPos, fontRegular)
        yPos += 10

        ' Footer
        yPos = DrawCenteredText(gfx, "THANK YOU FOR YOUR PURCHASE!", yPos, fontBold)
        DrawLine(gfx, "==================================================", yPos, fontRegular)
    End Sub

    ''' <summary>
    ''' Draws centered text
    ''' </summary>
    Private Function DrawCenteredText(gfx As XGraphics, text As String, yPos As Double, font As XFont) As Double
        Dim size As XSize = gfx.MeasureString(text, font)
        Dim xPos As Double = (RECEIPT_WIDTH - size.Width) / 2
        gfx.DrawString(text, font, XBrushes.Black, New XPoint(xPos, yPos))
        Return yPos + LINE_HEIGHT
    End Function

    ''' <summary>
    ''' Draws left-aligned text
    ''' </summary>
    Private Function DrawText(gfx As XGraphics, text As String, yPos As Double, font As XFont) As Double
        gfx.DrawString(text, font, XBrushes.Black, New XPoint(MARGIN, yPos))
        Return yPos + LINE_HEIGHT
    End Function

    ''' <summary>
    ''' Draws text with left and right alignment
    ''' </summary>
    Private Function DrawLeftRightText(gfx As XGraphics, leftText As String, rightText As String, yPos As Double, font As XFont) As Double
        ' Left text
        gfx.DrawString(leftText, font, XBrushes.Black, New XPoint(MARGIN, yPos))
        
        ' Right text
        Dim rightSize As XSize = gfx.MeasureString(rightText, font)
        Dim rightX As Double = RECEIPT_WIDTH - MARGIN - rightSize.Width
        gfx.DrawString(rightText, font, XBrushes.Black, New XPoint(rightX, yPos))
        
        Return yPos + LINE_HEIGHT
    End Function

    ''' <summary>
    ''' Draws a separator line
    ''' </summary>
    Private Function DrawLine(gfx As XGraphics, text As String, yPos As Double, font As XFont) As Double
        gfx.DrawString(text, font, XBrushes.Black, New XPoint(MARGIN, yPos))
        Return yPos + LINE_HEIGHT
    End Function
End Class
