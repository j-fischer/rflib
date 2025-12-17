export const CurrentPageReference = (function() {
    let _dataCallback;
    const adapter = jest.fn().mockImplementation((dataCallback) => {
        _dataCallback = dataCallback;
        return {
            connect: jest.fn(),
            disconnect: jest.fn(),
            update: jest.fn(),
        };
    });
    adapter.emit = (value) => {
        if (_dataCallback) {
            _dataCallback(value);
        }
    };
    adapter.getLastConfig = jest.fn();
    return adapter;
})();

export const NavigationMixin = (Base) => {
    return class extends Base {
        [NavigationMixin.Navigate] = jest.fn();
        [NavigationMixin.GenerateUrl] = jest.fn();
    };
};
NavigationMixin.Navigate = 'lightning__UrlAddressable';
NavigationMixin.GenerateUrl = 'lightning__UrlAddressable';
