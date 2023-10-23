
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure;    
	
	OpenForm("CommonForm.AxialERP_UserInterfaceParameters", 
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);       
	
EndProcedure
