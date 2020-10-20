/*********************************************************************
Class Name: GGSServicesController_AC_Test
Created By: MST - Robert Jaramillo 
Created On: 09-17-2020
Description: Test class for GGSServicesController_AC_Test
*********************************************************************/
@isTest
public class GGSServicesController_AC_Test {
    
    @testSetup
    static void setup() {
        List<Account> newAccounts = new List<Account>();
        Id engagedStudentRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('02 - Engaged Student').getRecordTypeId();
        
        //Faculty and student account
        Account studentAcc = new Account(FirstName = 'Student', LastName = 'Account', Person_IRN__c = '1112223334444', 
                                         Caller_Type__c = 'STUDENT', RecordTypeId = engagedStudentRT);
        newAccounts.add(studentAcc);
        Account facultyAcc = new Account(FirstName = 'Faculty', LastName = 'Account', Person_IRN__c = '5556667778888', 
                                         Preferred_Email__pc = 'Home', Personal_Email__pc = 'test1234@email.com', RecordTypeId = engagedStudentRT);
        newAccounts.add(facultyAcc);
        insert newAccounts;
        
        //Environment Variables
        List<Environment_Variables__c> envVbl = new List<Environment_Variables__c>();
        Environment_Variables__c env1 = new Environment_Variables__c(name='PlatformEndPoint', value__c='https://st-servicegateway.apollo.edu/servicegateway/rest');
        envVbl.add(env1);
        Environment_Variables__c env2 = new Environment_Variables__c(name='ApolloPlatformCert', value__c='TEST1');
        envVbl.add(env2);
        insert envVbl;
    }
    
    static testMethod void setFieldsTest() {
        
        GGS__C ggsRec = new GGS__c();
        
        List<Account> facultyAcc = [SELECT Id, Person_IRN__c FROM account WHERE FirstName = 'Faculty'];
        List<Account> studentAcc = [SELECT Id, Person_IRN__c FROM account WHERE FirstName = 'Student'];
        
        PageReference myVfPage = Page.GGSServices_VF;
        // Populate the current page Parameters
        myVfPage.getParameters().put('irn',studentAcc[0].Person_IRN__c);
        myVfPage.getParameters().put('facultyirn',facultyAcc[0].Person_IRN__c);
        myVfPage.getParameters().put('CourseNum','123456');
        Test.setCurrentPage(myVfPage);
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(ggsRec);
        GGSServicesController_AC controller = new GGSServicesController_AC(sc);
        controller.setFields();
        controller.contentType = '.txt';
        controller.fileName = 'Test Attachment';
        controller.afile = Blob.valueOf('Hello World');
        controller.createCaseWithAttachment();
        Test.stopTest();
        
        List<Account> facultyAccUpdate = [SELECT Id, Person_IRN__c, Caller_Type__c FROM account WHERE FirstName = 'Faculty'];
        System.assertEquals('FACULTY', facultyAccUpdate[0].Caller_Type__c, 'Faculty account was not updated.');
        System.assertEquals(facultyAccUpdate[0].Person_IRN__c, controller.instructorIRN, 'Fields on controller were not updated.');
        
    }
    
    static testMethod void confirmationPageTest() {
        GGS__C ggsRec = new GGS__c();
        
        PageReference myVfPage = Page.GGSConfirmationPage_VF;
        // Populate the current page Parameters
        myVfPage.getParameters().put('recordName','TestRecord');
        Test.setCurrentPage(myVfPage);
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(ggsRec);
        GGSServicesController_AC controller = new GGSServicesController_AC(sc);
        controller.setFieldsOnConfirmation();
        Test.stopTest();
    }
        
}