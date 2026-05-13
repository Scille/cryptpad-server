(function () {
  let readyTimeout = null;

  console.log('Forcing CryptPad theme to `light`');
  localStorage.setItem('CRYPTPAD_STORE|colortheme', 'light');
  localStorage.setItem('CRYPTPAD_STORE|colortheme_default', 'light');

  const CryptpadCommAPI = {
    Commands: {
      Ready: 'editics-ready',
      Hello: 'editics-hello',
      Init: 'editics-init',
      InitResult: 'editics-init-result',
      Open: 'editics-open',
      OpenResult: 'editics-open-result',
      Event: 'editics-event',
      Save: 'editics-save',
    },
    Events: {
      SaveStatus: 'save-status',
      Save: 'save',
      Error: 'error',
      Ready: 'ready',
    },
    ErrorCodes: {
      OpenInvalidConfig: 'open-invalid-config',
      OpenFailed: 'open-failed',
      InitFailed: 'init-failed',
    },
    Editors: {
      Pad: 'pad',
      Sheet: 'sheet',
      Doc: 'doc',
      Presentation: 'presentation',
      Code: 'code',
      Unsupported: 'unsupported',
    },
    OpenModes: {
      View: 'view',
      Edit: 'edit',
    },
    OpenDocumentOptions: ['documentContent', 'documentName', 'documentExtension', 'cryptpadEditor', 'key', 'userName', 'userId', 'autosaveInterval', 'mode', 'locale'],
  }

  let origin = undefined;
  let cryptpadInstance = undefined;

  function sendToParent(data) {
    window.parent.postMessage(data, origin);
  }

  function onReady() {
    if (readyTimeout !== null) {
      clearTimeout(readyTimeout)
      readyTimeout = null;
    }
    sendToParent({ command: CryptpadCommAPI.Commands.Event, event: CryptpadCommAPI.Events.Ready });
  }

  function onSave(file, callback) {
    sendToParent({ command: CryptpadCommAPI.Commands.Event, event: CryptpadCommAPI.Events.Save, documentContent: file });
    callback();
  }

  function onUnsavedChanges(unsaved) {
    sendToParent({ command: CryptpadCommAPI.Commands.Event, event: CryptpadCommAPI.Events.SaveStatus, saved: !unsaved });
  }

  function onError(...attrs) {
    sendToParent({ command: CryptpadCommAPI.Commands.Event, event: CryptpadCommAPI.Events.Error, details: attrs });
  }

  function initialize() {
    if (typeof window.CryptPadAPI === 'function') {
      sendToParent({ command: CryptpadCommAPI.Commands.InitResult, success: true });
    } else {
      sendToParent({ command: CryptpadCommAPI.Commands.InitResult, success: false, error: CryptpadCommAPI.ErrorCodes.InitFailed, details: "Missing 'CrytpadAPI on window object'."});
    }
  }

  function openFile(data) {
    let missing = [];
    for (const attr of CryptpadCommAPI.OpenDocumentOptions) {
      if (!(attr in data)) {
        missing.push(attr);
      }
    }
    if (missing.length > 0) {
      sendToParent({ command: CryptpadCommAPI.Commands.OpenResult, success: false, error: CryptpadCommAPI.ErrorCodes.OpenInvalidConfig, details: `Missing '${missing.join(', ')}'.`});
      return;
    }
    if (!Object.values(CryptpadCommAPI.Editors).includes(data.cryptpadEditor)) {
      sendToParent({ command: CryptpadCommAPI.Commands.OpenResult, success: false, error: CryptpadCommAPI.ErrorCodes.OpenInvalidConfig, details: `Invalid 'cryptpadEditor' (${data.cryptpadError}).`});
      return;
    }
    if (!Object.values(CryptpadCommAPI.OpenModes).includes(data.mode)) {
      sendToParent({ command: CryptpadCommAPI.Commands.OpenResult, success: false, error: CryptpadCommAPI.ErrorCodes.OpenInvalidConfig, details: `Invalid 'mode' (${data.mode}).`});
      return;
    }
    const documentUrl = URL.createObjectURL(new Blob([data.documentContent], { type: 'application/octet-stream' }));
    const config = {
      document: {
        url: documentUrl,
        fileType: data.documentExtension,
        title: data.documentName,
        key: data.key,
      },
      documentType: data.cryptpadEditor,
      editorConfig: {
        lang: data.locale,
        user: {
          name: data.userName,
          id: data.userId,
        }
      },
      autosave: data.autosaveInterval,
      mode: data.mode,
      events: {
        onSave: onSave,
        onHasUnsavedChanges: onUnsavedChanges,
        onError: onError,
        onReady: onReady,
      }
    };
    try {
      cryptpadInstance = window.CryptPadAPI(window.location.origin, 'editor-container', config);
      sendToParent({ command: CryptpadCommAPI.Commands.OpenResult, success: true });
      // Bug in view mode, onReady is never called
      if (data.mode !== 'view') {
        readyTimeout = setTimeout(() => {
          readyTimeout = null;
          onError('ready-timeout');
        }, 30000);
      }
    } catch (e) {
      sendToParent({ command: CryptpadCommAPI.Commands.OpenResult, success: false, error: CryptpadCommAPI.ErrorCodes.OpenFailed, details: e.toString() } );
    }
  }

  window.addEventListener('message', (event) => {
    if (!event.data.command) {
      console.log("Missing 'command', ignoring");
      return;
    }
    if (event.data.command === CryptpadCommAPI.Commands.Hello) {
      origin = event.origin;
      console.log(`Origin set to '${origin}'`);
      return;
    }
    if (!origin) {
      console.error("Origin is not set, send 'parsec-hello' command first.");
      return;
    }
    if (event.origin !== origin) {
      console.log(`Unknown origin '${event.origin}', ignoring`);
      return;
    }
    switch (event.data.command) {
      case CryptpadCommAPI.Commands.Init: {
        initialize();
        break;
      }
      case CryptpadCommAPI.Commands.Open: {
        openFile(event.data);
        break;
      }
      case CryptpadCommAPI.Commands.Save: {
        if (cryptpadInstance && typeof cryptpadInstance.save === 'function') {
          cryptpadInstance.save();
        } else {
          console.error('CryptPad instance not available or save not supported');
        }
        break;
      }
      default:
        console.error(`Unknown command '${event.data.command}'`);
        break;
    }
  });

  // Signaling everyone that we're ready
  window.parent.postMessage({ command: CryptpadCommAPI.Commands.Ready }, '*');
})();
