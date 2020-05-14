public class permControlController{
    
    ApexPages.StandardSetController setCon;
    
    public pse__Permission_Control__c permControlEntry {get; set;}  
    List<pse__Permission_Control__c> permControlInsertList;
    List<pse__Permission_Control__c> permControlUpdateList;
    
    public permControlController(ApexPages.StandardSetController controller)
    {
        setCon = controller;
        permControlInsertList = new List<pse__Permission_Control__c>();
        permControlUpdateList = new List<pse__Permission_Control__c>();
        permControlEntry = new pse__Permission_Control__c();
    }

    public pageReference createPermissions()
    {
        //Below action called from Create Permissions button        
        //Loop through all selected Contacts and create or update Perm Control for their SFDC User
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

            //Create list of existing Perm Controls for current selected User
            List<pse__Permission_Control__c> existingPermControls = [
                SELECT Id, pse__User__c, pse__Region__c, pse__Practice__c, pse__Group__c, pse__Project__c, pse__Resource__c
                FROM pse__Permission_Control__c
                WHERE pse__User__c = :con.pse__Salesforce_User__c
                ];
            
            System.debug('Number Existing PermControls for ' + con.Name + ' found: ' + existingPermControls.size());
            
            //Check if any Perm Controls match User plus RPGPR combination. Update if so, Insert if not
            if (existingPermControls.size()>0)
            {
                //Loop through all existing to check if an update is possible before defaulting to insert
                for (Integer i = 0; i < existingPermControls.size(); i++)
                {
                    if (
                    (existingPermControls[i].pse__User__c == con.pse__Salesforce_User__c) && (existingPermControls[i].pse__Region__c <> null) && (existingPermControls[i].pse__Region__c == permControlCreate.pse__Region__c)||
                    (existingPermControls[i].pse__User__c == con.pse__Salesforce_User__c) && (existingPermControls[i].pse__Practice__c <> null) && (existingPermControls[i].pse__Practice__c == permControlCreate.pse__Practice__c)||
                    (existingPermControls[i].pse__User__c == con.pse__Salesforce_User__c) && (existingPermControls[i].pse__Group__c <> null) && (existingPermControls[i].pse__Group__c == permControlCreate.pse__Group__c)||
                    (existingPermControls[i].pse__User__c == con.pse__Salesforce_User__c) && (existingPermControls[i].pse__Project__c <> null) && (existingPermControls[i].pse__Project__c == permControlCreate.pse__Project__c)||
                    (existingPermControls[i].pse__User__c == con.pse__Salesforce_User__c) && (existingPermControls[i].pse__Resource__c <> null) && (existingPermControls[i].pse__Resource__c == permControlCreate.pse__Resource__c))
                    {
                        permControlCreate.Id = existingPermControls[i].Id;
                        permControlUpdateList.add(permControlCreate);
                        System.debug('Added to Update List');
                        break;
                    }
                    else if (i == (existingPermControls.size() - 1))
                    {
                        permControlInsertList.add(permControlCreate);
                        System.debug('Added to Insert List');
                    }
                }
            }   
            else 
            {
                permControlInsertList.add(permControlCreate);
                System.debug('Added to Insert List');
            }
                       
        }
        System.debug('PermControlInsert List Size ' + permControlInsertList.size());
        System.debug('PermControlUpdate List Size ' + permControlUpdateList.size());

        insert permControlInsertList;
        update permControlUpdateList;

        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,
        'Created ' + permControlInsertList.size() + ' and Updated ' + permControlUpdateList.size() + ' Permission Control Records')); 

        //clear out values to create new records for same Users
        permControlInsertList.clear();
        permControlUpdateList.clear();
        permControlEntry.clear();
        
        return null;
    }
}