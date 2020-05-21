/*
* Date: May 21, 2020
* Author: Chris Moreno
* Description: Visualforce Controller extension to handle PSAPermControlCreationTool page.
* This tool is used to mass-generate or update Permission Control records, based on selected 
* Contacts in list view.  Page launched from List button on Contact tab. Requires FinancialForce PSA.
* History: Created 5/21/2020
**/

public class permControlController {
    
    ApexPages.StandardSetController setCon;
    
    public pse__Permission_Control__c permControlEntry {get; set;}  
    List<pse__Permission_Control__c> permControlInsertList;
    List<pse__Permission_Control__c> permControlUpdateList;
    
    public permControlController(ApexPages.StandardSetController controller) {
        setCon = controller;
        permControlInsertList = new List<pse__Permission_Control__c>();
        permControlUpdateList = new List<pse__Permission_Control__c>();
        permControlEntry = new pse__Permission_Control__c();
    }

    // Below action called from Create Permissions button on PSAPermControlCreationTool page  
    public pageReference createPermissions() {
        
        // Create list of all selected Contacts
        List<Contact> selectedContacts = setCon.getselected();
        
        // Get all Salesforce User Id's for selected contacts and populate in Map 
        // Map: 'salesforceUser' format: <Contact ID, User ID>
        // Checks for both PSA Resource Salesforce User field and Community User info 
        Map<Id, Id> salesforceUsers = new Map<Id, Id>();
        for (Contact c : [SELECT Id, pse__Salesforce_User__c FROM Contact WHERE Id IN :selectedContacts]) {
            if (c.pse__Salesforce_User__c <> null) {
                salesforceUsers.put(c.Id, c.pse__Salesforce_User__c);
            }
        }
        for (User u : [SELECT Id, ContactID 
                    FROM User 
                    WHERE (ContactID IN :selectedContacts) AND (Id NOT IN :salesforceUsers.values())]) {
            salesforceUsers.put(u.ContactID, u.Id);
        }
        
        // Double check for common error of selected Contact having no User
        if (salesforceUsers.size() <> selectedContacts.size()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,
                'All selected Contacts must have a populated Salesforce User field or be a Community User'));
            return null;
        }

        // Get all existing Permission Controls for selected Contacts' Salesforce User ID's
        // Key Id is pse__User__c field instead of Permission Control record Id 
        List<Id> usrIds = salesforceUsers.values();
        Map<Id, List<pse__Permission_Control__c>> existingPermControlsMap = new Map<Id, List<pse__Permission_Control__c>>();

        for (pse__Permission_Control__c perm : [
                SELECT Id, pse__User__c, pse__Region__c, pse__Practice__c, pse__Group__c, pse__Project__c, pse__Resource__c
                FROM pse__Permission_Control__c LIMIT 50000
                ]) {
            if (existingPermControlsMap.containsKey(perm.pse__User__c)) {
                List<pse__Permission_Control__c> existingPermControls = existingPermControlsMap.get(perm.pse__User__c);
                existingPermControls.add(perm);
                existingPermControlsMap.put(perm.pse__User__c, existingPermControls);
            }
            else if (usrIds.contains(perm.pse__User__c)) {
                existingPermControlsMap.put(perm.pse__User__c, new List<pse__Permission_Control__c>{perm});
            }
        }        

        // Loop through all selected Users and create or update a Perm Control for them
        for (Id usr : salesforceUsers.values()) {
            
            // Cloning values entered in VF page into new sObject
            pse__Permission_Control__c permControlCreate = permControlEntry.clone();
            permControlCreate.put('pse__User__c', usr);
            
            // Check if any Perm Controls exist for User
            if (existingPermControlsMap.containsKey(usr)) {
                
                List<pse__Permission_Control__c> usrPermControls = new List<pse__Permission_Control__c>();
                usrPermControls = existingPermControlsMap.get(usr);
                
                // Evaluate if any existing Perm Controls for User match RPGPR of new entry
                for (Integer i = 0; i < usrPermControls.size(); i++) {
                    // If match is found, update existing to prevent creation of duplicates
                    if ( 
                            (usrPermControls[i].pse__Region__c <> null) && (usrPermControls[i].pse__Region__c == permControlCreate.pse__Region__c)||
                            (usrPermControls[i].pse__Practice__c <> null) && (usrPermControls[i].pse__Practice__c == permControlCreate.pse__Practice__c)||
                            (usrPermControls[i].pse__Group__c <> null) && (usrPermControls[i].pse__Group__c == permControlCreate.pse__Group__c)||
                            (usrPermControls[i].pse__Project__c <> null) && (usrPermControls[i].pse__Project__c == permControlCreate.pse__Project__c)||
                            (usrPermControls[i].pse__Resource__c <> null) && (usrPermControls[i].pse__Resource__c == permControlCreate.pse__Resource__c)
                            ) {
                        permControlCreate.Id = usrPermControls[i].Id;
                        permControlUpdateList.add(permControlCreate);
                        break;
                    // If no match of RPGPR, add new record to insert list
                    } else if (i == (usrPermControls.size() - 1)) {
                        permControlInsertList.add(permControlCreate);
                    }
                }
            // If no existing Perm Controls for User, add new record to insert list          
            } else {
                permControlInsertList.add(permControlCreate);
            }                
        }
        
        try {
            insert permControlInsertList;
            update permControlUpdateList;
            
            // Multiple Success message scenarios to display whether records were created and/or updated
            if (permControlInsertList.size() > 0 && permControlUpdateList.size() == 0) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,
                'Created ' + permControlInsertList.size() + ' Permission Control Records'));
            } else if ((permControlInsertList.size() == 0 && permControlUpdateList.size() > 0)) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,
                'Updated ' + permControlUpdateList.size() + ' Permission Control Records'));
            } else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,
                'Created ' + permControlInsertList.size() + ' and Updated ' + permControlUpdateList.size() + ' Permission Control Records'));
            }
        } catch (Exception ex) {
            Apexpages.addMessages(ex);
        }
        
        //clear out values to allow creation new records for same Users
        permControlInsertList.clear();
        permControlUpdateList.clear();
        permControlEntry.clear();

        return null;
    }
}