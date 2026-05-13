// SPDX-FileCopyrightText: 2023 XWiki CryptPad Team <contact@cryptpad.org> and contributors
//
// SPDX-License-Identifier: AGPL-3.0-or-later

// <Parsec customization> removed 'jquery' and '/common/outer/local-store.js' dependencies (link removed)
define([
    '/api/config',
    '/common/hyperscript.js',
    '/customize/messages.js',

    'less!/customize/src/less2/pages/page-404.less',
], function (Config, h, Messages) {
// </Parsec customization>
    var urlArgs = Config.requireConf.urlArgs;
    var img = h('img#cp-logo', {
        src: '/customize/CryptPad_logo_grey.svg?' + urlArgs
    });

    var is500 = Boolean(document.querySelector('#five-hundred'));
    // <Parsec customization>
    var brand = h('h1#cp-brand', 'Parsec');
    // </Parsec customization>
    // Msg.fivehundred_internalServerError.four04_pageNotFound
    var message = h('h2#cp-scramble', Messages[is500? 'fivehundred_internalServerError':'four04_pageNotFound']);
    var title = h('h2#cp-title', is500? "500":"404");

    // <Parsec customization> removed link element (loggedIn, link variable, click handler)
    var content = h('div#cp-main', [
        img,
        brand,
        title,
        message,
    ]);
    // </Parsec customization>
    document.body.appendChild(content);

    var die = function (n) { return Math.floor(Math.random() * n); };
    var randomChar = function () {
        return String.fromCharCode(die(94) + 34);
    };
    var mutate = function (S, i, c) {
        var A = S.split("");
        A[i] = c;
        return A.join("");
    };

    var take = function (A) {
        var n = die(A.length);
        var choice = A[n];
        A.splice(n, 1);
        return choice;
    };

    var makeDecryptor = function (el, t, difficulty, cb) {
        var Orig = el.innerText;
        var options = [];
        el.innerText = el.innerText.split("").map(function (c, i) {
            Orig[i] = c;
            options.push(i);
            return randomChar();
        }).join("");

        return function f () {
            if (die(difficulty) === 0) {
                var choice = take(options);
                el.innerText = mutate(el.innerText, choice, Orig.charAt(choice));
            } else { // make a superficial change
                el.innerText = mutate(el.innerText,
                    options[die(options.length)],
                    randomChar());
            }
            setTimeout(options.length > 0? f: cb, t);
        };
    };

    makeDecryptor(brand, 70, 2, function () { })();
    makeDecryptor(title, 50, 14, function () { })();
    // <Parsec customization> removed makeDecryptor(link, ...)
    // </Parsec customization>
    makeDecryptor(message, 12, 3, function () {
        console.log('done');
    })();
});

