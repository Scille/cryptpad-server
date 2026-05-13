// SPDX-FileCopyrightText: 2023 XWiki CryptPad Team <contact@cryptpad.org> and contributors
//
// SPDX-License-Identifier: AGPL-3.0-or-later

define(['/common/translations/messages.js'], function (Messages) {
    // <Parsec customization>
    Messages.error_missingDependency = "Could not load a dependency. Could be linked to network troubles. Please try again.";
    Messages.error_unknownError = "An unknown error occurred.";
    Messages.loading_encrypted = "Secure connection";
    // </Parsec customization>

    return Messages;
});
