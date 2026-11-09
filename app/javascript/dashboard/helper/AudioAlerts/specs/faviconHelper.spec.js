import { showBadgeOnFavicon, initFaviconSwitcher } from '../faviconHelper';

const addFavicon = size => {
  const link = document.createElement('link');
  link.className = 'favicon';
  // jsdom has no HTMLLinkElement#sizes; browsers expose it as a token list
  Object.defineProperty(link, 'sizes', { value: [size] });
  link.href = `/favicon-${size}.png`;
  document.head.appendChild(link);
  return link;
};

describe('faviconHelper', () => {
  afterEach(() => {
    document.head.innerHTML = '';
  });

  it('switches to the versioned badge favicon so browsers skip stale caches', () => {
    const link = addFavicon('32x32');

    showBadgeOnFavicon();

    expect(link.getAttribute('href')).toBe('/favicon-badge-32x32.png?v=cca2');
  });

  it('restores the versioned favicon when the tab becomes visible', () => {
    const link = addFavicon('16x16');
    initFaviconSwitcher();
    showBadgeOnFavicon();

    document.dispatchEvent(new Event('visibilitychange'));

    expect(link.getAttribute('href')).toBe('/favicon-16x16.png?v=cca2');
  });
});
