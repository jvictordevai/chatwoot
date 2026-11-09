// Bump when the favicons change: /public files are cached for a year, so a
// new query string is what makes browsers fetch the Community icons.
export const FAVICON_VERSION = 'cca2';

const faviconPath = name => `/${name}.png?v=${FAVICON_VERSION}`;

export const showBadgeOnFavicon = () => {
  const favicons = document.querySelectorAll('.favicon');

  favicons.forEach(favicon => {
    favicon.href = faviconPath(`favicon-badge-${favicon.sizes[[0]]}`);
  });
};

export const initFaviconSwitcher = () => {
  const favicons = document.querySelectorAll('.favicon');

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      favicons.forEach(favicon => {
        favicon.href = faviconPath(`favicon-${favicon.sizes[[0]]}`);
      });
    }
  });
};
