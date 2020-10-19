// Created by :Vijaya Varada
// This class handles all platform calls that are non profile related.  Refer to ProfileServiceCallouts_AC for profile related platform calls
public class PlatformServiceCallouts_AC {
    
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