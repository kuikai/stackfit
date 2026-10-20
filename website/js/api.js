import { ensureSnapshot, mergeSnapshots } from './snapshot.js';

export class AccountApi {
  async signUp({ email, password, displayName }) {
    return this.#send('POST', '/v1/auth/signup', {
      body: { email, password, displayName },
    });
  }

  async signIn({ email, password }) {
    return this.#send('POST', '/v1/auth/signin', {
      body: { email, password },
    });
  }

  async signOut(token) {
    await this.#send('POST', '/v1/auth/signout', { token });
  }

  async requestReset(email) {
    return this.#send('POST', '/v1/auth/request-reset', {
      body: { email },
    });
  }

  async resetPassword({ email, code, password }) {
    return this.#send('POST', '/v1/auth/reset', {
      body: { email, code, password },
    });
  }

  async listShares(token) {
    return this.#send('GET', '/v1/shares', { token });
  }

  async createShare(token, body) {
    return this.#send('POST', '/v1/shares', { token, body });
  }

  async readShare(token) {
    return this.#send('GET', `/v1/shares/${token}`);
  }

  async disableShare(token, shareToken) {
    return this.#send('POST', `/v1/shares/${shareToken}/disable`, { token });
  }

  async load(token) {
    const data = await this.#send('GET', '/v1/sync', { token });
    return {
      revision: data.revision ?? 0,
      displayName: data.displayName ?? '',
      snapshot: ensureSnapshot(data.snapshot),
    };
  }

  async save(token, revision, snapshot) {
    let baseRevision = revision;
    let next = snapshot;
    for (let attempt = 0; attempt < 3; attempt += 1) {
      const result = await this.#raw('PUT', '/v1/sync', {
        token,
        body: { baseRevision, snapshot: next },
      });
      if (result.ok) {
        return {
          revision: result.data.revision ?? baseRevision,
          snapshot: ensureSnapshot(result.data.snapshot),
        };
      }
      if (result.status === 409 && result.data.snapshot && attempt < 2) {
        next = mergeSnapshots(next, ensureSnapshot(result.data.snapshot));
        baseRevision = result.data.revision;
        continue;
      }
      throw new Error(result.data.message || 'Could not save.');
    }
    throw new Error('Could not save.');
  }

  async #send(method, path, options = {}) {
    const result = await this.#raw(method, path, options);
    if (!result.ok) {
      throw new Error(result.data.message || 'Something went wrong.');
    }
    return result.data;
  }

  async #raw(method, path, { token, body } = {}) {
    let response;
    try {
      response = await fetch(path, {
        method,
        headers: {
          'content-type': 'application/json',
          ...(token ? { authorization: `Bearer ${token}` } : {}),
        },
        body: body == null ? undefined : JSON.stringify(body),
      });
    } catch {
      throw new Error('Cannot reach the account server.');
    }
    return {
      ok: response.ok,
      status: response.status,
      data: await readJson(response),
    };
  }
}

async function readJson(response) {
  try {
    const data = await response.json();
    return data && typeof data === 'object' ? data : {};
  } catch {
    return {};
  }
}
