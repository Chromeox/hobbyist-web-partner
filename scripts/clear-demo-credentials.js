/**
 * Clear Demo Credentials Script
 *
 * Run this in your browser's DevTools console (F12) on the auth page
 * to clear any saved demo@hobbyist.com credentials from localStorage
 */

(function clearDemoCredentials() {
  const savedEmail = localStorage.getItem('hobbyist_remember_email');
  const rememberMe = localStorage.getItem('hobbyist_remember_me');

  console.log('Current saved credentials:');
  console.log('- Email:', savedEmail);
  console.log('- Remember me:', rememberMe);

  if (savedEmail === 'demo@hobbyist.com') {
    localStorage.removeItem('hobbyist_remember_email');
    localStorage.removeItem('hobbyist_remember_me');
    console.log('✅ Cleared demo@hobbyist.com from localStorage');
    console.log('Please reload the page');
  } else {
    console.log('ℹ️ No demo credentials found in localStorage');
  }
})();
