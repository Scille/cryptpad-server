// SPDX-FileCopyrightText: 2023 XWiki CryptPad Team <contact@cryptpad.org> and contributors
//
// SPDX-License-Identifier: AGPL-3.0-or-later

(function () {
var logoPath = '/customize/CryptPad_logo_grey.svg';

var elem = document.createElement('div');
elem.setAttribute('id', 'placeholder');
elem.innerHTML = `
<div></div>
<div class="placeholder-message-container">
    <p>Loading...</p>
</div>
<div id="placeholder-loading-footer">
    <div class="placeholder-logo-container">
        <!-- <Parsec customization> -->
        <img class="placeholder-logo" alt="" aria-hidden="true" src="${logoPath}"><span>Parsec</span>
        <!-- </Parsec customization> -->
    </div>
    <div id="placeholder-loading-status">
        <i data-lucide="lock" aria-hidden="true"></i>
        <span>End-to-end encrypted</span>
    </div>
</div>
`;

var key = 'CRYPTPAD_STORE|colortheme'; // handle outer
if (localStorage[key] && localStorage[key] === 'dark') {
    // <Parsec customization>
    localStorage[key] = 'light'; // Override any dark theme setting
    //elem.classList.add('dark-theme');
    // </Parsec customization>
}
if (!localStorage[key] && localStorage[key+'_default'] && localStorage[key+'_default'] === 'dark') {
    // <Parsec customization>
    localStorage[key+'_default'] = 'light'; // Override OS dark theme detection
    // elem.classList.add('dark-theme');
    // </Parsec customization>
}

var req;
try {
    req = JSON.parse(decodeURIComponent(window.location.hash.substring(1)));
    if ((req.theme || req.themeOS) === 'dark') { // handle inner
        // <Parsec customization>
        // Force override dark theme from URL params
        req.theme = 'light';
        req.themeOS = 'light';
        // elem.classList.add('dark-theme');
        // </Parsec customization>
    }
} catch (e) {}

document.addEventListener('DOMContentLoaded', function() {
    document.body.appendChild(elem);
    window.CP_preloadingTime = +new Date();

    // soft transition between inner and outer placeholders
    if (req && req.time && (+new Date() - req.time > 2000)) {
        try {
            var logo = document.querySelector('.placeholder-logo-container');
            var message = document.querySelector('.placeholder-message-container');
            logo.style.opacity = 100;
            message.style.opacity = 100;
            logo.style.animation = 'none';
            message.style.animation = 'none';
        } catch (err) {}
    }

    // fallback if CSS animations not available
    setTimeout(() => {
        try {
            document.querySelector('.placeholder-logo-container').style.opacity = 100;
            document.querySelector('.placeholder-message-container').style.opacity = 100;
        } catch (e) {}
    }, 3000);
});
}());
