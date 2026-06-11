export const CurrentPageReference = (function () {
    let _dataCallback;
    const adapter = jest.fn().mockImplementation((dataCallback) => {
        _dataCallback = dataCallback;
        return {
            connect: jest.fn(),
            disconnect: jest.fn(),
            update: jest.fn()
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

const navigateMock = jest.fn();

export const NavigationMixin = (Base) => {
    return class extends Base {
        [NavigationMixin.Navigate] = navigateMock;
        [NavigationMixin.GenerateUrl] = jest.fn();
    };
};
NavigationMixin.Navigate = Symbol('Navigate');
NavigationMixin.GenerateUrl = Symbol('GenerateUrl');

export function getNavigateCalledWith() {
    const calls = navigateMock.mock.calls;
    return calls.length ? calls[calls.length - 1][0] : null;
}
