/************************************************************************************************************
 * Name         :  acRequestToS4
 * Description  :  Script used to refresh Advanced Return Order Related List
 *
 * @author MST
 * @date 12/07/2021 
 *
 *
 * Modification Log :
 * Developer                 Date                   Description
 * ----------------------------------------------------------------------------------------------------------                
 * Ramya                   12/07/2021              Initial Version - Refresh Advanced Return Order Related List 
 *************************************************************************************************************/

({
    refreshMethod : function(component, event, helper) {
        $A. get('e.force:refreshView').fire(); 
    }
})