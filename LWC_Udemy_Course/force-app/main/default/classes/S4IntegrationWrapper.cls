/*********************************************************************************************************************************
* Name         :  SendSalesforceDetailsToS4
* Description  :  This class used to serialize the Complaint and Complaint line item object fields.
* @author Vijay
* @date   10/08/2021
* @test class   : SendSalesforceDetailsToS4Test
* Modification Log :
* Developer                 Date                   Description
* -------------------------------------------------------------------------------------------------------------------------------                
* Vijay              10/08/2021                  Created
* Vijay              11/26/2021                  Added the return reason attribute in the complaint wrapper
* Vijay              12/06/2021                  New Request parameter is added in S4
*********************************************************************************************************************************/
public class S4IntegrationWrapper{
    
    public CaseHeader Header;
    public List<ComplaintLineItem> Item;
        
    //Mapping for Complaint object
    public class CaseHeader {
        public String Casenumber;
        public String Distribution_channel; 
        public String Division;   
        public String Order_C; 
        public String Sales_org;   
        public String Ship_to_party;
        public String Sold_to_party; 
        public String Next_activity;
        public String Return_reason;  
        public String Need_Material_Back;  

        public String Invoice_number;
    }
    
    //Mapping for Compliant Line Item
    public class ComplaintLineItem {
        public String line_item_id; 
        //public String Quantity_Rejected_c;  
        public String unit_of_measure;  
        public String Material;
        public String sample_required;
        public String return_quantity_credit_request_qty;
    }
    
    public static void wrapMethod(){}
}