import { shareTokenFromPath, showLocalWorkout } from './sharing.js';

export function installAuth(app) {
  document.querySelector('#sign-in-form').addEventListener('submit', (event) => {
    onSignIn(event, app);
  });
  document.querySelector('#sign-up-form').addEventListener('submit', (event) => {
    onSignUp(event, app);
  });
  document.querySelector('#request-reset-form').addEventListener('submit', (event) => {
    onRequestReset(event, app);
  });
  document.querySelector('#finish-reset-form').addEventListener('submit', (event) => {
    onFinishReset(event, app);
  });
  document.querySelector('#sign-out').addEventListener('click', () => onSignOut(app));
  document.querySelector('#delete-account').addEventListener('click', () => openDeleteAccount());
  document.querySelector('#cancel-delete').addEventListener('click', () => closeDeleteAccount());
  document.querySelector('#delete-account-form').addEventListener('submit', (event) => {
    onDeleteAccount(event, app);
  });
}

async function onSignIn(event, app) {
  event.preventDefault();
  await authenticate(app, () => app.api.signIn(formValues(event.target)));
}

async function onSignUp(event, app) {
  event.preventDefault();
  const values = formValues(event.target);
  await authenticate(app, () => app.api.signUp(values));
}

async function authenticate(app, request) {
  app.clearBanner();
  try {
    const data = await request();
    app.storeAccount(data);
    const returnShare = sessionStorage.getItem('stackfit.returnShare');
    sessionStorage.removeItem('stackfit.returnShare');
    if (returnShare) {
      window.location.assign(`/s/${returnShare}`);
      return;
    }
    await app.refresh();
    const pendingRoutine = sessionStorage.getItem('stackfit.pendingRoutine');
    sessionStorage.removeItem('stackfit.pendingRoutine');
    if (pendingRoutine) {
      showLocalWorkout(JSON.parse(pendingRoutine), app);
    }
  } catch (error) {
    app.showBanner(error.message);
  }
}

async function onRequestReset(event, app) {
  event.preventDefault();
  app.clearBanner();
  try {
    const email = document.querySelector('#reset-email').value;
    await app.api.requestReset(email);
    app.showBanner('If that email has an account, the code was printed by the server.', 'ok');
  } catch (error) {
    app.showBanner(error.message);
  }
}

async function onFinishReset(event, app) {
  event.preventDefault();
  app.clearBanner();
  try {
    await app.api.resetPassword({
      email: document.querySelector('#reset-email').value,
      code: document.querySelector('#reset-code').value,
      password: document.querySelector('#reset-password').value,
    });
    app.showAuth('sign-in-panel');
    app.showBanner('Password updated. Sign in with the new password.', 'ok');
  } catch (error) {
    app.showBanner(error.message);
  }
}

function openDeleteAccount() {
  const password = document.querySelector('#delete-password');
  password.value = '';
  document.querySelector('#delete-error').hidden = true;
  document.querySelector('#delete-account-panel').hidden = false;
  password.focus();
}

function closeDeleteAccount() {
  document.querySelector('#delete-account-panel').hidden = true;
}

async function onDeleteAccount(event, app) {
  event.preventDefault();
  app.clearBanner();
  try {
    await app.api.deleteAccount(
      app.account.token,
      document.querySelector('#delete-password').value,
    );
    app.clearAccount();
    closeDeleteAccount();
    if (window.location.pathname !== '/') {
      history.replaceState(null, '', '/');
    }
    app.showSignedOut('');
    app.showBanner(
      'Account deleted. Workouts on a phone stay on that phone.',
      'ok',
    );
  } catch (error) {
    const errorLine = document.querySelector('#delete-error');
    errorLine.hidden = false;
    errorLine.textContent = error.message;
  }
}

async function onSignOut(app) {
  const token = app.account.token;
  app.clearAccount();
  if (shareTokenFromPath()) {
    document.querySelector('#account-bar').hidden = true;
    document.querySelector('#signed-out').hidden = true;
  } else {
    app.showSignedOut('');
  }
  try {
    await app.api.signOut(token);
  } catch {
    // The device is already signed out. The server token can expire unused.
  }
}

function formValues(form) {
  const data = new FormData(form);
  return {
    email: String(data.get('email') || '').trim(),
    password: String(data.get('password') || ''),
    displayName: String(data.get('displayName') || '').trim(),
  };
}
