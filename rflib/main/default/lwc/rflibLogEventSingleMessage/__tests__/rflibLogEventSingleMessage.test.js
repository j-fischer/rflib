import { createElement } from 'lwc';
import RflibLogEventSingleMessage from 'c/rflibLogEventSingleMessage';

describe('c-rflib-log-event-single-message', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    async function setupElementComponent(props = {}) {
        const element = createElement('c-rflib-log-event-single-message', {
            is: RflibLogEventSingleMessage
        });
        // Ensure fieldVisibility is properly initialized
        console.log(props);
        if (props.fieldVisibility) {
            console.log(props.fieldVisibility);
            element.fieldVisibility = { ...props.fieldVisibility };
        }
        if (props.message) {
            console.log(props.message);
            element.message = { ...props.message };
        }
        document.body.appendChild(element);
        await Promise.resolve(); // Wait for the component to render
        return element;
    }

    it('Verify that the component handles JSON message rendering correctly.', () => {
        // Arrange
        const element = createElement('c-rflib-log-event-single-message', {
            is: RflibLogEventSingleMessage
        });
        element.message = {
            content: '{"key":"value"}',
            preview: 'JSON Preview',
            isJson: true,
            isText: false,
            formattedJson: '{"key":"value"}'
        };

        // Act
        document.body.appendChild(element);

        // Assert
        const jsonLabel = element.shadowRoot.querySelector('.json-label');
        expect(jsonLabel.textContent).toBe('JSON Preview');
    });

    it('Verify that the component handles text message with date.', async () => {
        // Arrange
        const message = {
            content: '2025-05-23T20:01:46.515Z|DEBUG|LogEventMonitor|Registering Error Listener',
            isJson: false,
            isText: true
        };
        const fieldVisibility = {
            showDate: true,
            showLogLevel: false,
            showContext: false,
            showCreatedBy: false
        };
        let element = await setupElementComponent({message: message, fieldVisibility: fieldVisibility});

        document.body.appendChild(element);
        await new Promise(resolve => setTimeout(resolve, 0));
        const dateText = element.shadowRoot.querySelectorAll('.text-message');
        const formattedText = dateText[0].querySelector('lightning-formatted-text');
        expect(formattedText.value).toBe('2025-05-23T20:01:46.515Z|Registering Error Listener');
    });

    it('Verify that the component handles text message log level rendering correctly.', async () => {
        // Arrange
        const message = {
            content: '2025-05-23T20:01:46.515Z|DEBUG|LogEventMonitor|Registering Error Listener',
            isJson: false,
            isText: true
        };
        const fieldVisibility = {
            showDate: false,
            showLogLevel: false,
            showContext: true,
            showCreatedBy: false
        };
        let element = await setupElementComponent({message: message, fieldVisibility: fieldVisibility});

        document.body.appendChild(element);
        await new Promise(resolve => setTimeout(resolve, 0));
        const dateText = element.shadowRoot.querySelectorAll('.text-message');
        const formattedText = dateText[0].querySelector('lightning-formatted-text');
        expect(formattedText.value).toBe('LogEventMonitor|Registering Error Listener');
    });

    it('Verify that the component expands and collapses JSON content correctly.', async () => {
        // Arrange
        const message = {
            content: '{"key":"value"}',
            preview: 'JSON Preview',
            isJson: true,
            isText: false,
            formattedJson: '{"key":"value"}'
        };
        const fieldVisibility = {
            showDate: true, 
            showLogLevel: true, 
            showContext: true, 
            showCreatedBy: true
        };
        const element = await setupElementComponent({message: message, fieldVisibility: fieldVisibility});


        // Act
        document.body.appendChild(element);

        // Assert initial state (collapsed)
        let jsonContent = element.shadowRoot.querySelector('.json-content');
        expect(jsonContent).toBeNull();
        await new Promise(resolve => setTimeout(resolve, 0));

        // Act: Click to expand
        const button = element.shadowRoot.querySelector('lightning-button-icon');
        button.click();
        await new Promise(resolve => setTimeout(resolve, 0));

        // Assert expanded state
        jsonContent = element.shadowRoot.querySelector('.json-content');
        expect(jsonContent).not.toBeNull();

        // Act: Click to collapse
        button.click();
        await new Promise(resolve => setTimeout(resolve, 0));

        // Assert collapsed state
        jsonContent = element.shadowRoot.querySelector('.json-content');
        expect(jsonContent).toBeNull();
    });
});