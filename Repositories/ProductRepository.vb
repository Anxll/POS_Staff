Imports MySql.Data.MySqlClient
Imports System.Collections.Generic

Public Class ProductRepository
    Public Function GetAllProducts() As List(Of Product)
        Return GetProducts("SELECT ProductID, ProductName, Category, Description, Price, Availability, ServingSize, ProductCode, PopularityTag, MealTime, OrderCount, Image, PrepTime FROM products WHERE Availability = 'Available' ORDER BY ProductName")
    End Function

    Public Function GetProductsByCategory(category As String) As List(Of Product)
        Dim query As String = "SELECT ProductID, ProductName, Category, Description, Price, Availability, ServingSize, ProductCode, PopularityTag, MealTime, OrderCount, Image, PrepTime FROM products WHERE Availability = 'Available' AND Category = @category ORDER BY ProductName"
        Dim parameters As MySqlParameter() = {New MySqlParameter("@category", category)}
        Return GetProducts(query, parameters)
    End Function

    Private Function GetProducts(query As String, Optional parameters As MySqlParameter() = Nothing) As List(Of Product)
        Dim products As New List(Of Product)
        Dim table As DataTable = Database.ExecuteQuery(query, parameters)

        If table IsNot Nothing Then
            For Each row As DataRow In table.Rows
                Dim product As New Product With {
                    .ProductID = Convert.ToInt32(row("ProductID")),
                    .ProductName = row("ProductName").ToString(),
                    .Category = row("Category").ToString(),
                    .Description = If(IsDBNull(row("Description")), "", row("Description").ToString()),
                    .Price = Convert.ToDecimal(row("Price")),
                    .Availability = row("Availability").ToString(),
                    .ServingSize = If(IsDBNull(row("ServingSize")), "", row("ServingSize").ToString()),
                    .ProductCode = If(IsDBNull(row("ProductCode")), "", row("ProductCode").ToString()),
                    .PopularityTag = If(IsDBNull(row("PopularityTag")), "Regular", row("PopularityTag").ToString()),
                    .MealTime = If(IsDBNull(row("MealTime")), "", row("MealTime").ToString()),
                    .OrderCount = If(IsDBNull(row("OrderCount")), 0, Convert.ToInt32(row("OrderCount"))),
                    .Image = If(IsDBNull(row("Image")), "", row("Image").ToString()),
                    .PrepTime = If(IsDBNull(row("PrepTime")), 0, Convert.ToInt32(row("PrepTime")))
                }

                products.Add(product)
            Next
        End If

        Return products
    End Function
End Class
