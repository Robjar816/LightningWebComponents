// Created by :Vijaya Varada
// This class handles all platform calls that are non profile related.  Refer to ProfileServiceCallouts_AC for profile related platform calls
public class PlatformServiceCallouts_AC {

    public static CompanyListWrapper_AC getCompanyList(String criteria) {
       try {
            criteria = EncodingUtil.urlEncode(criteria, 'UTF-8') + '&limit=200';  //returns only first 2 hunderd for any search that returns more than 200
            System.debug('Encoded Criteria String >>' + criteria);
            String companyServiceEndPoint = Environment_Variables__c.getInstance('PlatformEndPoint').Value__c + '/hz/companyservice/v3/companies?companyName=' + criteria;
            String certificateName = Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c;   
            /************ Start **************/
            String responseBody; 
            if (!System.Test.isRunningTest())
            {
                responseBody = ServiceUtility_AC.processRequest(ServiceUtility_AC.HttpMethod.GET, companyServiceEndPoint, '',certificateName,
                                        new Map<String, String> { 'Accept' => 'application/json',
                                                                  'tenantid' => '831D8B107020BBEBE0400F0A32207789' });
            }else{
                responseBody =      '{'+
                                    '    "companyList": ['+
                                    '        {'+
                                    '            "id": "String",'+
                                    '            "name": "String",'+
                                    '            "dunsNumber": "String",'+
                                    '            "primaryAddress": {'+
                                    '                "address1": "String",'+
                                    '                "city": "String",'+
                                    '                "state": "String",'+
                                    '                "country": "String"'+
                                    '            },'+
                                    '            "ultimateParent": {'+
                                    '                "dunsNumber": "String"'+
                                    '            }'+
                                    '        }'+
                                    '    ]'+
                                    '}';
            }
            /************ End  **************/  
            system.debug('getCompanyList service call response = '+responseBody);    
            CompanyListWrapper_AC companyList = (CompanyListWrapper_AC)JSON.deserialize(responseBody, CompanyListWrapper_AC.class);
            companyList.filterOnlyUSEmployers();
            return companyList;
        } catch (Exception e) {
            system.debug('Error in PlatformServiceCallouts_AC->getCompanyList unable to get CompnayList for criteria: ' + criteria);
            throw e;
        }
    }
    
    public static String aggregateService(String requestBody){
        
        
        try{            
            HttpResponse response = aggregateServiceCall(requestBody);
            if(response != null ){
                return response.getBody();
            }
            else{
                return null;
            }
        }
         catch(Exception e){            
            
            throw e;
            
        }
        
    }
    
    
    public static HttpResponse aggregateServiceCall(String requestBody){
        
        HttpResponse res = new Httpresponse();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String transactionId = GuidUtil_AC.getNewGuid();
        try{
            
            String resourcePath = '/aggregation/v1/sequenceCall';
            String serviceEndPoint =  Environment_Variables__c.getInstance('PlatformEndPoint').Value__c;        
            String certName = Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c;           
            req.setEndpoint(serviceEndpoint+resourcePath);                     
            req.setHeader('Content-Type', 'application/json; charset=utf-8');
            req.setHeader('Accept', 'application/json');
            req.setHeader('tenantid','831D8B107020BBEBE0400F0A32207789');           
            req.setBody(requestBody);                   
            req.setMethod('POST');
            req.setTimeout(Integer.valueOf(Environment_Variables__c.getInstance('PlatformCalloutTimeoutLimit').Value__c));
            system.debug('request payload = '+req.getBody());
            req.setClientCertificateName(Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c);
            req.setHeader('x-apollo-transaction-id',transactionId);
            system.debug('transactionId = '+transactionId);                              
            res = h.send(req);
            system.debug('response = '+res);
            if(res != null){
                system.debug('response body = '+res.getBody());
            }
            return res;
        }
         catch(Exception e){            
            if(System.isBatch() || System.isFuture()) {
                ApplicationLogs__c appLog = new ApplicationLogs__c();
                appLog.payload__c = requestbody;
                appLog.TransactionId__c = transactionId;
                appLog.StackTrace__c = e.getStackTraceString();
                appLog.Error_Message__c = e.getMessage(); 
                appLog.Class_Name__c = 'PlatformServiceCallouts_AC : aggregateService';
                appLog.Response__c = res == null ? '' : res.getBody();
                insert appLog;
            }else {
                 insertAppLog(requestbody,transactionId, e.getStackTraceString(), e.getMessage(), res.getBody());    
            }
            throw e;
            
        }
        
    }
    
    @future
    public static void insertAppLog(String requestbody, String transactionId, String stackTrace, String errorMsg, String resBody) {
        ApplicationLogs__c appLog = new ApplicationLogs__c();
        appLog.payload__c = requestbody;
        appLog.TransactionId__c = transactionId;
        appLog.StackTrace__c = stackTrace;
        appLog.Error_Message__c = errorMsg; 
        appLog.Class_Name__c = 'PlatformServiceCallouts_AC : aggregateService';
        appLog.Response__c = resBody == null ? '' : resBody;
        insert appLog;
    }
    
    public static String aggregateServiceCallWithoutAppLog(String requestBody){
        
        HttpResponse res = new Httpresponse();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String transactionId = GuidUtil_AC.getNewGuid();
        try{
            
            String resourcePath = '/aggregation/v1/sequenceCall';
            String serviceEndPoint =  Environment_Variables__c.getInstance('PlatformEndPoint').Value__c;        
            String certName = Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c;           
            req.setEndpoint(serviceEndpoint+resourcePath);                     
            req.setHeader('Content-Type', 'application/json; charset=utf-8');
            req.setHeader('Accept', 'application/json');
            req.setHeader('tenantid','831D8B107020BBEBE0400F0A32207789');           
            req.setBody(requestBody);                   
            req.setMethod('POST');
            req.setTimeout(Integer.valueOf(Environment_Variables__c.getInstance('PlatformCalloutTimeoutLimit').Value__c));
            system.debug('request payload = '+req.getBody());
            req.setClientCertificateName(Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c);
            req.setHeader('x-apollo-transaction-id',transactionId);
            system.debug('transactionId = '+transactionId);                              
            res = h.send(req);
            system.debug('response = '+res);
            if(res != null){
                system.debug('response body = '+res.getBody());
                return res.getBody();
            }
            return null;
        }
        catch(Exception e){            
            throw e;
        }
        
    }
    
    public static HttpResponse TCPAEmailService(String body){
    //TCPAEmailConsentRequestWrapper_AC tcparequest = buildRequest();
    //String body = JSON.serialize(tcparequest);
        
        HttpResponse res = new Httpresponse();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String transactionId = GuidUtil_AC.getNewGuid();
        try{
            
            String resourcePath = '/hz/emailservice/v1/email';
            String serviceEndPoint =   Environment_Variables__c.getInstance('PlatformEndPoint').Value__c;       
            String certName = Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c;           
            req.setEndpoint(serviceEndpoint+resourcePath);
            req.setHeader('Content-Type', 'application/json; charset=utf-8');
            req.setHeader('Accept', 'application/json');
            req.setHeader('tenantid','831D8B107020BBEBE0400F0A32207789');           
            req.setBody(body);                   
            req.setMethod('POST');
            //req.setTimeout(1);
            system.debug('request payload = '+req.getBody());
            req.setClientCertificateName(Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c);
            req.setHeader('x-apollo-transaction-id',transactionId);
            system.debug('transactionId = '+transactionId);                              
            res = h.send(req);
             system.debug('response... = '+res);
            system.debug('response = '+res.getBody());
            return res;
        }
         catch(Exception e){            
            
            ApplicationLogs__c appLog = new ApplicationLogs__c();
            appLog.payload__c = body;
            appLog.TransactionId__c = transactionId;
            appLog.StackTrace__c = e.getStackTraceString();
            appLog.Error_Message__c = e.getMessage(); 
            appLog.Class_Name__c = 'PlatformServiceCallouts_AC : aggregateService';
            appLog.Response__c = res == null ? '' : res.getBody();
            insert appLog;
            throw e;
            
        }
        
    }
    
    public static String getPlatformDataRest(String restEndPoint, String testRes){
            String endPoint =  Environment_Variables__c.getInstance('PlatformEndPoint').Value__c;
            String serviceEndPoint =endPoint+restEndPoint  ; 
            String certName =  Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c;           
            
            String res=null;
            try{
                if(!test.isRunningTest())
                    res = ServiceUtility_AC.processRequest(ServiceUtility_AC.HttpMethod.GET, serviceEndPoint, '',certName, new Map<String, String> {'Content-Type' =>'text/xml; charset=utf-8', 'Accept' => 'application/json','tenantid' => '831D8B107020BBEBE0400F0A32207789'});              
                else
                    res = testRes;
                System.debug('response2 = '+res);
                   
            }catch(Exception e){
               system.debug(e);
               if(!e.getMessage().contains('response status: Not Found') )
                    //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'Service unavailable '));
                    System.debug('Service unavailable');
                
            }
            
            return res;
    }

    public static HttpResponse AcademicProgDetailsService(String orgOid){
        HttpResponse res = new Httpresponse();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String transactionId = GuidUtil_AC.getNewGuid();
        try{
            if(test.isRunningTest()) {
                res.setStatusCode(200);
                res.setBody('{"self":"https://st-servicegateway.apollo.edu/servicegateway/rest/st/academicprogram/v1/academicprograms?offeredbyid=3","items":[{"name":"Bachelor of Science in Business with a Concentration in Accounting","id":"3","self":"https://st-servicegateway.apollo.edu/servicegateway/rest/st/academicprogram/v1/academicprogram/3","modality":"G","academicProgramCode":"BSB/ACC","academicAwardLevel":{"name":"Bachelors"},"orgaNumber":"21","programArea":"Business and Management","programType":"Degree","qualificationLevel":"Undergraduate"},{"name":"Bachelor of Science in Business with a Concentration in Communications","id":"3","self":"https://st-servicegateway.apollo.edu/servicegateway/rest/st/academicprogram/v1/academicprogram/3","modality":"G","academicProgramCode":"BSB/C","academicAwardLevel":{"name":"Bachelors"},"orgaNumber":"21","programArea":"Business and Management","programType":"Degree","qualificationLevel":"Undergraduate"},{"name":"Master of Science in Nursing for Nurse Practitioners","id":"3","self":"https://st-servicegateway.apollo.edu/servicegateway/rest/st/academicprogram/v1/academicprogram/3","modality":"G","academicProgramCode":"MSN/NPFT","academicAwardLevel":{"name":"Masters"},"orgaNumber":"21","programArea":"Nursing and Health Care","programType":"Degree","qualificationLevel":"Graduate"}]}');
                return res;
            } else {
                String resourcePath = '/st/academicprogram/v1/academicprogramdetails?campusId='+orgOid;
                String serviceEndPoint =   Environment_Variables__c.getInstance('PlatformEndPoint').Value__c;       
                String certName = Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c;           
                req.setEndpoint(serviceEndpoint+resourcePath);
                req.setHeader('Content-Type', 'application/json; charset=utf-8');
                req.setHeader('Accept', 'application/json');
                req.setHeader('tenantid','831D8B107020BBEBE0400F0A32207789');           
                req.setMethod('GET');
                system.debug('request payload = '+req.getBody());
                req.setClientCertificateName(Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c);
                req.setHeader('x-apollo-transaction-id',transactionId);
                system.debug('transactionId = '+transactionId);                              
                res = h.send(req);
                system.debug('response... = '+res);
                system.debug('response = '+res.getBody());
                return res;
            }
        }catch(Exception e){            
            system.debug('Exception = '+e);
            throw e;
        }
    }
    
    public static HttpResponse getProgramComplianceData(String programCode, String modality, String studSubDivCode){
        HttpResponse res = new Httpresponse();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String transactionId = GuidUtil_AC.getNewGuid();
        try{
            if(test.isRunningTest()) {
                res.setStatusCode(200);
                res.setBody('{"programCompliance":{"programCode":"MBA","modality":"ONLINE","studentSubdivisionCode":"US-CA","compliantActivities":[{"activityType":"ENROLLMENT","advisorLocations":[{"subdivisionCode":"US-AZ"},{"subdivisionCode":"US-CA"}]}]},"self":"https://st-servicegateway.apollogrp.edu/servicegateway/rest/pc/program/v1/compliance?activitytype=ENROLLMENT&programcode={programabbreviation}&modality={modality}&studentsubdivisioncode={studentsubdivisioncode}"}');
                return res;
            } else {
                String resourcePath = '/pc/program/v1/compliance?activitytype=ENROLLMENT&programcode='+programCode+'&modality='+modality+'&studentsubdivisioncode='+studSubDivCode;
                String serviceEndPoint =   Environment_Variables__c.getInstance('PlatformEndPoint').Value__c;       
                String certName = Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c;           
                req.setEndpoint(serviceEndpoint+resourcePath);
                req.setHeader('Content-Type', 'application/json; charset=utf-8');
                req.setHeader('Accept', 'application/json');
                req.setHeader('tenantid','831D8B107020BBEBE0400F0A32207789');           
                req.setMethod('GET');
                system.debug('request payload = '+req.getBody());
                req.setClientCertificateName(Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c);
                req.setHeader('x-apollo-transaction-id',transactionId);
                system.debug('transactionId = '+transactionId);                              
                res = h.send(req);
                system.debug('response... = '+res);
                system.debug('response = '+res.getBody());
                return res;
            }
        }catch(Exception e){            
            system.debug('Exception = '+e);
            throw e;
        }
    }
    
//Ravi Voleti - Method to see if the phone number is a mobile number or not
    public static List<HttpResponse> isPhoneNumbMobile(Set<String> Phones){
      
        HttpResponse res = new Httpresponse();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String transactionId = GuidUtil_AC.getNewGuid();
        List<HttpResponse> phoneList = new List<HttpResponse>();
        try{
            if(test.isRunningTest()) {
                List<HttpResponse> testRes = new List<HttpResponse>();
                res.setStatusCode(200);
                res.setBody('{"mobile": [ ],"other": ["8905313195"]}');
                testRes.add(res);
                return testRes;
            }
            else{
                for(String phoneNumb : Phones){
                    String resourcePath = '/hz/phonetype/v1/phonetype?phoneNumber='+phoneNumb;
                    String serviceEndPoint =   Environment_Variables__c.getInstance('PlatformEndPoint').Value__c;       
                    String certName = Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c;           
                    req.setEndpoint(serviceEndpoint+resourcePath);
                    req.setHeader('Content-Type', 'application/json; charset=utf-8');
                    req.setHeader('Accept', 'application/json');
                    req.setHeader('tenantid','831D8B107020BBEBE0400F0A32207789');                             
                    req.setMethod('GET');
                    system.debug('request payload = '+req.getBody());
                    req.setClientCertificateName(Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c);
                    req.setHeader('x-apollo-transaction-id',transactionId);
                    system.debug('transactionId = '+transactionId);                              
                    res = h.send(req);
                    system.debug('response... = '+res);
                    system.debug('response body= '+res.getBody());
                    phoneList.add(res);
                }
             }
             return phoneList;
        }
         catch(Exception e){            
            system.debug('Exception = '+e);
            throw e;        
        }
    }
    
    // Ravi Voleti - PREX-12404, introducing new student workshop information to AP in SRM
    public static String getCourseOfferingMemberships(String profileId) {
        String endPoint =  Environment_Variables__c.getInstance('PlatformEndPoint').Value__c;        
        String resourcePath = '/ac/v3/courseofferingmemberships?profileId='+profileId+'&membershipRole=ST&includeWorkshop=true&includeCourseOffering=true';
        String serviceEndPoint =endPoint+resourcePath;
        String certName = Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c;
        String res=null;
            try{
                if(!test.isRunningTest())
                    res = ServiceUtility_AC.processRequest(ServiceUtility_AC.HttpMethod.GET, serviceEndPoint, '',certName, new Map<String, String> {'Content-Type' =>'text/xml; charset=utf-8', 'Accept' => 'application/json','tenantid' => '831D8B107020BBEBE0400F0A32207789'});              
                else{
                    String testRes;
                    //res.setStatusCode(200);
                    //testRes = res.setBody('{"mobile": [ ],"other": ["8905313195"]}');
                    res = testRes;
                }
                System.debug('response2 = '+res);
                   
            }catch(Exception e){
               system.debug(e);
               if(!e.getMessage().contains('response status: Not Found') )
                    System.debug('Service unavailable'); 
            }
        return res;
    }
    
    //Ravi Voleti - Method to get personId from backfil microservice for the given profile Id
    public static HttpResponse getPersonId(String profileId){
        
        HttpResponse res = new Httpresponse();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String transactionId = GuidUtil_AC.getNewGuid();
        try{
            
            if(test.isRunningTest()) {
                HttpResponse resp = new HttpResponse();
                resp.setStatusCode(200);
                resp.setBody('{"personId": "647122225868247040"}');
                return resp;
            }else {
                String resourcePath = '/pf/profile/v5/profile/ms/sync.JSON';
                String serviceEndPoint =   Environment_Variables__c.getInstance('PlatformEndPoint').Value__c;
                String certName = Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c;
                req.setEndpoint(serviceEndpoint+resourcePath);
                req.setHeader('Content-Type', 'application/json; charset=utf-8');
                req.setHeader('Accept', 'application/json');
                req.setHeader('tenantid','831D8B107020BBEBE0400F0A32207789');
                req.setBody('{"identityType":"PROFILE_ID","identityValue":"'+profileId+'"}');
                req.setMethod('POST');
                system.debug('request payload = '+req.getBody());
                req.setClientCertificateName(Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c);
                req.setHeader('x-apollo-transaction-id',transactionId);
                system.debug('transactionId = '+transactionId);
                res = h.send(req);
                system.debug('response... = '+res);
                system.debug('response = '+res.getBody());
                return res;
            }

        }
            catch(Exception e){
            system.debug('Exception = '+e);
            throw e;
        }
        
    }
    
    //Satya Bogolu - Method to get programID for the given profile Id
    public static HttpResponse getprogramId(String profileId){
        HttpResponse res = new Httpresponse();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String transactionId = GuidUtil_AC.getNewGuid();
        try{
            if(test.isRunningTest()) {
                HttpResponse resp = new HttpResponse();
                resp.setStatusCode(200);
                resp.setBody('{"studentPrograms":[{"id":"4922754","profileId":"a29dc445-5e9f-478e-94db-83ce49ca62c9","isPrimary":true,"creditsCompleted":0.0,"creditsTransferred":0.0,"creditsAssessed":0.0,"creditsWaived":0.0,"creditsEarned":0.0,"creditsRemaining":120.0,"creditsRequired":120.0,"programId":"41470261896","gpa":0.0,"statuses":[{"statusType":"AcademicStatus","statusValue":"RG"},{"statusType":"AdmissionStatus","statusValue":"RR"},{"statusType":"EnrollmentStatus","statusValue":"X","statusDate":"2020-04-27T14:44:42"},{"statusType":"EstimatedGraduationDate","statusValue":"Available","statusDate":"2020-04-27T00:00:00"},{"statusType":"FinancialAidStatus","statusValue":"RG"}],"milestones":[{"milestoneType":"AnticipatedStartDate","milestoneDate":"2020-05-19T00:00:00"},{"milestoneType":"CoreRequirementsCompletedDate","milestoneDate":"2020-04-27T00:00:00"},{"milestoneType":"EstimatedGraduationDate","milestoneDate":"2024-03-18T00:00:00"}],"links":[{"href":"https://st-servicegateway.apollo.edu/servicegateway/rest/ac/v2/students/a29dc445-5e9f-478e-94db-83ce49ca62c9/studentprograms","rel":"self","method":null},{"href":"https://st-servicegateway.apollo.edu/servicegateway/rest/pf/profile/v5/profile/a29dc445-5e9f-478e-94db-83ce49ca62c9","rel":"pf/profile/v5/profile","method":null},{"href":"https://st-servicegateway.apollo.edu/servicegateway/rest/pc/v2/programs/41470261896","rel":"pc/v2/programs","method":null}],"cbeFlag":false,"programCode":"BSM","programVersionCode":"004A","homeCampus":"campus:31","enrollCampus":"campus:31"}]}');
                return resp;
            }else {
                String resourcePath = '/ac/v2/students/' + profileId + '/studentprograms';
                String serviceEndPoint =   Environment_Variables__c.getInstance('PlatformEndPoint').Value__c;
                String certName = Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c;
                req.setEndpoint(serviceEndpoint+resourcePath);
                req.setHeader('Content-Type', 'application/json; charset=utf-8');
                req.setHeader('Accept', 'application/json');
                req.setHeader('tenantid','831D8B107020BBEBE0400F0A32207789');
                req.setMethod('GET');
                system.debug('request payload = '+req.getBody());
                req.setClientCertificateName(Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c);
                req.setHeader('x-apollo-transaction-id',transactionId);
                system.debug('transactionId = '+transactionId);
                res = h.send(req);
                system.debug('response... = '+res);
                system.debug('response = '+res.getBody());
                return res;
            }
        }
        catch(Exception exp){
            system.debug('Exception = ' + exp);
            throw exp;
        }
    }
    
    //Satya Bogolu - Method to get programlevel  for the given Program Id
    public static HttpResponse getprogramLevel(String programId){
        HttpResponse res = new Httpresponse();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String transactionId = GuidUtil_AC.getNewGuid();
        try{
            if(test.isRunningTest()) {
                HttpResponse resp = new HttpResponse();
                resp.setStatusCode(200);
                resp.setBody('{"id":"41470261896","code":"BSM","versionCode":"004A","name":"Bachelor of Science in Management","shortDescription":"BACHELOR OF SCIENCE IN MANAGEMENT","academicAwardCode":"9166430138","academicAwardLevelCode":"13688063439","tags":["652"],"offeredbyOrgId":"department:12871154528","cipCode":"52.0201","effectiveDate":"2015-04-01T00:00:00.000-07:00","graduationRequirement":{"minimumCredits":120.0,"minimumGPA":2.0},"links":[{"href":"https://st-servicegateway.apollo.edu/servicegateway/rest/pc/v2/programs/41470261896/concentrations","rel":"pc/v2/programs/concentrations","method":null},{"href":"https://st-servicegateway.apollo.edu/servicegateway/rest/pc/v2/programs/41470261896/descriptions","rel":"pc/v2/programs/descriptions","method":null},{"href":"https://st-servicegateway.apollo.edu/servicegateway/rest/pc/v2/programs/41470261896","rel":"self","method":null},{"href":"https://st-servicegateway.apollo.edu/servicegateway/rest/or/v4/organizations/department:12871154528","rel":"or/v4/organizations","method":null}],"isCBEProgram":false,"extension":{"GE_WARNING":"FALSE","GE_ELIGIBLE":"FALSE"}}');
                return resp;
            }else {
                String resourcePath = '/pc/v3/programs/'+programId;
                String serviceEndPoint =   Environment_Variables__c.getInstance('PlatformEndPoint').Value__c;
                String certName = Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c;
                req.setEndpoint(serviceEndpoint+resourcePath);
                req.setHeader('Content-Type', 'application/json; charset=utf-8');
                req.setHeader('Accept', 'application/json');
                req.setHeader('tenantid','831D8B107020BBEBE0400F0A32207789');
                req.setMethod('GET');
                system.debug('request payload = '+req.getBody());
                req.setClientCertificateName(Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c);
                req.setHeader('x-apollo-transaction-id',transactionId);
                system.debug('transactionId = '+transactionId);
                res = h.send(req);
                system.debug('response... = '+res);
                system.debug('response = '+res.getBody());
                return res;
            }
        }
        catch(Exception exp){
            system.debug('Exception = ' + exp);
            throw exp;
        }
    }
    
    public static String getCourseOffering(String courseOfferingId) {
        String endPoint =  Environment_Variables__c.getInstance('PlatformEndPoint').Value__c;        
        String resourcePath = '/ac/v3/courseofferings/' + courseOfferingId;
        String serviceEndPoint =endPoint+resourcePath;
        String certName = Environment_Variables__c.getInstance('ApolloPlatformCert').Value__c;
        String res=null;
            try{
                if(!test.isRunningTest())
                    res = ServiceUtility_AC.processRequest(ServiceUtility_AC.HttpMethod.GET, serviceEndPoint, '',certName, new Map<String, String> {'Content-Type' =>'text/xml; charset=utf-8', 'Accept' => 'application/json','tenantid' => '831D8B107020BBEBE0400F0A32207789'});              
                else{
                    res = '{'+
                        '"id": "OSIRIS:31256",'+
                        '"courseId": "OSIRIS:331212",'+
                        '"courseCode": "TQS/602",'+
                        '"courseAvailabilityId": "OSIRIS:4545",'+
                        '"course_type" : "COURSE",'+
                        '"title": "QUALITY MEASUREMENT TECHNIQUES",'+
                        '"description": "CourseOffering for MATH/101",'+
                        '"code": "GBCNS22",'+
                        '"syllabusId": "SYB-001",'+
                        '"modality": "Ground",'+
                        '"status": "L",'+
                        '"locationId": "campus:23232",'+
                        '"site_Code" : "SF",'+
                        '"classroom_version" : "R1",'+
                        '"site_oid": "site:2332",'+
                        '"siteAddress": {'+
                        '		"line1": "fdsds",'+
                        '		"line2": "sfds",'+
                        '		"city": "sdfd",'+
                        '		"state": "AZ",'+
                        '		"zipCode": "56564"'+
                        '		},'+
                        '"offeringType": "OL",'+
                        '"defaultCredits": "3",'+
                        '"maxNumberOfStudents": "3",'+
                        '"numberOfStudents": "3",'+
                        '"dateRange": {'+
                        '		"startDate": "2013-04-09T00:00:00.000-07:00",'+
                        '		"endDate": "2013-05-14T00:00:00.000-07:00"'+
                        '		},'+
                        '"enrollmentAccept": "True",'+
                        '"note": "This is  a courseoffering for MATH/101",'+
                        '"vleCode": "BB"'+
                        '}';
                }
                System.debug('response2 = '+res);
                   
            }catch(Exception e){
               system.debug(e);
               if(!e.getMessage().contains('response status: Not Found') )
                    System.debug('Service unavailable'); 
            }
        return res;
    }
}