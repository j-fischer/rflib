import { LightningElement, api } from 'lwc';

export default class RflibLogEventSingleMessage extends LightningElement {

    @api
    message;

    @api
    fieldVisibility;

    isExpanded = false;

    toggleJsonExpansion() {
        this.isExpanded = !this.isExpanded;
    }

    get expandIcon() {
        return this.isExpanded  ? 'utility:collapse_all' : 'utility:expand_all';
    }

    get expandLabel() {
        return this.isExpanded  ? 'Expand JSON' : 'Collapse JSON';
    }

    get wrapperClass() {
        let wrapperClass = 'wrapper ';
        if(!this.message) {
            return wrapperClass + 'light';
        }
        wrapperClass += this.message.lineId % 2 == 0 ? 'light' : 'dark';
        return wrapperClass;
    }

    get processedMessage() {
        if(!this.message?.content) {
            return '';
        }
        console.log(JSON.stringify(this.message));
        console.log(this.message.id);
        if(!this.message.content.includes('|')) {
            return this.message.content;
        }
        const parts = this.message.content.split('|');
        let processedTextArray = [];
        if(this.fieldVisibility.showDate) {
            processedTextArray.push(parts[0]);
        }
        if(this.fieldVisibility.showLogLevel && parts[1]) {
            processedTextArray.push(parts[1]);
        }
        if(this.fieldVisibility.showCreatedById && parts[2] && parts[2].startsWith('005')) {
            processedTextArray.push(parts[2]);
            if(this.fieldVisibility.showRequestId && parts[3] && parts.length >= 5) {
                processedTextArray.push(parts[3]);
                if(this.fieldVisibility.showContext && parts[4]) {
                    processedTextArray.push(parts[4]);
                }
                if(parts[4]) {
                    processedTextArray.push(parts.slice(5).join('|'));
                }
                return processedTextArray.join('|');
            }
            else if (parts[3]) {
                if(this.fieldVisibility.showContext && parts[3]) {
                    processedTextArray.push(parts[3]);
                }
                if(parts[3]) {
                    processedTextArray.push(parts.slice(4).join('|'));
                }
                return processedTextArray.join('|');
            }
        }
        else if(parts[2] && parts[2].startsWith('005')) {
            if(this.fieldVisibility.showRequestId && parts[3] && parts.length >= 5) {
                processedTextArray.push(parts[3]);
                if(this.fieldVisibility.showContext && parts[4]) {
                    processedTextArray.push(parts[4]);
                }
                processedTextArray.push(parts.slice(5).join('|'));
                return processedTextArray.join('|');
            }
            if (parts[4]) {
                if(this.fieldVisibility.showContext && parts[4]) {
                    processedTextArray.push(parts[4]);
                }
                processedTextArray.push(parts.slice(5).join('|'));
                
                return processedTextArray.join('|');
            }
        }
        else if (parts[2]) {
            if (this.fieldVisibility.showContext) {
                processedTextArray.push(parts[2])
            }
            processedTextArray.push(parts.slice(3).join('|'));

        }
        return processedTextArray.join('|');
    }
}