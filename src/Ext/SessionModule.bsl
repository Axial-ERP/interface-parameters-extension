&After("УстановкаПараметровСеанса")
Procedure AxialERP_SessionParametersSetting(RequiredParameters)

	If RequiredParameters <> Undefined Then
		Return;
	EndIf;	     
	
	// Use User-defined style, then globally admin defined style, otherwise default style 
	UserDefinedInterfaceStyle = CommonSettingsStorage.Load("AxialERP", "SelectedStyleName");
	
	If ValueIsFilled(UserDefinedInterfaceStyle) 
		AND Metadata.Styles.Find(String(UserDefinedInterfaceStyle)) <> Undefined Then	  
		
		MainStyle = StyleLib[UserDefinedInterfaceStyle];    
		
	Else  
		
		AdminDefinedInterfaceStyle = CommonSettingsStorage.Load("AxialERP", "SelectedStyleName",, "");
		
		If ValueIsFilled(AdminDefinedInterfaceStyle) 
			AND Metadata.Styles.Find(String(AdminDefinedInterfaceStyle)) <> Undefined Then	 
			
			MainStyle = StyleLib[AdminDefinedInterfaceStyle];   
			
		Else        
			
			Try
				MainStyle = StyleLib.Default; //not found in ru-SSL
			Except
				MainStyle = new Style();
			EndTry;
			
		EndIf;   
		
	EndIf;   

EndProcedure

