document.addEventListener('DOMContentLoaded', () => {
    // Elements
    const authContainer = document.getElementById('authContainer');
    const accountContainer = document.getElementById('accountContainer');
    const forgotPasswordContainer = document.getElementById('forgotPasswordContainer');

    // Auth Forms
    const authForm = document.getElementById('authForm');
    const authTitle = document.getElementById('authTitle');
    const authEmail = document.getElementById('authEmail');
    const authPassword = document.getElementById('authPassword');
    const authSubmitBtn = document.getElementById('authSubmitBtn');
    const authError = document.getElementById('authError');
    const toggleAuthModeBtn = document.getElementById('toggleAuthModeBtn');
    const forgotPasswordLink = document.getElementById('forgotPasswordLink');

    // Forgot Password Forms
    const forgotRequestForm = document.getElementById('forgotRequestForm');
    const forgotConfirmForm = document.getElementById('forgotConfirmForm');
    const forgotEmailInput = document.getElementById('forgotEmail');
    const forgotCodeInput = document.getElementById('forgotCode');
    const forgotNewPasswordInput = document.getElementById('forgotNewPassword');
    const forgotAlert = document.getElementById('forgotAlert');
    const forgotDisplayEmail = document.getElementById('forgotDisplayEmail');
    const backToLoginBtn = document.getElementById('backToLoginBtn');

    // Account Forms
    const userAvatar = document.getElementById('userAvatar');
    const userEmailDisplay = document.getElementById('userEmailDisplay');
    const signOutBtn = document.getElementById('signOutBtn');

    // Change Password
    const cpAlert = document.getElementById('cpAlert');
    const cpRequestForm = document.getElementById('cpRequestForm');
    const cpConfirmForm = document.getElementById('cpConfirmForm');
    const cpCodeInput = document.getElementById('cpCode');
    const cpNewPasswordInput = document.getElementById('cpNewPassword');
    const cpCancelBtn = document.getElementById('cpCancelBtn');

    // Stats Dashboard Elements
    const statsDashboard = document.getElementById('statsDashboard');
    const statPorn = document.getElementById('statPorn');
    const statMast = document.getElementById('statMast');
    const statUrges = document.getElementById('statUrges');

    const statPureThoughtsBox = document.getElementById('statPureThoughtsBox');
    const statPureThoughts = document.getElementById('statPureThoughts');

    const statHoursBox = document.getElementById('statHoursBox');
    const statHours = document.getElementById('statHours');

    const toggleExamens = document.getElementById('toggleExamens');
    const toggleUrges = document.getElementById('toggleUrges');
    const toggleRelapses = document.getElementById('toggleRelapses');

    // State
    let isLoginMode = true;
    let forgotEmailStr = ''; // Stores email during forgot password flow
    let userPayload = null; // Stores the raw payload from /me

    // --- Utility ---
    function getToken() {
        return localStorage.getItem('purity_token');
    }

    function setToken(token) {
        localStorage.setItem('purity_token', token);
    }

    function clearToken() {
        localStorage.removeItem('purity_token');
    }

    function showAlert(element, message, isSuccess = false) {
        element.textContent = message;
        element.className = 'alert ' + (isSuccess ? 'alert-success' : 'alert-error');
        element.classList.remove('hidden');
    }

    function hideAlert(element) {
        element.classList.add('hidden');
        element.textContent = '';
    }

    // --- View Management ---
    function updateView() {
        const token = getToken();
        hideAlert(authError);
        hideAlert(forgotAlert);
        hideAlert(cpAlert);

        if (token) {
            authContainer.classList.add('hidden');
            forgotPasswordContainer.classList.add('hidden');
            accountContainer.classList.remove('hidden');
            fetchUserProfile();
        } else {
            accountContainer.classList.add('hidden');
            forgotPasswordContainer.classList.add('hidden');
            authContainer.classList.remove('hidden');
            resetAuthForm();
        }
    }

    function showForgotPasswordView() {
        authContainer.classList.add('hidden');
        accountContainer.classList.add('hidden');
        forgotPasswordContainer.classList.remove('hidden');

        hideAlert(forgotAlert);
        forgotRequestForm.classList.remove('hidden');
        forgotConfirmForm.classList.add('hidden');
        forgotEmailInput.value = '';
        forgotCodeInput.value = '';
        forgotNewPasswordInput.value = '';
    }

    // --- Auth Flow ---
    toggleAuthModeBtn.addEventListener('click', () => {
        isLoginMode = !isLoginMode;
        authTitle.textContent = isLoginMode ? 'Log In' : 'Create an account';
        authSubmitBtn.textContent = isLoginMode ? 'Log In' : 'Sign Up';
        toggleAuthModeBtn.textContent = isLoginMode ? 'Create an account' : 'I already have an account';
        hideAlert(authError);
    });

    authForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        hideAlert(authError);
        const email = authEmail.value;
        const password = authPassword.value;
        const endpoint = isLoginMode ? '/auth/login' : '/auth/signup';

        if (!isLoginMode && password.length < 8) {
            showAlert(authError, 'Password must be at least 8 characters.');
            return;
        }

        try {
            authSubmitBtn.disabled = true;
            const res = await fetch(endpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, password })
            });
            const data = await res.json();

            if (!res.ok) throw new Error(data.error || 'Authentication failed');

            setToken(data.token);
            updateView();
        } catch (err) {
            showAlert(authError, err.message);
        } finally {
            authSubmitBtn.disabled = false;
        }
    });

    function resetAuthForm() {
        authEmail.value = '';
        authPassword.value = '';
    }

    signOutBtn.addEventListener('click', () => {
        clearToken();
        updateView();
    });

    forgotPasswordLink.addEventListener('click', () => {
        showForgotPasswordView();
    });

    backToLoginBtn.addEventListener('click', () => {
        updateView();
    });

    // --- Forgot Password Flow (Unauthenticated) ---

    // To avoid adding a new endpoint specifically for unauthenticated reset requests
    // Let's implement this by calling /auth/request-reset AFTER authenticating them minimally or 
    // actually... the backend currently REQUIRES a Bearer token for /auth/request-reset.
    // Wait, if it's "Forgot Password", they don't have a Bearer token because they can't log in!
    // I need to add an unauthenticated /auth/forgot-password to the backend next. 
    // For now, I'll wire it to /auth/forgot-password and /auth/forgot-password-confirm

    forgotRequestForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        hideAlert(forgotAlert);
        const email = forgotEmailInput.value;
        forgotEmailStr = email;
        const btn = document.getElementById('forgotRequestBtn');

        try {
            btn.disabled = true;
            const res = await fetch('/auth/forgot-password', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email })
            });
            const data = await res.json();

            if (!res.ok) throw new Error(data.error || 'Failed to request reset.');

            // Move to step 2
            forgotRequestForm.classList.add('hidden');
            forgotConfirmForm.classList.remove('hidden');
            forgotDisplayEmail.textContent = email;
            showAlert(forgotAlert, 'Reset code sent!', true);
        } catch (err) {
            showAlert(forgotAlert, err.message);
        } finally {
            btn.disabled = false;
        }
    });

    forgotConfirmForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        hideAlert(forgotAlert);
        const code = forgotCodeInput.value;
        const newPassword = forgotNewPasswordInput.value;
        const btn = document.getElementById('forgotConfirmBtn');

        try {
            btn.disabled = true;
            const res = await fetch('/auth/forgot-password-confirm', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email: forgotEmailStr, code, newPassword })
            });
            const data = await res.json();

            if (!res.ok) throw new Error(data.error || 'Invalid code.');

            showAlert(forgotAlert, 'Password updated! Logging you in...', true);

            // Auto login with new password
            const loginRes = await fetch('/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email: forgotEmailStr, password: newPassword })
            });
            const loginData = await loginRes.json();
            if (loginRes.ok && loginData.token) {
                setToken(loginData.token);
                setTimeout(updateView, 1500);
            } else {
                setTimeout(updateView, 1500); // go to login screen
            }
        } catch (err) {
            showAlert(forgotAlert, err.message);
        } finally {
            btn.disabled = false;
        }
    });


    // --- Account Data ---
    async function fetchUserProfile() {
        const token = getToken();
        userEmailDisplay.textContent = 'Loading...';
        statsDashboard.classList.add('hidden');

        try {
            // First fetch the email (we need a direct /auth/me for this since /me just returns payload)
            // Wait, the backend has /auth/me which returns { email }. Let's fetch that.
            const userRes = await fetch('/auth/me', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!userRes.ok) {
                if (userRes.status === 401) clearToken();
                throw new Error('Failed to fetch profile');
            }
            const userData = await userRes.json();
            userEmailDisplay.textContent = userData.email;
            userAvatar.textContent = userData.email.charAt(0).toUpperCase();

            // Next, fetch the sync payload from /me to build the dashboard
            const syncRes = await fetch('/me', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (syncRes.ok) {
                const syncData = await syncRes.json();
                userPayload = syncData.payload || {};
                renderStatsDashboard();
            }
        } catch (err) {
            console.error(err);
            if (!getToken()) updateView();
        }
    }

    function renderStatsDashboard() {
        if (!userPayload || Object.keys(userPayload).length === 0) {
            statsDashboard.classList.add('hidden');
            return;
        }

        statsDashboard.classList.remove('hidden');

        // Populate core stats
        statPorn.textContent = userPayload.pornographyDays || 0;
        statMast.textContent = userPayload.masturbationDays || 0;
        statUrges.textContent = userPayload.urgeMomentsCount || 0;

        // Optional stats
        if (userPayload.pureThoughtsDays !== undefined) {
            statPureThoughtsBox.style.display = 'block';
            statPureThoughts.textContent = userPayload.pureThoughtsDays;
        } else {
            statPureThoughtsBox.style.display = 'none';
        }

        if (userPayload.hoursReclaimed !== undefined && userPayload.hoursReclaimed > 0) {
            statHoursBox.style.display = 'block';
            statHours.textContent = userPayload.hoursReclaimed;
        } else {
            statHoursBox.style.display = 'none';
        }

        // Load toggle states from localStorage or default to true
        toggleExamens.checked = localStorage.getItem('shareExamens') !== 'false';
        toggleUrges.checked = localStorage.getItem('shareUrges') !== 'false';
        toggleRelapses.checked = localStorage.getItem('shareRelapses') !== 'false';
    }

    // Handle Toggle Saves
    toggleExamens.addEventListener('change', (e) => localStorage.setItem('shareExamens', e.target.checked));
    toggleUrges.addEventListener('change', (e) => localStorage.setItem('shareUrges', e.target.checked));
    toggleRelapses.addEventListener('change', (e) => localStorage.setItem('shareRelapses', e.target.checked));

    // --- Change Password Flow (Authenticated) ---
    cpRequestForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        hideAlert(cpAlert);
        const btn = document.getElementById('cpRequestBtn');

        try {
            btn.disabled = true;
            const res = await fetch('/auth/request-reset', {
                method: 'POST',
                headers: { 'Authorization': `Bearer ${getToken()}` }
            });
            const data = await res.json();

            if (!res.ok) throw new Error(data.error || 'Failed to send code.');

            cpRequestForm.classList.add('hidden');
            cpConfirmForm.classList.remove('hidden');
            showAlert(cpAlert, 'Code sent to your email!', true);
        } catch (err) {
            showAlert(cpAlert, err.message);
        } finally {
            btn.disabled = false;
        }
    });

    cpConfirmForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        hideAlert(cpAlert);
        const code = cpCodeInput.value;
        const newPassword = cpNewPasswordInput.value;
        const btn = document.getElementById('cpConfirmBtn');

        try {
            btn.disabled = true;
            const res = await fetch('/auth/confirm-reset', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${getToken()}`
                },
                body: JSON.stringify({ code, newPassword })
            });
            const data = await res.json();

            if (!res.ok) throw new Error(data.error || 'Invalid code.');

            showAlert(cpAlert, 'Password successfully changed!', true);
            cpConfirmForm.classList.add('hidden');
            cpRequestForm.classList.remove('hidden');
            cpCodeInput.value = '';
            cpNewPasswordInput.value = '';

            setTimeout(() => hideAlert(cpAlert), 3000);
        } catch (err) {
            showAlert(cpAlert, err.message);
        } finally {
            btn.disabled = false;
        }
    });

    cpCancelBtn.addEventListener('click', () => {
        cpConfirmForm.classList.add('hidden');
        cpRequestForm.classList.remove('hidden');
        cpCodeInput.value = '';
        cpNewPasswordInput.value = '';
        hideAlert(cpAlert);
    });

    // Init
    updateView();
});
