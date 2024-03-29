VERSION 5.00
Object = "{248DD890-BB45-11CF-9ABC-0080C7E7B78D}#1.0#0"; "MSWINSCK.OCX"
Object = "{3B7C8863-D78F-101B-B9B5-04021C009402}#1.2#0"; "Richtx32.ocx"
Begin VB.Form frmMain 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Secure Authentication Example"
   ClientHeight    =   3825
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   7200
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   3825
   ScaleWidth      =   7200
   StartUpPosition =   3  'Windows Default
   Begin MSWinsockLib.Winsock sckServer 
      Index           =   0
      Left            =   600
      Top             =   3360
      _ExtentX        =   741
      _ExtentY        =   741
      _Version        =   393216
   End
   Begin MSWinsockLib.Winsock sckListen 
      Left            =   120
      Top             =   3360
      _ExtentX        =   741
      _ExtentY        =   741
      _Version        =   393216
      LocalPort       =   1414
   End
   Begin VB.CommandButton cmdQuit 
      Cancel          =   -1  'True
      Caption         =   "&Quit"
      Height          =   375
      Left            =   3840
      TabIndex        =   4
      Top             =   3360
      Width           =   1575
   End
   Begin VB.CommandButton cmdToggleServer 
      Caption         =   "&Stop Server"
      Default         =   -1  'True
      Height          =   375
      Left            =   5520
      TabIndex        =   3
      Top             =   3360
      Width           =   1575
   End
   Begin VB.Frame fraLog 
      Caption         =   "Log"
      Height          =   2175
      Left            =   120
      TabIndex        =   1
      Top             =   1080
      Width           =   6975
      Begin RichTextLib.RichTextBox rtbLog 
         Height          =   1815
         Left            =   120
         TabIndex        =   2
         Top             =   240
         Width           =   6735
         _ExtentX        =   11880
         _ExtentY        =   3201
         _Version        =   393217
         ReadOnly        =   -1  'True
         ScrollBars      =   2
         TextRTF         =   $"frmMain.frx":0000
      End
   End
   Begin VB.Label Label3 
      Alignment       =   2  'Center
      Caption         =   "Created by Andrew Armstrong"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   255
      Left            =   120
      TabIndex        =   5
      Top             =   3480
      Width           =   3615
   End
   Begin VB.Label Label1 
      Caption         =   $"frmMain.frx":0082
      Height          =   735
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   6975
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Sub StartServer()
    sckListen.Listen 'Listen for connections
    Log "Server started successfully." 'See the sub 'Log' in modMain for details"
    
End Sub
Private Sub StopServer()
    sckListen.Close 'Stop listening for connections
    For i = 0 To MAX_USERS 'Lets disconnect all current users
        If User(i).FreeSocket = False Then 'If this socket is in use
        User(i).FreeSocket = True 'Reset our freesocket variable
        User(i).HasAuthenticated = False 'Set our HasAuthenticated variable to false
        sckServer(i).Close 'Drop the connection
    End If
Next i 'Loop through the other connections
Log "Server stopped successfully." 'Log this event

End Sub
    
Private Sub cmdQuit_Click()
    StopServer 'Stop the server
    Unload Me 'Remove this form from memory
    End 'Quit the application
End Sub
    
Private Sub cmdToggleServer_Click()
    If cmdToggleServer.Caption = "&Start Server" Then
        StartServer 'Lets start the server!
        cmdToggleServer.Caption = "&Stop Server" 'Change the caption of the 'Toggle Server'
        'button. The & represents an underscore ( _ ) under the following letter ( S ).
        'This is a shortcut key.
    Else
        StopServer 'Lets drop all current connections and stop listening for them
        cmdToggleServer.Caption = "&Start Server" 'Change the caption of the button
    End If
    
End Sub
    
Private Sub Form_Load()
MsgBox "Created by Andrew Armstrong. Contact me at: " & vbCrLf & _
 "andrewa@bigpond.net.au or ICQ# 14344635 !" & vbCrLf & _
 "Please contact me if you ever do use this in an application, I would be interested to know! :)", vbInformation, "Contact/About"
    'Lets initilize our server sockets (I am using a fixed number of sockets here)
    For i = 1 To MAX_USERS
        User(i).FreeSocket = True 'Set this USER index's 'FreeSocket' boolean value to True.
        Load sckServer(i) 'Load the socket
    Next i
    User(0).FreeSocket = True 'Set our first user index's 'FreeSocket' value to true.
    
    StartServer 'Lets activate our server
    
End Sub
    
Private Sub rtbLog_Change()
    rtbLog.SelStart = Len(rtbLog) 'Scroll to the bottem of the textbox so you see the most
    'recent event
    
End Sub
    
Private Sub sckListen_ConnectionRequest(ByVal requestID As Long)
    Dim i As Integer
    Dim strAuthString As String
    
    For i = 0 To MAX_USERS
        'Find a free socket to connect this user with
        If User(i).FreeSocket = True Then
            'We've found a free socket, lets accept the connection to that socket index
            sckServer(i).Accept requestID 'Notice I am accepting the connection to sckServer, not sckListen.
            User(i).FreeSocket = False 'Lets set this user's freesocket variable to false
            Log "Server accepted connection using Socket ID: " & i & " and has the IP of " & sckServer(i).RemoteHostIP & "."
            DoEvents
            
            strAuthString = GenerateAuthString(i)
            
            SendData GenerateAuthString(i), i 'Send the user a random encrypted string
            Exit Sub 'No need to keep searching for a free socket, we have accepted it
        End If
    Next i 'Continue the loop
    
    'If no free sockets are found, just disconnect the user and re-listen on the socket
    Log "User with IP " & sckListen.RemoteHostIP & " was denied a connection due to no free sockets."
    sckListen.Close 'Close the connection
    sckListen.Listen 'Start listening again
End Sub
    
Private Sub sckServer_Close(Index As Integer)
    sckServer(Index).Close 'Cleanup the socket, make sure it is closed
    User(Index).FreeSocket = True 'Reset our freesocket variable
    User(Index).HasAuthenticated = False
    Log "Socket ID: " & Index & " has closed the connection." 'Log this event
End Sub
    
Private Sub sckServer_DataArrival(Index As Integer, ByVal bytesTotal As Long)
    Dim strData As String, SplitData() As String, SplitRequest() As String
    Dim strAuthString As String
    On Error GoTo errServer
    
    'strData is our raw data, SplitData is the data separated by DATA_DELIMITER
    'The splitting of data prevents winsock from jamming strings together with one another
    
    sckServer(Index).GetData strData
    LogRAW strData
    
    SplitData = Split(strData, DATA_DELIMITER)
    
    For i = 0 To UBound(SplitData) - 1 'Loop through all the data
        SplitRequest = Split(SplitData(i), "|") 'Split the sub-data using the pipe character (|)
        
        If User(Index).HasAuthenticated = False Then 'Before allowing this user to send commands
        
        'The user must first authenticate
        If CheckAuthentication(SplitRequest(0), Index) = True Then 'If this is a valid auth string
        User(Index).HasAuthenticated = True
        Log "Socket ID: " & Index & " has successfully authenticated and verified."
        SendData "AUTHENTICATION|GRANTED", Index
    Else
        User(Index).HasAuthenticated = False
        SendData "AUTHENTICATION|DENIED", Index
        Log "Socket ID: " & Index & " is being disconnected (Invalid Authentication String)"
        DisconnectUser Index
    End If
    Else 'If the user has been authenticated... Process any commands from the client!
    'You can have an endless list of sub-commands here
 
 'Place any commands that your normal program would use here such as sending of messages
 'and userlists for a chat program.
 
    
End If
Next i

errServer: 'Just quit the sub
End Sub
    
Private Sub sckServer_Error(Index As Integer, ByVal Number As Integer, Description As String, ByVal Scode As Long, ByVal Source As String, ByVal HelpFile As String, ByVal HelpContext As Long, CancelDisplay As Boolean)
    sckServer_Close Index 'If a socket error has occured, just drop the clients connection
    'No need to re-write any code here, I am simply passing on the information to the sockets
    'close procedure!
End Sub
    
