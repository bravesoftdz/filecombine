﻿unit Form.FileCombineMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls,
  ListView.EmptyMessage;

type
  TFormFileCombineMain = class(TForm)
    ListViewFile: TListView;
    SaveDialogCombined: TSaveDialog;
    PanelMain: TPanel;
    PanelButton: TPanel;
    ButtonCombine: TButton;
    MemoLog: TMemo;
    procedure ListViewFileDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure ListViewFileDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure ButtonCombineClick(Sender: TObject);
  private
    { Private declarations }
  protected
    FListViewWndProc: TWndMethod;

    procedure ListViewWndProc(var Message: TMessage);
    procedure WMDropFiles(var Msg: TMessage);

    procedure DoCreate; override;
    procedure DoDestroy; override;
  public
    { Public declarations }
  end;

var
  FormFileCombineMain: TFormFileCombineMain;

implementation

uses
  ShellAPI;

{$R *.dfm}

{ TForm1 }

procedure TFormFileCombineMain.ButtonCombineClick(Sender: TObject);
var
  I: Integer;
  FileStreamTotal: TFileStream;
  FileStreamItem: TFileStream;
  FileName: string;
begin
  if SaveDialogCombined.Execute then
  begin
    FileStreamTotal := TFileStream.Create( SaveDialogCombined.FileName, fmCreate );

    MemoLog.Lines.Add( '== Start combining process ==' );
    for I := 0 to ListViewFile.Items.Count - 1 do
    begin
      FileName := ListViewFile.Items[I].Caption;

      FileStreamItem := TFileStream.Create( FileName, fmOpenRead );
      try
        if FileStreamItem.Size > 0 then
        begin
          FileStreamTotal.CopyFrom( FileStreamItem, FileStreamItem.Size );

          MemoLog.Lines.Add( 'Combine file: ' + ExtractFileName(FileName) );
          MemoLog.Lines.Add( Format('  filesize: %d, totalsize: %d', [FileStreamItem.Size, FileStreamTotal.Size]) );
        end;
      finally
        FileStreamItem.Free;
      end;
    end;
    MemoLog.Lines.Add( '== Finish combining process ==' );

    FileStreamTotal.Free;
  end;
end;

procedure TFormFileCombineMain.DoCreate;
begin
  inherited;

  Caption := Application.Title;

  FListViewWndProc := ListViewFile.WindowProc;
  ListViewFile.WindowProc := ListViewWndProc;
  DragAcceptFiles( ListViewFile.Handle, True );

  ListViewFile.EmptyMessage := 'Drag&drop files from Windows Explorer.';
end;

procedure TFormFileCombineMain.DoDestroy;
begin
  ListViewFile.WindowProc := FListViewWndProc;
  DragAcceptFiles( ListViewFile.Handle, False );

  inherited;
end;

procedure TFormFileCombineMain.ListViewFileDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  DragItem, DropItem, CurrentItem, NextItem: TListItem;
begin
  if Sender = Source then
    with TListView(Sender) do
    begin
      DropItem    := GetItemAt(X, Y);
      CurrentItem := Selected;
      while CurrentItem <> nil do
      begin
        NextItem := GetNextItem(CurrentItem, SdAll, [IsSelected]);
        if DropItem = nil then DragItem := Items.Add
        else
          DragItem := Items.Insert(DropItem.Index);
        DragItem.Assign(CurrentItem);
        CurrentItem.Free;
        CurrentItem := NextItem;
      end;
    end;
end;

procedure TFormFileCombineMain.ListViewFileDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  Accept := Sender = ListViewFile;
end;

procedure TFormFileCombineMain.ListViewWndProc(var Message: TMessage);
begin
  if Message.Msg = WM_DROPFILES then
  begin
    WMDropFiles( Message );
  end;

  FListViewWndProc( Message );
end;

procedure TFormFileCombineMain.WMDropFiles(var Msg: TMessage);
var
  FileName: PWideChar;
  I, Size, FileCount: integer;
  ListItem: TListItem;
begin
  FileName := '';
  FileCount := DragQueryFile(Msg.wParam, $FFFFFFFF, FileName, 255);
  for I := 0 to FileCount - 1 do
  begin
    Size := DragQueryFile(Msg.wParam, I, nil, 0) + 1;
    FileName := StrAlloc(Size);
    DragQueryFile(Msg.wParam, I, FileName, Size);
    if FileExists(FileName) then
    begin
      ListItem := ListViewFile.Items.Add;
      ListItem.Caption := FileName;
    end;
    StrDispose(FileName);
  end;
  DragFinish(Msg.wParam);

  ListViewFile.AlphaSort;
end;

end.
