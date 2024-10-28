import { LightningElement, api } from 'lwc';

export default class ParentComponent extends LightningElement {
    isOrderVisible = false;
    @api recordId;

    handleCreateOrder() {
        this.isOrderVisible = true; 
    }
}
