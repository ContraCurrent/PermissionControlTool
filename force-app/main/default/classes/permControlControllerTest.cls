/*
* Date: May 21, 2020
* Author: Chris Moreno
* Description: Test permControlController Visualforce Controller extension 
* which handles PSAPermControlCreationTool page.
* History: Created 5/21/2020
**/

@isTest 
public class permControlControllerTest
{
    @TestSetup
    static void setup()
    {
        // Start test and call to insertUser @future method to create first 100 standard users
        Test.startTest();
        
        insertUser();

        // Stop test here to force syncronous creation of Users, so they are all available now
        Test.stopTest();

        // Contact creation block, includes create account, and associating some Contacts with User
        Account mainAccount = new Account(Name = 'Main Account');
        insert mainAccount;

        List<Contact> lstContacts = new List<Contact>();
        List<User> sfdcUsrs = [SELECT Id FROM User];

        for (Integer i = 0; i < 200; i++) {
            Contact c = new Contact();
            c.FirstName                  = 'Jules';
            c.LastName                   = 'Vincent' + i;
            c.Email                      = 'jvincent@jrslims.com.invalid';
            c.pse__Is_Resource__c        = true;
            c.pse__Is_Resource_Active__c = true;
            c.AccountId                  = mainAccount.Id;
            c.pse__Salesforce_User__c    = sfdcUsrs.get(i).Id;
            lstContacts.add(c);
        }
        insert lstContacts;

        //Create a dummy Region and Practice to be added to Permission Controls
        pse__Region__c testRegion = new pse__Region__c(Name = 'Test Region');
        insert testRegion;

        pse__Practice__c testPractice = new pse__Practice__c(Name = 'Test Practice');
        insert testPractice;

        //Create existing Permission Control records to test ability to compare and update existing records
        List<pse__Permission_Control__c> testPermList = new List<pse__Permission_Control__c>();
        List<User> permUsers = [SELECT Id FROM User WHERE FirstName = 'Jules' LIMIT 10];

        for (User u : permUsers){
            pse__Permission_Control__c perm = new pse__Permission_Control__c();
            perm.pse__User__c = u.Id;
            perm.pse__Region__c = testRegion.Id;
            perm.pse__Timecard_Entry__c = true;
            testPermList.add(perm);
        }
        insert testPermList;
    }

    @IsTest
    static void testSuccessUpdateInsert() 
    {
        // Instantiate page and controller extension and send StandardSetControl ID's from newly created Contacts
        Test.startTest();
        
        // Select all newly created Contacts to be brought into controller
        List<Contact> lstContact = [SELECT Id FROM Contact];
        pse__Region__c testregion = [SELECT Id FROM pse__Region__c];
    
        Test.setCurrentPage(Page.PSAPermControlCreationTool);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstContact);
        stdSetController.setSelected(lstContact);
        permControlController ext = new permControlController(stdSetController);


        // Set values for new Permission Control records to be created and execute creation code
        ext.permControlEntry.pse__Region__c = testregion.Id;
        ext.permControlEntry.pse__Staffing__c = true;
        ext.createPermissions();

        // Pull all Permission Controls in system
        List<pse__Permission_Control__c> verifyPermCount = [
            SELECT Id 
            FROM pse__Permission_Control__c 
            ];

        // Verify amount of Permission Controls
        // TestSetup containted 10 total, all for Region
        // This method grants permission for 200 Users, all for Region
        // So should have 190 created, 10 updated = 200
        Integer permListSize = verifyPermCount.size();
        System.assertEquals(200, permListSize);

        // Checking for expected success message in pageMessages
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());

        Boolean messageFound = false;

        for (ApexPages.Message message : pageMessages) {
            if (message.getSummary() == 'Created 190 and Updated 10 Permission Control Records'
                && message.getSeverity() == ApexPages.Severity.CONFIRM) {
                messageFound = true;        
            }
        }
        System.assert(messageFound);

        Test.stopTest();
    }

    @IsTest
    static void testSuccessInsertOnly() 
    {
        //Instantiate page and controller extension and send StandardSetControl ID's from newly created Contacts
        Test.startTest();
        
        // Select all newly created Contacts to be brought into controller
        List<Contact> lstContact = [SELECT Id FROM Contact];
        pse__Practice__c testPractice = [SELECT Id FROM pse__Practice__c];
    
        Test.setCurrentPage(Page.PSAPermControlCreationTool);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstContact);
        stdSetController.setSelected(lstContact);
        permControlController ext = new permControlController(stdSetController);

        // Set values for new Permission Control records to be created and execute creation code
        ext.permControlEntry.pse__Practice__c = testPractice.Id;
        ext.permControlEntry.pse__Staffing__c = true;
        ext.createPermissions();

        // Pull all Permission Controls in system
        List<pse__Permission_Control__c> verifyPermCount = [
            SELECT Id 
            FROM pse__Permission_Control__c 
            ];

        // Verify amount of Permission Controls
        // TestSetup containted 10 total, all for Region
        // This method grants permission for 200 Users, all for Practice
        // So should have 200 created, 10 existing = 210
        Integer permListSize = verifyPermCount.size();
        System.assertEquals(210, permListSize);

        // Checking for expected success message in pageMessages
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        Boolean messageFound = false;

        for (ApexPages.Message message : pageMessages) {
            if (message.getSummary() == 'Created 200 Permission Control Records'
                && message.getSeverity() == ApexPages.Severity.CONFIRM) {
                messageFound = true;        
            }
        }
        System.assert(messageFound);

        Test.stopTest();
    }
    
    @IsTest
    static void testSuccessUpdateOnly() 
    {
        // Instantiate page and controller extension and send StandardSetControl ID's from newly created Contacts
        Test.startTest();
        
        // Use existing Permission Controls to pull list of all Contacts who already have Permission Controls
        List<Id> lstUserId = new List<Id>();
        for (pse__Permission_Control__c currentPerm : [SELECT Id, pse__User__c FROM pse__Permission_Control__c]) {
            lstUserId.add(currentPerm.pse__User__c);
        }
        
        List<Contact> lstContact = [SELECT Id, pse__Salesforce_User__c 
                                    FROM Contact 
                                    WHERE pse__Salesforce_User__c 
                                    IN :lstUserId];

        pse__Region__c testRegion = [SELECT Id FROM pse__Region__c];
    
        Test.setCurrentPage(Page.PSAPermControlCreationTool);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstContact);
        stdSetController.setSelected(lstContact);
        permControlController ext = new permControlController(stdSetController);


        // Set values for new Permission Control records to be created and execute creation code
        ext.permControlEntry.pse__Region__c = testRegion.Id;
        ext.permControlEntry.pse__Staffing__c = true;
        ext.createPermissions();

        // Pull all Permission Controls in system
        List<pse__Permission_Control__c> verifyPermCount = [
            SELECT Id 
            FROM pse__Permission_Control__c 
            ];

        // Verify amount of Permission Controls
        // TestSetup containted 10 total, all for Region
        // This method grants permission for the same 10 Users, so no new ones created
        Integer permListSize = verifyPermCount.size();
        System.assertEquals(10, permListSize);

        // Checking for expected success message in pageMessages
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        Boolean messageFound = false;

        for (ApexPages.Message message : pageMessages) {
            if (message.getSummary() == 'Updated 10 Permission Control Records'
                && message.getSeverity() == ApexPages.Severity.CONFIRM) {
                messageFound = true;        
            }
        }
        System.assert(messageFound);

        Test.stopTest();
    }

    @IsTest
    static void testError1() 
    {
        //Instantiate page and controller extension and send StandardSetControl ID's from newly created Contacts
        Test.startTest();

        // Select all newly created Contacts to be brought into controller 
        List<Contact> lstContact = [SELECT Id FROM Contact];
        // Add new Contact designed to cause failure and show error
        Contact nonResource = new Contact(FirstName = 'NonResource', LastName = 'Bob', Email = 'bob@jrslims.com.invalid');

        lstContact.add(nonResource);

        pse__Region__c testRegion = [SELECT Id FROM pse__Region__c];
    
        Test.setCurrentPage(Page.PSAPermControlCreationTool);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstContact);
        stdSetController.setSelected(lstContact);
        permControlController ext = new permControlController(stdSetController);

        // Set values for new Permission Control records to be created and execute creation code
        ext.permControlEntry.pse__Region__c = testRegion.Id;
        ext.permControlEntry.pse__Staffing__c = true;
        
        // Verify that correct error message is shown
        try {
            ext.createPermissions();
        } catch (Exception error) {
            System.assert(error.getMessage().contains('must have a populated Salesforce User field'));
        }
        Test.stopTest();
    }

    // Method is called in @TestSetup to create Users in separate method from Contacts
    // Prevents "Mixed DML" error
    @future
    public static void insertUser(){

        Profile Profile = [SELECT Id FROM Profile WHERE Name='Standard User']; 

        List<User> lstUsers = new List<User>();
        for (Integer i = 0; i < 200; i++) {
            User u = new User();
            u.FirstName         = 'Jules';
            u.LastName          = 'Vincent' + i;
            u.Email             = 'jvincent@jrslims.com.invalid';
            u.Alias             = 'jvin' + i;
            u.Username          = 'jvin' + i + '@jrslims.com';
            u.LocaleSidKey      = 'en_US';
            u.TimeZoneSidKey    = 'GMT';
            u.IsActive          = false;
            u.ProfileID         = Profile.Id;
            u.LanguageLocaleKey = 'en_US';
            u.EmailEncodingKey  = 'UTF-8';
            lstUsers.add(u);
        }
        insert lstUsers;    

        System.debug('Number of Users created: ' + lstUsers.size());
    }
}
