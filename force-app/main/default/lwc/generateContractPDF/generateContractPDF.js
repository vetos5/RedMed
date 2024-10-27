import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class GenerateContractPdf extends NavigationMixin(LightningElement) {
    @api recordId;

    generatePdf() {
                this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: `/apex/Contract_PDF_Template?id=${this.recordId}`
            }
        }).then((generatedUrl) => {
                window.open(generatedUrl);
        });
    }
}
