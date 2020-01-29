import { LightningElement, api } from 'lwc';
export default class Paginator extends LightningElement {
    @api totalrecords;
    @api currentpage;
    @api pagesize;

    lastpage = false;
    firstpage = false;

    get showFirstButton() {
        if (this.currentpage === 1) {
            return true;
        }
        return false;
    }

    get showLastButton() {
        if (Math.ceil(this.totalrecords / this.pagesize) === this.currentpage) {
            return true;
        }
        return false;
    }

    handlePrevious() {
        this.dispatchEvent(new CustomEvent('previous'));
    }
    handleNext() {
        this.dispatchEvent(new CustomEvent('next'));
    }
    handleFirst() {
        this.dispatchEvent(new CustomEvent('first'));
    }
    handleLast() {
        this.dispatchEvent(new CustomEvent('last'));
    }
}
