import { LightningElement, api } from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class UpdateLeadForm extends LightningElement {
    @api recordId;

    handleOnSuccess(){
        this.dispatchEvent(
            new ShowToastEvent({
                title: "Success!!!",
                message: "Lead Successfully Updated",
                variant: "success"
            })
        );

    }
}