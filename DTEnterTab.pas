unit DTEnterTab;

interface

uses
 Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, SysUtils;


type
  THackForm = class(TForm);
  {$IfDef FMX}
   THackButtomControl = class(TCustomButton);
  {$Else}
   THackButtomControl = class(TButtonControl);
  {$EndIf}

  TDTEnterTab = class ( TComponent )
  private
    FAllowDefault: Boolean;
    FEnterAsTab: Boolean;
    FFormOwner: TForm;
    {$IfDef FMX}
     FOldOnKeyDown: TKeyEvent;
    {$Else}
     FOldKeyPreview : Boolean;
     FOldOnKeyPress : TKeyPressEvent ;
     FUseScreenControl: Boolean;
    {$EndIf}
    procedure SetEnterAsTab(const Value: Boolean);
  public
    constructor Create(AOwner: TComponent); override ;
    destructor Destroy ; override ;

    {$IfDef FMX}
     procedure DoKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
     property EnterAsTab: Boolean read FEnterAsTab write SetEnterAsTab default False ;
    {$Else}
     procedure DoEnterAsTab(AForm : TObject; var Key: Char);
    {$EndIf}
  published
    property AllowDefault: Boolean read FAllowDefault write FAllowDefault default true ;
    {$IfNDef FMX}
     property EnterAsTab: Boolean read FEnterAsTab write SetEnterAsTab default False ;
     property UseScreenControl: Boolean read FUseScreenControl write FUseScreenControl
        default {$IfDef FPC}True{$Else}False{$EndIf};
    {$EndIf}
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('DT Inovacao', [TDTEnterTab]);
end;

constructor TDTEnterTab.Create(AOwner: TComponent);
begin
  if not Assigned(AOwner) then
    raise Exception.Create(('TDTEnterTab.Owner n?o informado'));

  inherited Create(AOwner);

  FFormOwner         := nil;
  FEnterAsTab        := False;
  FAllowDefault      := True;
  {$IfDef FMX}
   FOldOnKeyDown     := nil;
  {$Else}
   FOldKeyPreview    := False;
   FOldOnKeyPress    := nil;
   FUseScreenControl := {$IfDef FPC}True{$Else}False{$EndIf};
  {$EndIf}
end;

destructor TDTEnterTab.Destroy;
begin
  { Restaurando estado das propriedades de Form modificadas }
  if Assigned(FFormOwner) then
  begin
    if not (csFreeNotification in FFormOwner.ComponentState) then
    begin
      with FFormOwner do
      begin
        {$IfDef FMX}
         OnKeyDown := FOldOnKeyDown;
        {$Else}
         KeyPreview := FOldKeyPreview;
         OnKeyPress := FOldOnKeyPress;
        {$EndIf}
      end ;
    end;
  end;

  inherited Destroy ;
end;

{$IfDef FMX}
 procedure TDTEnterTab.DoKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
 begin
   try
     If Key = vkReturn Then
     begin
       if (FFormOwner.ActiveControl is TCustomButton) and FAllowDefault then
         THackButtomControl( FFormOwner.ActiveControl ).Click
       else
       begin
         Key := vkTab;
         FFormOwner.KeyDown(Key, KeyChar, Shift);
       end;
     end ;
   finally
     if Assigned(FOldOnKeyDown) then
       FOldOnKeyDown(Sender, Key, KeyChar, Shift);

     Key := 0;
   end;
 end;
{$Else}
 procedure TDTEnterTab.DoEnterAsTab(AForm: TObject; var Key: Char);
 Var
   DoClick : Boolean ;
 begin
   try
     if not (AForm is TForm) then
       exit ;

     If Key = #13 Then
     begin
       if (TForm(AForm).ActiveControl is TButtonControl) and FAllowDefault then
       begin
          {$IFDEF VisualCLX}
           TButtonControl( TForm(AForm).ActiveControl ).AnimateClick;
          {$ELSE}
            DoClick := True;
           {$IFDEF FPC}
            {$IFNDEF Linux}
             DoClick := False;  // Para evitar Click ocorre 2x em FPC com Win32
            {$ENDIF}
           {$ENDIF}
           if DoClick then
             THackButtomControl( TForm(AForm).ActiveControl ).Click;
          {$ENDIF}
          Exit;
       end ;

       if FUseScreenControl then
         THackForm( AForm ).SelectNext( Screen.ActiveControl, True, True )
       else
         THackForm( AForm ).SelectNext( TForm(AForm).ActiveControl, True, True );
     end ;
   finally
     if Assigned( FOldOnKeyPress ) then
       FOldOnKeyPress( AForm, Key );

     If Key = #13 Then
       Key := #0;
   end;
 end;
{$EndIf}

procedure TDTEnterTab.SetEnterAsTab(const Value: Boolean);
var
  RealOwner: TComponent;
begin
  if Value = FEnterAsTab then
    Exit;

  if Value and (not Assigned(FFormOwner)) then
  begin
    RealOwner := Owner;
    while Assigned(RealOwner) and (not (RealOwner is TCustomForm)) do
      RealOwner := RealOwner.Owner;

    if (not Assigned(RealOwner)) then
      raise Exception.Create(('N?o foi poss?vel encontrar o Form Pai para TDTEnterTab'));

    FFormOwner := TForm(RealOwner);
    { Salvando estado das Propriedades do Form, que ser?o modificadas }
    with FFormOwner do
    begin
      {$IfDef FMX}
       FOldOnKeyDown := OnKeyDown;
      {$Else}
       FOldKeyPreview := KeyPreview ;
       FOldOnKeyPress := OnKeyPress ;
      {$EndIf}
    end ;
  end;

  if not (csDesigning in ComponentState) then
  begin
    with TForm(Owner) do
    begin
      if Value then
      begin
        {$IfDef FMX}
         OnKeyDown := DoKeyDown;
        {$Else}
         KeyPreview := true;
         OnKeyPress := DoEnterAsTab;
        {$EndIf}
      end
      else
      begin
        {$IfDef FMX}
         OnKeyDown := FOldOnKeyDown;
        {$Else}
         KeyPreview := FOldKeyPreview;
         OnKeyPress := FOldOnKeyPress;
        {$EndIf}
      end;
    end;
  end;

  FEnterAsTab := Value;
end;

end.
