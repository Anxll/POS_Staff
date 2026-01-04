Imports System.Security.Cryptography
Imports System.Text

''' <summary>
''' Provides AES-256 encryption and decryption for sensitive data
''' Used primarily for encrypting database passwords in config.json
''' </summary>
''' <summary>
''' Provides AES-256 encryption and decryption for sensitive data
''' Used primarily for encrypting database passwords in config.json
''' </summary>
Public Class EncryptionHelper
    ' IMPORTANT: This key MUST match the one in modDB.vb for user_accounts password encryption
    ' Changed from "TabeyaPOS2024!SecureKey#9876" to match Admin system
    Private Shared ReadOnly EncryptionKey As String = "MAKV2SPBNI99212"
    Private Shared ReadOnly IV As String = "1234567890123456" ' 16 bytes for AES

    ''' <summary>
    ''' Encrypts a plain text string using AES-256 encryption
    ''' MUST match the implementation in modDB.vb
    ''' </summary>
    ''' <param name="plainText">The text to encrypt</param>
    ''' <returns>Base64-encoded encrypted string</returns>
    Public Shared Function Encrypt(plainText As String) As String
        If String.IsNullOrEmpty(plainText) Then
            Return String.Empty
        End If

        Try
            Using aes As Aes = Aes.Create()
                aes.Key = GetKey()
                aes.IV = GetIV()
                aes.Mode = CipherMode.CBC
                aes.Padding = PaddingMode.PKCS7

                Using encryptor As ICryptoTransform = aes.CreateEncryptor()
                    Dim plainBytes As Byte() = Encoding.Unicode.GetBytes(plainText) ' Changed to Unicode
                    Dim encryptedBytes As Byte() = encryptor.TransformFinalBlock(plainBytes, 0, plainBytes.Length)
                    Return Convert.ToBase64String(encryptedBytes)
                End Using
            End Using
        Catch ex As Exception
            Throw New Exception($"Encryption failed: {ex.Message}", ex)
        End Try
    End Function

    ''' <summary>
    ''' Decrypts an encrypted string using AES-256 decryption
    ''' MUST match the implementation in modDB.vb
    ''' </summary>
    ''' <param name="encryptedText">Base64-encoded encrypted string</param>
    ''' <returns>Decrypted plain text string</returns>
    Public Shared Function Decrypt(encryptedText As String) As String
        If String.IsNullOrEmpty(encryptedText) Then
            Return String.Empty
        End If

        Try
            Using aes As Aes = Aes.Create()
                aes.Key = GetKey()
                aes.IV = GetIV()
                aes.Mode = CipherMode.CBC
                aes.Padding = PaddingMode.PKCS7

                Using decryptor As ICryptoTransform = aes.CreateDecryptor()
                    Dim encryptedBytes As Byte() = Convert.FromBase64String(encryptedText)
                    Dim decryptedBytes As Byte() = decryptor.TransformFinalBlock(encryptedBytes, 0, encryptedBytes.Length)
                    Return Encoding.Unicode.GetString(decryptedBytes) ' Changed to Unicode
                End Using
            End Using
        Catch ex As Exception
            Throw New Exception($"Decryption failed: {ex.Message}", ex)
        End Try
    End Function

    ''' <summary>
    ''' Converts the encryption key to a 32-byte array for AES-256
    ''' MUST match the implementation in modDB.vb
    ''' </summary>
    Private Shared Function GetKey() As Byte()
        ' Use same key derivation as modDB.vb
        Dim pdb As New Rfc2898DeriveBytes(EncryptionKey,
            New Byte() {&H49, &H76, &H61, &H6E, &H20, &H4D, &H65, &H64, &H76, &H65, &H64, &H65, &H76})
        Return pdb.GetBytes(32)
    End Function

    ''' <summary>
    ''' Converts the IV to a 16-byte array for AES
    ''' MUST match the implementation in modDB.vb
    ''' </summary>
    Private Shared Function GetIV() As Byte()
        ' Use same IV derivation as modDB.vb
        Dim pdb As New Rfc2898DeriveBytes(EncryptionKey,
            New Byte() {&H49, &H76, &H61, &H6E, &H20, &H4D, &H65, &H64, &H76, &H65, &H64, &H65, &H76})
        Return pdb.GetBytes(16)
    End Function
    ''' <summary>
    ''' Verifies a password against a stored hash or plain text
    ''' Supports: Plain Text, AES Encrypted (Base64), MD5, SHA256
    ''' </summary>
    Public Shared Function VerifyPassword(inputPassword As String, storedPassword As String) As Boolean
        If String.IsNullOrEmpty(inputPassword) OrElse String.IsNullOrEmpty(storedPassword) Then
            Return False
        End If

        ' 1. Check Plain Text Match (Legacy/Dev)
        If inputPassword = storedPassword Then
            Return True
        End If

        ' 2. Check AES Encrypted (Base64 format - has == padding or looks like Base64)
        Try
            If storedPassword.Contains("=") OrElse storedPassword.Length Mod 4 = 0 Then
                Dim decryptedPassword As String = Decrypt(storedPassword)
                If inputPassword = decryptedPassword Then
                    Return True
                End If
            End If
        Catch
            ' Not a valid encrypted password, continue to hash checks
        End Try

        ' 3. Check MD5 Hash
        Dim md5Hash As String = ComputeMD5Hash(inputPassword)
        If String.Equals(md5Hash, storedPassword, StringComparison.OrdinalIgnoreCase) Then
            Return True
        End If

        ' 4. Check SHA256 Hash
        Dim sha256Hash As String = ComputeSHA256Hash(inputPassword)
        If String.Equals(sha256Hash, storedPassword, StringComparison.OrdinalIgnoreCase) Then
            Return True
        End If

        Return False
    End Function

    Public Shared Function ComputeMD5Hash(input As String) As String
        Using md5 As MD5 = MD5.Create()
            Dim inputBytes As Byte() = Encoding.UTF8.GetBytes(input)
            Dim hashBytes As Byte() = md5.ComputeHash(inputBytes)
            Dim sb As New StringBuilder()
            For Each b As Byte In hashBytes
                sb.Append(b.ToString("x2"))
            Next
            Return sb.ToString()
        End Using
    End Function

    Public Shared Function ComputeSHA256Hash(input As String) As String
        Using sha256 As SHA256 = SHA256.Create()
            Dim inputBytes As Byte() = Encoding.UTF8.GetBytes(input)
            Dim hashBytes As Byte() = sha256.ComputeHash(inputBytes)
            Dim sb As New StringBuilder()
            For Each b As Byte In hashBytes
                sb.Append(b.ToString("x2"))
            Next
            Return sb.ToString()
        End Using
    End Function
End Class
