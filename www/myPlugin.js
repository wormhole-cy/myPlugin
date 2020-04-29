var exec = require('cordova/exec');

myPlugin.openTaobao = function (url, showParams, taoKeParams, trackParams, success, error) {
    exec(success, error, 'myPlugin', 'openTaobao', [url, showParams, taoKeParams, trackParams]);
};

myPlugin.openJD = function (url, userInfo, success, error) {
    exec(success, error, 'myPlugin', 'openJD', [url, userInfo]);
};
