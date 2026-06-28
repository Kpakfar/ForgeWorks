import { describe, expect, it } from 'vitest';
import { greet } from '../src/example';

describe('greet', () => {
  it('includes the name', () => {
    expect(greet('world')).toBe('Hello, world!');
  });
});
