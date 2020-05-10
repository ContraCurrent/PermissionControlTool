public class permControlController{
    
    ApexPages.StandardSetController setCon;
    
    public pse__Permission_Control__c permControlEntry {get; set;}  
    List<pse__Permission_Control__c> permControlList;
    
    public permControlController(ApexPages.StandardSetController controller)
    {
        setCon = controller;
        permControlList = new List<pse__Permission_Control__c>();
        permControlEntry = new pse__Permission_Control__c();
    }

    public pageReference createPermissions()
    {
        /** Below action called from Create Permissions button
         * It takes all values entered in screen
         * Then creates a new permcontrol record for each Contact that was selected
         * It adds each one to a list and inserts list
        */
        for ( Contact con : [SELECT Id, Name, pse__Salesforce_User__c FROM Contact WHERE Id IN :setCon.getSelected()])
        {
            System.debug('Contact SFDC ID = ' + con.pse__Salesforce_User__c);
            pse__Permission_Control__c permControlCreate = new pse__Permission_Control__c
            (
                pse__User__c = con.pse__Salesforce_User__c,
                pse__Billing__c = permControlEntry.pse__Billing__c,
                pse__Cascading_Permission__c = permControlEntry.pse__Cascading_Permission__c,
                pse__Compare_Project_Version__c = permControlEntry.pse__Compare_Project_Version__c,
                pse__Create_Project_Version__c = permControlEntry.pse__Create_Project_Version__c,
                pse__Delete_Project_Version__c = permControlEntry.pse__Delete_Project_Version__c,
                pse__Edit_Task_Manager__c = permControlEntry.pse__Edit_Task_Manager__c,
                pse__End_Date__c = permControlEntry.pse__End_Date__c,
                pse__Expense_Entry__c = permControlEntry.pse__Expense_Entry__c,
                pse__Expense_Ops_Edit__c = permControlEntry.pse__Expense_Ops_Edit__c,
                pse__Forecast_Edit__c = permControlEntry.pse__Forecast_Edit__c,
                pse__Forecast_View__c = permControlEntry.pse__Forecast_View__c,
                pse__Group__c = permControlEntry.pse__Group__c,
                pse__Invoicing__c = permControlEntry.pse__Invoicing__c,
                pse__Practice__c = permControlEntry.pse__Practice__c,
                pse__Project__c = permControlEntry.pse__Project__c,
                pse__Region__c = permControlEntry.pse__Region__c,           
                pse__Resource__c = permControlEntry.pse__Resource__c,
                pse__Resource_Request_Entry__c = permControlEntry.pse__Resource_Request_Entry__c,
                pse__Skills_And_Certifications_Entry__c = permControlEntry.pse__Skills_And_Certifications_Entry__c,
                pse__Skills_And_Certifications_View__c = permControlEntry.pse__Skills_And_Certifications_View__c,
                pse__Staffing__c = permControlEntry.pse__Staffing__c,
                pse__Start_Date__c = permControlEntry.pse__Start_Date__c,
                pse__Team__c = permControlEntry.pse__Team__c,
                pse__Team_Create__c = permControlEntry.pse__Team_Create__c,
                pse__Team_Edit__c = permControlEntry.pse__Team_Edit__c,
                pse__Team_View__c = permControlEntry.pse__Team_View__c,
                pse__Timecard_Entry__c = permControlEntry.pse__Timecard_Entry__c,
                pse__Timecard_Ops_Edit__c = permControlEntry.pse__Timecard_Ops_Edit__c,
                pse__View_Task_Manager__c = permControlEntry.pse__View_Task_Manager__c
            );
            System.debug('Perm Control Region =' + permcontrolCreate.get('pse__Region__c'));  

            permControlList.add(permControlCreate);
        }
        insert permControlList;
        return null;
    }
}