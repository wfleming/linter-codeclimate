'use babel';

import { join } from 'path';

const fixturesPath = join(__dirname, 'fixtures');
const coolCodePath = join(fixturesPath, 'cool_code.rb');

describe('The codeclimate provider for Linter', () => {
  const lint = require('../lib/index.js').provideLinter().lint;

  beforeEach(() => {
    atom.workspace.destroyActivePaneItem();

    waitsForPromise(() =>
      Promise.all([
        atom.packages.activatePackage('language-ruby'),
        atom.packages.activatePackage('linter-codeclimate'),
      ]),
    );
  });

  it('works with a valid .codeclimate.yml file', () =>
    waitsForPromise(() =>
      atom.workspace.open(coolCodePath).then(editor => lint(editor)).then(
        (messages) => {
          expect(messages[0].type).toBe('Warning');
          expect(messages[0].text).toBe('some text');
          expect(messages[0].html).not.toBeDefined();
          expect(messages[0].filePath).toBe(coolCodePath);
          expect(messages[0].range).toEqual([[0, 5], [0, 7]]);
        },
      ),
    ),
  );
});
