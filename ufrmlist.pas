unit ufrmlist;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids, Types;

const dataFName: string = 'HaziP.csv';

type

  { TfrmList }

  TfrmList = class(TForm)
    sgGrid: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure sgGridDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
  private
    thisMStrLong: string;
    procedure ProcessRow(line: string; var rowDate: TDateTime; var rowBW: string; var rowComment: string; var rowValue: Integer);
    procedure HandleGrid(txtBW, txtComment, txtValue: string); //Feliratok, összegek frissítése

  public

  end;

var
  frmList: TfrmList;

implementation

{$R *.lfm}

{ TfrmList }

procedure TfrmList.sgGridDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var i,j : integer;
    s : string;
begin
  if (aRow>0) then begin
    if (sgGrid.Cells[2,aRow].Equals('Napi zárás')) then begin
      sgGrid.canvas.Brush.Color:=TColor($b0b0b0);
    end
    else begin
      if (sgGrid.Cells[3,aRow].ToInteger<0) then begin
        sgGrid.canvas.Brush.Color:=TColor($e0e0ff);
      end
      else begin
        sgGrid.canvas.Brush.Color:=TColor($e0ffe0);
      end;
    end;
    sgGrid.canvas.FillRect(aRect);
    if aCol=3 then begin
      s := sgGrid.cells[ACol,ARow];
      i := sgGrid.Canvas.Textwidth(s);
      j := sgGrid.Canvas.TextHeight(s);
      sgGrid.Canvas.TextOut(aRect.right - i-3,aRect.top + (aRect.bottom - aRect.top - j) div 2,s);
    end
    else begin
      sgGrid.Canvas.TextRect(aRect,aRect.Left+3,aRect.top,sgGrid.Cells[ACol,ARow]);
    end;
  end;
end;

procedure TfrmList.FormCreate(Sender: TObject);
var
  fileExists: Boolean;
  txtLine: string;
  ldTime: TDateTime;
  ldBW: string;
  ldComment: string;
  ldValue: Integer;
  fData: text;
begin
  sgGrid.RowCount := 1;
  {$I-}
  AssignFile (fData, dataFName);
  Reset (fData);
  {$I+}
  fileExists := (IoResult=0);
  if fileExists then begin
    while not Eof(fData) do begin
      ReadLn(fData, txtLine);
      ProcessRow(txtLine, ldTime, ldBW, ldComment, ldValue);
      thisMStrLong := FormatDateTime('YYYY.MM.DD hh:nn:ss',ldTime);
      HandleGrid(ldBW, ldComment, IntToStr(ldValue));
    end;
    CloseFile (fData);
  end
  else begin
    {$I-}
    Rewrite (fData);
    CloseFile(fData);
    {$I+}
  end;
end;

procedure TfrmList.ProcessRow(line: string; var rowDate: TDateTime; var rowBW: string; var rowComment: string; var rowValue: Integer);
var
  tmpString: string;
begin
  tmpString := Copy(line, 1, Pos(';', line)-1);
  rowDate := StrToDateTime(tmpString);
  line := Copy(line, Pos(';', line)+1);
  rowBW := Copy(line, 1, Pos(';', line)-1);
  line := Copy(line, Pos(';', line)+2);
  rowComment := Copy(line, 1, Pos('"', line)-1);
  line := Copy(line, Pos(';', line)+1);
  rowValue := StrToInt(line);
end;

procedure TfrmList.HandleGrid(txtBW, txtComment, txtValue: string); //Feliratok, összegek frissítése
begin
  sgGrid.InsertRowWithValues(sgGrid.RowCount,[Copy(thisMStrLong,12), txtBW, txtComment, txtValue]);
end;

end.

