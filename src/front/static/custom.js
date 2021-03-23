// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/* EzDeploy Javascript Cookie Management */

function createCookie(name,value,hours) {
    if (days) {
        var date = new Date();
        date.setTime(date.getTime()+(hours*60*1000));
        var expires = "; expires="+date.toGMTString();
    }
    else var expires = "";
    document.cookie = name+"="+value+expires+"; path=/";
}

function readCookie(name) {
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(name+"=") == 0) return c.substring(name.length+1,c.length);
    }
    return null;
}
