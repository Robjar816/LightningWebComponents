/************************************************************************************************************
 * Name         :  lwcRequestToS4
 * Description  :  This JS used to call Apex class and send data to S4 through API Call
 *
 * @author MST
 * @date 10/20/2021 
 *
 *
 * Modification Log :
 * Developer                 Date                   Description
 * ----------------------------------------------------------------------------------------------------------                
 *  * Ramya             10/20/2021             Initial Version - Send Data to S4 
 *    Ramya             11/26/2021             Initial call to Constant class then caling respective methods
 *    Ramya             12/06/2021             Multiple RMA Changes
 *    Ramya             12/13/2021             Sending MapResponse to errorlog method 
 *************************************************************************************************************/
import { LightningElement, wire, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import getConstants from '@salesforce/apex/SendSalesforceDetailsToS4.getAllConstants';
import checkCodeLineItemsHasS4Product from '@salesforce/apex/SendSalesforceDetailsToS4.checkCodeLineItemsHasS4Product';
import doS4PostCall from '@salesforce/apex/SendSalesforceDetailsToS4.initateS4CalloutService';
import updateErrorMessage from '@salesforce/apex/SendSalesforceDetailsToS4.setErrorMessage';
import updateRMACasesfrom from '@salesforce/apex/SendSalesforceDetailsToS4.updateCaseDetails';
export default class lwcRequestToS4 extends LightningElement {
     recordId;
    boolShowSpinner = true;
    boolSuccess = false;
    boolWarning = false;    
    boolError = false;    
    boolS4ProductAccess = false;
    strErrorMessage;
    strSuccessMessage;
    strActualMessage;
    strRMANumber;
    strWarningMessage;
    strS4ProductAccessMessage;
    @track returnS4tMap;
    /**
     * @description This method used to set the recordId
     * @author MST | 10-26-2021
     **/
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.attributes.recordId;
        }
    }
    /**
     * @description This method used to close the pop-up window.
     * @author MST | 10-20-2021
     **/
    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    /**
     * @description This method used to call Constant class and set the static variables value.
     * @author MST | 10-20-2021
     **/
    @wire(getConstants) 
    allConstants ({error, data}) {
        if (data) {
            this.strSuccessMessage = data.S4_SUCCESS_MESSAGE; 
            this.strErrorMessage = data.S4_FAILURE_MESSAGE; 
            this.strS4ProductMessage = data.S4_PRODUCT_MESSAGE;
            this.callLineItemsStatus();

        } else {
            console.log('Error in Constant---'+JSON.stringify(error));
        }
    } 
    /**
     * @description This method used to call controller and check whether CodeLintItem has S4 Product.Call S4 system if it has S4 Product otherwise shows message
     * @author MST | 10-24-2021
     **/
    callLineItemsStatus(){
        checkCodeLineItemsHasS4Product({recordId:this.recordId})
        .then( result => {
            if(result == false){
                this.boolS4ProductAccess = true;
                this.boolSuccess = false;
                this.boolError = false;
                this.boolShowSpinner = false;        
            }
            else if(result){
                this.callS4API();
            }        
        })
        .catch(error => {
            console.log('IN Error in Check S4 Prodcut Line Items---'+JSON.stringify(error));
        })
    }    
    /**
     * @description This method used to call S4 System and capture the response based on SF inputs.
     * @author MST | 10-20-2021
     **/
    callS4API(){
        doS4PostCall({recordId:this.recordId})
        .then( result => {
            this.boolSuccess = true;           
            this.boolShowSpinner = false;
            this.boolS4ProductAccess = false;
            this.boolError = false;
            this.returnS4tMap = result;
            this.strErrorMessage = '';
            this.strActualMessage = '';
            this.strS4ProductMessage = '';
            this.updateRMANumber();
        })
        .catch(error => {
            this.boolSuccess = false;
            this.boolError = true;
            this.boolShowSpinner = false;
            this.boolS4ProductAccess = false;
            this.strSuccessMessage = '';
            this.strS4ProductMessage = '';
            this.returnS4tMap = JSON.parse(error.body.message).RequestandResponseMap;
            this.strActualMessage = JSON.parse(error.body.message).exceptionMessage;
            this.updateError(); 
        })
    }
    /**
     * @description This method used to update fields in Complaints.
     * @author MST | 10-20-2021
     **/
    updateRMANumber(){
       updateRMACasesfrom({recordId:this.recordId, responseMap:this.returnS4tMap})
        .then(result => {
           this.customEventPageRefresh();           
        })
        .catch(error => { console.log(this.recordId+'=====Update RMA:- '+JSON.stringify(error));});
    }
    /**
     * @description This method used to update error descriptions in Complaints.
     * @author MST | 10-20-2021
     **/
    updateError(){
       updateErrorMessage({recordId:this.recordId, strErrorMessage:this.strActualMessage, responseMap:this.returnS4tMap})
        .then(result => { 
            this.customEventPageRefresh();            
        })
        .catch(error => { console.log(this.recordId+'=====Errorured:- '+JSON.stringify(error));});
    }
    /**
     * @description This method used to refresh the page from parent component by calling customEvent.
     * @author MST | 12-2-2021
     **/
     customEventPageRefresh(){
        const textChangeEvent = new CustomEvent('show',{});    
            //Fire Event
         this.dispatchEvent(textChangeEvent);
     }
    /**
     * @description This method used to show toast message in Complaints.
     * @author MST | 10-20-2021
     **/ 
    showNotification() {
        const evt = new ShowToastEvent({
            title: this.strToastTitle,
            message: this.strToastMessage,
           // variant: this.variant,
        });
        this.dispatchEvent(evt);
    }
    
}