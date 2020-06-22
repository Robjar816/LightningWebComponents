import { LightningElement } from 'lwc';

export default class CalculatorComponent extends LightningElement {
    number1;
    number2;

    handleChangeEvent(event){
        const val = event.target.value;
        const name = event.target.name;
        if(name === 'number1'){
            this.number1 = val;
        }else{
            this.number2 = val;
        }
    }
    doSum(){
        const sum = parseInt(this.number1) + parseInt(this.number2);
        alert(sum);
    }
    doSubt(){
        const subt = parseInt(this.number1) - parseInt(this.number2);
        alert(subt);
    }

    doDiv(){
        const div = parseInt(this.number1) / parseInt(this.number2);
        alert(div);
    }
    doMulti(){
        const mult = parseInt(this.number1) * parseInt(this.number2);
        alert(mult);
    }
}