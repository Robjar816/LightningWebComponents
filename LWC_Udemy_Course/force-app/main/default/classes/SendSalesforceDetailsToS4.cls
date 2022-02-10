/*********************************************************************************************************************************
* Name         :  SendSalesforceDetailsToS4
* Description  :  This class used to send S4 Callout when the click send to s4 button in complaint detail page
* @author Vijay
* @date   10/08/2021
* @test class   : SendSalesforceDetailsToS4Test
* Modification Log :
* Developer                 Date                   Description
* -------------------------------------------------------------------------------------------------------------------------------                
* Vijay              10/08/2021                  Created
* Vijay              11/26/2021                  Added the return reason attribute in the complaint request body
* Ramya              11/26/2021                  Created new method (checkCodeLineItemsHasS4Product) to verify the complaint has S4 product or not.
* Vijay              12/06/2021                  New Request parameter is added in S4
* Vijay              12/13/2021                  Store the S4 error details to Error log record under complaint
*********************************************************************************************************************************/
public class SendSalesforceDetailsToS4{

    /**
    * @description This method used for to return the access token to initate the S4 callout.
    * @author Vijay | 10-18-2021
    * @return String as authToken.
    **/
    public static string generateS4AccessToken(){
        
        S4_Configuration_Service__mdt getAccessToken = S4_Configuration_Service__mdt.getInstance(Constant_AC.S4_SERVICE_COMPLAINT_NAME);
        String clientId = getAccessToken.Client_Id__c;
        String clientSecret = getAccessToken.Client_Secret__c;
        String grantType = getAccessToken.Grant_Type__c;
        String endPointURL = getAccessToken.Token_EndPoint__c;
        String authToken;
        
        Http http = new Http();
        //Generating the Access Token
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        // this is the OAuth endpoint where this request will be hit
        req.setEndpoint(endPointURL);
        req.setBody('grant_type='+grantType+'&client_id='+clientId+'&client_secret='+clientSecret);
        
        HTTPResponse res = http.send(req);
        JSONParser parser = JSON.createParser(res.getBody());
        while(parser.nextToken() !=NULL){
            if((parser.getCurrentToken() == JSONTOKEN.FIELD_NAME) && parser.getText()=='access_token'){
                parser.nextToken();
                authToken = parser.getText();
            }
        }
        return authToken;
    }
    
     /**
    * @description This method used for S4 Callout. The service is inited through button click. The button is placed in complaint detail page.
    * @author Vijay | 10-18-2021 
    * @param recordId 
    * @return Map<String, String> as a key "Record Id" for RMA Number.
    **/
    @Auraenabled
    public static Map<String,String> initateS4CalloutService(Id recordId){
    
        S4_Configuration_Service__mdt getAccessToken = S4_Configuration_Service__mdt.getInstance(Constant_AC.S4_SERVICE_COMPLAINT_NAME);
        String endPointURL = getAccessToken.S4_Service_Endpoint__c;
        String finalPopUpMsg,requestBody;
        String objectAPIName = String.valueOf(recordId.getSobjectType()); 
        if(objectAPIName != null && objectAPIName == Constant_AC.CASE_OBJ){
            system.debug('----Inside Case object condition----');
            
            Case caseRec = [SELECT Id, Order__c,CaseNumber,Ship_to_Party__c,Ship_to_Party__r.S4_BP_ID__c,Need_Material_Back__c,Sales_Org__c,
                            Division__c, Next_Activity_Field__c,Invoice_Number__c,Customer_Id__c,
                            Distribution_Channel__c,Order_Number__c,Return_Reason__c FROM Case WHERE Id =: recordId] ; 
            
            //Complaint Field Mapping
            S4IntegrationWrapper.CaseHeader caseVal = new S4IntegrationWrapper.CaseHeader();
            caseVal.Casenumber = caseRec.CaseNumber;
            caseVal.Invoice_number = caseRec.Invoice_Number__c;
            caseVal.Order_C = caseRec.Order_Number__c;
            caseVal.Return_reason = caseRec.Return_Reason__c;
            caseVal.Need_Material_Back = caseRec.Need_Material_Back__c;
            caseVal.Next_activity = caseRec.Next_Activity_Field__c;
            if(caseRec.Invoice_Number__c != null || caseRec.Order_Number__c != null){
                caseVal.Sales_org = null;
                caseVal.Distribution_channel = null;
                caseVal.Division = null;
                caseVal.Ship_to_party = null;
                caseVal.Ship_to_party = null;
            }
            else if(caseRec.Invoice_Number__c == null && caseRec.Order_Number__c == null){
                caseVal.Sales_org = caseRec.Sales_Org__c;
                caseVal.Distribution_channel = caseRec.Distribution_Channel__c;
                caseVal.Division = caseRec.Division__c;
                caseVal.Ship_to_party = caseRec.Ship_to_Party__c != null ? caseRec.Ship_to_Party__r.S4_BP_ID__c : null;
                caseVal.Sold_to_party = caseRec.Customer_Id__c;
            }
            
            List<S4IntegrationWrapper.ComplaintLineItem> clsLineItemList = new List<S4IntegrationWrapper.ComplaintLineItem>();
            for(Complaint_Line_Item__c compLineItem : [SELECT Id, Sample_Required__c, Returns_Order_Quantity__c, Line_Item_Number__c, Unit_of_Measure__c, Quantity_Affected__c,Product__c,
                                           Product__r.S4_Material_ID__c FROM Complaint_Line_Item__c WHERE Complaint__c =: recordId AND Product__r.RecordTypeId =: Constant_AC.S4_PRODUCT_RECORD_TYPE_Id]){
                //Complaint Line Item field mapping
                S4IntegrationWrapper.ComplaintLineItem compLineItemWrapper = new S4IntegrationWrapper.ComplaintLineItem();
                //compLineItemWrapper.Quantity_Rejected_c = compLineItem.Quantity_Rejected__c != null ? String.valueOf(compLineItem.Quantity_Rejected__c) : null;
                compLineItemWrapper.unit_of_measure = compLineItem.Unit_of_Measure__c ;
                compLineItemWrapper.return_quantity_credit_request_qty = String.valueOf(compLineItem.Returns_Order_Quantity__c);
                compLineItemWrapper.sample_required = String.valueOf(compLineItem.Sample_Required__c);
                if(caseRec.Invoice_Number__c != null || caseRec.Order_Number__c != null){
                    compLineItemWrapper.line_item_id =  compLineItem.Line_Item_Number__c != null ? compLineItem.Line_Item_Number__c : null;
                    compLineItemWrapper.Material = null;
                }
                else if(caseRec.Invoice_Number__c == null && caseRec.Order_Number__c == null){
                    compLineItemWrapper.line_item_id = null;
                    compLineItemWrapper.Material = compLineItem.Product__c != null ? compLineItem.Product__r.S4_Material_ID__c : null;
                }
                clsLineItemList.add(compLineItemWrapper);
            }
            
            S4IntegrationWrapper caseWrap = new S4IntegrationWrapper();
            caseWrap.Header = caseVal;
            caseWrap.Item = clsLineItemList;
            requestBody = JSON.serialize(caseWrap);
            System.debug('requestBody: '+requestBody);
        }
        
        string auth_Token = generateS4AccessToken();
        
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(endPointURL);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer '+auth_Token);
        system.debug('--requestBody--'+requestBody);
        req.setbody(requestBody);
        
        Http http = new Http();
        Map<String, String> values = new Map<String, String>();
        try{ 
            HTTPResponse response = http.send(req);
            System.debug('----Status Code---->'+response.getStatusCode());
            
            String jsonBody = response.getBody();
            system.debug('--Response Body--->'+response.getBody());
            values = (Map<String, String>)JSON.deserialize(response.getBody(), Map<String, String>.class);
            values.put('RequestBody',requestBody);
            
            String errorDetail = values.Containskey(Constant_AC.S4_ERROR) ? values.get(Constant_AC.S4_ERROR) : null;

            system.debug('---errorDetail ----'+errorDetail);
            
            if(response.getStatusCode() == 200){
                if(errorDetail != null && errorDetail != ''){
                     system.debug('---errorDetail ---->'+errorDetail);
                     throw new CustomException(response.getStatus(),errorDetail,values);
                }
            }
            else{
                throw new CustomException(response.getStatus(),response.getBody(),values);
            }        

        }
        catch(CustomException callOutCusExp) {
            throw new AuraHandledException(JSON.serialize(callOutCusExp));
        }
        catch(Exception callOutExp) {
            throw new AuraHandledException(JSON.serialize(callOutExp));
        }
        return values;
    }   
    
    /**
    * @description Used to update Error Description field in Complaints in case of exception in the callout.
    * @author Vijay | 10-18-2021 
    * @param recordId
    * @param strErrorMessage 
    **/
    @AuraEnabled
    public static void setErrorMessage(Id recordId, String strErrorMessage, Map<String,String> responseMap){
        if(recordId != null){
            String objectAPIName = String.valueOf(recordId.getSobjectType()); 
            if(objectAPIName == 'Case'){
                Error_Log__c errorLog = new Error_Log__c();
                errorLog.Complaint_Number__c = recordId;
                errorLog.Error_Description__c = strErrorMessage;
                errorLog.Request_Payload__c = responseMap != null && responseMap.containsKey('RequestBody') ? responseMap.get('RequestBody') : null;
                insert errorLog;
            }
        }
    }
    
    /**
    * @description Update the RMA Delivey number to Complaint record.
    * @author Vijay | 10-18-2021 
    * @param recordId 
    * @param RMANo
    * @param errorMessage
    **/
    @AuraEnabled
    public static void updateCaseDetails(Id recordId, Map<String, String> responseMap){
        if(recordId != null){
            system.debug('--responseMap--'+responseMap);
            String objectAPIName = String.valueOf(recordId.getSobjectType()); 
            if(objectAPIName == 'Case' && responseMap.size() > 0){
                Case caseRec = [SELECT Id,S4_Error_Description__c FROM Case WHERE Id =: recordId] ; 
                Advanced_Return_Orders__c returnRecord = new Advanced_Return_Orders__c();
                if(responseMap.Containskey(Constant_AC.S4_ADVANCED_RETURN_ORDER) && responseMap.get(Constant_AC.S4_ADVANCED_RETURN_ORDER) != null){
                   
                   returnRecord.Advanced_Return_Order_Number__c = responseMap.get(Constant_AC.S4_ADVANCED_RETURN_ORDER);
                   returnRecord.Complaint__c = recordId;
                }
                if(returnRecord != null){
                    Upsert returnRecord Advanced_Return_Order_Number__c;
                }
                if(String.isNotBlank(caseRec.S4_Error_Description__c)){
                    caseRec.S4_Error_Description__c = '';
                    update caseRec;
                }
            }
        }
    }
    /**
    * @description Use this method to access the Constant class variables in LWC.
    * @author Ramya | 10-22-2021 
    * 
    **/
    @Auraenabled(cacheable=true)
    public static Constant_AC getAllConstants() {
        return new Constant_AC();
    }
    /**
    * @description Use this method to check whether any one of the case line items has been created with S4 Product before sending data to S4.
    * @author Ramya | 11-24-2021 
    * 
    **/
    @AuraEnabled
    public static Boolean checkCodeLineItemsHasS4Product(Id recordId){
        Boolean checkStatus = false;
        
        try {
           List<Complaint_Line_Item__c> complaintLineItemListHasS4Product = [SELECT Id, Name FROM Complaint_Line_Item__c WHERE Product__r.RecordTypeId =: Constant_AC.S4_PRODUCT_RECORD_TYPE_Id  AND Complaint__c =: recordId];
            if(complaintLineItemListHasS4Product.size() > 0){
                checkStatus = true;
            }          
            System.debug('Line Items-----'+complaintLineItemListHasS4Product); 
            System.debug('Line Items   checkStatus-----'+checkStatus);  
            System.debug('Line Items   RECOID-----'+recordId);  
            System.debug('Line Items   RT ID-----'+Constant_AC.S4_PRODUCT_RECORD_TYPE_Id);        
        } 
        catch(CustomException checkStatusCusExp) {
            throw new AuraHandledException(JSON.serialize(checkStatusCusExp));
        }
        catch(Exception checkStatusExp) {
            throw new AuraHandledException(JSON.serialize(checkStatusExp));
        }
        return checkStatus;
    }
}