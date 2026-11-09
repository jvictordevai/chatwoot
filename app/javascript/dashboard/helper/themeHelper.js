import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

// Community: light is the default. Users can switch to dark or follow the OS
// ('auto') from the Appearance menu.
export const DEFAULT_COLOR_SCHEME = 'light';

export const getSelectedColorScheme = () =>
  LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || DEFAULT_COLOR_SCHEME;

export const isDarkColorScheme = isOSOnDarkMode => {
  const selectedColorScheme = getSelectedColorScheme();
  return (
    (selectedColorScheme === 'auto' && isOSOnDarkMode) ||
    selectedColorScheme === 'dark'
  );
};

export const setColorTheme = isOSOnDarkMode => {
  if (isDarkColorScheme(isOSOnDarkMode)) {
    document.body.classList.add('dark');
    document.documentElement.style.setProperty('color-scheme', 'dark');
  } else {
    document.body.classList.remove('dark');
    document.documentElement.style.setProperty('color-scheme', 'light');
  }
};
