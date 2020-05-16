@isTest 
public class permControlControllerTest
{
    static testMethod void testMethod1() 
    {
        //Get ID of Standard User Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 

        //Create three dummy Users
        List<User> lstUser = new List<User>();

        User u1 = new User(Alias = 'demo1', Country='United States', Email='demo1@sfdcpdx.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US',
            ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='demo1@sfdcpdx.com');
        lstUser.add(u1);
        
        User u2 = new User(Alias = 'demo2', Country='United States', Email='demo2@sfdcpdx.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US',
            ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='demo2@sfdcpdx.com');
        lstUser.add(u2);

        User u3 = new User(Alias = 'demo2', Country='United States', Email='demo3@sfdcpdx.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US',
            ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='demo3@sfdcpdx.com');
        lstUser.add(u3);

        insert lstUser;
        
        //Create three dummy Contacts, associate with User records 
        List<Contact> lstContact = new List<Contact>();
    
        Contact person1 = new Contact(FirstName = 'Bob', LastName = 'Johnson', Email = 'demo1@sfdcpdx.com',
            pse__Is_Resource__c = true, pse__Is_Resource_Active__c = true, pse__Salesforce_User__c = u1.Id);
        lstContact.add(person1);

        Contact person2 = new Contact(FirstName = 'Frank', LastName = 'Shields', Email = 'demo2@sfdcpdx.com',
            pse__Is_Resource__c = true, pse__Is_Resource_Active__c = true, pse__Salesforce_User__c = u2.Id);
        lstContact.add(person2);

        Contact person3 = new Contact(FirstName = 'John', LastName = 'Smith', Email = 'demo3@sfdcpdx.com',
            pse__Is_Resource__c = true, pse__Is_Resource_Active__c = true, pse__Salesforce_User__c = u3.Id);
        lstContact.add(person3);
        
        insert lstContact;

        //Create a dummy Region and Practice to be added to Permission Controls
        pse__Region__c testRegion = new pse__Region__c(Name = 'Test Region');
        insert testRegion;

        pse__Practice__c testPractice = new pse__Practice__c(Name = 'Test Practice');
        insert testPractice;

        //Create two existing Permission Control records to test ability to compare and update existing records
        List<pse__Permission_Control__c> testPermList = new List<pse__Permission_Control__c>();

        pse__Permission_Control__c testPerm1 = new pse__Permission_Control__c(
            pse__User__c = u1.Id, pse__Region__c = testRegion.Id
            );
        testPermList.add(testPerm1);

        pse__Permission_Control__c testPerm2 = new pse__Permission_Control__c(
            pse__User__c = u2.Id, pse__Practice__c = testPractice.Id
            );
        testPermList.add(testPerm2);

        insert testPermList;

        //Instantiate page and controller extension and send StandardSetControl ID's from newly created Contacts
        Test.startTest();
        Test.setCurrentPage(Page.PSAPermControlCreationTool);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstContact);
        stdSetController.setSelected(lstContact);
        permControlController ext = new permControlController(stdSetController);

        //Set values for new Permission Control records to be created and execute creation code
        ext.permControlEntry.pse__Region__c = testregion.Id;
        ext.permControlEntry.pse__Staffing__c = true;
        ext.createPermissions();

        //Pull all Permission Controls in system associated with the three dummy Users
        List<pse__Permission_Control__c> verifyPermInsert = [
            SELECT Id 
            FROM pse__Permission_Control__c 
            WHERE pse__User__c = :u1.Id OR pse__User__c = :u2.Id OR pse__User__c = :u3.Id
            ];

        //Code should create 3 and update 1 Permission Control for above Users, so verify 4 exist
        Integer permListSize = verifyPermInsert.size();
        System.assertEquals(4, permListSize);

        Test.stopTest();
    }
}
