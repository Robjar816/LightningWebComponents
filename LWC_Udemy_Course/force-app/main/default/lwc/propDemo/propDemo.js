import { LightningElement, track, api} from 'lwc';

export default class PropDemo extends LightningElement {
    message = 'Reactive Property';

    @api message1 = 'Reactive Property Using Api decorator';

    get name() {
        return 'Robert Jaramillo ';
    }

    get changedMessage() {
        //this.message1 = this.message1 + ' Added Value using get prop!';
        return this.message1 + ' Added Value using get prop!';
    }

    handleChange(event){
        this.message1 = event.target.value;
        console.log('Updated Message is ', this.message1);
    }
}