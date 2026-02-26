import { hasAnUpdateAvailable } from '../versionCheckHelper';

describe('#hasAnUpdateAvailable', () => {
  it('always returns false (no-op)', () => {
    expect(hasAnUpdateAvailable('2.0.0', '1.0.0')).toBe(false);
    expect(hasAnUpdateAvailable(null, '1.0.0')).toBe(false);
  });
});
