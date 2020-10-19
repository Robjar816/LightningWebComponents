public with sharing class ServiceUtility_AC {
	//process request and log and throw any invalid response
	public static String processRequest(HttpMethod method, String endpoint, String body, String certificateName, boolean isCompressed, Map<String, String> headerValues, boolean maskLog) {
		HttpRequest request = new HttpRequest();
		Http http = new Http();
		
		request.setMethod(getMethodValue(method));
		request.setEndpoint(endpoint);		
		if (body.trim() != '') {
			request.setBody(body);
		}
		if (certificateName.trim() != '') {
			request.setClientCertificateName(certificateName);
		}
		request.setCompressed(isCompressed);
		if (headerValues != null && !headerValues.isEmpty()) {
			for (String name: headerValues.keySet()) {
				request.setHeader(name, headerValues.get(name));
			}
		}
		
		HttpResponse response = new HttpResponse();
		if(Test.isRunningTest()){
			response = generateMockResponse();
		}
		else{
			request.setTimeout(Integer.valueOf(Environment_Variables__c.getInstance('PlatformCalloutTimeoutLimit').Value__c));
			response = http.send(request);
		}
		//adding below if condition and debug for troubleshooting. This will capture response from service when internal server error occurs on service side.
		//isValidResponse skips any other status code except 200
		if(response != null && !maskLog){
			system.debug('ServiceUtility_AC :processRequest: response = '+response.getBody());
		}
		if (isValidResponse(response) && !maskLog) {
			system.debug('ServiceUtility_AC :processRequest: response = '+response.getBody());
			return response.getBody();
		} else {
			throw new ServiceUtilityException('Error processing request for endpoint: ' + endpoint + 
				' response status: ' + response.getStatus() + ' response code: ' + response.getStatusCode());
		}
	}

	public static String processRequest(HttpMethod method, String endpoint, String body, String certificateName, boolean isCompressed, Map<String, String> headerValues) {
		return processRequest(method, endpoint, body, certificateName, isCompressed, headerValues, false);
	}
	
	public static String processRequest(HttpMethod method, String endpoint, String body, String certificateName) {
		return processRequest(method, endpoint, body, certificateName, false, null);
	}		
	
	public static String processRequest(HttpMethod method, String endpoint, String certificateName) {
		return processRequest(method, endpoint, '', certificateName, false, null);
	}
	
	public static String processRequest(HttpMethod method, String endpoint, String body, Map<String, String> headerValues) {
		return processRequest(method, endpoint, body, '', false, headerValues);
	}
	
	public static String processRequest(HttpMethod method, String endpoint, String body, String certificateName, Map<String, String> headerValues) {
		return processRequest(method, endpoint, body, certificateName, false, headerValues);
	}

	public static String processRequest(HttpMethod method, String endpoint, String body, String certificateName, Map<String, String> headerValues, boolean maskLog) {
		return processRequest(method, endpoint, body, certificateName, false, headerValues, maskLog);
	}
	
	//send request but return response to handle any custom erro messages
	public static HttpResponse sendRequest(HttpMethod method, String endpoint, String body, String certificateName, boolean isCompressed, Map<String, String> headerValues) {
		HttpRequest request = new HttpRequest();
		Http http = new Http();
		
		request.setMethod(getMethodValue(method));
		request.setEndpoint(endpoint);
		if (body.trim() != '') {
			request.setBody(body);
		}
		if (certificateName.trim() != '') {
			request.setClientCertificateName(certificateName);
		}
		request.setCompressed(isCompressed);
		if (headerValues != null && !headerValues.isEmpty()) {
			for (String name: headerValues.keySet()) {
				request.setHeader(name, headerValues.get(name));
			}
		}
		
		HttpResponse response = new HttpResponse();
		if(Test.isRunningTest()){
			response = generateMockResponse();
		}
		else{
			response = http.send(request);
		}
		return response;
	}
	
	public static HttpResponse sendRequest(HttpMethod method, String endpoint, String body, String certificateName) {
		return sendRequest(method, endpoint, body, certificateName, false, null);
	}		
	
	public static HttpResponse sendRequest(HttpMethod method, String endpoint, String certificateName) {
		return sendRequest(method, endpoint, '', certificateName, false, null);
	}
	
	public static HttpResponse sendRequest(HttpMethod method, String endpoint, String body, Map<String, String> headerValues) {
		return sendRequest(method, endpoint, body, '', false, headerValues);
	}
	
	public static HttpResponse sendRequest(HttpMethod method, String endpoint, String body, String certificateName, Map<String, String> headerValues) {
		return sendRequest(method, endpoint, body, certificateName, false, headerValues);
	}
	
	private static String getMethodValue(HttpMethod method) {
		if (method == HttpMethod.GET) {
			return GET_VALUE;
		} else if (method == HttpMethod.POST) {
			return POST_VALUE;
		} else if (method == HttpMethod.PUT) {
			return PUT_VALUE;
		} else if (method == HttpMethod.REMOVE) {
			return DELETE_VALUE;
		} else {
			throw new ServiceUtilityException('Unknown method passed to ServiceUtility.');
		}
	}
	
	public static Boolean isValidResponse(HttpResponse response) {
		Boolean isValid = false;
		if (response.getStatus() == STATUS_OK && response.getStatusCode() == STATUS_CODE_OK) {
			isValid = true;
		} else if (response.getStatus() == STATUS_CREATED && response.getStatusCode() == STATUS_CODE_CREATED) {
			isValid = true;
		}  else if (response.getStatus() == STATUS_ACCEPTED && response.getStatusCode() == STATUS_CODE_ACCEPTED) {
			isValid = true;
		}
		
		return isValid;
	}
	
	public class ServiceUtilityException extends Exception { }
	
	private static final String GET_VALUE = 'GET'; 
	private static final String POST_VALUE = 'POST';
	private static final String PUT_VALUE = 'PUT';
	private static final String DELETE_VALUE = 'DELETE';
	
	public static final String STATUS_OK = 'OK';
	public static final Integer STATUS_CODE_OK = 200;
	public static final String STATUS_CREATED = 'CREATED';
	public static final Integer STATUS_CODE_CREATED = 201;
	public static final String STATUS_ACCEPTED = 'ACCEPTED';
	public static final Integer STATUS_CODE_ACCEPTED = 202;
	public static final String STATUS_INTERNAL_SERVER_ERROR = 'Internal Server Error';
	public static final Integer STATUS_CODE_INTERNAL_SERVER_ERROR = 500;
	
	public enum HttpMethod { GET, POST, PUT, REMOVE }//DELETE is a reserved keyword
	
	public static HttpResponse generateMockResponse(){
    	HttpResponse response = new HttpResponse();
        response.setStatus(STATUS_OK);
        response.setStatusCode(STATUS_CODE_OK);
        response.setBody('TEST');
    	return response;
    }
	
	private static testMethod void test() {
        string endPointVar = '';
        string platformCertificate  = '';
        if(Environment_Variables__c.getInstance('ERPEndPoint')!=null){
            endPointVar = Environment_Variables__c.getInstance('ERPEndPoint').Value__c;
        }
        if(Environment_Variables__c.getInstance('ERPSTPlatformCert')!= null){
            platformCertificate  = Environment_Variables__c.getInstance('ERPSTPlatformCert').Value__c;
        }
        string endPoint = endpointVar;
        string certificateName = platformCertificate;
        HttpResponse response = new HttpResponse();
        response.setStatus(STATUS_OK);
        response.setStatusCode(STATUS_CODE_OK);        
        Boolean result = ServiceUtility_AC.isValidResponse(response);
        
        response.setStatus(STATUS_CREATED);
        response.setStatusCode(STATUS_CODE_CREATED);        
        result = ServiceUtility_AC.isValidResponse(response);
        
        response.setStatus(STATUS_ACCEPTED);
        response.setStatusCode(STATUS_CODE_ACCEPTED);        
        result = ServiceUtility_AC.isValidResponse(response);
        
        String sResult = ServiceUtility_AC.getMethodValue(HttpMethod.GET);
        sResult = ServiceUtility_AC.getMethodValue(HttpMethod.POST);
        sResult = ServiceUtility_AC.getMethodValue(HttpMethod.PUT);
        sResult = ServiceUtility_AC.getMethodValue(HttpMethod.REMOVE);
        try{
            sResult = ServiceUtility_AC.getMethodValue(null);
        }
        catch(Exception e){
            System.assertEquals('Unknown method passed to ServiceUtility.', e.getMessage());
        
        }
        String body = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ';
        body += 'xmlns:v1="http://asb.apollogrp.edu/ASBService/base/ApolloHeader/v1" ';
        body += 'xmlns:v11="http://asb.apollogrp.edu/ASBService/base/NameValuePair/v1" ';
        body += 'xmlns:tok="http://asb.apollogrp.edu/ASBService/service/Horizontal/Account/v1/TokenService" ';
        body += 'xmlns:v12="http://asb.apollogrp.edu/ASBService/model/Horizontal/Account/v1">';
        body += '<soapenv:Header/>';
        body += '<soapenv:Body>';
        body += '<tok:generateTokenRequest>';
        body += '<v12:tokenGenerateData>';
        body += '<v12:tokenHeaderData>';
        body += '<v12:invitationType>MYAPPLY_REGISTRATION</v12:invitationType>';
        body += '<v12:IRN>'+'1234'+'</v12:IRN>';
        body += '<v12:profileID></v12:profileID><v12:requestorLogin>'+'testAlias'+'</v12:requestorLogin>';
        body += '<v12:activeHours>'+'1234'+'</v12:activeHours>';
        body += '</v12:tokenHeaderData>';
        body += '<v12:tokenCommunicationData>';
        body += '<v12:recipientFirstName>'+'John'+'</v12:recipientFirstName>';
        body += '<v12:recipientLastName>'+'Done'+'</v12:recipientLastName>';
        body += '<v12:recipientEmail>'+'test1@gmail.com'+'</v12:recipientEmail>';
        body += '<v12:targetSystemUrl>'+'https://myapply.phoenix.edu/Apply/RegisterInvite.aspx?t='+'</v12:targetSystemUrl>';
        body += '<v12:requestorFirstName>'+'Jane'+'</v12:requestorFirstName>';
        body += '<v12:requestorLastName>'+'Doe'+'</v12:requestorLastName>';
        body += '<v12:requestorEmail>'+'janetest@gmail.com'+'</v12:requestorEmail>';
        body += '<v12:requestorPhone>'+'none'+'</v12:requestorPhone>';
        body += '</v12:tokenCommunicationData>';
        body += '</v12:tokenGenerateData>';
        body += '</tok:generateTokenRequest>';
        body += '</soapenv:Body></soapenv:Envelope>';
        //sendInvitesStudent(String irn,String reqLogin,String activeHours,String recFirstName,String recLastName,String recEmail,String reqFirstName,String reqLastName,String reqEmail,String reqPhone,String targetURL)
        //sendInvitesStudent('1234','testAlias','1234','John','Done','test1@gmail.com','Jane','Doe','janetest@gmail.com','none','https://myapply.phoenix.edu/Apply/RegisterInvite.aspx?t=');
        Map<String, String> samplemap=new Map<String, String>();
        samplemap.put('test','test');       
       
          
        sResult = ServiceUtility_AC.processRequest(HttpMethod.GET, endPoint, body, certificateName, false, samplemap);
        sResult = ServiceUtility_AC.processRequest(HttpMethod.GET, endPoint, body, certificateName);
        sResult = ServiceUtility_AC.processRequest(HttpMethod.GET, endPoint, certificateName);
        sResult = ServiceUtility_AC.processRequest(HttpMethod.GET, endPoint, body, samplemap);
        sResult = ServiceUtility_AC.processRequest(HttpMethod.GET, endPoint, body, certificateName, samplemap);
        
        response = ServiceUtility_AC.sendRequest(HttpMethod.GET, endPoint, body, certificateName, false, samplemap);
        response = ServiceUtility_AC.sendRequest(HttpMethod.GET, endPoint, body, certificateName);
        response = ServiceUtility_AC.sendRequest(HttpMethod.GET, endPoint, certificateName);
        response = ServiceUtility_AC.sendRequest(HttpMethod.GET, endPoint, body, samplemap);
        response = ServiceUtility_AC.sendRequest(HttpMethod.GET, endPoint, body, certificateName, samplemap);
    }
}