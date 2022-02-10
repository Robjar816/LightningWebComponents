/*********************************************************************************************************************************
* Name         :  CustomException  
* @author Ramya
* @date   10/08/2021
*  
* Modification Log :
* Developer                 Date                   Description
* -------------------------------------------------------------------------------------------------------------------------------                
* Ramya                10/08/2021                  Created test class
* Vijay                12/13/2021                  Added new parameter in the consturctor
*********************************************************************************************************************************/
public with sharing class CustomException  extends Exception{
    public String exceptionName;
    public String exceptionMessage;
    public Map<String,String> RequestandResponseMap = new Map<String,String>();
    public CustomException(String excepName, String excepMessage, Map<String,String> reqAndResMap) {
       this.exceptionName = excepName;
       this.exceptionMessage = excepMessage;
       this.RequestandResponseMap = reqAndResMap;
    }  
}