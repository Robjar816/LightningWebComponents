import { LightningElement, api } from 'lwc';

export default class ChildComp extends LightningElement {
    @api message;
    @api pagenumber;
    name = 'Robert ';
    constructor() {
        super();
        console.log(' Inside constructor in Child');
        this.name = this.name + ' Jaramillo - in Child';
    }

    connectedCallback() {
        console.log(' connectedCallback in Child ');
    }

    disconnectedCallback() {
        console.log(' disconnectedCallback in Child ');
    }

    /*render() {
        return 
    }*/

    renderedCallback() {
        console.log(' renderedCallback in Child ');
    }

    errorCallback(error, stack) {
        console.error(error);
    }

    handleEvent() {
        /*
            Step 1 - Create Event
        */
       const eventS = new CustomEvent(
           'simple',
           {
               //Passing data to parent using a custom event
               //detail : {message : this.message, pagenumber : this.pagenumber, staticVal : "Robert Jaramillo"}

               //passing data to parent using a bubble event
               bubbles : true,
               composed : false
           }
           );
       /*
            Step 2 - Dispatch Event
        */
       this.dispatchEvent(eventS);
    }
}