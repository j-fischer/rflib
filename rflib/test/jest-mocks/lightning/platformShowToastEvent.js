export const ShowToastEventName = 'lightning__ShowToastEvent';

export class ShowToastEvent extends CustomEvent {
    constructor(toast) {
        super(ShowToastEventName, {
            composed: true,
            bubbles: true,
            detail: toast
        });
    }
}
