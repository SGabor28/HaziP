unit UfrmMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, EditBtn, Grids, Buttons, Types, Crt, DateUtils, ufrmList;

const dataFName: string = 'HaziP.csv';

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnWhExpense: TButton;
    btnBlExpense: TButton;
    btnWhIncome: TButton;
    btnBlIncome: TButton;
    btnList: TButton;
    edComment: TEdit;
    edValue: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    lblActualBalance: TLabel;
    lblDailyWhBalance: TLabel;
    Label3: TLabel;
    lblActualWhBalance: TLabel;
    lblDailyBalance: TLabel;
    pnlExpense: TPanel;
    pnlExpense1: TPanel;
    pnlIncome: TPanel;
    pnlIncome1: TPanel;
    sgDailyGrid: TStringGrid;
    procedure btnListClick(Sender: TObject);
    procedure btnWhExpenseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure sgDailyGridDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
  private
    formatSettings : TFormatSettings;
    today: TDate;
    todayStr: string;
    thisMoment: TDateTime;
    thisMStrShort: string;
    thisMStrLong: string;
    fData: text;
    dailyWhOpenBalance: Integer;
    dailyOpenBalance: Integer;
    actualWhBalance: Integer;
    actualBalance: Integer;
    sign: string;
    whText: string;
    procedure FieldCheck;
    procedure PrepareOnStart;
    procedure FLoadOnStart;
    procedure CalcValue(Sender: TObject); //Feliratok, összegek frissítése
    procedure RefreshLabels; //Feliratok, összegek frissítése
    procedure HandleGrid(txtBW, txtComment, txtValue: string); //Feliratok, összegek frissítése
    procedure SaveToFile(Sender: TObject); //Új sor fájlba mentése
    procedure DoBackup(Sender: TObject); //Új biztonsági másolat készítés
    procedure PrepareNext(doFocus: boolean); //Képernyő ürítések
    procedure DailyClose(Day: TDateTime); //Előző nap zárása
    procedure GetDateLine;
    procedure ProcessRow(line: string; var rowDate: TDateTime; var rowBW: string; var rowComment: string; var rowValue: Integer); //Sor feldolgozása
    function IsDailyRow(line: string): boolean; //A sor napi zárás-e
    function FormatCurrency(currText: string): string;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  PrepareOnStart;
  FLoadOnStart;
end;

procedure TfrmMain.btnWhExpenseClick(Sender: TObject);
begin
  FieldCheck; ///Ellenőrzések
  frmMain.Color := clRed;
  frmMain.Repaint;
  CalcValue(Sender);
  SaveToFile(Sender); //Új sor fájlba mentése
  DoBackup(Sender); //Új biztonsági másolat készítés
  PrepareNext(True); //Képernyő ürítések
  frmMain.Color := clDefault;
end;

procedure TfrmMain.btnListClick(Sender: TObject);
var
  frmList: TFrmList;
begin
  frmList := TFrmList.Create(nil);
  frmList.ShowModal;
end;



//TODO: ezt még meg kell csinálni
procedure TfrmMain.PrepareOnStart;
begin
  formatSettings.DateSeparator:='.';
  formatSettings.TimeSeparator:=':';
  dailyOpenBalance:=0;
  dailyWhOpenBalance:=0;
  actualBalance:=0;
  actualWhBalance:=0;
  today:=DateOf(Now);
  todayStr:=FormatDateTime('YYYYMMDD',today);
  If Not DirectoryExists(todayStr) then
    If Not CreateDir (todayStr) then
      MessageDlg('Hiba', 'Alkönyvtár létrehozási hiba: '+todayStr, mtError, [mbOK], '');
end;

//
procedure TfrmMain.FLoadOnStart;
var
  fileExists: Boolean;
  txtLine: string;
  ldTime: TDateTime;
  ldBW: string;
  ldComment: string;
  ldValue: Integer;
begin
  {$I-}
  AssignFile (fData, dataFName);
  Reset (fData);
  {$I+}
  fileExists := (IoResult=0);
  if fileExists then begin
    while not Eof(fData) do begin
      ReadLn(fData, txtLine);
      ProcessRow(txtLine, ldTime, ldBW, ldComment, ldValue);
      if IsDailyRow(txtLine) then begin
        if ldBW = '' then begin
          dailyOpenBalance := ldValue;
          actualBalance := ldValue;
        end
        else begin
          dailyWhOpenBalance := ldValue;
          actualWhBalance := ldValue;
        end;
        sgDailyGrid.RowCount := 1;
        RefreshLabels;
      end
      else begin
        if ldBW <> '' then begin
          actualWhBalance := actualWhBalance + ldValue;
        end;
        actualBalance := actualBalance + ldValue;
        thisMStrLong := FormatDateTime('YYYY.MM.DD hh:nn:ss',ldTime);
        HandleGrid(ldBW, ldComment, IntToStr(ldValue));
      end;
    end;
    CloseFile (fData);
    if (not IsDailyRow(txtLine)) and (today > DateOf(ldTime)) then begin
      DailyClose(DateOf(ldTime))
    end
    else begin
      RefreshLabels;
    end;
  end
  else begin
    {$I-}
    Rewrite (fData);
    CloseFile(fData);
    {$I+}
  end;
  PrepareNext(False); //Képernyő ürítések
end;


procedure TfrmMain.CalcValue(Sender: TObject); //Feliratok, összegek frissítése
begin
  GetDateLine;
  if ((Sender as TButton).Name = 'btnBlIncome') or
     ((Sender as TButton).Name = 'btnWhIncome') then begin
    sign := '';
  end
  else if ((Sender as TButton).Name = 'btnBlExpense') or
          ((Sender as TButton).Name = 'btnWhExpense') then begin
    sign := '-';
  end;
  if ((Sender as TButton).Name = 'btnWhIncome') or
     ((Sender as TButton).Name = 'btnWhExpense') then begin
    whText := 'Sz';
  end
  else begin
    whText := '';
  end;
  actualBalance := actualBalance+StrToInt(sign+edValue.text);
  if whText = 'Sz' then begin
    actualWhBalance := actualWhBalance+StrToInt(sign+edValue.text);
  end;
  RefreshLabels;
  HandleGrid(whText, edComment.Text, sign+edValue.Text);
end;

procedure TfrmMain.RefreshLabels; //Feliratok, összegek frissítése
begin
  lblDailyBalance.Caption:=FormatCurrency(dailyOpenBalance.ToString)+ 'Ft';
  lblActualBalance.Caption:=FormatCurrency(actualBalance.ToString)+ 'Ft';
  lblDailyWhBalance.Caption:=FormatCurrency(dailyWhOpenBalance.ToString)+ 'Ft';
  lblActualWhBalance.Caption:=FormatCurrency(actualWhBalance.ToString)+ 'Ft';
  if actualWhBalance<0 then
    lblActualWhBalance.Font.Color:=clRed
  else
    lblActualWhBalance.Font.Color:=clDefault;
  if actualBalance<0 then
    lblActualBalance.Font.Color:=clRed
  else
    lblActualBalance.Font.Color:=clDefault;
end;

procedure TfrmMain.HandleGrid(txtBW, txtComment, txtValue: string); //Feliratok, összegek frissítése
begin
  sgDailyGrid.InsertRowWithValues(sgDailyGrid.RowCount,[Copy(thisMStrLong,12), txtBW, txtComment, txtValue]);
end;

//TODO: ezt még meg kell csinálni
procedure TfrmMain.SaveToFile(Sender: TObject); //Új sor fájlba mentése
var
  txtline: string;
begin
  {$I-}
  AssignFile (fData, dataFName);
  Append (fData);
  {$I+}
  txtline := thisMStrLong+';'+whText+';"'+edComment.Text+'";'+sign+edValue.Text;
  WriteLn(fData, txtline);
  CloseFile(fData);
end;

//TODO: ezt még meg kell csinálni
procedure TfrmMain.DoBackup(Sender: TObject); //Új biztonsági másolat készítés
begin
  CopyFile(dataFName, todayStr+'\'+thisMStrShort+'.csv');
end;

//TODO: ezt még meg kell csinálni
procedure TfrmMain.PrepareNext(doFocus: boolean); //Képernyő ürítések
begin
  sgDailyGrid.Row := sgDailyGrid.RowCount-1;
  edComment.Text := '';
  edValue.Text := '';
  if doFocus then
    edComment.SetFocus;
end;

procedure TfrmMain.sgDailyGridDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var i,j : integer;
    s : string;
begin
  if (aRow>0) then begin
    if (sgDailyGrid.Cells[3,aRow].ToInteger<0) then begin
      sgDailyGrid.canvas.Brush.Color:=TColor($e0e0ff);
    end
    else begin
      sgDailyGrid.canvas.Brush.Color:=TColor($e0ffe0);
    end;
    sgDailyGrid.canvas.FillRect(aRect);
    if aCol=3 then begin
      s := sgDailyGrid.cells[ACol,ARow];
      i := sgDailyGrid.Canvas.Textwidth(s);
      j := sgDailyGrid.Canvas.TextHeight(s);
      sgDailyGrid.Canvas.TextOut(aRect.right - i-3,aRect.top + (aRect.bottom - aRect.top - j) div 2,s);
    end
    else begin
      sgDailyGrid.Canvas.TextRect(aRect,aRect.Left+3,aRect.top,sgDailyGrid.Cells[ACol,ARow]);
    end;
  end;
end;

procedure TfrmMain.GetDateLine;
begin
  thisMoment := Now;
  thisMStrShort:=FormatDateTime('YYYYMMDDhhnnss',ThisMoment);
  thisMStrLong:=FormatDateTime('YYYY.MM.DD hh:nn:ss',ThisMoment);
  if today < DateOf(thisMoment) then
    DailyClose(today);
end;

///Napi zárás
procedure TFrmMain.DailyClose(Day: TDateTime);
var
  txtLine: string;
begin
  {$I-}
  AssignFile (fData, dataFName);
  Append (fData);
  {$I+}
  txtline := FormatDateTime('YYYY.MM.DD',Day)+';Sz;"Napi zárás";'+IntToStr(actualWhBalance);
  WriteLn(fData, txtline);
  txtline := FormatDateTime('YYYY.MM.DD',Day)+';;"Napi zárás";'+IntToStr(actualBalance);
  WriteLn(fData, txtline);
  CloseFile(fData);
  dailyOpenBalance := actualBalance;
  dailyWhOpenBalance := actualWhBalance;
  sgDailyGrid.RowCount := 1;
  RefreshLabels;
end;

procedure TfrmMain.FieldCheck;
begin
  if (edComment.Text = '') or (edValue.Text = '') then begin
    MessageDlg('Hiba', 'Nincs kitöltve', mtError, [mbOK], '');
    Abort;
  end;
end;

//Sor feldolgozása
procedure TfrmMain.ProcessRow(line: string; var rowDate: TDateTime; var rowBW: string; var rowComment: string; var rowValue: Integer);
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

//A sor napi zárás-e
function TfrmMain.IsDailyRow(line: string): boolean;
var
  tmpTxt: string;
begin
  tmpTxt:=Copy(line, Pos('"', line)+1);
  tmpTxt:=Copy(tmpTxt, 1, Pos('"', tmpTxt)-1);
  result :=  tmpTxt = 'Napi zárás';
end;

///Pénz string hármas tagolása
function TfrmMain.FormatCurrency(currText: string): string;
var
  c, i: Integer;
begin
  i := 0;
  for c:=Length(currText) downto 1 do begin
    Inc(i);
    if (i=3) and (c>1) then begin
      i := 0;
      Insert('.', currText, c);
    end;
  end;
  Result := currText;
end;

end.

