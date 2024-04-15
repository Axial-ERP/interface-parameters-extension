//MIT License

//Copyright (c) [2023-2024] Axial Solutions LLC

//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:

//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.

//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
 
&AtClient
Var Message_ThisActionAffectsAllUser;   
&AtClient
Var Message_SetCompactModeForAllUsers; 
&AtClient
Var Message_SetFullScaleForAllUsers; 
&AtClient
Var Message_SetStyleForAllUsers;   
&AtClient
Var Message_SetPanelsSettingsForAllUsers;   
&AtClient
Var Message_RevertChangesForAllUsers;    

&AtClient
Procedure OnOpen(Cancel)    
	
	Message_ThisActionAffectsAllUser 		= NStr("en = 'This action affects all users'; 
													|es_CO = 'Esta acción afecta a todos los usuarios'; 
													|ru = 'Это действие распространяется на всех пользователей'");  
	
	Message_SetCompactModeForAllUsers 		= NStr("en = 'Do you want to set the compact mode for all users?'; 
													|es_CO = '¿Desea establecer el modo compacto para todos los usuarios?'; 
													|ru = 'Установить компактный режим для всех пользователей?'");       
	
	Message_SetFullScaleForAllUsers 		= NStr("en = 'Do you want to set the full scale intefrace mode for all users?'; 
													|es_CO = '¿Desea establecer el modo de interfaz a escala completa para todos los usuarios?'; 
													|ru = 'Установить полноразмерный режим для всех пользователей?'");    
	
	Message_SetStyleForAllUsers 			= NStr("en = 'Do you want to set this interface style for all users?'; 
													|es_CO = '¿Desea establecer este estilo de interfaz para todos los usuarios?'; 
													|ru = 'Установить этот стиль интерфейса для всех пользователей?'");  
	
	Message_SetPanelsSettingsForAllUsers	= NStr("en = 'Do you want to set these panel settings for all users?'; 
													|es_CO = '¿Desea establecer estas configuraciones de panel para todos los usuarios?'; 
													|ru = 'Установить эту конфигурацию панелей для всех пользователей?'");  
	
	Message_RevertChangesForAllUsers 		= NStr("en = 'Do you want to revert changes for all users?'; 
													|es_CO = '¿Desea revertir los cambios para todos los usuarios?'; 
													|ru = 'Отменить изменения для всех пользователей?'");

EndProcedure

&AtServer
Procedure SetClientApplicationFormScaleVariantForAllUsersAtServer(FormScaleVariant)   
	
	SettingsSelection = SystemSettingsStorage.Select(New Structure("ObjectKey", "Common/ClientSettings"));
	
	While SettingsSelection.Next() Do    
		
		Settings = SettingsSelection.Settings;     
		
		Settings.ClientApplicationFormScaleVariant = FormScaleVariant;
		
		SystemSettingsStorage.Save("Common/ClientSettings",, Settings,, SettingsSelection.User);          
		
	EndDo;          
	
EndProcedure   

&AtClient
Async Procedure ShowRestartDialog()    
	
	Buttons = New ValueList;
	Buttons.Add("Restart", 		NStr("en = 'Restart'; es_CO = 'Reiniciar'; ru = 'Перезапустить'"));
	Buttons.Add("DoNotRestart", NStr("en = 'Do not restart'; es_CO = 'No reiniciar'; ru = 'Не перезапускать'"));  
	
	QueryText = NStr("en = 'Changes have been applied! Please restart the app to see the updated interface.'; 
					|es_CO = '¡Los cambios se han aplicado! Por favor, reinicia la aplicación para ver la interfaz actualizada.'; 
					|ru = 'Изменения применены! Пожалуйста, перезапустите приложение, чтобы увидеть обновленный интерфейс.'");
	
	Result = Await DoQueryBoxAsync(QueryText, Buttons, 60, "Restart", "", "Restart");       
	
	If Result = "Restart" Then
			
		Exit(False, True);    
		
	EndIf;
		
EndProcedure     

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)   
	
	Items.AllStyles.ChoiceList.Clear();  
	Items.AllStyles.ChoiceList.Add("AxialERP_Default", NStr("en = 'Default Style'; es_CO = 'Estilo predeterminado'; ru = 'Стиль по умолчанию'"));
	
	For Each Style in Metadata.Styles Do   
		
		If StrStartsWith(Style.Name, "AxialERP_") Then         
			
			Items.AllStyles.ChoiceList.Add(Style.Name, Style.Synonym);    
			
		EndIf;
		
	EndDo;    
	
	// load currently selected style
	UserPreferredInterfaceStyle = CommonSettingsStorage.Load("AxialERP", "SelectedStyleName",, InfoBaseUsers.CurrentUser().Name);
	
	If ValueIsFilled(UserPreferredInterfaceStyle) 
		AND Metadata.Styles.Find(String(UserPreferredInterfaceStyle)) <> Undefined Then	    
		
		SelectedStyle = UserPreferredInterfaceStyle;         
		
	Else  
		
		SelectedStyle = "AxialERP_Default";
		
	EndIf;  
	
	DisplayStylePreview();   
	
	// load currently used panel settings     
	UserSelectedSectionPanelSettings = SystemSettingsStorage.Load("Common/SectionsPanel/CommandInterfaceSettings", "",, InfoBaseUsers.CurrentUser().Name);
	
	If TypeOf(UserSelectedSectionPanelSettings) = Type("CommandInterfaceSettings") Then   
		
		DisplaySectionTitle = Not (UserSelectedSectionPanelSettings.SectionsPanelRepresentation = SectionsPanelRepresentation.Picture); 
		
	Else        
		
		DisplaySectionTitle = True;
		
	EndIf;  
	
	UserSelectedOpenItemsPanelSettings = SystemSettingsStorage.Load("Common/ClientApplicationInterfaceSettings", "",, InfoBaseUsers.CurrentUser().Name);
	
	If TypeOf(UserSelectedOpenItemsPanelSettings) = Type("ClientApplicationInterfaceSettings") Then	        
		
		SettingsContent = UserSelectedOpenItemsPanelSettings.GetContent();   
		
		Location = CheckPanelLocation("LEFT", SettingsContent.Left, "OpenItemsPanel");   
		If ValueIsFilled(Location) Then OpenItemsPanelLocation = "LEFT" EndIf;  
		
		Location = CheckPanelLocation("RIGHT", SettingsContent.Right, "OpenItemsPanel");   
		If ValueIsFilled(Location) Then OpenItemsPanelLocation = "RIGHT" EndIf;    
		
		Location = CheckPanelLocation("TOP", SettingsContent.Top, "OpenItemsPanel");   
		If ValueIsFilled(Location) Then OpenItemsPanelLocation = "TOP" EndIf;    
		
		Location = CheckPanelLocation("BOTTOM", SettingsContent.Bottom, "OpenItemsPanel");   
		If ValueIsFilled(Location) Then OpenItemsPanelLocation = "BOTTOM" EndIf;   
		
		Location = CheckPanelLocation("LEFT", SettingsContent.Left, "SectionsPanel");   
		If ValueIsFilled(Location) Then SectionPanelLocation = "LEFT" EndIf;     
		
		Location = CheckPanelLocation("TOP", SettingsContent.Top, "SectionsPanel");   
		If ValueIsFilled(Location) Then SectionPanelLocation = "TOP" EndIf;      	
		
	Else       
		
		OpenItemsPanelLocation = "BOTTOM";          
		SectionPanelLocation = "TOP";
		
	EndIf;  
	
	DisplaySectionPanelPreview();
	
	DisplayOpenItemsPanelPreview();
	
EndProcedure    

&AtServer
Function CheckPanelLocation(TargetLocation, PanelGroup, PanelName)    
	
	For Each Panel in PanelGroup Do   
		
		If TypeOf(Panel) = Type("ClientApplicationInterfaceContentSettingsGroup") Then      
			
			Return CheckPanelLocation(TargetLocation, Panel, PanelName);
			
		ElsIf TypeOf(Panel) = Type("ClientApplicationInterfaceContentSettingsItem") Then
			
			If Panel.Name = PanelName Then
				Return TargetLocation;
			EndIf;    
			
		EndIf;
							
	EndDo;     
	
	Return Undefined;
	
EndFunction

&AtServer
Procedure DisplaySectionPanelPreview()        
	
	PictureName = "AxialERP_SectionPanel_" + SectionPanelLocation; 
	
	If DisplaySectionTitle Then       
		PictureName = PictureName + "_WithText";		
	Else                       
		PictureName = PictureName + "_NoText";		
	EndIf;
	
	SectionPanelPicPreview = Metadata.CommonPictures.Find(PictureName);       
	
	If SectionPanelPicPreview <> Undefined Then       
		SectionPanelPreview = PutToTempStorage(PictureLib[SectionPanelPicPreview.Name].GetBinaryData());   
	Else   
		SectionPanelPreview = PutToTempStorage(PictureLib.AxialERP_SectionPanel_TOP_WithText.GetBinaryData());   
	EndIf;  
	
EndProcedure    

&AtServer
Procedure DisplayOpenItemsPanelPreview()        
	
	PictureName = "AxialERP_OpenItemsPanel_" + OpenItemsPanelLocation; 
	
	OpenItemsPanelPicPreview = Metadata.CommonPictures.Find(PictureName);       
	
	If OpenItemsPanelPicPreview <> Undefined Then       
		OpenItemsPanelPreview = PutToTempStorage(PictureLib[OpenItemsPanelPicPreview.Name].GetBinaryData());   
	Else   
		OpenItemsPanelPreview = PutToTempStorage(PictureLib.AxialERP_OpenItemsPanel_BOTTOM.GetBinaryData());   
	EndIf;  
	
EndProcedure

&AtServer
Procedure DisplayStylePreview()       
	
	PictureName = StrReplace(SelectedStyle, "AxialERP_", "AxialERP_StyleExample_"); 
	
	StylePreviewCommonPicture = Metadata.CommonPictures.Find(PictureName);       
	
	If StylePreviewCommonPicture <> Undefined Then        
		
		StylePreview = PutToTempStorage(PictureLib[StylePreviewCommonPicture.Name].GetBinaryData());   
		
	Else   
		
		StylePreview = PutToTempStorage(PictureLib.AxialERP_StyleExample_Default.GetBinaryData());   
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AllStylesOnChangeAtServer()
	
	DisplayStylePreview();
	
EndProcedure

&AtClient
Procedure AllStylesOnChange(Item) 
	
	AllStylesOnChangeAtServer();
	
EndProcedure     

&AtClient
Procedure DecorationAxialAdLogoClick(Item)   
	
	If CurrentLanguage() = "es_CO" Then   
		RunApp("https://axial-erp.co");
	Else 
		RunApp("https://axial-erp.com");
	EndIf;
	
EndProcedure

&AtServer
Function CreateSectionsPanelSettings(SectionsPanelSettings, Default)       
	
	If Default Or TypeOf(SectionsPanelSettings) <> Type("CommandInterfaceSettings") Then    
		SectionsPanelSettings = New CommandInterfaceSettings;    
	EndIf;   

	If Default Or DisplaySectionTitle Then     
		SectionsPanelSettings.SectionsPanelRepresentation = SectionsPanelRepresentation.PictureAndText;   
	Else
		SectionsPanelSettings.SectionsPanelRepresentation = SectionsPanelRepresentation.Picture;   
	EndIf;   
	
	Return SectionsPanelSettings;
	
EndFunction

&AtServer
Function CreatePanelsLocationSettings(PanelsLocationSettings, Default)       
	
	If Default Or TypeOf(PanelsLocationSettings) <> Type("ClientApplicationInterfaceSettings") Then   
		PanelsLocationSettings = New ClientApplicationInterfaceSettings;	    
	EndIf;
	
	ClientSettings = New ClientApplicationInterfaceContentSettings;   
	
	PopulateGroup(ClientSettings.Top, 		"TOP");
	PopulateGroup(ClientSettings.Bottom, 	"BOTTOM");
	PopulateGroup(ClientSettings.Left, 		"LEFT");
	PopulateGroup(ClientSettings.Right, 	"RIGHT");
	
	PanelsLocationSettings.SetContent(ClientSettings);
	
	Return PanelsLocationSettings;
	
EndFunction

	
	
#Region FormCommands

&AtClient
Async Procedure SetCompactModeForAllUsers(Command)   
	
	Result = Await DoQueryBoxAsync(Message_SetCompactModeForAllUsers, 
		QuestionDialogMode.YesNo, 
		60, 
		DialogReturnCode.No, 
		Message_ThisActionAffectsAllUser, 
		DialogReturnCode.No);
		
	If Result = DialogReturnCode.Yes Then
			
		SetCompactModeForAllUsersAtServer();  
		
		ShowRestartDialog();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetCompactModeForAllUsersAtServer()   
	
	SetClientApplicationFormScaleVariantForAllUsersAtServer(ClientApplicationFormScaleVariant.Compact);          
	
EndProcedure

&AtClient
Procedure SetCompactModeForMe(Command)    
	
	SetCompactModeForMeAtServer();    
	
	ShowRestartDialog();
	
EndProcedure  

&AtServer
Procedure SetCompactModeForMeAtServer()
	
	Settings = SystemSettingsStorage.Load("Common/ClientSettings");         

	If Settings = Undefined Then   
		
		// copy from the default system settings 
		Settings = SystemSettingsStorage.Load("Common/ClientSettings",,, "");       
		
		// this shouldn't be the case, but let's add this just in case
		If Settings = Undefined Then   
			Settings = New ClientSettings;	    
			Settings.ClientApplicationInterfaceVariant = ClientApplicationInterfaceVariant.Taxi;
		EndIf;        
			
	EndIf;
	
	Settings.ClientApplicationFormScaleVariant = ClientApplicationFormScaleVariant.Compact;
	
	SystemSettingsStorage.Save("Common/ClientSettings",, Settings);          
	
EndProcedure

&AtClient
Async Procedure SetFullScaleSizeForAllUsers(Command)    
	
	Result = Await DoQueryBoxAsync(Message_SetFullScaleForAllUsers, 
		QuestionDialogMode.YesNo, 
		60, 
		DialogReturnCode.No, 
		Message_ThisActionAffectsAllUser, 
		DialogReturnCode.No);
		
	If Result = DialogReturnCode.Yes Then
			
		SetFullScaleModeForAllUsersAtServer();       
		
		ShowRestartDialog();
		
	EndIf;    
	
EndProcedure

&AtServer
Procedure SetFullScaleModeForAllUsersAtServer()        
	
	SetClientApplicationFormScaleVariantForAllUsersAtServer(ClientApplicationFormScaleVariant.Normal);          
	
EndProcedure    

&AtServer
Procedure SetFullScaleModeForMeAtServer()
	
	Settings = SystemSettingsStorage.Load("Common/ClientSettings");         

	If Settings = Undefined Then   
		
		// copy from the default system settings 
		Settings = SystemSettingsStorage.Load("Common/ClientSettings",,, "");    
		
		// this shouldn't be the case, but let's add this just in case
		If Settings = Undefined Then   
			Settings = New ClientSettings;	    
			Settings.ClientApplicationInterfaceVariant = ClientApplicationInterfaceVariant.Taxi;
		EndIf;        
			
	EndIf;
	
	Settings.ClientApplicationFormScaleVariant = ClientApplicationFormScaleVariant.Normal;
	
	SystemSettingsStorage.Save("Common/ClientSettings",, Settings);          
	
EndProcedure

&AtClient
Procedure SetFullScaleSizeForMe(Command)

	SetFullScaleModeForMeAtServer();     
	
	ShowRestartDialog();
	
EndProcedure

&AtServer
Procedure RevertAllChangesForMeAtServer()      
	
	CommonSettingsStorage.Delete("AxialERP", "SelectedStyleName", UserName()); 
	
	// revert system settings to auto   
	Settings = SystemSettingsStorage.Load("Common/ClientSettings");         

	If Settings <> Undefined Then   
		
		Settings.ClientApplicationFormScaleVariant = ClientApplicationFormScaleVariant.Auto;
	
		SystemSettingsStorage.Save("Common/ClientSettings",, Settings);          
			
	EndIf;     
	
	//restore panels settings 
	SectionPanelLocation 	= "LEFT";
	OpenItemsPanelLocation 	= "BOTTOM";
	DisplaySectionTitle 	= True;
	
	SetPanelSettingsForMeAtServer(True);

EndProcedure

&AtClient
Procedure RevertAllChangesForMe(Command)   
	
	RevertAllChangesForMeAtServer();     
	
	ShowRestartDialog();

EndProcedure

&AtClient
Async Procedure RevertAllChangesForAllUsers(Command)

	Result = Await DoQueryBoxAsync(Message_RevertChangesForAllUsers, 
		QuestionDialogMode.YesNo, 
		60, 
		DialogReturnCode.No, 
		Message_ThisActionAffectsAllUser, 
		DialogReturnCode.No);
		
	If Result = DialogReturnCode.Yes Then
			
		RevertAllChangesForAllUsersAtServer();  
		
		ShowRestartDialog();

	EndIf;

EndProcedure    

&AtServer
Procedure RevertAllChangesForAllUsersAtServer()      
	
	SetClientApplicationFormScaleVariantForAllUsersAtServer(ClientApplicationFormScaleVariant.Auto);    
	
	//delete selected style for all users
	SettingsSelection = CommonSettingsStorage.Select(New Structure("ObjectKey,SettingsKey", "AxialERP", "SelectedStyleName"));
	
	While SettingsSelection.Next() Do    
		
		CommonSettingsStorage.Delete("AxialERP", "SelectedStyleName", SettingsSelection.User);          
		
	EndDo;     
	
	//restore panels settings 
	SectionPanelLocation 	= "LEFT";
	OpenItemsPanelLocation 	= "BOTTOM";
	DisplaySectionTitle 	= True;
	
	SetPanelSettingsForAllUsersAtServer(True);
	
EndProcedure  

&AtServer
Procedure SetSelectedStyleForMeAtServer()      
	
	CommonSettingsStorage.Save("AxialERP", "SelectedStyleName", SelectedStyle);  
	
EndProcedure

&AtClient
Procedure SetSelectedStyleForMe(Command)
	
	SetSelectedStyleForMeAtServer();     
	
	ShowRestartDialog();

EndProcedure    

&AtServer
Procedure SetSelectedStyleForAllUsersAtServer()      
	
	UsersArray = InfoBaseUsers.GetUsers();
	
	For Each InfoBaseUser in UsersArray Do
		CommonSettingsStorage.Save("AxialERP", "SelectedStyleName", SelectedStyle,, InfoBaseUser.FullName);		
	EndDo;
	
	
EndProcedure

&AtClient
Async Procedure SetSelectedStyleForAllUsers(Command)      
	
	Result = Await DoQueryBoxAsync(Message_SetStyleForAllUsers, 
		QuestionDialogMode.YesNo, 
		60, 
		DialogReturnCode.No, 
		Message_ThisActionAffectsAllUser, 
		DialogReturnCode.No);
		
	If Result = DialogReturnCode.Yes Then
			
		SetSelectedStyleForAllUsersAtServer();        
		
		ShowRestartDialog();
		
	EndIf;

EndProcedure  

&AtServer
Procedure SetPanelSettingsForMeAtServer(Default = False)   
	
	UserSettings = SystemSettingsStorage.Load("Common/SectionsPanel/CommandInterfaceSettings"); 
	
	SystemSettingsStorage.Save("Common/SectionsPanel/CommandInterfaceSettings",, CreateSectionsPanelSettings(UserSettings, Default));       
	
	//----------------------------------------------------
	
	UserSettings = SystemSettingsStorage.Load("Common/ClientApplicationInterfaceSettings");         
	
	SystemSettingsStorage.Save("Common/ClientApplicationInterfaceSettings",, CreatePanelsLocationSettings(UserSettings, Default));       

EndProcedure 

&AtServer
Procedure PopulateGroup(PanelGroups, Position)     
	
	//make it on top of each other in both cases
	If Position = "LEFT" Or Position = "RIGHT" Then   
		
		PanelGroup = New ClientApplicationInterfaceContentSettingsGroup;
	
		If SectionPanelLocation = Position Then     
			PanelGroup.Add(New ClientApplicationInterfaceContentSettingsItem("SectionsPanel"));	
		EndIf;
		If OpenItemsPanelLocation = Position Then     
			PanelGroup.Add(New ClientApplicationInterfaceContentSettingsItem("OpenItemsPanel"));	
		EndIf;
		
		If PanelGroup.Count() > 0 Then  
			PanelGroups.Add(PanelGroup);
		EndIf;
		
	Else  
		If SectionPanelLocation = Position Then     
			PanelGroups.Add(New ClientApplicationInterfaceContentSettingsItem("SectionsPanel"));	
		EndIf;
		If OpenItemsPanelLocation = Position Then     
			PanelGroups.Add(New ClientApplicationInterfaceContentSettingsItem("OpenItemsPanel"));	
		EndIf;
	EndIf;
	
EndProcedure
	
&AtClient
Procedure SetPanelSettingsForMe(Command)  
	
	SetPanelSettingsForMeAtServer();  
	
	ShowRestartDialog();    
	
EndProcedure

&AtServer
Procedure SetPanelSettingsForAllUsersAtServer(Default = False)
	
	SettingsSelection = SystemSettingsStorage.Select(New Structure("ObjectKey", "Common/SectionsPanel/CommandInterfaceSettings"));
	
	While SettingsSelection.Next() Do    
		
		UserSettings = SettingsSelection.Settings;     
		
		SystemSettingsStorage.Save("Common/SectionsPanel/CommandInterfaceSettings",, 
								CreateSectionsPanelSettings(UserSettings, Default),, SettingsSelection.User);          
		
	EndDo;       
	
	//----------------------------------------------------
	
	SettingsSelection = SystemSettingsStorage.Select(New Structure("ObjectKey", "Common/ClientApplicationInterfaceSettings"));
	
	While SettingsSelection.Next() Do    
		
		UserSettings = SettingsSelection.Settings;     
		
		SystemSettingsStorage.Save("Common/ClientApplicationInterfaceSettings",, 
								CreatePanelsLocationSettings(UserSettings, Default),, SettingsSelection.User);          
		
	EndDo;    

EndProcedure

&AtClient
Async Procedure SetPanelSettingsForAllUsers(Command)    
	
	Result = Await DoQueryBoxAsync(Message_SetPanelsSettingsForAllUsers, 
		QuestionDialogMode.YesNo, 
		60, 
		DialogReturnCode.No, 
		Message_ThisActionAffectsAllUser, 
		DialogReturnCode.No);
		
	If Result = DialogReturnCode.Yes Then
			
		SetPanelSettingsForAllUsersAtServer();  
		
		ShowRestartDialog();
		
	EndIf;

EndProcedure

&AtClient
Procedure SectionPanelLocationOnChange(Item) 
	
	DisplaySectionPanelPreview();    
	
EndProcedure

&AtClient
Procedure DisplaySectionPanelTextOnChange(Item)

	DisplaySectionPanelPreview();  
	
EndProcedure

&AtClient
Procedure OpenItemsPanelLocationOnChange(Item)
	
	DisplayOpenItemsPanelPreview();
	
EndProcedure

#EndRegion

