//MIT License

//Copyright (c) [2023] Axial Solutions LLC

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
Var Message_RevertChangesForAllUsers;    

&AtClient
Procedure OnOpen(Cancel)    
	
	Message_ThisActionAffectsAllUser 	= NStr("en = 'This action affects all users'; es_CO = 'Esta acción afecta a todos los usuarios'");
	Message_SetCompactModeForAllUsers 	= NStr("en = 'Do you want to set the compact mode for all users?'; es_CO = '¿Desea establecer el modo compacto para todos los usuarios?'");
	Message_SetFullScaleForAllUsers 	= NStr("en = 'Do you want to set the full scale intefrace mode for all users?'; es_CO = '¿Desea establecer el modo de interfaz a escala completa para todos los usuarios?'");
	Message_SetStyleForAllUsers 		= NStr("en = 'Do you want to set this interface style for all users?'; es_CO = '¿Desea establecer este estilo de interfaz para todos los usuarios?'");
	Message_RevertChangesForAllUsers 	= NStr("en = 'Do you want to revert changes for all users?'; es_CO = '¿Desea revertir los cambios para todos los usuarios?'");

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
	Buttons.Add("Restart", 		NStr("en = 'Restart'; es_CO = 'Reiniciar';"));
	Buttons.Add("DoNotRestart", NStr("en = 'Do not restart'; es_CO = 'No reiniciar';"));  
	
	QueryText = NStr("en = 'Changes have been applied! Please restart the app to see the updated interface.';
					|es_CO = '¡Los cambios se han aplicado! Por favor, reinicia la aplicación para ver la interfaz actualizada.';");
	
	Result = Await DoQueryBoxAsync(QueryText, Buttons, 60, "Restart", "", "Restart");       
	
	If Result = "Restart" Then
			
		Exit(False, True);    
		
	EndIf;
		
EndProcedure     


&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)   
	
	Items.AllStyles.ChoiceList.Clear();  
	Items.AllStyles.ChoiceList.Add("AxialERP_Default", NStr("en = 'Default Style'; es_CO = 'Estilo predeterminado';"));
	
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

#EndRegion

