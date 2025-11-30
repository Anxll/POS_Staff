Public Class Reservation
    Public Property ReservationID As Integer
    Public Property CustomerID As Integer
    Public Property CustomerName As String ' Joined from Customers table
    Public Property FullName As String ' NEW: Full name from reservation (independent of customer)
    Public Property ContactNumber As String ' NEW: Phone number
    Public Property CustomerEmail As String ' Joined from Customers table
    Public Property AssignedStaffID As Integer? ' NEW: Staff assignment
    Public Property ReservationType As String
    Public Property EventType As String
    Public Property EventDate As Date
    Public Property EventTime As TimeSpan
    Public Property NumberOfGuests As Integer
    Public Property ProductSelection As String ' NEW: Text field for selected products
    Public Property SpecialRequests As String
    Public Property ReservationStatus As String
    Public Property DeliveryAddress As String ' NEW: For catering deliveries
    Public Property DeliveryOption As String ' NEW: Pickup/Delivery
    Public Property TotalPrice As Decimal ' Calculated from reservation_items (not in DB schema)
    Public Property Items As New List(Of ReservationItem) ' NEW: List of items for this reservation
End Class
