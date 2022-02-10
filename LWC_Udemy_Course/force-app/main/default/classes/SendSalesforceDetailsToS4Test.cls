/**

/*********************************************************************************************************************************
* Name         :  SendSalesforceDetailsToS4
* Description  :  Test class
* @author Vijay
* @date   10/08/2021
* Modification Log :
* Developer                 Date                   Description
* -------------------------------------------------------------------------------------------------------------------------------                
* Vijay              10/08/2021                  Created
* Vijay              11/26/2021                  Added new test method to verify return reason logic
* Vijay              12/06/2021                  New Parameter is added in S4 Callout
*********************************************************************************************************************************/
@isTest
public class SendSalesforceDetailsToS4Test{
    
    @testSetup
    static void setup(){
        
        //Insert Account with required details
        Account acc = new Account(Name = 'TestAccount',S4_BP_ID__c = '10000011');
        insert acc;
        
        //Insert Contact.Need to replace with your required fields
        Contact con = new Contact(FirstName= 'GCS', RecordTypeId = RecordTypeFactory.getRecordTypeByName(Contact.sObjectType, 'Web User Contact').getRecordTypeId(),LastName='Dummy', AccountId = acc.Id);
        insert con;
        
        // Need to replace the name of your record type
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        
        //Insert Case.Need to replace with your required fields
        Case complaintRec = new Case(AccountId = acc.Id, ContactId = con.Id, Type = 'Sales', Status = 'New', 
                                     Description = 'This is a test', 
                                     RecordTypeId = recordTypeId,Ship_to_Party__c = acc.Id,
                                     Division__c='02',Next_Activity_Field__c='Advanced Return Order');
        insert complaintRec;
        
        Product2 prodRec = new Product2();
        prodRec.Name = 'Test Product';
        prodRec.Description='Test Product';
        prodRec.productCode = 'ABC';
        prodRec.isActive = true;
        prodRec.RecordTypeId = Constant_AC.S4_PRODUCT_RECORD_TYPE_Id;
        insert prodRec;
        
        Complaint_Line_Item__c cLineItem = new Complaint_Line_Item__c(Complaint__c = complaintRec.Id, Quantity_Affected__c = 20.0,Line_Item_Number__c = '60', Product__c = prodRec.Id);
        insert cLineItem;
        
    }
    
    @isTest public static void testSendSuccessComplaints() {
        
        S4_Configuration_Service__mdt getAccessToken = S4_Configuration_Service__mdt.getInstance('S4_SFDC_Complaints_Service');
        String endPointURL = getAccessToken.Token_EndPoint__c;
        
        Test.startTest();
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('endPointURL');
        request.setMethod('POST');
        request.setHeader('content-type', 'application/json');
        
        request.setBody('{"Item":[{"unit_of_measure":"Square Inch (Sq.In)","Quantity_Rejected_c":60.0,"Part_number":"786446","Order_number":"O24234343","Material":"60000589","line_item_id":50,"Line_Item_disposition":"Accepted","Invoice_number":"INV5454543"},{"unit_of_measure":"Square Foot (Sq.F)","Quantity_Rejected_c":20.0,"Part_number":"9899","Order_number":"O98755","Material":"60000589","line_item_id":60,"Line_Item_disposition":"Rejected","Invoice_number":"INV5454545"}],"Header":{"Sold_to_party":"60000588","Ship_to_party":"60000586","Sales_org":"3000 - Europe HQ - Belgium Sales Org.","Returns_Delivery_number":"60000703","Order_C":"110","Next_activity":"Credit memo request","Need_Material_Back":"No","Division":"03 - ECD","Distribution_channel":"10 - Direct","Complaint_reason":"Admin Request","Casenumber":"00016544"}}');
        Test.setMock(HttpCalloutMock.class, new S4MockResponseGenerator('Case', True, request));
        S4MockResponseGenerator mockRe = new S4MockResponseGenerator('Case', True, request);
        HttpResponse res = mockRe.Respond(request);
        SendSalesforceDetailsToS4.initateS4CalloutService(caseRec.Id);
        
        Map<String, String> values = (Map<String, String>)JSON.deserialize(res.getBody(), Map<String, String>.class);
        System.assert(values.get('Error') == '','Please check the Error in response');
        System.assert(values.get('Advance_Return_Order_OR_Credit_Request') == '60000586','Please check advance Return Order in Response');
        System.assertEquals(200, res.getStatusCode(),'Please check Request Status in S4');
        
        SendSalesforceDetailsToS4.updateCaseDetails(caseRec.Id, values);
        Test.stopTest();
    }
    
    @isTest public static void testGetFailedComplaints() {
        
        S4_Configuration_Service__mdt getAccessToken = S4_Configuration_Service__mdt.getInstance('S4_SFDC_Complaints_Service');
        String endPointURL = getAccessToken.S4_Service_Endpoint__c;
        
        Test.startTest();
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
        caseRec.Invoice_Number__c = '242343';
        update caseRec;
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('endPointURL');
        request.setMethod('POST');
        request.setHeader('content-type', 'application/json');
        
        request.setBody('{"Item":[{"unit_of_measure":"Square Inch (Sq.In)","sample_required":"No","Material":"60000589","line_item_id":50,"return_quantity_credit_request_qty":"12"},{"unit_of_measure":"Square Foot (Sq.F)","sample_required":"No","Material":"60000589","line_item_id":60,"return_quantity_credit_request_qty":"12"}],"Header":{"Sold_to_party":"60000588","Ship_to_party":"60000586","Sales_org":"3000 - Europe HQ - Belgium Sales Org.","Returns_Delivery_number":"60000703","Order_C":"110","Next_activity":"Credit memo request","Need_Material_Back":"No","Division":"03 - ECD","Distribution_channel":"10 - Direct","Complaint_reason":"Admin Request","Casenumber":"00016544"}}');
        Test.setMock(HttpCalloutMock.class, new S4MockResponseGenerator('Case', false, request));
        S4MockResponseGenerator mockRe = new S4MockResponseGenerator('Case', false, request);
        HttpResponse res = mockRe.Respond(request);
        try{
            SendSalesforceDetailsToS4.initateS4CalloutService(caseRec.Id);
        }catch(Exception callOutExp){
            System.debug('callOutExp--> '+callOutExp.getCause());
        }
        Map<String, String> values = (Map<String, String>)JSON.deserialize(res.getBody(), Map<String, String>.class);
        System.assert(values.get('Error') == 'Next activity is invalid','Please check Error field in Response');
        System.assert(values.get('Advance_Return_Order_OR_Credit_Request')== '','Please check the S4 response');
        
        SendSalesforceDetailsToS4.setErrorMessage(caseRec.Id, values.get('Error'), null);
        CustomException exp = new CustomException(caseRec.Id, values.get('Error'),null);
        Test.stopTest();
    }
    
     @isTest public static void testVerifyWrapper() {
         S4IntegrationWrapper.CaseHeader caseVal = new S4IntegrationWrapper.CaseHeader();
         caseVal.Casenumber = '35353';
         caseVal.Division = 'Test';
         caseVal.Need_Material_Back = 'Yes';
         
         S4IntegrationWrapper.ComplaintLineItem litemWrap = new S4IntegrationWrapper.ComplaintLineItem();
         litemWrap.return_quantity_credit_request_qty = 'Test';
         
         S4IntegrationWrapper.wrapMethod();
         
     }
     
     @isTest public static void testcheckCodeLineItemsHasS4Product() {
         S4IntegrationWrapper.CaseHeader caseVal = new S4IntegrationWrapper.CaseHeader();
         caseVal.Casenumber = '35353';
         caseVal.Invoice_number = '90000293';
         caseVal.Need_Material_Back = 'Yes';
         
          Case caseRec = [SELECT Id FROM Case LIMIT 1];
          SendSalesforceDetailsToS4.getAllConstants();
          Boolean checkStatus = SendSalesforceDetailsToS4.checkCodeLineItemsHasS4Product(caseRec.Id);
          system.assertEquals(True, checkStatus);
     }
}