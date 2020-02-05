import { LightningElement, api } from 'lwc';
export default class Paginator extends LightningElement {
    @api totalRecords;
    @api currentPage;
    @api pageSize;

    lastpage = false;
    firstpage = false;

    get showFirstButton() {
        if (this.currentPage === 1) {
            return true;
        }
        return false;
    }

    get showLastButton() {
        if (Math.ceil(this.totalRecords / this.pageSize) === this.currentPage) {
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
