import {
  CognitoUserPool,
  CognitoUser,
  AuthenticationDetails,
  CognitoUserSession,
  CognitoUserAttribute,
} from 'amazon-cognito-identity-js';

export interface AuthConfig {
  userPoolId: string;
  clientId: string;
}

export interface AuthSession {
  idToken: string;
  accessToken: string;
  refreshToken: string;
}

export interface AuthClient {
  signIn(email: string, password: string): Promise<AuthSession>;
  signUp(email: string, password: string): Promise<void>;
  confirmSignUp(email: string, code: string): Promise<void>;
  signOut(): void;
  completeNewPassword(
    email: string,
    tempPassword: string,
    newPassword: string
  ): Promise<AuthSession>;
  forgotPassword(email: string): Promise<void>;
  confirmForgotPassword(
    email: string,
    code: string,
    newPassword: string
  ): Promise<void>;
  getSession(): Promise<AuthSession | null>;
  getIdToken(): Promise<string | null>;
  getCurrentUserEmail(): string | null;
}

export class NewPasswordRequiredError extends Error {
  constructor() {
    super('New password required');
    this.name = 'NewPasswordRequiredError';
  }
}

function sessionToAuthSession(session: CognitoUserSession): AuthSession {
  return {
    idToken: session.getIdToken().getJwtToken(),
    accessToken: session.getAccessToken().getJwtToken(),
    refreshToken: session.getRefreshToken().getToken(),
  };
}

export function createAuth(config: AuthConfig): AuthClient {
  const userPool = new CognitoUserPool({
    UserPoolId: config.userPoolId,
    ClientId: config.clientId,
  });

  function getCognitoUser(email: string): CognitoUser {
    return new CognitoUser({ Username: email, Pool: userPool });
  }

  function signIn(email: string, password: string): Promise<AuthSession> {
    return new Promise((resolve, reject) => {
      const user = getCognitoUser(email);
      const authDetails = new AuthenticationDetails({
        Username: email,
        Password: password,
      });

      user.authenticateUser(authDetails, {
        onSuccess(session) {
          resolve(sessionToAuthSession(session));
        },
        onFailure(err) {
          reject(err);
        },
        newPasswordRequired() {
          reject(new NewPasswordRequiredError());
        },
      });
    });
  }

  function signUp(email: string, password: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const emailAttribute = new CognitoUserAttribute({
        Name: 'email',
        Value: email,
      });

      userPool.signUp(email, password, [emailAttribute], [], (err) => {
        if (err) {
          reject(err);
        } else {
          resolve();
        }
      });
    });
  }

  function confirmSignUp(email: string, code: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const user = getCognitoUser(email);
      user.confirmRegistration(code, true, (err) => {
        if (err) {
          reject(err);
        } else {
          resolve();
        }
      });
    });
  }

  function signOut(): void {
    const user = userPool.getCurrentUser();
    if (user) {
      user.signOut();
    }
  }

  function completeNewPassword(
    email: string,
    tempPassword: string,
    newPassword: string
  ): Promise<AuthSession> {
    return new Promise((resolve, reject) => {
      const user = getCognitoUser(email);
      const authDetails = new AuthenticationDetails({
        Username: email,
        Password: tempPassword,
      });

      user.authenticateUser(authDetails, {
        onSuccess(session) {
          resolve(sessionToAuthSession(session));
        },
        onFailure(err) {
          reject(err);
        },
        newPasswordRequired() {
          user.completeNewPasswordChallenge(newPassword, {}, {
            onSuccess(session) {
              resolve(sessionToAuthSession(session));
            },
            onFailure(err) {
              reject(err);
            },
          });
        },
      });
    });
  }

  function forgotPassword(email: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const user = getCognitoUser(email);
      user.forgotPassword({
        onSuccess() {
          resolve();
        },
        onFailure(err) {
          reject(err);
        },
      });
    });
  }

  function confirmForgotPassword(
    email: string,
    code: string,
    newPassword: string
  ): Promise<void> {
    return new Promise((resolve, reject) => {
      const user = getCognitoUser(email);
      user.confirmPassword(code, newPassword, {
        onSuccess() {
          resolve();
        },
        onFailure(err) {
          reject(err);
        },
      });
    });
  }

  function getSession(): Promise<AuthSession | null> {
    return new Promise((resolve, reject) => {
      const user = userPool.getCurrentUser();
      if (!user) {
        resolve(null);
        return;
      }

      user.getSession(
        (err: Error | null, session: CognitoUserSession | null) => {
          if (err) {
            reject(err);
            return;
          }
          if (!session || !session.isValid()) {
            resolve(null);
            return;
          }
          resolve(sessionToAuthSession(session));
        }
      );
    });
  }

  async function getIdToken(): Promise<string | null> {
    const session = await getSession();
    return session?.idToken ?? null;
  }

  function getCurrentUserEmail(): string | null {
    const user = userPool.getCurrentUser();
    return user?.getUsername() ?? null;
  }

  return {
    signIn,
    signUp,
    confirmSignUp,
    signOut,
    completeNewPassword,
    forgotPassword,
    confirmForgotPassword,
    getSession,
    getIdToken,
    getCurrentUserEmail,
  };
}
