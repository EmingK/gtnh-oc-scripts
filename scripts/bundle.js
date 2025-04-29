/*
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
*/

import path from 'path';
import fs from 'fs-extra';
import { bundle } from 'luabundle';

const targets = [
  {
    name: 'reactor',
    entry: 'reactor/main.lua',
    resources: 'res/reactor',
  }
];

const multilineCommentPattern = /--\[\[.*?\]\]/gs;

function stripComments(module) {
  return module.content
          .replaceAll(multilineCommentPattern, '')
          .replaceAll('shell.parse(...)', 'table.unpack(_argv)');
}

function buildTarget(cfg) {
  // Create dist dir
  fs.mkdirpSync(`dist/${cfg.name}`);

  const bundled = bundle(
    cfg.entry,
    {
      ignoredModuleNames: ['pal'],
      preprocess: stripComments
    }
  );

  const finalSrc = `local _argv = table.pack(require('shell').parse(...))
  ${bundled}`

  fs.writeFileSync(`dist/${cfg.name}/${cfg.name}.lua`, finalSrc);
  fs.copySync(cfg.resources, `dist/${cfg.name}/res`);
}

targets.forEach(buildTarget);
