/*********************************************************************************************************************************
* Name         :  SendSalesforceDetailsToS4
* Description  :  Test coverage for SendSalesforceDetailsToS4.
* @author Vijay
* @date   10/08/2021
*  
* Modification Log :
* Developer                 Date                   Description
* -------------------------------------------------------------------------------------------------------------------------------                
* Vijay              10/08/2021                  Created test class
* 
*********************************************************************************************************************************/

@isTest
global class S4MockResponseGenerator implements HttpCalloutMock {
    
    HTTPRequest req;
    String objectAPIName;
    Boolean isSuccess;
    
    public S4MockResponseGenerator(String objectName,Boolean isSuccess , HTTPRequest request) {
        this.objectAPIName = objectName;
        this.req = request;
        this.isSuccess = isSuccess;
    }
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        if(objectAPIName == Constant_AC.CASE_OBJ){
            res.setHeader('Content-Type', 'application/json');
            if(isSuccess)
                res.setBody('{"Case_number":"Test 123","Advance_Return_Order_OR_Credit_Request":"60000586","Error":""}');
            else
                res.setBody('{"Case_number":"","Advance_Return_Order_OR_Credit_Request":"","Error":"Next activity is invalid"}');
            res.setStatusCode(200);
            return res;
        }
        return null;
    }
}