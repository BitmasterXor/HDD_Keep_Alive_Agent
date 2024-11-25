unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, scControls, CnWaterImage, Vcl.StdCtrls, Vcl.Imaging.jpeg,
  Vcl.Samples.Spin, Vcl.Menus, Vcl.ExtCtrls, scStyledForm, System.ImageList,
  Vcl.ImgList;

type
  TDrivePingThread = class(TThread)
  private
    FInterval: Integer;
    FDrives: TStringList;
    FStatusText: string;
    procedure UpdateStatus;
    procedure HandleError(const Drive, ErrorMsg: string);
  protected
    procedure Execute; override;
  public
    constructor Create(Interval: Integer);
    destructor Destroy; override;
    procedure UpdateDriveList(ListView: TListView);
  end;

type
  TForm1 = class(TForm)
    scPageControl1: TscPageControl;
    scStatusBar1: TscStatusBar;
    scTabSheet1: TscTabSheet;
    scTabSheet2: TscTabSheet;
    CnWaterImage1: TCnWaterImage;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    GroupBox3: TGroupBox;
    RichEdit1: TRichEdit;
    GroupBox2: TGroupBox;
    Button1: TButton;
    Button2: TButton;
    GroupBox4: TGroupBox;
    SpinEdit1: TSpinEdit;
    Label2: TLabel;
    Button3: TButton;
    TrayIcon1: TTrayIcon;
    MainMenu: TPopupMenu;
    H1: TMenuItem;
    N1: TMenuItem;
    S1: TMenuItem;
    N2: TMenuItem;
    S2: TMenuItem;
    S3: TMenuItem;
    E1: TMenuItem;
    Label3: TLabel;
    scStyledForm1: TscStyledForm;
    AnotherMenu: TPopupMenu;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    ImageList1: TImageList;
    ListView1: TListView;
    ListView2: TListView;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure E1Click(Sender: TObject);
    procedure scStyledForm1Tabs0Click(Sender: TObject);
    procedure scStyledForm1Tabs1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure H1Click(Sender: TObject);
    procedure S1Click(Sender: TObject);
    procedure S2Click(Sender: TObject);
    procedure S3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure WMSize(var Msg: TMessage); message WM_SIZE;
    procedure SpinEdit1Change(Sender: TObject);
  private
    FPingThread: TDrivePingThread;
    procedure WriteToSelectedDrives;
    procedure EnableStartControls;
    procedure DisableStartControls;
  public
    { Public declarations }
  end;

const
  TextFileName = 'PingFile.txt';

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.WMSize(var Msg: TMessage);
begin
  Inherited;
  if Msg.WParam = SIZE_MINIMIZED then
  begin
    Form1.Hide;
  end;
end;

procedure TForm1.EnableStartControls;
begin
  // Enable Start controls
  S2.Enabled := True;
  MenuItem4.Enabled := True;
   listview1.enabled:=True;
listview2.enabled:=True;
button1.enabled:=True;
button2.enabled:=True;

  // Disable Stop controls
  S3.Enabled := False;
  MenuItem5.Enabled := False;
end;

procedure TForm1.DisableStartControls;
begin
  // Disable Start controls
  S2.Enabled := False;
  MenuItem4.Enabled := False;
  ListView1.Enabled := False;
  ListView2.Enabled := False;
  Button1.Enabled := False;
  Button2.Enabled := False;


  // Enable Stop controls
  S3.Enabled := True;
  MenuItem5.Enabled := True;

end;

constructor TDrivePingThread.Create(Interval: Integer);
begin
  inherited Create(True); // Create suspended
  FInterval := Interval;
  FDrives := TStringList.Create;
  FreeOnTerminate := True;
end;

destructor TDrivePingThread.Destroy;
begin
  FDrives.Free;
  inherited;
end;

procedure TDrivePingThread.UpdateDriveList(ListView: TListView);
var
  I: Integer;
begin
  FDrives.Clear;
  for I := 0 to ListView.Items.Count - 1 do
    FDrives.Add(ListView.Items[I].Caption);
end;

procedure TDrivePingThread.UpdateStatus;
begin
  if Assigned(Form1) then
    Form1.scStatusBar1.Panels[1].Text := FStatusText;
end;

procedure TDrivePingThread.HandleError(const Drive, ErrorMsg: string);
begin
  FStatusText := 'Status: Write Error';
  Synchronize(UpdateStatus);
end;

procedure ListDrives(ListView: TListView);
var
  Drives: DWORD;
  DriveLetter: Char;
  ListItem: TListItem;
begin
  ListView.Items.Clear; // Clear existing items
  Drives := GetLogicalDrives;
  for DriveLetter := 'A' to 'Z' do
  begin
    if (Drives and (1 shl (Ord(DriveLetter) - Ord('A')))) <> 0 then
    begin
      ListItem := ListView.Items.Add;
      ListItem.Caption := DriveLetter + ':\'; // Drive letter with colon
      ListItem.ImageIndex := 3; // Set an appropriate icon index
    end;
  end;

  // Update status bar with the count of drives
  Form1.scStatusBar1.Panels[0].Text := 'Drives Found: [' +
    IntToStr(ListView.Items.Count) + ']';
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  I: Integer;
  Item: TListItem;
begin
  for I := ListView1.Items.Count - 1 downto 0 do
  begin
    if ListView1.Items[I].Selected then
    begin
      Item := ListView2.Items.Add;
      Item.Caption := ListView1.Items[I].Caption;
      Item.ImageIndex := ListView1.Items[I].ImageIndex;
      ListView1.Items.Delete(I);
    end;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  I: Integer;
  Item: TListItem;
begin
  for I := ListView2.Items.Count - 1 downto 0 do
  begin
    if ListView2.Items[I].Selected then
    begin
      Item := ListView1.Items.Add;
      Item.Caption := ListView2.Items[I].Caption;
      Item.ImageIndex := ListView2.Items[I].ImageIndex;
      ListView2.Items.Delete(I);
    end;
  end;
end;

procedure TDrivePingThread.Execute;
var
  Drive, FilePath, TimeStr: string;
  FileStream: TFileStream;
  I: Integer;
begin
  while not Terminated do // Keep running until Stop button is clicked
  begin
    // Write to each drive in the list
    for I := 0 to FDrives.Count - 1 do
    begin
      Drive := FDrives[I];
      FilePath := Drive + TextFileName;

      try
        // Get current timestamp
        TimeStr := DateTimeToStr(Now) + #13#10;

        // Create/Overwrite the file
        FileStream := TFileStream.Create(FilePath, fmCreate or fmShareDenyNone);
        try
          FileStream.WriteBuffer(TimeStr[1], Length(TimeStr) * SizeOf(Char));
          FStatusText := 'Status: Active';
          Synchronize(UpdateStatus);
        finally
          FileStream.Free;
        end;
      except
        on E: Exception do
          HandleError(Drive, E.Message);
      end;
    end;

    // Wait for the interval specified in SpinEdit1 before next write
    Sleep(Form1.SpinEdit1.Value); // Convert seconds to milliseconds
  end;
end;

procedure TForm1.WriteToSelectedDrives;
begin
  if not Assigned(FPingThread) then
  begin
    FPingThread := TDrivePingThread.Create(SpinEdit1.Value * 1000);
    FPingThread.UpdateDriveList(ListView2);
    FPingThread.Start;
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  I: Integer;
  Drive, FilePath: string;
begin
  if ListView2.Items.Count = 0 then
  begin
    ShowMessage('No Drives Added!');
    Exit;
  end;

  if Button3.Caption = '             Start' then
  begin
    WriteToSelectedDrives;
    Button3.Caption := '             Stop';
    Button3.ImageIndex := 1;
    DisableStartControls;
  end
  else
  begin
    if Assigned(FPingThread) then
    begin
      FPingThread.Terminate;
      FPingThread := nil;
    end;

    // Clean up ping files from all drives in ListView2
    for I := 0 to ListView2.Items.Count - 1 do
    begin
      Drive := ListView2.Items[I].Caption;
      FilePath := Drive + TextFileName;
      try
        if FileExists(FilePath) then
        begin
          DeleteFile(FilePath);
        end;
      except
        on E: Exception do
          scStatusBar1.Panels[1].Text := 'Status: Error removing PingFile';
      end;
    end;

    Button3.Caption := '             Start';
    Button3.ImageIndex := 0;
    scStatusBar1.Panels[1].Text := 'Status: Stopped!';
    EnableStartControls;
  end;
end;

procedure TForm1.E1Click(Sender: TObject);
begin
  // Halt the program
  Halt;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  scPageControl1.Pages[0].TabVisible := False;
  scPageControl1.Pages[1].TabVisible := False;
  scPageControl1.ActivePageIndex := 0;

  // Set initial control states
  EnableStartControls;

  // Begin finding and listing out drive letters
  ListDrives(Form1.ListView1);
end;

procedure TForm1.FormDestroy(Sender: TObject);
var
  I: Integer;
  Drive, FilePath: string;
begin
  if Assigned(FPingThread) then
  begin
    FPingThread.Terminate;
    FPingThread := nil;
  end;

  // Destroy the Textfiles and Cleanup...
  // Clean up ping files from all drives in ListView2
  for I := 0 to ListView2.Items.Count - 1 do
  begin
    Drive := ListView2.Items[I].Caption;
    FilePath := Drive + TextFileName;
    try
      if FileExists(FilePath) then
      begin
        DeleteFile(FilePath);
      end;
    except
      on E: Exception do
        scStatusBar1.Panels[1].Text := 'Status: Error removing PingFile';
    end;
  end;
end;

procedure TForm1.H1Click(Sender: TObject);
begin
  // Hide the main form from the screen
  Self.Hide;
end;

procedure TForm1.S1Click(Sender: TObject);
begin
  // Show the main form on screen
  Self.Show;

  // Restore the form to its normal state
  Self.WindowState := wsNormal;

  // Bring the application to the front
  Application.BringToFront;
end;

procedure TForm1.MenuItem4Click(Sender: TObject);
begin
  if ListView2.Items.Count = 0 then
  begin
    ShowMessage('No Drives Added!');
    Exit;
  end;

  if not Assigned(FPingThread) then
  begin
    WriteToSelectedDrives;
    Button3.Caption := '             Stop';
    Button3.ImageIndex := 1;
    DisableStartControls;
  end;
end;

procedure TForm1.S2Click(Sender: TObject);
begin
  if ListView2.Items.Count = 0 then
  begin
    ShowMessage('No Drives Added!');
    Exit;
  end;

  if not Assigned(FPingThread) then
  begin
    WriteToSelectedDrives;
    Button3.Caption := '             Stop';
    Button3.ImageIndex := 1;
    DisableStartControls;
  end;
end;

procedure TForm1.MenuItem5Click(Sender: TObject);
var
  I: Integer;
  Drive, FilePath: string;
begin
  if Assigned(FPingThread) then
  begin
    FPingThread.Terminate;
    FPingThread := nil;

    // Clean up ping files from all drives in ListView2
    for I := 0 to ListView2.Items.Count - 1 do
    begin
      Drive := ListView2.Items[I].Caption;
      FilePath := Drive + TextFileName;
      try
        if FileExists(FilePath) then
        begin
          DeleteFile(FilePath);
        end;
      except
        on E: Exception do
          scStatusBar1.Panels[1].Text := 'Status: Error removing PingFile';
      end;
    end;

    Button3.Caption := '             Start';
    Button3.ImageIndex := 0;
    scStatusBar1.Panels[1].Text := 'Status: Stopped!';
    EnableStartControls;
  end;
end;

procedure TForm1.S3Click(Sender: TObject);
var
  I: Integer;
  Drive, FilePath: string;
begin
  if Assigned(FPingThread) then
  begin
    FPingThread.Terminate;
    FPingThread := nil;

    // Clean up ping files from all drives in ListView2
    for I := 0 to ListView2.Items.Count - 1 do
    begin
      Drive := ListView2.Items[I].Caption;
      FilePath := Drive + TextFileName;
      try
        if FileExists(FilePath) then
        begin
          DeleteFile(FilePath);

        end;
      except
        on E: Exception do
          scStatusBar1.Panels[1].Text := 'Status: Error removing PingFile';
      end;
    end;

    Button3.Caption := '             Start';
    Button3.ImageIndex := 0;
    scStatusBar1.Panels[1].Text := 'Status: Stopped!';
    EnableStartControls;
  end;
end;

procedure TForm1.scStyledForm1Tabs0Click(Sender: TObject);
begin
  scPageControl1.ActivePageIndex := 0;
end;

procedure TForm1.scStyledForm1Tabs1Click(Sender: TObject);
begin
  scPageControl1.ActivePageIndex := 1;
end;

procedure TForm1.SpinEdit1Change(Sender: TObject);
var
  inputValue: Integer;
  milliseconds: Integer;
  seconds: Single;
begin
  // Get the input value from the user (or any other source)
  inputValue := Self.SpinEdit1.Value; // Example value

  // Convert the input value to milliseconds
  milliseconds := inputValue;

  // Calculate the number of seconds
  seconds := milliseconds / 1000;

  // Update the label with the number of seconds
  Self.Label3.Caption := 'Every ' + FormatFloat('0', seconds) + ' Seconds';
end;

end.
