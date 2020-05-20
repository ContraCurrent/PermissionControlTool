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

    //Below action called from Create Permissions button on PSAPermControlCreationTool page  
    public pageReference createPermissions()
    {
        //Create list of all selected Contacts
        List<Contact> selectedContacts = setCon.getselected();
        
        /* Get all Salesforce User Id's for selected contacts and populate in Map 
        * salesforceUser Map format: Contact ID, User ID
        * Checks for both PSA Resource Salesforce User field and Community User info */
        Map<Id, Id> salesforceUsers = new Map<Id, Id>();
        for (Contact c : [SELECT Id, pse__Salesforce_User__c FROM Contact WHERE Id IN :selectedContacts])
        {
            if (c.pse__Salesforce_User__c <> null)
            {
                salesforceUsers.put(c.Id, c.pse__Salesforce_User__c);
            }
        }
        for (User u : [SELECT Id, ContactID FROM User WHERE (ContactID IN :selectedContacts) AND (Id NOT IN :salesforceUsers.values())])
        {
            salesforceUsers.put(u.ContactID, u.Id);
        }
        System.debug('Number of User ID\'s found: ' + salesforceUsers.size());
        
        //Double check for common error of selected Contact having no User
        if (salesforceUsers.size() <> selectedContacts.size())
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,
                'All selected Contacts must have a populated Salesforce User field or be a Community User'));
            return null;
        }
        System.debug('All Contacts found to have associated User');

        /* Get all existing Permission Controls for selected Contacts' Salesforce User ID's
        * Key Id is pse__User__c field instead of Permission Control record Id */
        List<Id> usrIds = salesforceUsers.values();
        Map<Id, List<pse__Permission_Control__c>> existingPermControlsMap = new Map<Id, List<pse__Permission_Control__c>>();
        List<pse__Permission_Control__c> existingPermControls = new List<pse__Permission_Control__c>();

        for (pse__Permission_Control__c perm : [
            SELECT Id, pse__User__c, pse__Region__c, pse__Practice__c, pse__Group__c, pse__Project__c, pse__Resource__c
            FROM pse__Permission_Control__c LIMIT 50000
            ])
        {
            if (existingPermControlsMap.containsKey(perm.pse__User__c))
            {
                List<pse__Permission_Control__c> existingPermControlsAdd = existingPermControlsMap.get(perm.pse__User__c);
                existingPermControlsAdd.add(perm);
                existingPermControlsMap.put(perm.pse__User__c, existingPermControlsAdd);
                System.debug('Added permControl to values list for existing key');
            }
            else if (usrIds.contains(perm.pse__User__c))
            {
                List<pse__Permission_Control__c> existingPermControlsNew = new List<pse__Permission_Control__c>();
                existingPermControlsNew.add(perm);
                existingPermControlsMap.put(perm.pse__User__c, existingPermControlsNew);
                System.debug('created permControl values list for new key');
            }
        }        
        System.debug('Number of Users Permission Controls found for: ' + existingPermControlsMap.size());

        //Loop through all selected Users and create or update a Perm Control for them
        for (Id usr : salesforceUsers.values())
        {
            System.debug('Salesforce User = ' + usr);
            pse__Permission_Control__c permControlCreate = new pse__Permission_Control__c
            (
                pse__User__c = usr,
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
            
            System.debug('Map contains values for user in key ' + existingPermControlsMap.containsKey(usr));

            List<pse__Permission_Control__c> usrPermControls = new List<pse__Permission_Control__c>();
            usrPermControls = existingPermControlsMap.get(usr);

            System.debug('Number Existing PermControls found for User: ' + usrPermControls.size());
            
            //Check if any Perm Controls match User plus RPGPR combination. Update if so, Insert if not
            if (usrPermControls.size()>0)
            {
                //Loop through all existing to check if an update is possible before defaulting to insert   
                for (Integer i = 0; i < usrPermControls.size(); i++)
                {
                    if( 
                    (usrPermControls[i].pse__Region__c <> null) && (usrPermControls[i].pse__Region__c == permControlCreate.pse__Region__c)||
                    (usrPermControls[i].pse__Practice__c <> null) && (usrPermControls[i].pse__Practice__c == permControlCreate.pse__Practice__c)||
                    (usrPermControls[i].pse__Group__c <> null) && (usrPermControls[i].pse__Group__c == permControlCreate.pse__Group__c)||
                    (usrPermControls[i].pse__Project__c <> null) && (usrPermControls[i].pse__Project__c == permControlCreate.pse__Project__c)||
                    (usrPermControls[i].pse__Resource__c <> null) && (usrPermControls[i].pse__Resource__c == permControlCreate.pse__Resource__c))
                    {
                        permControlCreate.Id = usrPermControls[i].Id;
                        permControlUpdateList.add(permControlCreate);
                        System.debug('Added to Update List');
                        break;
                    }
                    else if (i == (usrPermControls.size() - 1))
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

        
        try 
        {
            insert permControlInsertList;
            update permControlUpdateList;

            if (permControlInsertList.size() > 0 && permControlUpdateList.size() == 0)
            {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,
                'Created ' + permControlInsertList.size() + ' Permission Control Records'));
            }
            else if ((permControlInsertList.size() == 0 && permControlUpdateList.size() > 0))
            {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,
                'Updated ' + permControlUpdateList.size() + ' Permission Control Records'));
            }
            else 
            {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,
                'Created ' + permControlInsertList.size() + ' and Updated ' + permControlUpdateList.size() + ' Permission Control Records'));
            }
        } 
        catch (Exception ex) 
        {
            Apexpages.addMessages(ex);
        }
        
        //clear out values to create new records for same Users
        permControlInsertList.clear();
        permControlUpdateList.clear();
        permControlEntry.clear();

        return null;
    }
}