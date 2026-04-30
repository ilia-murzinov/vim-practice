// Utility functions — general purpose helpers

const DEFAULT_TIMEOUT = 5000;
const MAX_RETRIES = 3;
const BASE_URL = 'https://api.example.com/v1';

function debounce(fn, delay = DEFAULT_TIMEOUT) {
  let timer;
  return function (...args) {
    clearTimeout(timer);
    timer = setTimeout(() => fn.apply(this, args), delay);
  };
}

function throttle(fn, limit) {
  let lastCall = 0;
  return function (...args) {
    const now = Date.now();
    if (now - lastCall >= limit) {
      lastCall = now;
      return fn.apply(this, args);
    }
  };
}

async function fetchWithRetry(url, options = {}, retries = MAX_RETRIES) {
  try {
    const response = await fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...options.headers,
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return response.json();
  } catch (err) {
    if (retries > 0) {
      await sleep(500 * (MAX_RETRIES - retries + 1));
      return fetchWithRetry(url, options, retries - 1);
    }
    throw err;
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function groupBy(array, keyFn) {
  return array.reduce((acc, item) => {
    const key = keyFn(item);
    if (!acc[key]) acc[key] = [];
    acc[key].push(item);
    return acc;
  }, {});
}

function pick(obj, keys) {
  return keys.reduce((acc, key) => {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      acc[key] = obj[key];
    }
    return acc;
  }, {});
}

function omit(obj, keys) {
  const keysToOmit = new Set(keys);
  return Object.fromEntries(
    Object.entries(obj).filter(([key]) => !keysToOmit.has(key))
  );
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function formatCurrency(amount, currency = 'USD', locale = 'en-US') {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount / 100);
}

function parseQueryString(qs) {
  return Object.fromEntries(new URLSearchParams(qs));
}

function buildQueryString(params) {
  return new URLSearchParams(
    Object.entries(params).filter(([, v]) => v !== null && v !== undefined)
  ).toString();
}

module.exports = {
  debounce,
  throttle,
  fetchWithRetry,
  sleep,
  groupBy,
  pick,
  omit,
  clamp,
  formatCurrency,
  parseQueryString,
  buildQueryString,
};
