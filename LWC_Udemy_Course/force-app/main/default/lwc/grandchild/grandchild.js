import { LightningElement } from 'lwc';

export default class Grandchild extends LightningElement {
    handleSimpleEvent(event) {
        //alert('Grand Child');
        console.log('Message in grand child = ' + event.target.message);
    }
}